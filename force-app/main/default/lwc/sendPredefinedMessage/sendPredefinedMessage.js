import { LightningElement, wire, track, api } from 'lwc';
import getTemplates from '@salesforce/apex/WhatsAppController.getTemplates';
import sendTemplateListPage from '@salesforce/apex/WhatsAppController.sendTemplateListPage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import sendTemplate from '@salesforce/apex/WhatsAppController.sendTemplate';
import { loadStyle } from "lightning/platformResourceLoader";
import dswastyling from '@salesforce/resourceUrl/DSWAStyling';

import Send_Message from '@salesforce/label/c.Send_Message';
import Cancel from '@salesforce/label/c.Cancel';
import Send from '@salesforce/label/c.send';
import Close from '@salesforce/label/c.Close';
import Template_Message from '@salesforce/label/c.Template_Message';
const coll = [
    { label: 'Template Name', type: 'text', fieldName: 'tempName' },
    { label: 'Message', type: 'text', fieldName: 'tempBody', hideDefaultActions: true },
    {
        label: 'Action', type: 'button',
        typeAttributes: {
            label: 'View Message',
            name: 'Show',
            title: 'Show',
            disabled: false,
            value: 'Show',
            iconPosition: 'left'
        }
    }
];

export default class SendPredefinedMessage extends LightningElement {
    @api recordId;
    @api phoneNumber;
    @api conName;
    @api parentClose = false;
    @api listofMembers;
    @track showMessage = false;
    @track templateName;
    @track customparam;
    error;
    buttonClicked = false;
    templatedata;
    showSpinner = false;
    mycolumns = coll;
    @track data;
    @track customparam;

    label = {
        Send_Message,
        Send,
        Cancel,
        Close,
        Template_Message
    };

    /*--------------------------------ConnectedCallBack (to load static resource styles)---------------------------------*/
    connectedCallback() {
        loadStyle(this, dswastyling);
        console.log('Selected Records==' + this.listofMembers);
        console.log('Phone Number: ' + this.phoneNumber);
        console.log('Phone Number: ' + this.conName);
    }

    /*--------------------------------Wire (getTemplates)---------------------------------*/
    @wire(getTemplates)
    tempdata({ data, error }) {
        console.log('dataOpdated-------' + data);
        console.log('recordId==' + this.recordId)
        if (data) {
            console.log('dataOpdated-------', JSON.stringify(data));
            this.data = data;
            let templates = data.watiTemplatesList
            console.log('data' + JSON.stringify(this.data));
            let TempList = [];
            templates.forEach((record) => {
                let tempData = Object.assign({}, record);
                tempData.tempName = tempData.templateName;
                tempData.tempBody = tempData.templatebody;
                tempData.customparam = JSON.stringify(tempData.recCustPar);
                console.log('Name=' + tempData.tempName);
                console.log('Body=' + tempData.tempBody);
                console.log('Body=' + tempData.customparam);
                TempList.push(tempData);
            });
            this.data = TempList;

        }
    }
    /*--------------------------------handleRowSelection (row selection in datatable)---------------------------------*/
    handleRowSelection = event => {
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();

        if (selectedRecords.length > 0) {
            console.log('selectedRows====>>>' + JSON.stringify(this.data));
            console.log('selectedRows====>>>' + JSON.stringify(selectedRecords));

            let templateName = '';
            let custpar = '';
            selectedRecords.forEach(currentItem => {
                templateName = currentItem.tempName;
                custpar = currentItem.customparam;
                console.log('Name=' + templateName);
                console.log('custpar=' + custpar);
            });
            this.templateName = templateName;
            this.customparam = custpar;

        }

    }

    /*--------------------------------callRowAction (row action)---------------------------------*/
    callRowAction(event) {

        console.log('Test' + JSON.stringify(event.detail.row.templatebody));
        this.templateebody = event.detail.row.templatebody;

        this.showMessage = true;
    }
    get setDatatableHeight() {
        if (this.count == 0) {//set the minimum height
            return 'height:rem;';
        }
        else if (this.count > 10) {//set the max height
            return 'height:50rem;';
        }
        return '';//don't set any height (height will be dynamic)
    }

