public class ARC_MockHttpFailResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "Internal Error"}');
        res.setStatus('Internal Error');

        res.setStatusCode(500);
        return res;
    }
}