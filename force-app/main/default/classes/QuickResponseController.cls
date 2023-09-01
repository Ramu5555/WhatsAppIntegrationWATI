public with sharing class QuickResponseController {
   
    @AuraEnabled
    public static void deleteQuickResponse(List<Quick_Response__c> deleteResponse){
        DELETE deleteResponse;
    }
    @AuraEnabled
    public static void updateQuickResponse(Quick_Response__c updateResponse){
        updateResponse.No_of_Times_Used__c = updateResponse.No_of_Times_Used__c + 1;
        UPDATE updateResponse;
    }
    @AuraEnabled(cacheable = true)
    public static List<Quick_Response__c> openQuickResponses(String searchKey, String selectOption)
    {
        List<Quick_Response__c> res;
        String key = '%' + searchKey + '%';
        if(selectOption == 'MostUsed')
        {
            res = [select id,Name,Description__c,CreatedDate,No_of_Times_Used__c from Quick_Response__c WHERE Name LIKE :key ORDER BY No_of_Times_Used__c DESC LIMIT 10 ];
        }
        else if(selectOption == 'NewestFirst')
        {
             res = [select id,Name,Description__c,CreatedDate,No_of_Times_Used__c from Quick_Response__c WHERE Name LIKE :key ORDER BY CreatedDate DESC LIMIT 10 ];
        }
        return res;
    }
}