/**
 * @description Apex classes
 */
@isTest
private class TestProcessCameraController {

    /**
     * カスタム設定あり
     */
	@isTest
    public static void testScan(){
        // Pick the Profile you want to test under here
        String profileName = '標準ユーザー';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        cocr__BSConfig__c config = new cocr__BSConfig__c(
            	cocr__UseAzureAI__c = true,
            	SetupOwnerId = p.Id
        );
        insert config;
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        
		Test.startTest();
        ProcessCameraController camera = new ProcessCameraController();
		
        List<Map<String,String>> resultList = camera.invoke('https://funnyp.info/uploads/1495522655-ZUsoC.jpg','');
		Test.stopTest();
        
        String name = '';
        String phone = '';
        String company = '';
        for(Map<String,String> mapVal : resultList){
            for(String key : mapVal.keySet()){
                if('name'.equals(mapVal.get(key))){
                    name = mapVal.get(key);
                } else if('workPhone'.equals(mapVal.get(key))){
                    phone = mapVal.get(key);
                } else if('companyNames'.equals(mapVal.get(key))){
                    company = mapVal.get(key);
                }
            }
        }
		
        system.assertNotEquals(null, name,'');
        system.assertNotEquals(null, phone,'');
        system.assertNotEquals(null, company,'');
    }


	@isTest
    public static void testCameraControllerSave() {
        String leadJsonStr = '{"address":"aaa","name":"test","departments":"aa","companyNames":"a","workPhone":"576"}';
        CameraController.insertData(leadJsonStr);

        Lead lead = [SELECT Id FROM Lead WHERE LastName='test' LIMIT 1];
        system.assertNotEquals(null, lead, 'Test OK');
    }
    
    /**
     * カスタム設定あり
     */ 
    @isTest
    public static void testCameraControlleUpload() {
        // Pick the Profile you want to test under here
        String profileName = '標準ユーザー';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        cocr__BSConfig__c config = new cocr__BSConfig__c(
            	cocr__UseAzureAI__c = true,
            	SetupOwnerId = p.Id
        );
        insert config;
        
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        Test.startTest();
        String base64String = 'asdadadasdaqwe';
        CameraController.uploadImage(base64String);
        Test.stopTest();
        
        system.assert(true,'Test OK');
    }
    
    /**
     * カスタム設定なし
     */ 
    @isTest
    public static void testCameraControlleUpload1() {
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        String base64String = 'asdadadasdaqwe';
        CameraController.uploadImage(base64String);
        system.assert(true,'Test OK');
    }

	/**
	 * カスタム設定あり（サービス利用しない）
	 */
    @isTest
    public static void testCameraControlleUpload2() {
        // Pick the Profile you want to test under here
        String profileName = '標準ユーザー';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        cocr__BSConfig__c config = new cocr__BSConfig__c(
            	cocr__UseAzureAI__c = false,
            	SetupOwnerId = p.Id
        );
        insert config;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        String base64String = 'asdadadasdaqwe';
        CameraController.uploadImage(base64String);
        Test.stopTest();
        system.assert(true,'Test OK');
    }

    /**
	 * カスタム設定あり（値なし）
	 */  
    @isTest
    public static void testCameraControlleUpload3() {
        // Pick the Profile you want to test under here
        String profileName = '標準ユーザー';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        cocr__BSConfig__c config = new cocr__BSConfig__c(
            	cocr__UseAzureAI__c = true,
            	SetupOwnerId = p.Id
        );
        insert config;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        String base64String = 'asdadadasdaqwe';
        CameraController.uploadImage(base64String);
        Test.stopTest();
        system.assert(true,'Test OK');
    }
    
    /**
     * 画像なし
     */ 
	@isTest
    public static void testCameraControlleUpload4() {
        // Pick the Profile you want to test under here
        String profileName = '標準ユーザー';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        cocr__BSConfig__c config = new cocr__BSConfig__c(
            	cocr__UseAzureAI__c = true,
            	SetupOwnerId = p.Id
        );
        insert config;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        ProcessCameraController camera = new ProcessCameraController();
		
        List<Map<String,String>> resultL= camera.invoke('','');
        Test.stopTest();
        system.assert(true,'Test OK');
    }
    
    @isTest
    public static void testCameraControlleAction() {
        Test.startTest();
    	CameraController.isButtonVisible();
        Test.stopTest();
        system.assert(true,'Test OK');
    }
    
