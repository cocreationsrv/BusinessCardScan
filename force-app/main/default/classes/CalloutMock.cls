/**
 * @description テスト用CalloutMock
 */
@isTest
global class CalloutMock implements system.HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('★APIゲートウェイのURL★', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Operation-Location', 'https://test.test');
        res.setBody('{ "status":"succeeded" ,"createdDateTime":"2024-01-24T02:10:35Z" ,"lastUpdatedDateTime":"2024-01-24T02:10:38Z" ,"analyzeResult":{ "apiVersion":"2023-07-31" ,"modelId":"prebuilt-businessCard" ,"stringIndexType":"textElements" ,"content":"テスト情報" ,"pages":[ { "pageNumber": 1, "angle": -0.2142000049352646, "width": 3024, "height": 4032, "unit": "pixel", "words": [] } ] ,"styles":[ { "confidence":"", "spans":[], "isHandwritten":false } ] ,"documents":[ { "docType":"businessCard" ,"boundingRegions":[ { "pageNumber":1, "polygon":[1757,2410] } ] ,"fields":{ "Addresses": { "type": "array", "valueArray": [ { "type": "address", "content": "テスト住所", "boundingRegions": [], "confidence": 0.907, "spans": [], "valueAddress": { "houseNumber": "1丁目8-2", "postalCode": "100-0011", "city": "千代田区", "state": "東京都", "streetAddress": "内幸町1丁目8-2 内幸町東急ビル6F", "cityDistrict": "内幸町", "house": "内幸町東急ビル6F" } } ] } ,"CompanyNames":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"テスト会社" ,"content":"テスト会社" } ] } ,"ContactNames":{ "type":"array" ,"valueArray":[ { "type":"object" ,"valueObject":{ "FirstName":{ "type":"string" ,"valueString":"テスト名" ,"content":"テスト名" } ,"LastName":{ "type":"string" ,"valueString":"テスト姓" ,"content":"テスト姓" } } ,"content":"テスト姓　テスト名" } ] } ,"Emails":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"test@test.com" ,"content":"test@test.com" } ] } ,"JobTitles":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"Managing Director" ,"content":"Managing Director" } ] } ,"Websites":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"www.test.com" ,"content":"www.test.com" } ] } ,"WorkPhones":{ "type":"array" ,"valueArray":[ { "type":"phoneNumber" ,"valueString":"999-9999-9999" ,"content":"999-9999-9999" } ] } ,"Faxes":{ "type":"array" ,"valueArray":[ { "type":"Faxes" ,"valueString":"999-9999-9999" ,"content":"999-9999-9999" } ] } } } ] } } ');
        res.setStatusCode(200);
        return res;
   }
}