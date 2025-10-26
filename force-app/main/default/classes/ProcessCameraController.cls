/**
 * @description 名刺スキャン画像処理コントロール
 */
public with sharing class ProcessCameraController {

    /** 
     * @description エンドポイント
     */
    String endPoint = '';
    /** 
     * @description キー
     */
    String subscriptionKey = '';
    /** 
     * @description トライ回数
     */
    Integer tryRound = 10;
    /** 
     * @description 待ち時間
     */
    Long waitTime = 2;

    /**
     * @description 主な処理
     * @param path
     * @param base64
     * @return list
     */
    public List<Map<String,String>> invoke(String path, String base64) {

        // サービス利用フラグ
        Boolean useServiceProcess = false;

        // カスタマ設定取得
        List<cocr__BSConfig__c> appSetting = [SELECT id,name,cocr__UseAzureAI__c,cocr__ServiceURL__c,cocr__APIKey__c 
                                FROM cocr__BSConfig__c];
        if (appSetting == null || appSetting.size() == 0) {
           useServiceProcess = false;
        } else {
            if (appSetting[0].cocr__UseAzureAI__c == false) {
                useServiceProcess = false;
            } else {
                if (String.isBlank(appSetting[0].cocr__ServiceURL__c) || String.isBlank(appSetting[0].cocr__APIKey__c)) {
                    useServiceProcess = false;
                } else {
                    useServiceProcess = true;
                    endPoint = appSetting[0].cocr__ServiceURL__c;
                    subscriptionKey = appSetting[0].cocr__APIKey__c;
                }
            } 
        }

        // サービス利用する場合
        if(useServiceProcess) {
            // カスタムメタデータから設定取得
            List<CardScanSettings__mdt> configList;
            try{
                configList = [SELECT ConstText__c, ConstText2__c, ConstText3__c, ConstText4__c
                                    FROM CardScanSettings__mdt
                                    WHERE ValidFlg__c = true
                                    AND DeveloperName = 'serverSettings'
                                    WITH SECURITY_ENFORCED];
            } catch(NoAccessException e) {
                System.debug(LoggingLevel.ERROR, e.getMessage());
                // オブジェクトに参照権限がない場合の処理
                throw e;
            }

            if (!configList.isEmpty()) {
                if (String.isNotBlank(configList[0].ConstText3__c)) {
                    tryRound = Integer.valueOf(configList[0].ConstText3__c);
                }

                if (String.isNotBlank(configList[0].ConstText4__c)) {
                    waitTime = Long.valueOf(configList[0].ConstText4__c);
                }
            } 

            //system.debug('-----path:'+ path + '; base64:'+ base64);

            if (String.isBlank(path) && String.isBlank(base64)) {
                return null;
            }

            //String imageBase64 = base64.split(',').get(1);

            Map<String,String> picMap = new Map<String,String>();
            if (!String.isBlank(path)) {
                picMap.put('urlSource', path);
            } else {
                picMap.put('base64Source', base64);
            }

            return httpClient(picMap);
        } else {
            // サービス利用しない場合
            List<Map<String,String>> rtnList = new List<Map<String,String>>();
            rtnList.add(new Map<String,String>{'LocalProcess' => 'true'});
            return rtnList;
        }
    }

    /**
     * @description httpClient
     * @param requestBody
     * @return list
     */
    public List<Map<String,String>> httpClient(Map<String,String> requestBody) {

        HttpRequest request = new HttpRequest();
        Http http = new Http();

        request.setendPoint(endPoint);
        request.setMethod('POST');

        String contentType = '';
        String body = JSON.serialize(requestBody);
        //system.debug('----requestBody:' + body);
        //body = '{"urlSource": "https://funnyp.info/uploads/1495522655-ZUsoC.jpg"}';
        contentType = 'application/json';

        request.setHeader('Content-Type', contentType);
        request.setHeader('Ocp-Apim-Subscription-Key', subscriptionKey);

        request.setBody(body);

        HttpResponse response = http.send(request);
        //system.debug('----response Location :' + JSON.serialize(response.getHeader('Operation-Location')));

        if (response != null) {
            String operationLocation = response.getHeader('Operation-Location');
            return callBack(operationLocation);
        }

        return null;
    }

    /**
     * @description callBack
     * @param path
     * @return list
     */
    public List<Map<String,String>> callBack(String path) {

        //system.debug('======callback path:' + path);

        if (path == null || path.length() <= 0) {
            return null;
        }

        HttpRequest request = new HttpRequest();
        Http http = new Http();

        request.setendPoint(path);
        request.setMethod('GET');
        request.setHeader('Ocp-Apim-Subscription-Key', subscriptionKey);

        // while(sleep(waitTime)) {
        //     break;
        // }

        String json = '';
        Result result = new Result();
        Integer round = 1;
        for( ; ;) {

            HttpResponse responseRe = http.send(request);
            json = responseRe.getBody();

            //system.debug(round + ' times, reponse: '+ json);

            if (String.isBlank(json)) {
                //system.debug('------json is blank. and round is : ' + round);
                while(sleep(waitTime)) {
                    break;
                }
            }  else {

                try{
                    result = (Result)System.JSON.deserialize(json, Result.class);
                    //system.debug('result:' + result);
                } catch (Exception e) {
                    system.debug(LoggingLevel.ERROR, e.getMessage());
                }

                sleep(waitTime);

                if (result != null && !String.isBlank(result.status) && 'succeeded'.equals(result.status)) {
                    break;
                } else {
                    system.debug(LoggingLevel.WARN, 'json value is incorrect.');
                }
            }

            if (round == tryRound) {
                system.debug(LoggingLevel.INFO, 'try a gain!');
                break;
            }

            round = round + 1;
        }


        if (result.analyzeResult == null || result.analyzeResult.documents == null) {
            system.debug(LoggingLevel.WARN, 'callback response is null.');
        }

        List<Document> documentList = result.analyzeResult.documents;

        if (documentList == null ) {
            return null;
        }

        List<String> resultList = new List<String>();

        String address = '';
        String name = '';
        String email = '';
        String fax = '';
        String jt = '';
        String workPhone = '';
        String departments = '';
        String websites = '';
        String companyNames = '';

        List<Map<String,String>> businessCardList = new List<Map<String,String>>();

        Map<String,String> aPiece = null;
        for(Document document: documentList) {

            aPiece = new Map<String,String>();

            if (String.isBlank(document.docType) || !document.docType.contains('businessCard')) {
                //system.debug('is not businessCard....');
                continue;
            }

            CommonNormalObj addrObj = document.fields.Addresses;
            address = getDetail(addrObj, resultList);
            aPiece.put('address', address);
            //system.debug('address: '+ address);

            CommonNormalObj nameObj = document.fields.ContactNames;
            name = getDetail(nameObj, resultList);
            aPiece.put('name', name);
            //system.debug('name: '+ name);

            CommonNormalObj emailObj = document.fields.Emails;
            email = getDetail(emailObj, resultList);
            aPiece.put('email', email);
            //system.debug('email: '+ email);

            CommonNormalObj faxObj = document.fields.Faxes;
            fax = getDetail(faxObj, resultList);
            fax = clearPrefix(fax);
            aPiece.put('fax', fax);
            //system.debug('fax: '+ fax);

            CommonNormalObj jtObj = document.fields.JobTitles;
            jt = getDetail(jtObj, resultList);
            aPiece.put('jt', jt);
            //system.debug('jt: '+ jt);

            CommonNormalObj workPhoneObj = document.fields.WorkPhones;
            workPhone = getDetail(workPhoneObj, resultList);
            workPhone = clearPrefix(workPhone);
            aPiece.put('workPhone', workPhone);
            //system.debug('workPhone: '+ workPhone);

            CommonNormalObj departmentsObj = document.fields.Departments;
            departments = getDetail(departmentsObj, resultList);
            aPiece.put('departments', departments);
            //system.debug('departments: '+ departments);

            CommonNormalObj websitesObj = document.fields.Websites;
            websites = getDetail(websitesObj, resultList);
            aPiece.put('websites', websites);
            //system.debug('websites: '+ websites);

            CommonNormalObj companyNamesObj = document.fields.CompanyNames;
            companyNames = getDetail(companyNamesObj, resultList);
            aPiece.put('companyNames', companyNames);
            //system.debug('companyNames: '+ companyNames);

            businessCardList.add(aPiece);
        }
        //system.debug('----businessCardList:'+businessCardList);
        //system.debug('---all of datas: ' + System.JSON.serialize(resultList));
        return businessCardList;
    }


    /**
     * @description clearPrefix
     * @param faxOrPhone
     * @return string
     */
    @TestVisible
    public String clearPrefix(String faxOrPhone) {

        faxOrPhone = faxOrPhone.replace(' ','');
        faxOrPhone = faxOrPhone.replace('TEL:','').replace('TEL.','').replace('Tel:','').replace('Tel.','');
        faxOrPhone = faxOrPhone.replace('FAX:','').replace('FAX.','').replace('Fax:','').replace('Fax.','');

        return faxOrPhone;

        // Pattern pattern = Pattern.compile('tel[:. ]', Pattern.CASE_INSENSITIVE);
        // Matcher matcher = pattern.matcher(faxOrPhone);
        // faxOrPhone = matcher.replaceAll('');

        // pattern = Pattern.compile('fax[:. ]', Pattern.CASE_INSENSITIVE);
        // matcher = pattern.matcher(faxOrPhone);
        // return matcher.replaceAll('');
    }

    /**
     * @description 明細情報読み込み
     * @param obj
     * @param resultList
     * @return string
     */
    public String getDetail(CommonNormalObj obj, List<String> resultList) {

        if (obj == null) {
            return '';
        }

        List<ValueArray> valueList = obj.valueArray;
        Integer i = 1;
        Boolean isEnglisWords = false;
        String firstValue = '';
        for( ValueArray ll : valueList ) {
            isEnglisWords = Pattern.matches('[a-zA-Z]+', ll.content.replace(' ',''));

            resultList.add(ll.content.replace('\n',''));
            if (i == 1 || !isEnglisWords) {
                firstValue = ll.content.replace('\n','');
            }
            i++;
        }

        return firstValue;
    }

    /**
     * @description sleep
     * @param second
     * @return boolean
     */
    public boolean sleep(long second) {
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();

        while ((finishTime - startTime) < second * 1000) {
            finishTime = DateTime.now().getTime();
        }

        return true;
    }

    /**
     * @description Result
     */
    @TestVisible
    public class Result {
        /**
         * @description status
         * @return status
         */
        public String status{get; set;}
        /**
         * @description createdDateTime
         * @return createdDateTime
         */
        public String createdDateTime{get; set;}
        /**
         * @description lastUpdatedDateTime
         * @return lastUpdatedDateTime
         */
        public String lastUpdatedDateTime{get; set;}
        /**
         * @description analyzeResult
         * @return analyzeResult
         */
        public AnalyzeResult analyzeResult{get; set;}
    }

    /**
     * @description AnalyzeResult
     */
    @TestVisible
    public class AnalyzeResult {
        /**
         * @description apiVersion
         * @return apiVersion
         */
        public String apiVersion{get; set;}
        /**
         * @description modelId
         * @return modelId
         */
        public String modelId{get; set;}
        /**
         * @description stringIndexType
         * @return stringIndexType
         */
        public String stringIndexType{get; set;}
        /**
         * @description content
         * @return content
         */
        public String content{get; set;}
        /**
         * @description pages
         * @return pages
         */
        @TestVisible
        public List<Pages> pages{get; set;}
        /**
         * @description styles
         * @return styles
         */
        @TestVisible
        public List<Style> styles{get; set;}
        /**
         * @description documents
         * @return documents
         */
        @TestVisible
        public List<Document> documents{get; set;}
    }

    /**
     * @description Style
     */
    @TestVisible
    public class Style {
        /**
         * @description documents
         * @return documents
         */
        public String confidence{get; set;}
        /**
         * @description documents
         * @return documents
         */
        public List<Span> spans{get; set;}
        /**
         * @description documents
         * @return documents
         */
        public Boolean isHandwritten{get; set;}
    }

    /**
     * @description Pages
     */
    @TestVisible
    public class Pages {
        /**
         * @description pageNumber
         * @return pageNumber
         */
        public Integer pageNumber{get; set;}
        /**
         * @description angle
         * @return angle
         */
        public double angle{get; set;}
        /**
         * @description width
         * @return width
         */
        public Integer width{get; set;}
        /**
         * @description height
         * @return height
         */
        public Integer height{get; set;}
        /**
         * @description unit
         * @return unit
         */
        public String unit{get; set;}
        /**
         * @description words
         * @return words
         */
        public List<Words> words{get; set;}
        /**
         * @description spans
         * @return spans
         */
        public List<Span> spans{get; set;}
    }

    /**
     * @description Words
     */
    @TestVisible
    public class Words {
        /**
         * @description content
         * @return content
         */
        public String content{get; set;}
        /**
         * @description polygon
         * @return polygon
         */
        public List<Integer> polygon{get; set;}
        /**
         * @description confidence
         * @return confidence
         */
        public Double confidence{get; set;}
        /**
         * @description span
         * @return span
         */
        public Span span{get; set;}
    }

    /**
     * @description Span
     */
    public class Span {
        /**
         * @description offset
         * @return offset
         */
        public Integer offset{get; set;}
        /**
         * @description length
         * @return length
         */
        public Integer length{get; set;}
    }

    /**
     * @description Document
     */
    @TestVisible
    public class Document {
        /**
         * @description docType
         * @return docType
         */
        public String docType{get; set;}
        /**
         * @description boundingRegions
         * @return boundingRegions
         */
        public List<BoundingRegion> boundingRegions{get; set;}
        /**
         * @description fields
         * @return fields
         */
        public Fields fields{get; set;}
    }

    /**
     * @description Fields
     */
    public class Fields {
        /**
         * @description addresses
         * @return addresses
         */
        public CommonNormalObj addresses{get; set;}
        /**
         * @description contactNames
         * @return contactNames
         */
        public CommonNormalObj contactNames{get; set;}
        /**
         * @description emails
         * @return emails
         */
        public CommonNormalObj emails{get; set;}
        /**
         * @description faxes
         * @return faxes
         */
        public CommonNormalObj faxes{get; set;}
        /**
         * @description jobTitles
         * @return jobTitles
         */
        public CommonNormalObj jobTitles{get; set;}
        /**
         * @description workPhones
         * @return workPhones
         */
        public CommonNormalObj workPhones{get; set;}
        /**
         * @description departments
         * @return departments
         */
        public CommonNormalObj departments{get; set;}
        /**
         * @description websites
         * @return websites
         */
        public CommonNormalObj websites{get; set;}
        /**
         * @description companyNames
         * @return companyNames
         */
        public CommonNormalObj companyNames{get; set;}
    }

    /**
     * @description BoundingRegion
     */
    public class BoundingRegion {
        /**
         * @description companyNames
         * @return companyNames
         */
        public Integer pageNumber{get; set;}
        /**
         * @description companyNames
         * @return companyNames
         */
        public List<Integer> polygon{get; set;}
    }

    /**
     * @description ValueArray
     */
    public class ValueArray {
        /**
         * @description type
         * @return type
         */
        public String type{get; set;}
        /**
         * @description valueString
         * @return valueString
         */
        public String valueString{get; set;}
        /**
         * @description content
         * @return content
         */
        public String content{get; set;}
        /**
         * @description boundingRegions
         * @return boundingRegions
         */
        public List<BoundingRegion> boundingRegions{get; set;}
        /**
         * @description confidence
         * @return confidence
         */
        public Double confidence{get; set;}
        /**
         * @description spans
         * @return spans
         */
        public List<Span> spans{get; set;}
        /**
         * @description valueAddress
         * @return valueAddress
         */
        public ValueAddress valueAddress{get; set;}
        /**
         * @description valueObject
         * @return valueObject
         */
        public ContactNamesValueObject valueObject{get; set;}
    }

    /**
     * @description ValueAddress
     */
    public class ValueAddress {
        /**
         * @description houseNumber
         * @return houseNumber
         */
        public String houseNumber{get; set;}
        /**
         * @description road
         * @return road
         */
        public String road{get; set;}
        /**
         * @description streetAddress
         * @return streetAddress
         */
        public String streetAddress{get; set;}
        /**
         * @description house
         * @return house
         */
        public String house{get; set;}
    }

    /**
     * @description ContactNamesValueObject
     */
    public class ContactNamesValueObject {
        /**
         * @description firstName
         * @return firstName
         */
        public NameCommonObj firstName{get; set;}
        /**
         * @description lastName
         * @return lastName
         */
        public NameCommonObj lastName{get; set;}
        /**
         * @description boundingRegions
         * @return boundingRegions
         */
        public List<BoundingRegion> boundingRegions{get; set;}
        /**
         * @description confidence
         * @return confidence
         */
        public Double confidence{get; set;}
        /**
         * @description spans
         * @return spans
         */
        public List<Span> spans{get; set;}
    }

    /**
     * @description NameCommonObj
     */
    public class NameCommonObj {
        /**
         * @description type
         * @return type
         */
        public String type{get; set;}
        /**
         * @description valueString
         * @return valueString
         */
        public String valueString{get; set;}
        /**
         * @description content
         * @return content
         */
        public String content{get; set;}
        /**
         * @description boundingRegions
         * @return boundingRegions
         */
        public List<BoundingRegion> boundingRegions{get; set;}
        /**
         * @description confidence
         * @return confidence
         */
        public Double confidence{get; set;}
        /**
         * @description spans
         * @return spans
         */
        public List<Span> spans{get; set;}
    }

    /**
     * @description CommonNormalObj
     */
    public class CommonNormalObj {
        /**
         * @description type
         * @return type
         */
        public String type{get; set;}
        /**
         * @description valueArray
         * @return valueArray
         */
        public List<ValueArray> valueArray{get; set;}
    }
}