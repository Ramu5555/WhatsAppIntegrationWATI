import { LightningElement, api, track, wire } from 'lwc';
import createMetaData from '@salesforce/apex/CustomMetadataUtils.createMetaData';
import saveTemplateMetadata from '@salesforce/apex/WhatsAppController.saveTemplateMetadata';
import getWhatsAppSetupScreen from '@salesforce/apex/WhatsAppSetupScreenController.getWhatsAppSetupScreen';
import saveTemplateParams from '@salesforce/apex/WhatsAppSetupScreenController.saveTemplateParams';
import getContactFiedls from '@salesforce/apex/WhatsAppSetupScreenController.getContactFiedls';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import API_Key_Setup from '@salesforce/label/c.API_Key_Setup';
import Label from '@salesforce/label/c.Label';
import API_Key from '@salesforce/label/c.API_Key';
import End_Point_URL from '@salesforce/label/c.End_Point_URL';
import Object_Name from '@salesforce/label/c.Object_Name';
import Phone_Field from '@salesforce/label/c.Phone_Field';
import Template_Param_Mapping from '@salesforce/label/c.Template_Param_Mapping';
import WA_Param from '@salesforce/label/c.WA_Param';
import SF_Field_API_Name from '@salesforce/label/c.SF_Field_API_Name';
import Save from '@salesforce/label/c.Save';
import Update_Templates from '@salesforce/label/c.Update_Templates';

export default class WhatsAppSetupScreen extends LightningElement {
    @track templateName = ''
    @track WAParamName = 'name';
    @track labelValue;
    @track apiValue;
    @track urlValue;
    @track objNameValue;
    @track phoneValue;
    @track updatedResult;
    phoneFiled;
    OBJEName;
    EDUrl;
    apiKey;
    label;
    valueMap = new Map();
    @track templateList;
    @track paramValues = [];
    @track options = [];
    allSectionNames = [];

    /*--------------------------------custom labels---------------------------------*/
    label = {
        API_Key_Setup,
        Label,
        API_Key,
        End_Point_URL,
        Object_Name,
        Phone_Field,
        Template_Param_Mapping,
        WA_Param,
        SF_Field_API_Name,
        Save,
        Update_Templates
    };
    /*-------------------Wire Method (getWhatsAppSetupScreen)-----------------------------*/
    @wire(getWhatsAppSetupScreen)
    tempMDdata(result) {
        this.updatedResult = result;
        console.log('updated Result: ' + JSON.stringify(this.updatedResult));
        if (result.data) {
            this.templateList = result.data;
            console.log('Template List: ' + JSON.stringify(this.templateList));
        }
    }

    /*-------------------ConnectedCallBack (getContactFiedls)-----------------------------*/
    connectedCallback() {
        getContactFiedls()
            .then((result) => {
                console.log('Result: ' + JSON.stringify(result));
                let fieldList = result;
                console.log('mCNames:: ' + fieldList);
                if (fieldList) {
                    for (let i = 0; i < fieldList.length; i++) {
                        this.options.push({ label: fieldList[i], value: fieldList[i] });
                    }
                    console.log('Options:: ' + JSON.stringify(this.options));
                }
            })
            .catch((error) => {
                console.log('Error:: ' + error);
            });
    }

    /*-------------------renderedCallback (to set height for template param mapping tab)-----------------------------*/
    renderedCallback() {
        let heightt = window.innerHeight;
        const layoutelement = this.template.querySelector('.layoutClass');
        if (layoutelement) {
            layoutelement.style.height = heightt - 375 + 'px';
        }

    }
    /*-------------------Input change in api key setup tab-----------------------------*/
    handleAPIChange(event) {
        this.apiValue = event.target.value;
        console.log('apiValue: ' + this.apiValue);
    }
    handleEPURLChange(event) {
        this.urlValue = event.target.value;
        console.log('urlValue: ' + this.urlValue);
    }
    handleObjNameChange(event) {
        this.objNameValue = event.target.value;
        console.log('objNameValue: ' + this.objNameValue);
    }
    handlePhoneChange(event) {
        this.phoneValue = event.target.value;
        console.log('phoneValue: ' + this.phoneValue);
    }

    /*-------------------combobox values change in param mapping-----------------------------*/
    handleParamChange(event) {
        try {
            let templateName = event.target.dataset.template;
            let paramName = event.target.dataset.param;
            let paramValue = event.target.value;
            console.log('tempList------>' + JSON.stringify(this.templateList));
            let tempList = JSON.parse(JSON.stringify(this.templateList));
            for (let rec of tempList) {
                if (rec.templateName == templateName) {
                    for (let params of rec.paramsList) {
                        if (params.paramName == paramName) {
                            params.paramValue = paramValue;
                        }
                    }
                }
            }
            console.log('temporaryList------>' + JSON.stringify(tempList));
            this.templateList = tempList;
        } catch (e) {
            console.log(e);
        }

    }

    /*------------------------------API Save-----------------------------*/
    handleAPISave() {
        console.log('apiValue ' + this.apiValue + 'urlValue ' + this.urlValue + 'objNameValue ' + this.objNameValue + 'phoneValue ' + this.phoneValue);
        createMetaData({ apiKey: this.apiValue, urlED: this.urlValue, objName: this.objNameValue, phone: this.phoneValue })
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!!',
                    message: 'API Details Successfully Saved!',
                    variant: 'success'
                }));
                this.apiKey = '';
                this.OBJEName = '';
                this.EDUrl = '';
                this.phoneFiled = '';
            })
            .catch((error) => {
                console.log('Error: ' + JSON.stringify(error));
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(error),
                    variant: 'error'
                }));
            });
    }

    /*--------------------------------site link---------------------------------*/
    handleClickSite() {
        window.location.href = '/setup/own/entity/RemoteSiteSetting/home';
    }

    /*--------------------------------Template metadata save---------------------------------*/
    handleSaveTemplates() {
        console.log('this.templateList: ' + JSON.stringify(this.templateList));
        saveTemplateParams({ tempWrapString: JSON.stringify(this.templateList) })
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!!',
                    message: 'Template param Values Updated Succcessfully',
                    variant: 'success'
                }));

            })
            .catch((error) => {
                console.log('Error: ' + JSON.stringify(error));
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(error),
                    variant: 'error'
                }));
            });
    }

    /*--------------------------------Template metadata update---------------------------------*/
    handleUpdateTemplates(event) {
        console.log('Update');
        saveTemplateMetadata()
            .then((result) => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!!',
                    message: 'Templates Updated Succcessfully',
                    variant: 'success'
                }));
                refreshApex(this.updatedResult);
                console.log('Result: ' + JSON.stringify(this.updatedResult));
            })
            .catch((error) => {
                console.log('Error: ' + JSON.stringify(error));
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(error),
                    variant: 'error'
                }));
            });
    }
}