import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import uploadImage from "@salesforce/apex/CameraController.uploadImage";
import insertData from "@salesforce/apex/CameraController.insertData";

export default class scanBuniessCardToLead extends LightningElement {
  @track in_name;
  @track in_email;
  @track in_company_names;
  @track in_address;
  @track in_departments;
  @track in_jt;
  @track in_websites;
  @track in_work_phone;
  @track in_fax;
  @track isLoading = false;

  leadInfo = {
    address: "",
    name: "",
    email: "",
    fax: "",
    jt: "",
    workPhone: "",
    departments: "",
    websites: "",
    companyNames: ""
  };

  connectedCallback() {
    this.init();
  }

  init() {
    this.in_name = "";
    this.in_email = "";
    this.in_company_names = "";
    this.in_address = "";
    this.in_departments = "";
    this.in_jt = "";
    this.in_websites = "";
    this.in_work_phone = "";
    this.in_fax = "";
  }

  handle_Name_Change(event) {
    this.in_name = event.detail.value;
  }

  handle_Email_Change(event) {
    this.in_email = event.detail.value;
  }

  handle_CompanyNames_Change(event) {
    this.in_company_names = event.detail.value;
  }

  handle_Address_Change(event) {
    this.in_address = event.detail.value;
  }

  handle_Departments_Change(event) {
    this.in_departments = event.detail.value;
  }

  handle_Jt_Change(event) {
    this.in_jt = event.detail.value;
  }

  handle_Websites_Change(event) {
    this.in_websites = event.detail.value;
  }

  handle_WorkPhone_Change(event) {
    this.in_work_phone = event.detail.value;
  }

  handle_Fax_Change(event) {
    this.in_fax = event.detail.value;
  }

  compressBase64Image(base64String) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = function() {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        let width = img.width;
        let height = img.height;

        const maxWidth = 800; // 压缩后最大宽度
        const maxHeight = 600; // 压缩后最大高度

        if (width > height) {
          if (width > maxWidth) {
            height *= maxWidth / width;
            width = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            width *= maxHeight / height;
            height = maxHeight;
          }
        }

        canvas.width = width;
        canvas.height = height;

        ctx.drawImage(img, 0, 0, width, height);

        const compressedBase64 = canvas.toDataURL('image/jpeg', 1);
        resolve(compressedBase64.substring(23));
      };
      img.onerror = reject;
      img.src = `data:image/jpeg;base64,${base64String}`;
    });
  }

  handle_UploadImage(event) {
    this.isLoading = true;
    console.log("start  handle_UploadImage");
    this.base64String = "";
    if (event.detail.files.length > 0) {
      const file = event.detail.files[0];
      const reader = new FileReader();
      reader.onload = async () => {
        let base64String = reader.result.split(",")[1];
        if (base64String.length > 1024 * 1024 * 3) {
          base64String = await this.compressBase64Image(base64String)
        }
        // console.log("--Base64:", base64String);
        uploadImage({ base64String: base64String })
          .then((result) => {
            console.log("result");
            console.log(result);
            if (result != null && result !== "ng") {
              const arr = JSON.parse(result);
              console.log("arr");
              console.log(arr);

              this.in_name = arr.name;
              this.in_email = arr.email;
              this.in_company_names = arr.companyNames;
              this.in_address = arr.address;
              this.in_departments = arr.departments;
              this.in_jt = arr.jt;
              this.in_websites = arr.websites;
              this.in_work_phone = arr.workPhone;
              this.in_fax = arr.fax;

              this.dispatchEvent(new ShowToastEvent({
                title: "名刺スキャン",
                message: "解析成功",
                variant: "success"
              }));
              this.isLoading = false;
            }
          })
          .catch((error) => {
            console.log("error");
            console.log(error);
            this.dispatchEvent(new ShowToastEvent({
              title: "エラー",
              message: "解析失敗",
              variant: "error"
            }));
            this.isLoading = false;
          });
      };
      reader.readAsDataURL(file);
    } else {
      this.dispatchEvent(new ShowToastEvent({
        title: "インフォメーション",
        message: "画像存在しません。",
        variant: "info"
      }));
      this.isLoading = false;
    }
  }

  handle_insertData() {
    console.log("start  handle_insertData");
    this.leadInfo.address = this.in_address;
    this.leadInfo.name = this.in_name;
    this.leadInfo.email = this.in_email;
    this.leadInfo.fax = this.in_fax;
    this.leadInfo.jt = this.in_jt;
    this.leadInfo.workPhone = this.in_work_phone;
    this.leadInfo.departments = this.in_departments;
    this.leadInfo.websites = this.in_websites;
    this.leadInfo.companyNames = this.in_company_names;
    const jsonStr = JSON.stringify(this.leadInfo);

    if (this.in_name == null || this.in_name === "") {
      this.dispatchEvent(new ShowToastEvent({
        title: "エラー",
        message: "名前が入力されていません。",
        variant: "error"
      }));
      return;
    }

    insertData({ leadJsonStr: jsonStr })
      .then((result) => {
        console.log("result");
        console.log(result);

        this.dispatchEvent(new ShowToastEvent({
          title: "リード",
          message: "登録成功",
          variant: "success"
        }));

        this.init();
        return true;
      })
      .catch((error) => {
        console.log("error");
        console.log(error);
        this.dispatchEvent(new ShowToastEvent({
          title: "エラー",
          message: "解析失敗",
          variant: "error"
        }));
      });
  }

  /*

    videoElement;
    canvasElement;


    renderedCallback() {
        this.videoElement = this.template.querySelector('.videoElement');
        this.canvasElement = this.template.querySelector('.canvas');
    }

    async uploadAndAanalysisImage(){
        
    }
    async initCamera() {
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {

            // phone
            try {
                this.videoElement.srcObject = await navigator.mediaDevices.getUserMedia({video:{ facingMode: { exact: "environment" }}, audio: false});
            } catch (error) {
                console.error('Error accessing the camera: ', JSON.stringify(error));
            }

            // pc
            // try {
            //     this.videoElement.srcObject = await navigator.mediaDevices.getUserMedia({video: true, audio: false});
            // } catch (error) {
            //     console.error('Error accessing the camera: ', JSON.stringify(error));
            // }
            
        } else {
            console.error('getUserMedia is not supported in this browser');
        }
    }   
    
    async captureImage() {
        if(this.videoElement && this.videoElement.srcObject !== null) {
            this.canvasElement.height = this.videoElement.videoHeight;
            this.canvasElement.width = this.videoElement.videoWidth;
            const context = this.canvasElement.getContext('2d');
            context.drawImage(this.videoElement, 0, 0, this.canvasElement.width, this.canvasElement.height);
            const imageData = this.canvasElement.toDataURL('image/png');
            const imageElement = this.template.querySelector('.imageElement');
            imageElement.setAttribute('src', imageData);
            
            imageElement.classList.add('slds-show');
            imageElement.classList.remove('slds-hide');

            saveFile({base64String: imageData})
            .then((result) => {
                console.log(result);
                if (result != '' && result != null) {
                    
                } else {

                }
            })
            .catch((error) => {
                let e = JSON.stringify(error);
                console.log('resultError : ' + e);
                return;
            });
        }
    }

    async stopCamera(){
        const video = this.template.querySelector(".videoElement");
        video.srcObject.getTracks().forEach((track) => track.stop());
        video.srcObject = null;
        this.hideImageElement();
    }

    hideImageElement(){
        const imageElement = this.template.querySelector('.imageElement');
        imageElement.setAttribute('src', "");
        imageElement.classList.add('slds-hide');
        imageElement.classList.remove('slds-show');
    }
    */
}