    /*--------------------------------handleClick (send template button)---------------------------------*/
    handleClick() {
        console.log('Member Record Id====' + this.recordId);
        console.log('Member Record Id====' + this.templateName);
        this.buttonClicked = true;
        if (this.templateName === undefined) {
            console.log('114Test');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning!!',
                message: 'Please select message template',
                variant: 'warning'
            }));
        }
        else {
            this.showSpinner = true;
            if (this.recordId != undefined) {
                sendTemplate({ recordId: this.recordId, templateName: this.templateName })
                    .then((result) => {
                        console.log('Result===' + JSON.stringify(result.isSuccess));
                        console.log('Invalid mobile Number===' + JSON.stringify(result.invalidMobileNumber));
                        console.log('Error:=== ' + JSON.stringify(result.errorDetails));
                        console.log('Param Error Message ' + JSON.stringify(result.paramEmptyError));
                        let errorMessage = JSON.stringify(result.errorDetails);
                        if (result.isSuccess == true) {
                            console.log('result==');
                            if (result.invalidMobileNumber === 'Invalid Mobile Number Please check Mobile Number') {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + JSON.stringify(result.invalidMobileNumber),
                                    variant: 'error'
                                }));
                            }

                            else {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Success!!',
                                    message: 'Template Message Sent Successfully',
                                    variant: 'success'
                                }));
                                this.dispatchEvent(new CloseActionScreenEvent());
                            }
                        }
                        else {
                            if (result.paramEmptyError != undefined) {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + JSON.stringify(result.paramEmptyError),
                                    variant: 'error'
                                }));
                            }
                            else {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + errorMessage,
                                    variant: 'error'
                                }));
                            }

                        }
                        this.showSpinner = false;
                        this.buttonClicked = false;
                        this.error = undefined;
                    })
                    .catch((error) => {
                        this.error = error;
                        this.contacts = undefined;
                    });
            }
            else if (this.phoneNumber != undefined) {
                sendTemplateListPage({ phoneNumber: this.phoneNumber, templateName: this.templateName, conName: this.conName })
                    .then((result) => {
                        console.log('Result===' + JSON.stringify(result.isSuccess));
                        console.log('Invalid mobile Number===' + JSON.stringify(result.invalidMobileNumber));
                        console.log('Error:=== ' + JSON.stringify(result.errorDetails));
                        console.log('Param Error Message ' + JSON.stringify(result.paramEmptyError));
                        let errorMessage = JSON.stringify(result.errorDetails);
                        if (result.isSuccess == true) {
                            console.log('result==');
                            if (result.invalidMobileNumber === 'Invalid Mobile Number Please check Mobile Number') {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + JSON.stringify(result.invalidMobileNumber),
                                    variant: 'error'
                                }));
                            }

                            else {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Success!!',
                                    message: 'Template Message Sent Successfully',
                                    variant: 'success'
                                }));
                                this.dispatchEvent(new CloseActionScreenEvent());
                            }
                        }
                        else {
                            if (result.paramEmptyError != undefined) {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + JSON.stringify(result.paramEmptyError),
                                    variant: 'error'
                                }));
                            }
                            else {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Error!!',
                                    message: 'Failed ' + errorMessage,
                                    variant: 'error'
                                }));
                            }

                        }
                        this.showSpinner = false;
                        this.buttonClicked = false;
                        this.error = undefined;
                    })
                    .catch((error) => {
                        this.error = error;
                        this.contacts = undefined;
                    });
            }

        }
        const event = new CustomEvent('childevent', {
            detail: { data: this.parentClose }
        });
        this.dispatchEvent(event);
    }
    /*--------------------------------cancel hide modal---------------------------------*/
    hideDisplayModalBox() {
        this.showMessage = false;
    }
    cancel() {
        this.dispatchEvent(new CloseActionScreenEvent());

        const event = new CustomEvent('childevent', {
            detail: { data: this.parentClose }
        });
        this.dispatchEvent(event);

    }
}