/**
 * @description 名刺スキャンコントロール
 */
public with sharing class CameraController {

    /** レスポンス　キー */
    final static String KEY_ADDRESS = 'address';
    final static String KEY_NAME = 'name';
    final static String KEY_EMAIL = 'email';
    final static String KEY_FAX = 'fax';
    final static String KEY_JT = 'jt';
    final static String KEY_WORKPHONE = 'workPhone';
    final static String KEY_DEPARTMENTS = 'departments';
    final static String KEY_WEBSITES = 'websites';
    final static String KEY_COMPANYNAMES = 'companyNames';

    /** 
     * @description file
     * @return file
     */
    public ContentVersion file {get;set;}
    /** @description currentRecordId
     * @return file
    */
    public string currentRecordId {get;set;}
    /** 
     * @description fileSaved
     * @return fileSaved
     */
    public boolean fileSaved {get;set;}

    /**
     * @description 画像アップロード
     * @param base64String
     * @return result
     */
    @AuraEnabled(cacheable=false)
    public static String uploadImage(String base64String) {

        //system.debug('==debug==saveFile().base64:' + base64String );
        if (base64String == null || base64String == '') {
            return 'ng';
        } else {
            ProcessCameraController controller = new ProcessCameraController();
            List<Map<String,String>> resultList = controller.invoke('', base64String);

            LeadInfoClass leadInfo = new LeadInfoClass();

            for(Map<String,String> item : resultList) {
                //system.debug('==debug==item:' + item);
                // 住所
                if(item.containsKey(KEY_ADDRESS)) {
                    leadInfo.address = item.get(KEY_ADDRESS);
                }
                // 名前
                if (item.containsKey(KEY_NAME)) {
                    leadInfo.name = item.get(KEY_NAME);
                }
                // email
                if (item.containsKey(KEY_EMAIL)) {
                    leadInfo.email = item.get(KEY_EMAIL);
                }
                // ファクス
                if (item.containsKey(KEY_FAX)) {
                    leadInfo.fax = item.get(KEY_FAX);
                    if (leadInfo.fax != null) {
                        leadInfo.fax = leadInfo.fax.replaceAll(':', '');
                        //leadInfo.fax = leadInfo.fax.replaceAll('(', '');
                        //leadInfo.fax = leadInfo.fax.replaceAll(')', '');
                    }
                }
                // ジョブタイトル
                if (item.containsKey(KEY_JT)) {
                    leadInfo.jt = item.get(KEY_JT);
                }
                // 電話 
                if (item.containsKey(KEY_WORKPHONE)) {
                    leadInfo.workPhone = item.get(KEY_WORKPHONE);
                    if (leadInfo.workPhone != null) {
                        leadInfo.workPhone = leadInfo.workPhone.replaceAll(':', '');
                        //leadInfo.workPhone = leadInfo.workPhone.replaceAll('(', '');
                        //leadInfo.workPhone = leadInfo.workPhone.replaceAll(')', '');
                    }
                }
                // 部署
                if (item.containsKey(KEY_DEPARTMENTS)) {
                    leadInfo.departments = item.get(KEY_DEPARTMENTS);
                }
                // ウェブサイト
                if (item.containsKey(KEY_WEBSITES)) {
                    leadInfo.websites = item.get(KEY_WEBSITES);
                }
                // 会社名
                if (item.containsKey(KEY_COMPANYNAMES)) {
                    leadInfo.companyNames = item.get(KEY_COMPANYNAMES);
                }
            }

            if (resultList.size() > 0) {
                return JSON.serialize(leadInfo);
            } else {
                return 'ng';
            }
        }

    }

    /**
     * @description insertData
     * @param leadJsonStr
     * @return result
     */
    @AuraEnabled(cacheable=false)
    public static String insertData(String leadJsonStr) {
        //System.debug('==debug==insertData().leadJsonStr:'+ leadJsonStr);
        string rtn;
        try {
            String [] expenseAccessFields = new String [] {'Email',
                                                            'LastName',
                                                            'Fax',
                                                            'Phone',
                                                            'Website',
                                                            'Company',
                                                            'Title'
                                                            };
            
            Map<String,Schema.SObjectField> m = Schema.SObjectType.Lead.fields.getMap();

            for (String fieldToCheck : expenseAccessFields) {
                // Check if the user has access to view field
                if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
                    // Pass error to client
                    throw new System.NoAccessException();
                }
            }

            LeadInfoClass leadInfo = (LeadInfoClass)JSON.deserialize(leadJsonStr, LeadInfoClass.class);
            system.debug('==debug==leadInfo:' + leadInfo);

            Lead lead = new Lead(
                LastName = leadInfo.name,
                Fax = leadInfo.fax,
                Phone = leadInfo.workPhone,
                Website = leadInfo.websites,
                Company = leadInfo.companyNames,
                Title = leadInfo.jt,
                Email = leadInfo.email
                );
            List<Lead> newLeads = new List<Lead>();
            newLeads.add(lead);

            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, newLeads);

            // No exceptions are thrown and no rating is set
            insert securityDecision.getRecords();

            rtn = 'ok';
        } catch(Exception ex) {
            rtn = 'ng';
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
            return rtn;
     }

     /**
      * @description LeadInfoClass
      */
    public Class LeadInfoClass {
        /**
         * @description address
         * @return address
         */
        public String address {get;set;}
        /**
         * @description name
         * @return name
         */
        public String name {get;set;}
        /**
         * @description email
         * @return email
         */
        public String email {get;set;}
        /**
         * @description fax
         * @return fax
         */
        public String fax {get;set;}
        /**
         * @description jt
         * @return jt
         */
        public String jt {get;set;}
        /**
         * @description workPhone
         * @return workPhone
         */
        public String workPhone {get;set;}
        /**
         * @description departments
         * @return departments
         */
        public String departments {get;set;}
        /**
         * @description websites
         * @return websites
         */
        public String websites {get;set;}
        /**
         * @description companyNames
         * @return companyNames
         */
        public String companyNames {get;set;}
    }
}