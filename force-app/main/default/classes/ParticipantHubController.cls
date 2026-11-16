/**
 * Server-side logic for the Participant Hub portal components.
 *
 * Security: runs "with sharing" and every query and DML uses USER_MODE, so the
 * signed-in user's record access (the household sharing set) and field-level
 * security (the Participant_Hub_Portal permission set) are always enforced.
 */
public with sharing class ParticipantHubController {

    private static final Set<String> VISIBLE_STATUSES = new Set<String>{
        'Active', 'Awaiting Participant Approval', 'Completed'
    };

    public class GoalView {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal progressPercent;
        @AuraEnabled public Date targetDate;
    }

    public class RequestView {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String requestType;
        @AuraEnabled public String details;
        @AuraEnabled public String status;
        @AuraEnabled public String staffResponse;
        @AuraEnabled public Datetime createdDate;
    }

    public class PlanView {
        @AuraEnabled public Id planId;
        @AuraEnabled public String planNumber;
        @AuraEnabled public String status;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public Decimal hoursPerWeek;
        @AuraEnabled public String planSummary;
        @AuraEnabled public String easyReadSummary;
        @AuraEnabled public String participantName;
        @AuraEnabled public String preferredContactMethod;
        @AuraEnabled public String communicationNeeds;
        @AuraEnabled public Boolean easyReadPreferred;
        @AuraEnabled public String supportPersonName;
        @AuraEnabled public String supportPersonPhone;
        @AuraEnabled public List<GoalView> goals = new List<GoalView>();
        @AuraEnabled public List<RequestView> requests = new List<RequestView>();
        @AuraEnabled public List<String> contactMethodOptions = new List<String>();
        @AuraEnabled public List<String> requestTypeOptions = new List<String>();
    }

    /**
     * Returns the plan the signed-in user can see. Draft plans are never shown to
     * participants. If several plans are visible, an Active plan is preferred.
     * Returns null when there is nothing to show.
     */
    @AuraEnabled
    public static PlanView getMyPlan() {
        try {
            List<Support_Plan__c> plans = [
                SELECT Id, Name, Status__c, Start_Date__c, End_Date__c, Hours_Per_Week__c,
                       Plan_Summary__c, Easy_Read_Summary__c, Participant__r.Name,
                       Preferred_Contact_Method__c, Communication_Needs__c, Easy_Read_Preferred__c,
                       Support_Person_Name__c, Support_Person_Phone__c
                FROM Support_Plan__c
                WHERE Status__c IN :VISIBLE_STATUSES
                WITH USER_MODE
                ORDER BY Start_Date__c DESC NULLS LAST
                LIMIT 20
            ];
            if (plans.isEmpty()) {
                return null;
            }

            Support_Plan__c chosen = plans[0];
            for (Support_Plan__c candidate : plans) {
                if (candidate.Status__c == 'Active') {
                    chosen = candidate;
                    break;
                }
            }
            Id chosenId = chosen.Id;

            PlanView view = new PlanView();
            view.planId = chosenId;
            view.planNumber = chosen.Name;
            view.status = chosen.Status__c;
            view.startDate = chosen.Start_Date__c;
            view.endDate = chosen.End_Date__c;
            view.hoursPerWeek = chosen.Hours_Per_Week__c;
            view.planSummary = chosen.Plan_Summary__c;
            view.easyReadSummary = chosen.Easy_Read_Summary__c;
            view.participantName = chosen.Participant__r == null ? '' : chosen.Participant__r.Name;
            view.preferredContactMethod = chosen.Preferred_Contact_Method__c;
            view.communicationNeeds = chosen.Communication_Needs__c;
            view.easyReadPreferred = chosen.Easy_Read_Preferred__c;
            view.supportPersonName = chosen.Support_Person_Name__c;
            view.supportPersonPhone = chosen.Support_Person_Phone__c;

            for (Plan_Goal__c goal : [
                SELECT Id, Name, Description__c, Status__c, Progress_Percent__c, Target_Date__c
                FROM Plan_Goal__c
                WHERE Support_Plan__c = :chosenId
                WITH USER_MODE
                ORDER BY Target_Date__c ASC NULLS LAST, Name
            ]) {
                GoalView g = new GoalView();
                g.recordId = goal.Id;
                g.name = goal.Name;
                g.description = goal.Description__c;
                g.status = goal.Status__c;
                g.progressPercent = goal.Progress_Percent__c;
                g.targetDate = goal.Target_Date__c;
                view.goals.add(g);
            }

            for (Plan_Change_Request__c req : [
                SELECT Id, Name, Request_Type__c, Details__c, Status__c, Staff_Response__c, CreatedDate
                FROM Plan_Change_Request__c
                WHERE Support_Plan__c = :chosenId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 20
            ]) {
                RequestView r = new RequestView();
                r.recordId = req.Id;
                r.name = req.Name;
                r.requestType = req.Request_Type__c;
                r.details = req.Details__c;
                r.status = req.Status__c;
                r.staffResponse = req.Staff_Response__c;
                r.createdDate = req.CreatedDate;
                view.requests.add(r);
            }

            view.contactMethodOptions = activePicklistValues(Support_Plan__c.Preferred_Contact_Method__c);
            view.requestTypeOptions = activePicklistValues(Plan_Change_Request__c.Request_Type__c);
            return view;
        } catch (QueryException e) {
            throw friendlyError('We could not load your plan. Please contact your support team.');
        }
    }

    /** Saves the communication preferences a participant is allowed to edit. */
    @AuraEnabled
    public static void savePreferences(
        Id planId,
        String preferredContactMethod,
        String communicationNeeds,
        Boolean easyReadPreferred,
        String supportPersonName,
        String supportPersonPhone
    ) {
        if (planId == null) {
            throw friendlyError('We could not find your plan.');
        }
        Support_Plan__c plan = new Support_Plan__c(
            Id = planId,
            Preferred_Contact_Method__c = String.isBlank(preferredContactMethod) ? null : preferredContactMethod,
            Communication_Needs__c = communicationNeeds,
            Easy_Read_Preferred__c = easyReadPreferred == true,
            Support_Person_Name__c = supportPersonName,
            Support_Person_Phone__c = supportPersonPhone
        );
        try {
            update as user plan;
        } catch (DmlException e) {
            throw friendlyError(e.getDmlMessage(0));
        }
    }

    /** Creates a change request for staff to review. Status starts as Submitted. */
    @AuraEnabled
    public static void createChangeRequest(Id planId, String requestType, String details) {
        if (planId == null) {
            throw friendlyError('We could not find your plan.');
        }
        if (String.isBlank(requestType)) {
            throw friendlyError('Please choose what you would like to change.');
        }
        if (String.isBlank(details)) {
            throw friendlyError('Please tell us about the change you would like.');
        }
        if (details.length() > 2000) {
            throw friendlyError('Please keep your request under 2000 characters.');
        }

        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
        Plan_Change_Request__c request = new Plan_Change_Request__c(
            Support_Plan__c = planId,
            Requested_By__c = contactId,
            Request_Type__c = requestType,
            Details__c = details.trim()
        );
        try {
            insert as user request;
        } catch (DmlException e) {
            throw friendlyError(e.getDmlMessage(0));
        }
    }

    private static List<String> activePicklistValues(Schema.SObjectField field) {
        List<String> values = new List<String>();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static AuraHandledException friendlyError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}
