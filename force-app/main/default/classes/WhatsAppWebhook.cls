@RestResource(urlMapping='/Watievents')
global class WhatsAppWebhook {
    @HttpPost
    global static string messagesRead() {
        string retVal = 'READING';
        RestResponse res = RestContext.response;
        RestRequest req = RestContext.request;
        system.debug('replyReQ----->'+req);
        Blob body = req.requestBody;
        String bodyString = body.toString();    
        system.debug('====='+bodyString);
        //system.debug('response-->'+req.getbody());
        system.debug('replyResponse----->'+res);
        system.debug('replyResponse----->'+res.statusCode);
        MessageWrapper responseWrapper = (MessageWrapper)JSON.deserialize(bodyString, MessageWrapper.class);
        system.debug('Text Message:: '+responseWrapper.text);
        system.debug('Text Message:: '+responseWrapper.type);
        WATI_Event__e watiEvent = new WATI_Event__e();
        if(responseWrapper.type == 'text'){
        watiEvent.Message__c = EncodingUtil.urlDecode(responseWrapper.text, 'UTF-8');
        }
        watiEvent.createdDate__c = System.now();
        watiEvent.messageStatus__c = responseWrapper.owner;
        watiEvent.Type__c = responseWrapper.type;
        System.debug('watiEvent.Message__c: '+watiEvent.Message__c);
        EventBus.publish(watiEvent);
        return retVal;
    }
    public class MessageWrapper {
        
        public String id;
        public dateTime created;
        public String whatsappMessageId;
        public String conversationId;
        public String ticketId;
        public String text;
        public String type;
        public String data;
        public Object sourceId;
        public Object sourceUrl;
        public String timestamp;
        public Boolean owner;
        public String eventType;
        public String statusString;
        public Object avatarUrl;
        public Object assignedId;
        public Object operatorName;
        public Object operatorEmail;
        public String waId;
        public Object messageContact;
        public String senderName;
        public Object listReply;
        public String replyContextId;
    }
    
    
}