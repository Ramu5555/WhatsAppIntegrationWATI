@isTest
public class QuickResponseControllerTest {
    @isTest
    public static void testMethod1() {
        List<Quick_Response__c> nqrList = new List<Quick_Response__c>();
        Quick_Response__c nqr = new Quick_Response__c();
        nqr.Name = 'Test';
        nqr.Description__c = 'Test D';
        nqr.No_of_Times_Used__c = 2.0;
        nqrList.add(nqr);
        insert nqrList;

        QuickResponseController.updateQuickResponse(nqr);
        QuickResponseController.deleteQuickResponse(nqrList);
        List<Quick_Response__c> updatedNqrList = QuickResponseController.openQuickResponses('a', 'MostUsed');

        // Add assertions here
        System.assertEquals(1, nqrList.size());
        System.assertEquals('Test', nqrList[0].Name);
    }

    @isTest
    public static void testMethod2() {
        List<Quick_Response__c> nqrList = new List<Quick_Response__c>();
        Quick_Response__c nqr = new Quick_Response__c();
        nqr.Name = 'Test';
        nqr.Description__c = 'Test D';
        nqr.No_of_Times_Used__c = 2.0;
        nqrList.add(nqr);
        insert nqrList;

        QuickResponseController.updateQuickResponse(nqr);
        QuickResponseController.deleteQuickResponse(nqrList);
        List<Quick_Response__c> updatedNqrList = QuickResponseController.openQuickResponses('a', 'NewestFirst');

        // Add assertions here
        System.assertEquals(1, nqrList.size());
        System.assertEquals('Test', nqrList[0].Name);
    }
}