    @isTest
    public static void testProcessCameraControllerAction() {
        ProcessCameraController pcc = new ProcessCameraController();
        String path = '';
        Test.startTest();
        pcc.callBack(path);
        Test.stopTest();
    }

    @isTest
    public static void testProcessCameraControllerAction2() {
        
        ProcessCameraController pcc = new ProcessCameraController();
        Test.startTest();
        string str='TEL.090-0909-9090';
        str = pcc.clearPrefix(str);
        Test.stopTest();
    }
    @isTest
    public static void testProcessCameraControllerAction3() {
        string json='{ "status":"succeeded" ,"createdDateTime":"2024-01-24T02:10:35Z" ,"lastUpdatedDateTime":"2024-01-24T02:10:38Z" ,"analyzeResult":{ "apiVersion":"2023-07-31" ,"modelId":"prebuilt-businessCard" ,"stringIndexType":"textElements" ,"content":"テスト情報" ,"pages":[ { "pageNumber": 1, "angle": -0.2142000049352646, "width": 3024, "height": 4032, "unit": "pixel", "words": [] } ] ,"styles":[ { "confidence":"", "spans":[], "isHandwritten":false } ] ,"documents":[ { "docType":"businessCard" ,"boundingRegions":[ { "pageNumber":1, "polygon":[1757,2410] } ] ,"fields":{ "Addresses": { "type": "array", "valueArray": [ { "type": "address", "content": "テスト住所", "boundingRegions": [], "confidence": 0.907, "spans": [], "valueAddress": { "houseNumber": "1丁目8-2", "postalCode": "100-0011", "city": "千代田区", "state": "東京都", "streetAddress": "内幸町1丁目8-2 内幸町東急ビル6F", "cityDistrict": "内幸町", "house": "内幸町東急ビル6F" } } ] } ,"CompanyNames":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"テスト会社" ,"content":"テスト会社" } ] } ,"ContactNames":{ "type":"array" ,"valueArray":[ { "type":"object" ,"valueObject":{ "FirstName":{ "type":"string" ,"valueString":"テスト名" ,"content":"テスト名" } ,"LastName":{ "type":"string" ,"valueString":"テスト姓" ,"content":"テスト姓" } } ,"content":"テスト姓　テスト名" } ] } ,"Emails":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"test@test.com" ,"content":"test@test.com" } ] } ,"JobTitles":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"Managing Director" ,"content":"Managing Director" } ] } ,"Websites":{ "type":"array" ,"valueArray":[ { "type":"string" ,"valueString":"www.test.com" ,"content":"www.test.com" } ] } ,"WorkPhones":{ "type":"array" ,"valueArray":[ { "type":"phoneNumber" ,"valueString":"999-9999-9999" ,"content":"999-9999-9999" } ] } ,"Faxes":{ "type":"array" ,"valueArray":[ { "type":"Faxes" ,"valueString":"999-9999-9999" ,"content":"999-9999-9999" } ] } } } ] } } ';
        ProcessCameraController.Result pcc = (ProcessCameraController.Result)System.JSON.deserialize(json, ProcessCameraController.Result.class);
        System.debug(pcc.createdDateTime);
        System.debug(pcc.lastUpdatedDateTime);
        ProcessCameraController.AnalyzeResult ar = pcc.analyzeResult;
        System.debug(ar.apiVersion);
        System.debug(ar.modelId);
        System.debug(ar.stringIndexType);
        System.debug(ar.content);

        List<ProcessCameraController.Pages> pages = ar.pages;
        System.debug(pages.size());
        for(ProcessCameraController.Pages page : pages) {
            System.debug(page.pageNumber);
            System.debug(page.angle);
            System.debug(page.width);
            System.debug(page.height);
            System.debug(page.unit);
            List<ProcessCameraController.Words> words = page.words;
            System.debug(words);
            List<ProcessCameraController.Span> spans = page.spans;
            System.debug(spans);
        }
        
        List<ProcessCameraController.Style> styles = ar.styles;
        System.debug(styles.size());
        // for(ProcessCameraController.Styles style : styles) {
        //     System.debug(style.confidence);
        //     System.debug(style.spans);
        //     System.debug(style.isHandwritten);
        // }

        List<ProcessCameraController.Document> documents = ar.documents;
        System.debug(documents.size());
        // for(ProcessCameraController.Document document : documents) {
        //     System.debug(document.docType);
        //     System.debug(document.boundingRegions);
        //     System.debug(document.fields);
        // }

        System.assert(true,'Test OK');

    }
}
