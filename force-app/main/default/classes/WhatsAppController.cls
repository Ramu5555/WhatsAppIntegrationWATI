public class WhatsAppController {
    
    @TestVisible private static DhruvsoftWATI__API_Configurations__mdt getAPIConfigs(){
        DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = [SELECT MasterLabel, DhruvsoftWATI__Object_Name__c,DhruvsoftWATI__Phone_Field__c,DhruvsoftWATI__API_Key__c,QualifiedApiName, DhruvsoftWATI__End_Point_URL__c  FROM DhruvsoftWATI__API_Configurations__mdt WHERE MasterLabel='WATI API Config'];
        return watiAPIConfig;
    }
    /*=======================================Template Save in Custom Metadata==========================================*/
    @AuraEnabled(cacheable=true)
    public static void saveTemplateMetadata()
    {
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getMessageTemplates?pageSize=100&pageNumber=1');
            request.setHeader('Authorization', 'Bearer ' +watiAPIConfig.API_Key__c);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                ResponseWrapper responseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                if(responseWrapper.result == 'success'){
                    SuccessWrapper successWrap = (SuccessWrapper)JSON.deserialize(response.getBody(), SuccessWrapper.class);
                    for(MessageTemplates temp : successWrap.messageTemplates){
                        if(temp.status == 'APPROVED'){
                            CustomParams cusp = new CustomParams();
                            if(temp.customParams != null && !temp.customParams.isEmpty()){
                                for(CustomParams cuspa : temp.customParams){
                                    CustomMetadataUtils.createTemplateMetaData(temp.elementName,cuspa.paramName,temp.bodyOriginal);
                                }
                            }else{
                                CustomMetadataUtils.createTemplateMetaData(temp.elementName,'',temp.bodyOriginal);
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug('Exception: '+e.getMessage()+' Line No: '+e.getLineNumber());
        }
        
    }
    /*=======================================Get Templates==========================================*/
    @AuraEnabled(cacheable = true)
    public static WATIMainWrapper getTemplates(){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        List<TemplatesWrapper> watiTemplatesList = new List<TemplatesWrapper>();
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            Map<String,String> tempMap = new Map<String,String>();
            List<DhruvsoftWATI__Template_Param_Configuration__mdt> tempParamMDTList = [SELECT MasterLabel,DhruvsoftWATI__SF_Field_API_Name__c,DhruvsoftWATI__WA_Param_Name__c,DhruvsoftWATI__Template_Body__c FROM DhruvsoftWATI__Template_Param_Configuration__mdt LIMIT 9999];
            
            for(DhruvsoftWATI__Template_Param_Configuration__mdt tempParamMD : tempParamMDTList)
            {
                Integer lastSpaceIndex = tempParamMD.MasterLabel.lastIndexOf(' ');
                String tempName = tempParamMD.MasterLabel.substring(0, lastSpaceIndex);
                tempMap.put(tempName,tempParamMD.Template_Body__c);
            }
            for(String tempName : tempMap.keySet()){
                TemplatesWrapper tempWrap = new TemplatesWrapper(); 
                tempWrap.templateName = tempName;
                tempWrap.templatebody = tempMap.get(tempName);
                watiTemplatesList.add(tempWrap);
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.watiTemplatesList = watiTemplatesList;
        waitMainWrapperData.errorDetails = failureWrap;
        return waitMainWrapperData;
    }
    /*=======================================Get Messages==========================================*/
    
    @AuraEnabled
    public static WATIMainWrapper getMessages(string recordId,string nextPageLink){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        List<MessageWrapper> watiMessagesList = New List<MessageWrapper>();
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(string.isNotBlank(nextPageLink)){
                request.setEndpoint(nextPageLink);
            }else{
                if(mobNumber != null){
                    request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getMessages/'+mobNumber+'?pageSize=10&pageNumber=1');
                } 
            }
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                isSuccess = true;
                ResponseWrapper responseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                if(responseWrapper.result == 'success'){
                    SuccessWrapper successWrap = (SuccessWrapper)JSON.deserialize(response.getBody(), SuccessWrapper.class);
                    waitMainWrapperData.prevPageLink = successWrap.link.prevPage;
                    waitMainWrapperData.nextPageLink = successWrap.link.nextPage;
                    Messages allMessages = successWrap.messages;
                    List<fileWrapper> fileWrapList = new List<fileWrapper>();
                    for(Items textMess : allMessages.items){
                        if(textMess.eventType == 'message'){
                            if(textMess.type == 'document' || textMess.type == 'image' || textMess.type == 'sticker'){
                                string fileBody = getfiles(textMess.data);
                                Blob fileBlob = EncodingUtil.base64Decode(fileBody);
                                String dataM = textMess.data;
                                String fileName = dataM.substringAfterLast('/');
                                fileWrapper fileWrap = new fileWrapper();
                                fileWrap.fileName = fileName;
                                fileWrap.fileBlob = fileBlob;
                                fileWrap.typeMess = textMess.type;
                                fileWrapList.add(fileWrap);
                            }
                        }
                    }
                    Map<String,String> fileIdList = insertFiles(fileWrapList,recordId);
                    for(Items textMessage : allMessages.items){
                        MessageWrapper messWrap = new MessageWrapper();
                        if(textMessage.eventType == 'message'){
                            if(textMessage.type == 'document' || textMessage.type == 'image' || textMessage.type == 'sticker'){
                                String dataM = textMessage.data;
                                String fileName = dataM.substringAfterLast('/');
                                messWrap.messtype = true;
                                messWrap.Doctype = textMessage.type;
                                if(textMessage.type == 'document'){
                                    messWrap.Doc = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName);
                                }
                                else if(textMessage.type == 'image' || textMessage.type == 'sticker'){
                                    messWrap.img = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName); 
                                }
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }else{
                                messWrap.textMessage = textMessage.text;
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }
                            messWrap.messageStatus = textMessage.owner;
                        }else if(textMessage.eventType == 'broadcastMessage'){
                            messWrap.textMessage = textMessage.finalText;
                            messWrap.messageStatus = true;
                            if(textMessage.statusString == 'SENT'){
                                messWrap.singleTick = true;
                            }else if(textMessage.statusString == 'DELIVERED'){
                                messWrap.doubleTick = true;
                            }else if(textMessage.statusString == 'READ'){
                                messWrap.blueTick = true;
                            }
                        }
                        messWrap.createdDate = textMessage.created;
                        if(String.isNotBlank(messWrap.textMessage)){
                            watiMessagesList.add(messWrap); 
                        }
                    }
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.watiMessagesList = watiMessagesList;
        waitMainWrapperData.errorDetails = failureWrap;
        return waitMainWrapperData;
    }
    
    /*=======================================Get Files==========================================*/
    
    private static String getfiles(String fileName){
        string fileData = '';
        DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(+watiAPIConfig.End_Point_URL__c+'v1/getMedia?fileName='+fileName);
        request.setHeader('Authorization', 'Bearer ' +watiAPIConfig.API_Key__c);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            blob fileBody = response.getBodyAsBlob();
            fileData =  EncodingUtil.base64Encode(fileBody);
        }else{
            fileData = 'ERROR';
        }
        return fileData;
    }
    
    /*=======================================Insert Files==========================================*/    
    
    @TestVisible private static Map<String,String> insertFiles(List<fileWrapper> fileList, String recordId){
        Map<String,Id> fileMap = new Map<String,Id>();
        Map<String,String> fileIdMap = new Map<String,String>();
        list<ContentDocumentLink> docLinksList = [SELECT Id, ContentDocument.Title,ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId =: recordId];
        for(ContentDocumentLink cdl : docLinksList){
            fileMap.put(cdl.ContentDocument.Title,cdl.ContentDocumentId);
        }
        
        List<ContentVersion> cvList = new List<ContentVersion>();
        for(fileWrapper fileWrap : fileList){
            if(!fileMap.keySet().contains(fileWrap.fileName)){
                ContentVersion cv = new ContentVersion();
                cv.Title = fileWrap.fileName; 
                if(fileWrap.typeMess == 'document'){
                    cv.PathOnClient = 'path/to/my/document.pdf';
                }
                if(fileWrap.typeMess == 'image'){
                    cv.PathOnClient = fileWrap.fileName; 
                }
                cv.VersionData = fileWrap.fileBlob;
                cv.Origin = 'H';
                cvList.add(cv);            
            }
            else{
                fileIdMap.put(fileWrap.fileName,fileMap.get(fileWrap.fileName));
            }
        }
        if( !Test.isRunningTest() ){
            insert cvList;
        }
        Set<Id> fileIds = new Set<Id>();
        for(ContentVersion cv : cvList){
            fileIds.add(cv.Id);
        }
        List<ContentVersion> cvList2 = [SELECT Id, Title, ContentDocumentId 
                                        FROM ContentVersion WHERE Id IN :fileIds];
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        for(ContentVersion cv2 : cvList2){
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = cv2.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId; 
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            cdList.add(contentDocumentLink);
        }
        if( !Test.isRunningTest() ){
            insert cdList;
        }
        
        list<ContentDocumentLink> docLinksList1 = [SELECT Id, ContentDocument.Title,ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId =: recordId];
        
        for(ContentDocumentLink cd : docLinksList1){
            fileIdMap.put(cd.ContentDocument.Title, cd.ContentDocumentId);    
        }
        return fileIdMap;
    }
    
    /*=======================================Refresh Messages==========================================*/
    @AuraEnabled(Cacheable=true)
    public static WATIMainWrapper refreshMessages(string recordId,string nextPageLink){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        List<MessageWrapper> watiMessagesList = New List<MessageWrapper>();
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(string.isNotBlank(nextPageLink)){
                request.setEndpoint(nextPageLink);
            }else{
                if(mobNumber != null){
                    request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getMessages/'+mobNumber+'?pageSize=10&pageNumber=1');
                } 
            }
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                isSuccess = true;
                ResponseWrapper responseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                if(responseWrapper.result == 'success'){
                    SuccessWrapper successWrap = (SuccessWrapper)JSON.deserialize(response.getBody(), SuccessWrapper.class);
                    waitMainWrapperData.prevPageLink = successWrap.link.prevPage;
                    waitMainWrapperData.nextPageLink = successWrap.link.nextPage;
                    Messages allMessages = successWrap.messages;
                    List<fileWrapper> fileWrapList = new List<fileWrapper>();
                    for(Items textMess : allMessages.items){
                        if(textMess.eventType == 'message'){
                            if(textMess.type == 'document' || textMess.type == 'image'){
                                string fileBody = getfiles(textMess.data);
                                Blob fileBlob = EncodingUtil.base64Decode(fileBody);
                                String dataM = textMess.data;
                                String fileName = dataM.substringAfterLast('/');
                                fileWrapper fileWrap = new fileWrapper();
                                fileWrap.fileName = fileName;
                                fileWrap.fileBlob = fileBlob;
                                fileWrap.typeMess = textMess.type;
                                fileWrapList.add(fileWrap);
                            }
                        }
                    }
                    Map<String,String> fileIdList = insertFiles(fileWrapList,recordId);
                    for(Items textMessage : allMessages.items){
                        MessageWrapper messWrap = new MessageWrapper();
                        if(textMessage.eventType == 'message'){
                            if(textMessage.type == 'document' || textMessage.type == 'image'){
                                String dataM = textMessage.data;
                                String fileName = dataM.substringAfterLast('/');
                                messWrap.messtype = true;
                                messWrap.Doctype = textMessage.type;
                                if(textMessage.type == 'document'){
                                    messWrap.Doc = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName);
                                }
                                else if(textMessage.type == 'image'){
                                    messWrap.img = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName); 
                                }
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }else{
                                messWrap.textMessage = textMessage.text;
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }
                            messWrap.messageStatus = textMessage.owner;
                        }else if(textMessage.eventType == 'broadcastMessage'){
                            messWrap.textMessage = textMessage.finalText;
                            messWrap.messageStatus = true;
                            if(textMessage.statusString == 'SENT'){
                                messWrap.singleTick = true;
                            }else if(textMessage.statusString == 'DELIVERED'){
                                messWrap.doubleTick = true;
                            }else if(textMessage.statusString == 'READ'){
                                messWrap.blueTick = true;
                            }else if(textMessage.statusString == 'FAILED'){
                                messWrap.failedTick = true;
                            }
                        }
                        messWrap.createdDate = textMessage.created;
                        if(String.isNotBlank(messWrap.textMessage)){
                            watiMessagesList.add(messWrap); 
                        }
                    }
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.watiMessagesList = watiMessagesList;
        waitMainWrapperData.errorDetails = failureWrap;
        return waitMainWrapperData;
    }
    
    /*=======================================Send Template==========================================*/
    @AuraEnabled(cacheable = true)
    public static WATIMainWrapper sendTemplate(String recordId,String templateName){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        String invalidNumber;
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            Pattern matchPattern1 = Pattern.compile('^[6-9]\\d{9}$'); //Format: 8885593331
            Pattern matchPattern2 = Pattern.compile('\\(\\d{3}\\)\\s\\d{3}-\\d{4}'); //Format: (888) 559-3331
            Pattern matchPattern3 = Pattern.compile('^\\+91[7-9]\\d{9}$'); //Format: +918885593331
            Pattern matchPattern4 = Pattern.compile('^[6-9]\\d{11}$'); //Format: 918885593331
            Matcher matchCase1;
            Matcher matchCase2;
            Matcher matchCase3;
            Matcher matchCase4;
            if(mobNumber != null)
            {
                matchCase1 = matchPattern1.matcher(mobNumber);
                matchCase2 = matchPattern2.matcher(mobNumber);
                matchCase3 = matchPattern3.matcher(mobNumber);
                matchCase4 = matchPattern4.matcher(mobNumber);
            }
            String MobileNumber;
            if(mobNumber != null && (matchCase1.matches()==TRUE || matchCase2.matches()==TRUE || matchCase3.matches()==TRUE || matchCase4.matches()==TRUE))
            {
                MobileNumber = mobNumber;
            }
            else if(mobNumber == null || mobNumber == '')
            {
                invalidNumber = 'Invalid Mobile Number Please check Mobile Number';
            }
            else
            {
                invalidNumber = 'Invalid Mobile Number Please check Mobile Number';
            }
            
            String paramValue;
            Set<String> SobjectFields = Schema.getGlobalDescribe().get(watiAPIConfig.Object_Name__c).getDescribe().fields.getMap().keySet();    
            List<String> fieldsInList = new List<String>(SobjectFields);
            String contQuery = 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+watiAPIConfig.Object_Name__c +' WHERE Id=:recordId';
            String conQuery = String.valueOf(contQuery);
            sObject recordData2 = database.query(conQuery);
            List<Template_Param_Configuration__mdt> tempParamMDTList = [SELECT MasterLabel,SF_Field_API_Name__c,WA_Param_Name__c,Template_Body__c FROM Template_Param_Configuration__mdt WHERE DhruvsoftWATI__Template_Name__c =: templateName  LIMIT 9999];
            List<Parameters> parms = New List<Parameters>();
            for(Template_Param_Configuration__mdt tempParamMDT : tempParamMDTList){
                String fieldAPIName = tempParamMDT.SF_Field_API_Name__c;
                Boolean containsField = conQuery.contains(fieldAPIName.toLowerCase());
                if (containsField) {
                    paramValue = string.valueOf(recordData2.get(fieldAPIName));
                } else {
                }
                if(paramValue != null){
                    parms.add(new Parameters(tempParamMDT.WA_Param_Name__c,paramValue));
                }
                else{
                    waitMainWrapperData.paramEmptyError = 'Please Check the value '+fieldAPIName;
                }     
            }
            SendTemplateWrapper sendTempWrap = new SendTemplateWrapper();
            sendTempWrap.template_name = templateName;
            sendTempWrap.broadcast_name = templateName;
            
            sendTempWrap.parameters = parms;            
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendTemplateMessage?whatsappNumber='+MobileNumber);
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setHeader('Content-Type', 'application/json-patch+json');
            request.setTimeout(2000);
            request.setBody(JSON.serialize(sendTempWrap));
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                object results = (object)JSON.deserializeUntyped(response.getBody());
                Map<String,Object> tempMap = (Map<String,Object>)results;
                Boolean resultResp = (Boolean)tempMap.get('result');
                if(resultResp == true){
                    isSuccess = true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
            
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        waitMainWrapperData.invalidMobileNumber = invalidNumber;
        return waitMainWrapperData;
    }
    
    /*=======================================Send Templates==========================================*/
    
    @AuraEnabled(cacheable = true)
    public static WATIMainWrapper sendTemplates(List<string> recordsIdSet,String templateName){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        FailureWrapper failureWrap = new FailureWrapper();
        Map<String,String> validNumbers = new Map<String,String>();
        Map<String,String> invalidMembers = new Map<String,String>();
        List<String> invalidNumbers = new List<String>();
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
                        
            List<string> idsList = new List<string>();
            set<Id> ids = new set<Id>();
            for(string recordId:recordsIdSet){
                idsList = recordId.split(',');
            }
            for(string recordId:idsList){
                ids.add(id.valueOf(recordId));
            }
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id IN:ids';
            List<sObject> listOfRecords = database.query(query);
            
            Pattern matchPattern1 = Pattern.compile('^[6-9]\\d{9}$'); //Format: 8885593331
            Pattern matchPattern2 = Pattern.compile('\\(\\d{3}\\)\\s\\d{3}-\\d{4}'); //Format: (888) 559-3331
            Pattern matchPattern3 = Pattern.compile('^\\+91[7-9]\\d{9}$'); //Format: +918885593331
            Pattern matchPattern4 = Pattern.compile('^[6-9]\\d{11}$'); //Format: 918885593331
            
            
            for(sObject record : listOfRecords){
                String phoneNumber = String.valueOf(record.get(watiAPIConfig.Phone_Field__c));
                Matcher matchCase1 = matchPattern1.matcher(phoneNumber);
                Matcher matchCase2 = matchPattern2.matcher(phoneNumber);
                Matcher matchCase3 = matchPattern3.matcher(phoneNumber);
                Matcher matchCase4 = matchPattern4.matcher(phoneNumber);
                if (String.valueOf(record.get(watiAPIConfig.Phone_Field__c)) != null && (matchCase1.matches()==TRUE || matchCase2.matches()==TRUE || matchCase3.matches()==TRUE || matchCase4.matches()==TRUE)){
                    
                    validNumbers.put(String.valueOf(record.get(watiAPIConfig.Phone_Field__c)),String.valueOf(record.get('Id')));
                }else{
                    invalidMembers.put(String.valueOf(record.get(watiAPIConfig.Phone_Field__c)),String.valueOf(record.get('Name')));
                } 
            }
            
            SendTemplateWrapper sendTempWrap = new SendTemplateWrapper();
            List<Receivers> listofMobileNumbers = New List<Receivers>();
            List<CustomParams> customParms = New List<CustomParams>(); 
            Map<String,String> receiversMap = New Map<String,String>();
            
            for (Integer i=0; i<validNumbers.size(); i++) {
                receiversMap = validNumbers;
            }
            
            List<String> MobileNumberList = new List<String>();
            set<string> recIdSet = new set<string>();
            for(string num:receiversMap.keyset()){
                String conId = receiversMap.get(num);
                recIdSet.add(conId);
            }
            Map<Id,sObject> recordDataMap = new Map<Id,sObject>();
            List<sObject> recordsData = new List<sObject>();
            Set<String> SobjectFields = Schema.getGlobalDescribe().get(watiAPIConfig.Object_Name__c).getDescribe().fields.getMap().keySet();    
            List<String> fieldsInList = new List<String>(SobjectFields);
            String contQuery = 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+watiAPIConfig.Object_Name__c +' WHERE Id IN: recIdSet';

            String conQuery = string.valueOf(contQuery);
            recordsData = database.query(conQuery);
            for(sObject record:recordsData){
                recordDataMap.put(record.Id,record);
            }
            List<Template_Param_Configuration__mdt> tempParamMDTList = [SELECT MasterLabel,SF_Field_API_Name__c,WA_Param_Name__c,Template_Body__c FROM Template_Param_Configuration__mdt WHERE DhruvsoftWATI__Template_Name__c =: templateName LIMIT 9999];
            for(string num:receiversMap.keyset()){
                List<CustomParams> parms = New List<CustomParams>();
                Receivers mobileNoList = new Receivers();
                mobileNoList.whatsappNumber = num;
                String conId = receiversMap.get(num);
                string paramValue;
                sObject recordData2 = recordDataMap.get(conId);
                
                
                for(Template_Param_Configuration__mdt tempParamMDT : tempParamMDTList){
                    String fieldAPIName = tempParamMDT.SF_Field_API_Name__c;
                    Boolean containsField = conQuery.contains(fieldAPIName.toLowerCase());
                    if (containsField) {
                        paramValue = string.valueOf(recordData2.get(fieldAPIName));
                    } else {

                    }
                    if(paramValue != null){
                        parms.add(new CustomParams(tempParamMDT.WA_Param_Name__c,paramValue));
                    }
                    else{
                        parms.add(new CustomParams(tempParamMDT.WA_Param_Name__c,'null'));
                    }     
                }
                mobileNoList.customParams = parms;
                listofMobileNumbers.add(mobileNoList);
            }
                        
            sendTempWrap.template_name = templateName;
            sendTempWrap.broadcast_name = templateName;
            sendTempWrap.receivers = listofMobileNumbers;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendTemplateMessages');
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setHeader('Content-Type', 'application/json-patch+json');
            request.setTimeout(2000);
            request.setBody(JSON.serialize(sendTempWrap));
            
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                ResultWrapper resWrap = new ResultWrapper();
                object results = (object)JSON.deserializeUntyped(response.getBody());
                Map<String,Object> tempMap = (Map<String,Object>)results;
                boolean resultVal = (Boolean)tempMap.get('result');
                if(resultVal == true){
                    isSuccess =  true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        waitMainWrapperData.invalidMemberMap = InvalidMembers;
        waitMainWrapperData.invalidWhatsappNumbers = InvalidMembers.keyset();
        waitMainWrapperData.validMemCount = validNumbers.size();
        return waitMainWrapperData;
    }
    
    /*=======================================Send Message==========================================*/
    
    @AuraEnabled(cacheable = true)
    public static WATIMainWrapper sendSingleMessage(String recordId,String textMessage){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            string encodedString  = EncodingUtil.urlEncode(textMessage, 'UTF-8');
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendSessionMessage/'+mobNumber+'?messageText='+encodedString);
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setTimeout(2000);
            request.setHeader('Content-Type', 'application/json-patch+json');
            
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                SendMessageWrapper sendMsgWrap = (SendMessageWrapper)JSON.deserialize(response.getBody(), SendMessageWrapper.class);
                if(sendMsgWrap.ok == true && sendMsgWrap.result == 'success'){
                    isSuccess = true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                isSuccess = false;
                failureWrap = new FailureWrapper();
                failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
            }
            
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        String error;
        if(failureWrap.info !=null)
        {
            error = failureWrap.info;
        }
        if(error != null && error.contains('Ticket has been expired'))
        { 
            waitMainWrapperData.errorMessage = 'Chat has been Expired';
        }
        return waitMainWrapperData;
    }
    
    /*=======================================Send Files==========================================*/
    
    @AuraEnabled
    public static ResultWrapperAttach uploadFiles(string recordId){
        ResultWrapperAttach resWrap = new ResultWrapperAttach();
        try{
            
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            String firstThreeCharacters = recordId.substring(0, 3);
            string query;
            if(firstThreeCharacters == '00Q'){
                query = 'SELECT ID,Name,Phone FROM Lead WHERE Id=:recordId';
            }
            else{
                query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            }
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            ContentDocumentLink cdl = [SELECT LinkedEntityId, ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.Id, ContentDocument.ContentSize, ContentDocument.FileType FROM ContentDocumentLink  
                                       WHERE linkedentityid=:recordId order by contentdocument.createddate DESC LIMIT 1];
            
            set<Id> cdIdSet  = new set<Id>{cdl.ContentDocument.Id};
                
                map<string,string> contentTypeMap = new map<string,string>{'PDF'=>'application/pdf','PNG'=>'image/png','JPG'=>'image/jpeg','JPEG'=>'image/jpeg'};
                    string file_name = cdl.ContentDocument.Title;
            string contentType = contentTypeMap.get(cdl.ContentDocument.FileType);
            ContentVersion cv  = [SELECT Id,ContentSize,VersionData,PathOnClient ,ContentDocumentId from ContentVersion where contentdocumentId IN:cdIdSet LIMIT 1];
            blob file_body;
            if(cv.ContentSize < 1500000){
                file_body = cv.VersionData;
            }
            else{
                resWrap.fileError = 'File Cannot be more than 1.5MB';
            }
            string uBoundary = recordId+mobNumber;
            String boundary = '----------------------------'+uBoundary;
            String header = '--'+boundary+'\r\nContent-Disposition: form-data; name="file"; filename="'+file_name+'"\r\nContent-Type: '+contentType; 
            String footer = '\r\n--'+boundary+'--';              
            String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            while(headerEncoded.endsWith('=')){
                header+=' ';
                headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            }
            String bodyEncoded = EncodingUtil.base64Encode(file_body);
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            Blob bodyBlob = null;
            String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
            if(last4Bytes.endsWith('=')){
                Blob decoded4Bytes = EncodingUtil.base64Decode(last4Bytes);
                HttpRequest tmp = new HttpRequest();
                tmp.setBodyAsBlob(decoded4Bytes);
                String last4BytesFooter = tmp.getBody()+footer;   
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded.substring(0,bodyEncoded.length()-4)+EncodingUtil.base64Encode(Blob.valueOf(last4BytesFooter)));
            }
            else{
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
            }
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
            req.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            req.setMethod('POST');
            req.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendSessionFile/'+mobNumber);
            req.setBodyAsBlob(bodyBlob);
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            
            if(response.getStatusCode() == 200){
                WAMainWrapper responseWrapper = (WAMainWrapper)JSON.deserialize(response.getBody(), WAMainWrapper.class);
                if(responseWrapper.result == true){
                    WAttachmentWrapper successWrapper = (WAttachmentWrapper)JSON.deserialize(response.getBody(), WAttachmentWrapper.class);
                    if(string.isNotBlank(successWrapper.message.whatsappMessageId)){
                        resWrap.isSuccess = true;
                        resWrap.message = 'File Sent Successfully';
                    }
                }else{
                    FailureWrapper failWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                    resWrap.isSuccess =  false;
                    resWrap.message = failWrap.info;
                }
            }else{
                string msg = string.valueOf(response.getStatusCode())+': '+response.getBody();
                resWrap.isSuccess =  false;
                resWrap.message = msg;
            }
            
            
        }catch(exception e){
            resWrap.isSuccess =  false;
            resWrap.message = e.getMessage();
        }
        return resWrap;
    }
    
    /*=======================================Get File Version==========================================*/
    
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getVersionFiles(String recordId){
        try {
            return [
                SELECT
                Id,
                Title,
                ContentDocumentId,
                FileType, 
                ContentSize,
                FileExtension,
                VersionNumber,
                CreatedDate,
                VersionData,
                FirstPublishLocationId
                FROM ContentVersion
                WHERE FirstPublishLocationId =:recordId
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*=======================================Send Template for FLOW==========================================*/
    @InvocableMethod
    public static void sendTemplateFlow(List<Id> Ids){
        sendTemplateFlow1(Ids);
        //return waitMainWrapperData;
    }
    
    @future(callout=true)
    public static void sendTemplateFlow1(List<Id> Ids)
    {
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        String invalidNumber;
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            
            string recordId = Ids[0];
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
            sObject recordData = database.query(query);
            string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));
            
            Pattern matchPattern1 = Pattern.compile('^[6-9]\\d{9}$'); //Format: 8885593331
            Pattern matchPattern2 = Pattern.compile('\\(\\d{3}\\)\\s\\d{3}-\\d{4}'); //Format: (888) 559-3331
            Pattern matchPattern3 = Pattern.compile('^\\+91[7-9]\\d{9}$'); //Format: +918885593331
            Pattern matchPattern4 = Pattern.compile('^[6-9]\\d{11}$'); //Format: 918885593331
            Matcher matchCase1;
            Matcher matchCase2;
            Matcher matchCase3;
            Matcher matchCase4;
            if(mobNumber != null)
            {
                matchCase1 = matchPattern1.matcher(mobNumber);
                matchCase2 = matchPattern2.matcher(mobNumber);
                matchCase3 = matchPattern3.matcher(mobNumber);
                matchCase4 = matchPattern4.matcher(mobNumber);
            }
            String MobileNumber;
            if(mobNumber != null && (matchCase1.matches()==TRUE || matchCase2.matches()==TRUE || matchCase3.matches()==TRUE || matchCase4.matches()==TRUE))
            {
                MobileNumber = mobNumber;
            }
            else if(mobNumber == null || mobNumber == '')
            {
                invalidNumber = 'Invalid Mobile Number Please check Mobile Number';
            }
            else
            {
                invalidNumber = 'Invalid Mobile Number Please check Mobile Number';
            }
            
            string paramValue;
            Set<String> SobjectFields = Schema.getGlobalDescribe().get(watiAPIConfig.Object_Name__c).getDescribe().fields.getMap().keySet();    
            List<String> fieldsInList = new List<String>(SobjectFields);
            String contQuery = 'SELECT ' + String.join(fieldsInList, ',') + ' FROM '+watiAPIConfig.Object_Name__c +' WHERE Id=:recordId';
            String conQuery = String.valueOf(contQuery);
            sObject recordData2 = database.query(conQuery);
            List<Template_Param_Configuration__mdt> tempParamMDTList = [SELECT MasterLabel,SF_Field_API_Name__c,WA_Param_Name__c,Template_Body__c FROM Template_Param_Configuration__mdt LIMIT 9999];
            
            List<Parameters> parms = New List<Parameters>();
            for(Template_Param_Configuration__mdt tempParamMDT : tempParamMDTList){
                String fieldAPIName = tempParamMDT.SF_Field_API_Name__c;
                Boolean containsField = conQuery.contains(fieldAPIName.toLowerCase());
                if (containsField) {
                    paramValue = string.valueOf(recordData2.get(fieldAPIName));
                } else {

                }
                if(paramValue != null){
                    parms.add(new Parameters(tempParamMDT.WA_Param_Name__c,paramValue));
                }
                else{
                    waitMainWrapperData.paramEmptyError = 'Please Check the value '+fieldAPIName;
                }     
            }
            SendTemplateWrapper sendTempWrap = new SendTemplateWrapper();
            sendTempWrap.template_name = 'new_chat';
            sendTempWrap.broadcast_name = 'new_chat';
            
            sendTempWrap.parameters = parms;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendTemplateMessage?whatsappNumber='+MobileNumber);
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setHeader('Content-Type', 'application/json-patch+json');
            request.setTimeout(2000);
            request.setBody(JSON.serialize(sendTempWrap));
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                object results = (object)JSON.deserializeUntyped(response.getBody());
                Map<String,Object> tempMap = (Map<String,Object>)results;
                Boolean resultResp = (Boolean)tempMap.get('result');
                if(resultResp == true){
                    isSuccess = true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
            
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        waitMainWrapperData.invalidMobileNumber = invalidNumber;
    }
    
    /*=======================================Get Contact List==========================================*/
    @AuraEnabled(cacheable=true)
    public static WATIMainWrapper getContactList(String searchName){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
        string encodedString;
        if(searchName != null){
            encodedString  = EncodingUtil.urlEncode(searchName, 'UTF-8');
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        if(searchName==null || searchName==''){
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getContacts');  
        }
        else{
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getContacts?name='+encodedString);
        }
        request.setHeader('Authorization', 'Bearer ' +watiAPIConfig.API_Key__c);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            ContactListWrapper conListWrapper = (ContactListWrapper)JSON.deserialize(response.getBody(), ContactListWrapper.class);
            List<contact_list> contactListWrapper = conListWrapper.contact_list;
            List<ContactWrapper> conListWrap = new List<ContactWrapper>();
            for(contact_list con : contactListWrapper){
                ContactWrapper conWrap = new ContactWrapper();
                conWrap.fullName = con.fullName;
                conWrap.firstName = con.firstName;
                conWrap.phone = con.phone;
                conWrap.lastUpdated = con.lastUpdated;
                conWrap.contactMatch = false;
                conWrap.leadMatch = false;
                conWrap.newLead = false;
                conWrap.recId = '';
                conListWrap.add(conWrap);
            }
            waitMainWrapperData.contact_list = conListWrap;
            Set<String> phoneSet = new Set<String>();
            for(contact_list con : contactListWrapper){
                phoneSet.add(con.phone);
            }
            List<String> conPhoneList = new List<String>();
            Map<String,String> contactMap = new Map<String,String>();
            List<Contact> ContactList = [SELECT Id,Name,Phone FROM Contact WHERE Phone IN : phoneSet];
            for(Contact con : ContactList){
                conPhoneList.add(con.Phone);
                contactMap.put(con.Phone, con.Id);
            }
            waitMainWrapperData.phoneList = conPhoneList;
            waitMainWrapperData.contactPhoneMap = contactMap;
            List<String> leadPhoneList = new List<String>();
            Map<String,String> leadMap = new Map<String,String>();
            List<Lead> leadList = [SELECT Id,Name,Phone FROM Lead WHERE Phone IN : phoneSet];
            for(Lead ld : leadList){
                leadMap.put(ld.Phone,ld.Id);
                leadPhoneList.add(ld.Phone);
            }
            waitMainWrapperData.leadPhoneList = leadPhoneList;
            waitMainWrapperData.leadPhoneMap = leadMap;
            
        }
        return waitMainWrapperData;
    }     
    
    /*=======================================Get Messages in List Page==========================================*/
    
    @AuraEnabled
    public static WATIMainWrapper getMessages1(string mobNumber,string nextPageLink){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        List<MessageWrapper> watiMessagesList = New List<MessageWrapper>();
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            Contact con = [SELECT Id,Name FROM Contact Where Name=:'WhatsApp Integration Contact' AND Email=:'whatsappintegration@WATI.com'];
            String recordId = con.Id;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(string.isNotBlank(nextPageLink)){
                request.setEndpoint(nextPageLink);
            }else{
                if(mobNumber != null){
                    request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getMessages/'+mobNumber+'?pageSize=15&pageNumber=1');
                } 
            }
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                isSuccess = true;
                ResponseWrapper responseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                if(responseWrapper.result == 'success'){
                    SuccessWrapper successWrap = (SuccessWrapper)JSON.deserialize(response.getBody(), SuccessWrapper.class);
                    waitMainWrapperData.prevPageLink = successWrap.link.prevPage;
                    waitMainWrapperData.nextPageLink = successWrap.link.nextPage;
                    Messages allMessages = successWrap.messages;
                    List<fileWrapper> fileWrapList = new List<fileWrapper>();
                    for(Items textMess : allMessages.items){
                        if(textMess.eventType == 'message'){
                            if(textMess.type == 'document' || textMess.type == 'image'){
                                string fileBody = getfiles(textMess.data);
                                Blob fileBlob = EncodingUtil.base64Decode(fileBody);
                                String dataM = textMess.data;
                                String fileName = dataM.substringAfterLast('/');
                                fileWrapper fileWrap = new fileWrapper();
                                fileWrap.fileName = fileName;
                                fileWrap.fileBlob = fileBlob;
                                fileWrap.typeMess = textMess.type;
                                fileWrapList.add(fileWrap);
                            }
                        }
                    }
                    Map<String,String> fileIdList = insertFiles(fileWrapList,recordId);
                    for(Items textMessage : allMessages.items){
                        MessageWrapper messWrap = new MessageWrapper();
                        if(textMessage.eventType == 'message'){
                            if(textMessage.type == 'document' || textMessage.type == 'image'){
                                String dataM = textMessage.data;
                                String fileName = dataM.substringAfterLast('/');
                                messWrap.messtype = true;
                                messWrap.Doctype = textMessage.type;
                                if(textMessage.type == 'document'){
                                    messWrap.Doc = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName);
                                }
                                else if(textMessage.type == 'image'){
                                    messWrap.img = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName); 
                                }
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }else{
                                messWrap.textMessage = textMessage.text;
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }
                            messWrap.messageStatus = textMessage.owner;
                        }else if(textMessage.eventType == 'broadcastMessage'){
                            messWrap.textMessage = textMessage.finalText;
                            messWrap.messageStatus = true;
                            if(textMessage.statusString == 'SENT'){
                                messWrap.singleTick = true;
                            }else if(textMessage.statusString == 'DELIVERED'){
                                messWrap.doubleTick = true;
                            }else if(textMessage.statusString == 'READ'){
                                messWrap.blueTick = true;
                            }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                        }
                        messWrap.createdDate = textMessage.created;
                        if(String.isNotBlank(messWrap.textMessage)){
                            watiMessagesList.add(messWrap); 
                        }
                    }
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.watiMessagesList = watiMessagesList;
        waitMainWrapperData.errorDetails = failureWrap;
        return waitMainWrapperData;
    }
    
    /*=======================================Send Message in List Page==========================================*/
    @AuraEnabled(cacheable = true)
    public static WATIMainWrapper sendMessageListPage(String mobNumber,String textMessage){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            /*string query = 'SELECT ID,Name,'+watiAPIConfig.Phone_Field__c+' FROM '+watiAPIConfig.Object_Name__c+' WHERE Id=:recordId';
sObject recordData = database.query(query);
string mobNumber = string.valueOf(recordData.get(watiAPIConfig.Phone_Field__c));*/
            
            string encodedString  = EncodingUtil.urlEncode(textMessage, 'UTF-8');
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendSessionMessage/'+mobNumber+'?messageText='+encodedString);
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setTimeout(2000);
            request.setHeader('Content-Type', 'application/json-patch+json');
            
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                SendMessageWrapper sendMsgWrap = (SendMessageWrapper)JSON.deserialize(response.getBody(), SendMessageWrapper.class);
                if(sendMsgWrap.ok == true && sendMsgWrap.result == 'success'){
                    isSuccess = true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                isSuccess = false;
                failureWrap = new FailureWrapper();
                failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
            }
            
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        String error;
        if(failureWrap.info !=null)
        {
            error = failureWrap.info;
        }
        if(error != null && error.contains('Ticket has been expired'))
        { 
            waitMainWrapperData.errorMessage = 'Chat has been Expired';
        }
        return waitMainWrapperData;
    }
    /*=======================================Refresh Mssages==========================================*/
    @AuraEnabled(cacheable=true)
    public static WATIMainWrapper refreshMessagesListPage(string mobNumber,string nextPageLink){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        List<MessageWrapper> watiMessagesList = New List<MessageWrapper>();
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            
            Contact con = [SELECT Id,Name FROM Contact Where Name=:'WhatsApp Integration Contact' AND Email=:'whatsappintegration@WATI.com'];
            String recordId = con.Id;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            if(string.isNotBlank(nextPageLink)){
                request.setEndpoint(nextPageLink);
            }else{
                if(mobNumber != null){
                    request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/getMessages/'+mobNumber+'?pageSize=15&pageNumber=1');
                } 
            }
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                isSuccess = true;
                ResponseWrapper responseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                if(responseWrapper.result == 'success'){
                    SuccessWrapper successWrap = (SuccessWrapper)JSON.deserialize(response.getBody(), SuccessWrapper.class);
                    waitMainWrapperData.prevPageLink = successWrap.link.prevPage;
                    waitMainWrapperData.nextPageLink = successWrap.link.nextPage;
                    Messages allMessages = successWrap.messages;
                    List<fileWrapper> fileWrapList = new List<fileWrapper>();
                    for(Items textMess : allMessages.items){
                        if(textMess.eventType == 'message'){
                            if(textMess.type == 'document' || textMess.type == 'image'){
                                string fileBody = getfiles(textMess.data);
                                Blob fileBlob = EncodingUtil.base64Decode(fileBody);
                                String dataM = textMess.data;
                                String fileName = dataM.substringAfterLast('/');
                                fileWrapper fileWrap = new fileWrapper();
                                fileWrap.fileName = fileName;
                                fileWrap.fileBlob = fileBlob;
                                fileWrap.typeMess = textMess.type;
                                fileWrapList.add(fileWrap);
                            }
                        }
                    }
                    Map<String,String> fileIdList = insertFiles(fileWrapList,recordId);
                    for(Items textMessage : allMessages.items){
                        MessageWrapper messWrap = new MessageWrapper();
                        if(textMessage.eventType == 'message'){
                            if(textMessage.type == 'document' || textMessage.type == 'image'){
                                String dataM = textMessage.data;
                                String fileName = dataM.substringAfterLast('/');
                                messWrap.messtype = true;
                                messWrap.Doctype = textMessage.type;
                                if(textMessage.type == 'document'){
                                    messWrap.Doc = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName);
                                }
                                else if(textMessage.type == 'image'){
                                    messWrap.img = true;
                                    messWrap.fileName = fileName;
                                    messWrap.textMessage = fileIdList.get(fileName); 
                                }
                                
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }else{
                                messWrap.textMessage = textMessage.text;
                                if(textMessage.statusString == 'SENT'){
                                    messWrap.singleTick = true;
                                }else if(textMessage.statusString == 'DELIVERED'){
                                    messWrap.doubleTick = true;
                                }else if(textMessage.statusString == 'READ'){
                                    messWrap.blueTick = true;
                                }else if(textMessage.statusString == 'FAILED'){
                                    messWrap.failedTick = true;
                                }
                            }
                            messWrap.messageStatus = textMessage.owner;
                        }else if(textMessage.eventType == 'broadcastMessage'){
                            messWrap.textMessage = textMessage.finalText;
                            messWrap.messageStatus = true;
                            if(textMessage.statusString == 'SENT'){
                                messWrap.singleTick = true;
                            }else if(textMessage.statusString == 'DELIVERED'){
                                messWrap.doubleTick = true;
                            }else if(textMessage.statusString == 'READ'){
                                messWrap.blueTick = true;
                            }else if(textMessage.statusString == 'FAILED'){
                                messWrap.failedTick = true;
                            }
                        }
                        messWrap.createdDate = textMessage.created;
                        if(String.isNotBlank(messWrap.textMessage)){
                            watiMessagesList.add(messWrap); 
                        }
                    }
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.watiMessagesList = watiMessagesList;
        waitMainWrapperData.errorDetails = failureWrap;
        return waitMainWrapperData;
    }
    
    /*=======================================Send Template from List Page==========================================*/
    @AuraEnabled(cacheable=true)
    public static WATIMainWrapper sendTemplateListPage(String phoneNumber,String templateName,String conName){
        WATIMainWrapper waitMainWrapperData = new WATIMainWrapper();
        boolean isSuccess = false;
        String invalidNumber;
        FailureWrapper failureWrap = new FailureWrapper();
        try{
            
            DhruvsoftWATI__API_Configurations__mdt watiAPIConfig = getAPIConfigs();
            string paramValue = conName;
            List<Parameters> parms = New List<Parameters>();
            
            parms.add(new Parameters('name',paramValue));
            SendTemplateWrapper sendTempWrap = new SendTemplateWrapper();
            sendTempWrap.template_name = templateName;
            sendTempWrap.broadcast_name = templateName;
            
            sendTempWrap.parameters = parms;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(watiAPIConfig.End_Point_URL__c+'v1/sendTemplateMessage?whatsappNumber='+phoneNumber);
            request.setHeader('Authorization', 'Bearer '+watiAPIConfig.API_Key__c);
            request.setHeader('Content-Type', 'application/json-patch+json');
            request.setTimeout(2000);
            request.setBody(JSON.serialize(sendTempWrap));
            HttpResponse response = http.send(request);
            
            if(response.getStatusCode() == 200){
                object results = (object)JSON.deserializeUntyped(response.getBody());
                Map<String,Object> tempMap = (Map<String,Object>)results;
                Boolean resultResp = (Boolean)tempMap.get('result');
                if(resultResp == true){
                    isSuccess = true;
                }else{
                    isSuccess = false;
                    failureWrap = new FailureWrapper();
                    failureWrap = (FailureWrapper)JSON.deserialize(response.getBody(), FailureWrapper.class);
                }
            }else{
                
            }
            
        }catch(exception e){
            isSuccess = false;
            failureWrap = new FailureWrapper();
            failureWrap.result = isSuccess;
            failureWrap.info = e.getMessage();
        }
        waitMainWrapperData.isSuccess = isSuccess;
        waitMainWrapperData.errorDetails = failureWrap;
        waitMainWrapperData.invalidMobileNumber = invalidNumber;
        return waitMainWrapperData;
    }
    
    
    //----------ALL WRAPPER CLASSES------------//
    
    public class Message{
        public String whatsappMessageId;
        public String localMessageId;
        public String text;
        public Media media;
        public String type;
        public String time_Z;
        public Integer status;
        public Boolean isOwner;
        public Boolean isUnread;
        public String ticketId;
        public String assignedId;
        public String operatorName;
        public Integer sourceType;
        public String id;
        public String created;
        public String conversationId;
    }
    
    public class Media{
        public String id {get;set;} 
        public String mimeType {get;set;} 
        public String caption {get;set;} 
    }
    
    
    public class WAttachmentWrapper{
        public boolean result;
        public Message message;
    }
    public class WAMainWrapper{
        public boolean result;
    }
    
    public class ResultWrapperAttach{
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public string message;
        @AuraEnabled public String fileError;
    }
    public class FailureWrapper{
        public boolean result;
        public string info;
    }
    
    public class ResponseWrapper {
        public String result;
    }
    
    public class SuccessWrapper{
        public String result;
        public List<MessageTemplates> messageTemplates;
        public Messages messages;
        public Link link;
    }
    
    public class Header {
        public Integer type;
        public String typeString;
        public Object text;
        public String link;
        public String mediaHeaderId;
        public String mediaFromPC;
        public Object headerOriginal;
        public Object headerParamMapping;
    }
    
    public class CustomParams {
        public String paramName;
        public String paramValue;
        public String name;
        public String value;
        public CustomParams(){
            
        }
        public CustomParams( String name ,String value)
        {
            this.name = name;
            this.value = value;
        }
    }
    
    public class MessageTemplates {
        public String id;
        public String elementName;
        public String category;
        public hsm hsm;
        public hsmOriginal hsmOriginal;
        public List<CustomParams> customParams;
        public String status;
        public Language language;
        public String lastModified;
        public String type;
        public Header header;
        public String body;
        public String bodyOriginal;
        public String footer;
        public List<Buttons> buttons;
        public String buttonsType;
    }
    
    public class hsm{
    }
    
    public class hsmOriginal{
    }
    
    public class Parameter_Z {
        public String text;
        public Object phoneNumber;
        public Object url;
        public Object urlOriginal;
        public String urlType;
        public Object buttonParamMapping;
    }
    
    public class Buttons_Z {
        public String type;
        public Parameter_Z parameter;
    }
    
    public class ResultWrapper{
        @AuraEnabled public Set<String> invalidWhatsappNumbers{get;set;}
        @AuraEnabled public List<String> invalidMemberNames{get;set;}
        @AuraEnabled public Map<String,String> invalidMemberMap{get;set;}
        @AuraEnabled public Boolean resultResp{get;set;}
        @AuraEnabled public integer validMemCount{get;set;}
    }
    public class TemplatesWrapper{
        @AuraEnabled Public String templateName{get;set;}
        @AuraEnabled Public String templatebody{get;set;}
        @AuraEnabled Public String templateStatus{get;set;}
        @AuraEnabled public List<receivedCustomParams> recCustPar{get;set;}	
    }
    public class receivedCustomParams{
        @AuraEnabled public String name;
        @AuraEnabled public String value;
    }
    public class MessageWrapper{
        @AuraEnabled Public String textMessage;
        @AuraEnabled Public boolean messtype;
        @AuraEnabled Public String Doctype;
        @AuraEnabled Public boolean messageStatus;
        @AuraEnabled public datetime createdDate;
        @AuraEnabled Public boolean Doc;
        @AuraEnabled Public String fileName;
        @AuraEnabled Public boolean img;
        @AuraEnabled public boolean singleTick;
        @AuraEnabled public boolean doubleTick;
        @AuraEnabled public boolean blueTick;
        @AuraEnabled public boolean failedTick;
    }
    public class Parameters {
        public String name;
        public String value;
        public parameters(){
            
        }
        public parameters( String name ,String value)
        {
            this.name = name;
            this.value = value;
        }
    }
    
    public class SendTemplateWrapper{
        public List<Parameters> parameters;	
        public String template_name;
        public String broadcast_name;
        public List<Receivers> receivers;
        
    }
    public class Receivers {
        public String whatsappNumber;
        public List<CustomParams> customParams;
    }
    
    public class Formdata {
        public String key;
        public String contentType;
        public String type;
        public List<Src> src;
    }
    
    
    
    public class Src {
    }
    
    public class Body {
        public String mode;
        public List<Formdata> formdata;
    }
    
    public class SortingWrapper implements Comparable {   
        public MessageWrapper record;
        public SortingWrapper(MessageWrapper record) {
            this.record = record;
        }
        public Integer compareTo(Object ObjToCompare) {
            SortingWrapper that = (SortingWrapper) ObjToCompare;
            
            datetime valueOne = this.record.createdDate;
            datetime valueTwo = that.record.createdDate;            
            
            // Assumes dates never null
            if (valueOne < valueTwo) return -1;
            else if (valueOne > valueTwo) return 1;
            else return 0;
        }
    }
    public class Language {
        public String key;
        public String value;
        public String text;
    }
    public class Parameter {
        public String text;
        public String phoneNumber;
        public String url;
        public String urlOriginal;
        public String urlType;
        public String buttonParamMapping;
    }
    
    public class Buttons {
        public String type;
        public Parameter parameter;
    }
    
    public class Link {
        public String prevPage;
        public String nextPage;
        public Integer pageNumber;
        public Integer pageSize;
        public Integer total;
    }
    public class Items {
        public String finalText;
        public String eventDescription;
        public String actor;
        public String assignee;
        public String topicName;
        public String replySourceMessage;
        public String messageReferral;
        public String text;
        public String type;
        public String data;
        public String timestamp;
        public Boolean owner;
        public String statusString;
        public String avatarUrl;
        public String assignedId;
        public String operatorName;
        public String localMessageId;
        public String failedDetail;
        public String contacts;
        public String id;
        public datetime created;
        public String conversationId;
        public String ticketId;
        public String eventType;
    }
    
    public class Messages {
        public List<Items> items;
        public Integer pageNumber;
        public Integer pageSize;
        public Integer convCount;
        public Integer total;
        public Integer grandTotal;
        public String orderBy;
        public String lastId;
        public Integer sortBy;
        public String filters;
        public String allowFilters;
        public String search;
    }
    
    public class SendMessageWrapper{
        @AuraEnabled public boolean ok;
        @AuraEnabled public string result;
        @AuraEnabled public Message message;
    }
    
    public class WATIMainWrapper{
        @AuraEnabled public boolean result;
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public List<TemplatesWrapper> watiTemplatesList;
        @AuraEnabled public FailureWrapper errorDetails;
        @AuraEnabled public List<MessageWrapper> watiMessagesList;
        @AuraEnabled public string prevPageLink;
        @AuraEnabled public string nextPageLink;
        @AuraEnabled public Set<String> invalidWhatsappNumbers{get;set;}
        @AuraEnabled public List<String> invalidMemberNames{get;set;}
        @AuraEnabled public Map<String,String> invalidMemberMap{get;set;}
        @AuraEnabled public integer validMemCount{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String paramEmptyError{get;set;}
        @AuraEnabled public String invalidMobileNumber{get;set;}
        @AuraEnabled public List<contactWrapper> contact_list{get;set;}
        @AuraEnabled public List<String> phoneList{get;set;}
        @AuraEnabled public List<String> leadPhoneList{get;set;}
        @AuraEnabled public Map<String,String> contactPhoneMap{get;set;}
        @AuraEnabled public Map<String,String> leadPhoneMap{get;set;}
        
    }
    public class fileWrapper{
        public String fileName;
        public Blob fileBlob;
        public String typemess;
    }
    public class contactWrapper{
        @AuraEnabled public String firstName{get;set;}	    
        @AuraEnabled public String fullName{get;set;}	    
        @AuraEnabled public String phone{get;set;}
        @AuraEnabled public String lastUpdated{get;set;}
        @AuraEnabled public boolean contactMatch{get;set;}
        @AuraEnabled public boolean leadMatch{get;set;}
        @AuraEnabled public boolean newLead{get;set;}
        @AuraEnabled public String recId{get;set;}        
    }
    public class ContactListWrapper{
        @AuraEnabled public String result;
        @AuraEnabled public List<contact_list> contact_list{get;set;}
    }
    public class contact_list{
        @AuraEnabled public String id;	    
        @AuraEnabled public String wAid;	  
        @AuraEnabled public String firstName;	    
        @AuraEnabled public String fullName;    
        @AuraEnabled public String phone;
        @AuraEnabled public String lastUpdated;     
    }
}