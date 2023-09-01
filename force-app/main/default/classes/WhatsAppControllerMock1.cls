global class WhatsAppControllerMock1 implements HttpCalloutMock
{
	global HTTPResponse respond(HTTPRequest req) {
       
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"result":"success","messageTemplates":[{"elementName": "sample_chat","Status": "APPROVED","bodyOriginal":"Hi","customParams": [{ "name": "name","value": "John"}]}],"messages": {"items": [{"text": "Hi","eventType": "message","data": "data/documents/b5f3b5d1-cdcd-46e2-8b9c-b94f4eb4dbbd.pdf","type": "document"}]},"link": {"nextPage": "https://live-server-102488.wati.io/api/v1/getMessages/918885593331?pageSize=4&pageNumber=2"},"contact_list":[{"id":"001","wAid":"WA001","firstName":"John","fullName":"John Doe","phone":"1234567890","lastUpdated":"2023-07-18"}]}');
        
        res.setStatusCode(200);
        return res;
    }
}