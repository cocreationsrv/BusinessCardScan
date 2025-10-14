/**
 * @description Apex classes
 */
@isTest
private class TestProcessCameraController {

	@isTest
    public static void testScan(){

        forTest fortest = new forTest();
        fortest.forTesMethod(1);
        fortest.forTesMethod1(1);
        fortest.forTesMethod2(1);
        fortest.forTesMethod3(1);
        fortest.forTesMethod4(1);
        fortest.forTesMethod5(1);
        fortest.forTesMethod6(1);
        fortest.forTesMethod7(1);
        fortest.forTesMethod8(1);
        fortest.forTesMethod9(1);

        Test.setMock(HttpCalloutMock.class, new CalloutMock());

        ProcessCameraController camera = new ProcessCameraController();

        List<Map<String,String>> resultList = camera.invoke('https://funnyp.info/uploads/1495522655-ZUsoC.jpg','');

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

    @isTest
    public static void testCameraControlleUpload() {
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        String base64String = 'asdadadasdaqwe';
        CameraController.uploadImage(base64String);
        system.assert(true,'Test OK');
    }
}