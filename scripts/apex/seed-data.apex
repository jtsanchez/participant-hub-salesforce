// Participant Hub seed data. All people, organisations and details are fictional.
// Run: sf apex run --file scripts/apex/seed-data.apex --target-org experience-demo

List<Program__c> programs = new List<Program__c>{
    new Program__c(Name = 'Everyday Independence', Status__c = 'Active',
        Description__c = 'Support with daily living skills, routines and community access.'),
    new Program__c(Name = 'Work and Learning', Status__c = 'Active',
        Description__c = 'Coaching for study, work experience and job readiness.'),
    new Program__c(Name = 'Family and Carer Connect', Status__c = 'Active',
        Description__c = 'Information, peer groups and short-break planning for families and carers.')
};
insert programs;

List<Account> households = new List<Account>{
    new Account(Name = 'Alder Household'),
    new Account(Name = 'Okafor Household'),
    new Account(Name = 'Reyes Household'),
    new Account(Name = 'Lindqvist Household')
};
insert households;

List<Contact> participants = new List<Contact>{
    new Contact(FirstName = 'Maya', LastName = 'Alder', AccountId = households[0].Id, Email = 'maya.alder@example.com'),
    new Contact(FirstName = 'Tobias', LastName = 'Okafor', AccountId = households[1].Id, Email = 'tobias.okafor@example.com'),
    new Contact(FirstName = 'Sofia', LastName = 'Reyes', AccountId = households[2].Id, Email = 'sofia.reyes@example.com'),
    new Contact(FirstName = 'Jonas', LastName = 'Lindqvist', AccountId = households[3].Id, Email = 'jonas.lindqvist@example.com')
};
insert participants;

// Enrollments: participant i joins program idx[i]
Integer[] programIdx = new Integer[]{ 0, 1, 0, 2 };
String[] enrollmentStatus = new String[]{ 'Active', 'Active', 'Active', 'Referred' };
List<Program_Enrollment__c> enrollments = new List<Program_Enrollment__c>();
for (Integer i = 0; i < participants.size(); i++) {
    enrollments.add(new Program_Enrollment__c(
        Participant__c = participants[i].Id,
        Program__c = programs[programIdx[i]].Id,
        Status__c = enrollmentStatus[i],
        Start_Date__c = Date.today().addDays(-60 + (i * 10))
    ));
}
insert enrollments;

String[] planStatus = new String[]{ 'Active', 'Awaiting Participant Approval', 'Active', 'Draft' };
Decimal[] hours = new Decimal[]{ 8, 12, 6, 4 };
String[] contactMethod = new String[]{ 'Text message', 'Email', 'Phone call', 'Video call' };
String[] needs = new String[]{
    'Prefers short messages and a few days to reply.',
    'Likes a quiet space for meetings. Please give an agenda ahead of time.',
    'Likes a support person to join calls.',
    'Needs extra time to make decisions. Avoid calls before 10am.'
};
String[] supportPerson = new String[]{ 'Priya Alder', 'Ngozi Okafor', 'Marco Reyes', 'Elsa Lindqvist' };
String[] summaries = new String[]{
    'Maya is working on cooking simple meals, travelling independently on local buses, and joining a weekly community art group.',
    'Tobias is building work skills with a supported placement at a local garden centre and a weekly job-readiness session.',
    'Sofia is practising daily routines at home, managing her own appointments, and starting a swimming class.',
    'Jonas is at the start of his plan. Goals are being agreed with him and his mother.'
};
String[] easyRead = new String[]{
    'Maya wants to learn to cook.\nMaya wants to catch the bus on her own.\nMaya will go to an art group each week.',
    'Tobias is learning work skills.\nTobias works at a garden centre.\nTobias goes to a job class each week.',
    'Sofia is learning daily routines.\nSofia will make her own appointments.\nSofia is starting swimming.',
    'Jonas has just started his plan.\nJonas and his mum are choosing goals.\nWe will check the plan with Jonas.'
};

