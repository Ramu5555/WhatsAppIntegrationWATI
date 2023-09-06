public with sharing class WhatsAppSetupScreenController {
    
    private static List<DhruvsoftWATI__Template_Param_Configuration__mdt> getTemplateDetails(){
        List<DhruvsoftWATI__Template_Param_Configuration__mdt> tempParamMDTList = [SELECT MasterLabel,Template_Name__c, DhruvsoftWATI__SF_Field_API_Name__c, DhruvsoftWATI__WA_Param_Name__c, DhruvsoftWATI__Template_Body__c FROM DhruvsoftWATI__Template_Param_Configuration__mdt  WHERE WA_Param_Name__c !=''];
        return tempParamMDTList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TemplateWrapper> getWhatsAppSetupScreen() {
        List<DhruvsoftWATI__Template_Param_Configuration__mdt> tempParamMDTList = getTemplateDetails();
        Map<String, TemplateWrapper> tempWrapMap = new Map<String, TemplateWrapper>(); 
        
        for(DhruvsoftWATI__Template_Param_Configuration__mdt tempMDT : tempParamMDTList) {
            String sfField = tempMDT.SF_Field_API_Name__c;
            List<FieldDefinition> fields;
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = [SELECT MasterLabel, DhruvsoftWATI__Object_Name__c,DhruvsoftWATI__Phone_Field__c,DhruvsoftWATI__API_Key__c,QualifiedApiName, DhruvsoftWATI__End_Point_URL__c  FROM DhruvsoftWATI__API_Configurations__mdt WHERE MasterLabel='WATI API Config'];
            if(sfField != null){
                fields = [SELECT Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName =: watiAPIConfig.DhruvsoftWATI__Object_Name__c AND QualifiedApiName =: sfField LIMIT 1];   
            }   
            String sfFieldApiName = (sfField != null) ? fields[0].Label : '';
            
            if (!tempWrapMap.containsKey(tempMDT.Template_Name__c)) {
                TemplateWrapper tempWrap = new TemplateWrapper();
                tempWrap.templateName = tempMDT.Template_Name__c;
                tempWrap.paramsList = new List<ParamWrapper>();
                tempWrapMap.put(tempMDT.Template_Name__c, tempWrap);
            }
            
            ParamWrapper param = new ParamWrapper();
            param.paramName = tempMDT.WA_Param_Name__c;
            param.paramValue = sfFieldApiName;
            
            TemplateWrapper tempWrapToUpdate = tempWrapMap.get(tempMDT.Template_Name__c);
            tempWrapToUpdate.paramsList.add(param);
        }
        
        List<TemplateWrapper> tempWrapList = tempWrapMap.values();
        System.debug('Template Wrapper: ' + tempWrapList);
        
        return tempWrapList;
    }
    
    @AuraEnabled(cacheable=true)
    public static void saveTemplateParams(String tempWrapString) {
        System.debug('tempWrapString: ' + tempWrapString);
        List<TemplateWrapper> tempWrapperList = (List<TemplateWrapper>)JSON.deserialize(tempWrapString, List<TemplateWrapper>.class);
        System.debug('tempWapper: ' + tempWrapperList);
        
        for(TemplateWrapper tempWrap : tempWrapperList) {
            for(ParamWrapper param : tempWrap.paramsList) {
                CustomMetadataUtils.updateTemplateMetaData(tempWrap.templateName, param.paramName, param.paramValue);
            } 
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getContactFiedls(){
        DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = [SELECT MasterLabel, DhruvsoftWATI__Object_Name__c,DhruvsoftWATI__Phone_Field__c,DhruvsoftWATI__API_Key__c,QualifiedApiName, DhruvsoftWATI__End_Point_URL__c  FROM DhruvsoftWATI__API_Configurations__mdt WHERE MasterLabel='WATI API Config'];
        system.debug('Object Name----->'+watiAPIConfig.DhruvsoftWATI__Object_Name__c);
        List<String> fieldsInList = new List<String>();
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(watiAPIConfig.DhruvsoftWATI__Object_Name__c).getDescribe();
        List<Schema.SObjectField> fields = objectDescribe.fields.getMap().values();
        for (Schema.SObjectField field : fields) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if(fieldDescribe.getType().name() == 'STRING' || fieldDescribe.getType().name() == 'PICKLIST'){
                fieldsInList.add(fieldDescribe.getName());
            }
        }
        return fieldsInList;
    }
    
    public static void createWhatsAppContact(){
        List<Contact> conList = new List<Contact>();
        Contact con = new Contact();
        con.LastName = 'WhatsApp Integration Contact';
        con.Email = 'whatsappintegration@WATI.com';
        con.Description = 'Sample WhatsApp contact to store chat documents.';
        conList.add(con);
        Database.UpsertResult[] upsertResults = Database.upsert(conList, Contact.Fields.Email, true);
    }
    
   	@future(callout=true)
    public static void createRemoteSiteSetting(String remoteSiteurl){
        System.debug('URL: '+remoteSiteurl);
        try{
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
            service.SessionHeader = new MetadataService.SessionHeader_element();
            
            string paramvalue = EncodingUtil.base64Encode(Blob.valueOf(userinfo.getSessionId()));
            System.debug('paramvalue:: '+ UserInfo.getSessionId());
            service.SessionHeader.sessionId = UserInfo.getSessionId();
            
            MetadataService.RemoteSiteSetting remoteSiteSetting = new MetadataService.RemoteSiteSetting();
            remoteSiteSetting.fullName = 'WhatsApp';
            remoteSiteSetting.url = remoteSiteurl;
            remoteSiteSetting.isActive = true;
            remoteSiteSetting.DisableProtocolSecurity = false;
            remoteSiteSetting.description = 'WhatsApp Remote Site Setting';
            
            List<MetadataService.UpsertResult> results = service.upsertMetadata(new List<MetadataService.Metadata>{ remoteSiteSetting });
            System.debug('results:: '+results[0].success);
                    createWhatsAppContact();

           
        }
        catch(Exception e){
            System.debug('Exception: '+e.getMessage()+' Line Number: '+e.getLineNumber()+' Type: '+e.getTypeName());
        }
    }
    /*=================================All Wrapper Classess=====================================*/
    public class TemplateWrapper {
        @AuraEnabled public String templateName;
        @AuraEnabled public List<ParamWrapper> paramsList;
    }
    
    public class ParamWrapper {
        @AuraEnabled public String paramName;
        @AuraEnabled public String paramValue;
    }
}