@IsTest
private class ParticipantHubControllerTest {

    @TestSetup
    static void setup() {
        // The controller runs in user mode, so the running user needs the staff permission set.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id userId = UserInfo.getUserId();
            PermissionSet staff = [SELECT Id FROM PermissionSet WHERE Name = 'Participant_Hub_Staff' LIMIT 1];
            Integer existing = [
                SELECT COUNT() FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSetId = :staff.Id
            ];
            if (existing == 0) {
                insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = staff.Id);
            }
        }

        Account household = new Account(Name = 'Test Household');
        insert household;
        Contact participant = new Contact(FirstName = 'Test', LastName = 'Participant', AccountId = household.Id);
        insert participant;

        Support_Plan__c active = new Support_Plan__c(
            Participant__c = participant.Id,
            Household__c = household.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-30),
            End_Date__c = Date.today().addDays(150),
            Hours_Per_Week__c = 6,
            Plan_Summary__c = 'Summary',
            Easy_Read_Summary__c = 'Easy line one.\nEasy line two.'
        );
        // A newer draft that must never be shown to participants.
        Support_Plan__c draft = new Support_Plan__c(
            Participant__c = participant.Id,
            Household__c = household.Id,
            Status__c = 'Draft',
            Start_Date__c = Date.today()
        );
        insert new List<Support_Plan__c>{ active, draft };

        insert new Plan_Goal__c(
            Support_Plan__c = active.Id,
            Name = 'Test goal',
            Status__c = 'In Progress',
            Progress_Percent__c = 40
        );
    }

    @IsTest
    static void getMyPlanReturnsActivePlanAndIgnoresDraft() {
        ParticipantHubController.PlanView view = ParticipantHubController.getMyPlan();

        System.Assert.isNotNull(view, 'A plan should be returned');
        System.Assert.areEqual('Active', view.status);
        System.Assert.areEqual('Test Participant', view.participantName);
        System.Assert.areEqual(1, view.goals.size());
        System.Assert.areEqual('Test goal', view.goals[0].name);
        System.Assert.isFalse(view.contactMethodOptions.isEmpty());
        System.Assert.isFalse(view.requestTypeOptions.isEmpty());
    }

    @IsTest
    static void getMyPlanReturnsNullWhenOnlyDraftExists() {
        delete [SELECT Id FROM Support_Plan__c WHERE Status__c = 'Active'];

        System.Assert.isNull(ParticipantHubController.getMyPlan(), 'Draft plans must not be shown');
    }

    @IsTest
    static void savePreferencesUpdatesThePlan() {
        Support_Plan__c plan = [SELECT Id FROM Support_Plan__c WHERE Status__c = 'Active' LIMIT 1];

        ParticipantHubController.savePreferences(
            plan.Id, 'Email', 'A quiet room please', true, 'Sam Helper', '0400 111 222'
        );

        Support_Plan__c updated = [
            SELECT Preferred_Contact_Method__c, Communication_Needs__c,
                   Easy_Read_Preferred__c, Support_Person_Name__c
            FROM Support_Plan__c WHERE Id = :plan.Id
        ];
        System.Assert.areEqual('Email', updated.Preferred_Contact_Method__c);
        System.Assert.areEqual('A quiet room please', updated.Communication_Needs__c);
        System.Assert.isTrue(updated.Easy_Read_Preferred__c);
        System.Assert.areEqual('Sam Helper', updated.Support_Person_Name__c);
    }

    @IsTest
    static void savePreferencesRequiresAPlan() {
        Boolean threw = false;
        try {
            ParticipantHubController.savePreferences(null, 'Email', null, false, null, null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.Assert.isTrue(threw, 'A missing plan should be rejected');
    }

    @IsTest
    static void createChangeRequestInsertsSubmittedRequest() {
        Support_Plan__c plan = [SELECT Id FROM Support_Plan__c WHERE Status__c = 'Active' LIMIT 1];

        ParticipantHubController.createChangeRequest(plan.Id, 'Change support hours', 'Two more hours please');

        Plan_Change_Request__c saved = [
            SELECT Status__c, Details__c, Request_Type__c FROM Plan_Change_Request__c LIMIT 1
        ];
        System.Assert.areEqual('Submitted', saved.Status__c);
        System.Assert.areEqual('Two more hours please', saved.Details__c);
        System.Assert.areEqual('Change support hours', saved.Request_Type__c);

        ParticipantHubController.PlanView view = ParticipantHubController.getMyPlan();
        System.Assert.areEqual(1, view.requests.size());
    }

    @IsTest
    static void createChangeRequestValidatesInput() {
        Support_Plan__c plan = [SELECT Id FROM Support_Plan__c WHERE Status__c = 'Active' LIMIT 1];

        Boolean missingDetails = false;
        try {
            ParticipantHubController.createChangeRequest(plan.Id, 'Other', '   ');
        } catch (AuraHandledException e) {
            missingDetails = true;
        }
        System.Assert.isTrue(missingDetails, 'Blank details should be rejected');

        Boolean missingType = false;
        try {
            ParticipantHubController.createChangeRequest(plan.Id, null, 'Something');
        } catch (AuraHandledException e) {
            missingType = true;
        }
        System.Assert.isTrue(missingType, 'A missing request type should be rejected');
    }
}