List<Support_Plan__c> plans = new List<Support_Plan__c>();
for (Integer i = 0; i < participants.size(); i++) {
    plans.add(new Support_Plan__c(
        Participant__c = participants[i].Id,
        Household__c = households[i].Id,
        Program_Enrollment__c = enrollments[i].Id,
        Status__c = planStatus[i],
        Start_Date__c = Date.today().addDays(-30 + (i * 5)),
        End_Date__c = Date.today().addDays(150 + (i * 5)),
        Hours_Per_Week__c = hours[i],
        Plan_Summary__c = summaries[i],
        Easy_Read_Summary__c = easyRead[i],
        Preferred_Contact_Method__c = contactMethod[i],
        Communication_Needs__c = needs[i],
        Easy_Read_Preferred__c = (i == 1 || i == 3),
        Support_Person_Name__c = supportPerson[i],
        Support_Person_Phone__c = '0400 000 00' + i
    ));
}
insert plans;

List<Plan_Goal__c> goals = new List<Plan_Goal__c>{
    new Plan_Goal__c(Support_Plan__c = plans[0].Id, Name = 'Cook three simple meals', Status__c = 'In Progress', Progress_Percent__c = 60, Target_Date__c = Date.today().addDays(60), Description__c = 'Learn to plan, shop for and cook three meals with minimal prompting.'),
    new Plan_Goal__c(Support_Plan__c = plans[0].Id, Name = 'Travel by local bus', Status__c = 'In Progress', Progress_Percent__c = 35, Target_Date__c = Date.today().addDays(90), Description__c = 'Practise a regular route, first with a support worker, then alone.'),
    new Plan_Goal__c(Support_Plan__c = plans[0].Id, Name = 'Join a community art group', Status__c = 'Achieved', Progress_Percent__c = 100, Target_Date__c = Date.today().addDays(-10), Description__c = 'Attend a weekly art group at the community centre.'),
    new Plan_Goal__c(Support_Plan__c = plans[1].Id, Name = 'Complete a work placement', Status__c = 'In Progress', Progress_Percent__c = 45, Target_Date__c = Date.today().addDays(100), Description__c = 'Complete a 12-week supported placement.'),
    new Plan_Goal__c(Support_Plan__c = plans[1].Id, Name = 'Update my resume', Status__c = 'Not Started', Progress_Percent__c = 0, Target_Date__c = Date.today().addDays(45), Description__c = 'Write a short resume with a job coach.'),
    new Plan_Goal__c(Support_Plan__c = plans[2].Id, Name = 'Book my own appointments', Status__c = 'In Progress', Progress_Percent__c = 50, Target_Date__c = Date.today().addDays(75), Description__c = 'Use a calendar and phone to book and keep appointments.'),
    new Plan_Goal__c(Support_Plan__c = plans[2].Id, Name = 'Start swimming class', Status__c = 'Not Started', Progress_Percent__c = 0, Target_Date__c = Date.today().addDays(30), Description__c = 'Enrol in a weekly accessible swimming class.'),
    new Plan_Goal__c(Support_Plan__c = plans[3].Id, Name = 'Agree on my goals', Status__c = 'In Progress', Progress_Percent__c = 20, Target_Date__c = Date.today().addDays(21), Description__c = 'Choose three goals with Jonas and his mother.')
};
insert goals;

List<Plan_Change_Request__c> requests = new List<Plan_Change_Request__c>{
    new Plan_Change_Request__c(Support_Plan__c = plans[0].Id, Requested_By__c = participants[0].Id, Request_Type__c = 'Change support hours', Status__c = 'Submitted', Details__c = 'I would like two more hours a week while I practise the bus route.'),
    new Plan_Change_Request__c(Support_Plan__c = plans[2].Id, Requested_By__c = participants[2].Id, Request_Type__c = 'Update contact details', Status__c = 'Approved', Details__c = 'Please use my new phone number for calls.', Staff_Response__c = 'Updated. Thank you.'),
    new Plan_Change_Request__c(Support_Plan__c = plans[1].Id, Requested_By__c = participants[1].Id, Request_Type__c = 'Change a goal', Status__c = 'Declined', Details__c = 'I would like to swap my placement for a different one.', Staff_Response__c = 'Let us talk about this at your next catch-up so we can find the right fit.')
};
insert requests;

System.debug('Participant Hub seed data created: ' + participants.size() + ' participants, ' + plans.size() + ' plans, ' + goals.size() + ' goals, ' + requests.size() + ' change requests.');
