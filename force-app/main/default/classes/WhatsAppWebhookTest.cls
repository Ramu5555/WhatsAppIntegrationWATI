@isTest
public class WhatsAppWebhookTest {
    @isTest
    static void testMessagesRead() {
        // Test data
        WhatsAppWebhook.MessageWrapper wrapper = new WhatsAppWebhook.MessageWrapper();
        wrapper.text = 'Test Message';
        wrapper.type = 'text';
        String requestBody = JSON.serialize(wrapper);
        
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/Watievents';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);
        
        RestResponse response = new RestResponse();
        
        Test.startTest();
        RestContext.request = request;
        RestContext.response = response;
        String result = WhatsAppWebhook.messagesRead();
        Test.stopTest();
        
        // Verify the response
        System.assertEquals('READING', result, 'Incorrect return value');
      
    }
}