global class WhatsAppControllerMock2 implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {
       
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"result":true,"messageTemplates":[{"elementName": "payment_reminder","bodyOriginal":"Hi","customParams": [{ "name": "name","value": "John"},{"amount_due":"10"},{"payment_url":"www.dhruvsoft.com"},{"soapdfurl","www.dhruvsoft.com"},{"due_date","18042023"}]}],"messages": {"items": [{"text": "","eventType": "message","data": "data/images/09049ef4-4c77-474b-b12c-05643291a31a.png","type": "image"}]},"link": {"nextPage": "https://live-server-102488.wati.io/api/v1/getMessages/918885593331?pageSize=4&pageNumber=2"}}');
        
        res.setStatusCode(200);
        return res;
    }

}