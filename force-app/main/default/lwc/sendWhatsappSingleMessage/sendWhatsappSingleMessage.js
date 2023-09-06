import { LightningElement, wire, track, api } from 'lwc';
import getMessages from '@salesforce/apex/WhatsAppController.getMessages';
import sendMessage from '@salesforce/apex/WhatsAppController.sendSingleMessage';
import uploadFiles from '@salesforce/apex/WhatsAppController.uploadFiles';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import openQuickResponses from '@salesforce/apex/QuickResponseController.openQuickResponses';
import updateQuickResponse from '@salesforce/apex/QuickResponseController.updateQuickResponse';
import deleteQuickResponse from '@salesforce/apex/QuickResponseController.deleteQuickResponse';
import { NavigationMixin } from 'lightning/navigation'
import { loadStyle } from 'lightning/platformResourceLoader';
import UtilityBarStyling from '@salesforce/resourceUrl/UtilityBarStyling';
import getFileVersions from "@salesforce/apex/WhatsAppController.getVersionFiles";
import refreshMessages from "@salesforce/apex/WhatsAppController.refreshMessages";
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

import Download from '@salesforce/label/c.Download';
import File from '@salesforce/label/c.File';
import Image from '@salesforce/label/c.Image';
import Attach from '@salesforce/label/c.Attach';
import Quick_Reply from '@salesforce/label/c.Quick_Reply';
import Write_your_message from '@salesforce/label/c.Write_your_message';
import Send from '@salesforce/label/c.send';
import Attachments from '@salesforce/label/c.Attachments';
import Close from '@salesforce/label/c.Close';
import Preview_File from '@salesforce/label/c.Preview_File';
import Preview from '@salesforce/label/c.Preview';
import Use_a_Quick_Response from '@salesforce/label/c.Use_a_Quick_Response';
import Search from '@salesforce/label/c.Search';
import Create from '@salesforce/label/c.Create';
import Edit from '@salesforce/label/c.Edit';
import Delete from '@salesforce/label/c.Delete';
import Save from '@salesforce/label/c.Save';
import Create_a_new_quick_response from '@salesforce/label/c.Create_a_new_quick_response';

const FIELDS = [
    'Narne_New_Member__c.Member_Full_Name__c',
    'Narne_New_Member__c.Narne_Official_Number__c',
    'Narne_New_Member__c.Name',
];

export default class SendWhatsappSingleMessage extends NavigationMixin(LightningElement) {
    @track listofMessages = [];
    @track message = '';
    error;
    @api recordId;
    @track updateMessages;
    showUpload = false;
    previewFile = false;
    showQuickreply = false;
    createQuickResponse = false;
    @track responseList = [];
    @track refreshResponse = [];
    @track responseObj = {};
    @track searchKey = '';
    @track selectOption = 'MostUsed';
    nextPageLink = '';
    loaded = false;
    @track fileList;
    @track files = [];
    subscription = {};
    buttonClicked = false;
    filebutton = false;
    enterKeyPressed = false;
    @api channelName = '/event/WATI_Event__e';

    label = {
        Download,
        File,
        Image,
        Attach,
        Quick_Reply,
        Write_your_message,
        Send,
        Attachments,
        Close,
        Preview_File,
        Use_a_Quick_Response,
        Create,
        Edit,
        Delete,
        Save,
        Create_a_new_quick_response,
        Preview,
        Search
    };

    get acceptedFormats() {
        return [".pdf", ".png", ".jpg", ".jpeg"];
    }
    get options() {
        return [
            { label: 'Most Used', value: 'MostUsed' },
            { label: 'Newest First', value: 'NewestFirst' }
        ];
    }

    connectedCallback() {
        // console.log('OUTRECID------->'+this.recordId);
        // if(this.recordId != null){
        //     console.log('INRECID---->'+this.recordId);
        //     this.loadMessages();
        // }
        this.registerErrorListener();
        this.handleSubscribe();
    }

    /*--------------------------------Wire (refreshMessages)---------------------------------*/
    @wire(refreshMessages, { recordId: '$recordId', nextPageLink: '' })
    getUpdatedMessages(result) {
        this.updateMessages = result;
        console.log('DIRECTRESP----->', JSON.stringify(result));
        if (result.data) {
            if (result.data.isSuccess == true) {
                console.log('link----->' + JSON.stringify(result.data.nextPageLink));
                this.listofMessages = result.data.watiMessagesList;
            }
            if (result.data.nextPageLink != undefined) {
                this.nextPageLink = result.data.nextPageLink;
            } else {
                this.nextPageLink = '';
            }
            console.log('listofMessagesLength----->' + this.listofMessages.length);
            console.log('listofMessages----->' + JSON.stringify(this.listofMessages));
        } else if (result.error) {
        }
    }

    /*--------------------------------Wire (getFileVersions)---------------------------------*/
    @wire(getFileVersions, { recordId: "$recordId" })
    fileResponse(value) {
        this.wiredActivities = value;
        const { data, error } = value;
        this.fileList = "";
        this.files = [];
        if (data) {
            this.fileList = data;
            for (let i = 0; i < this.fileList.length; i++) {
                let file = {
                    Id: this.fileList[i].Id,
                    Title: this.fileList[i].Title,
                    Extension: this.fileList[i].FileExtension,
                    ContentDocumentId: this.fileList[i].ContentDocumentId,
                    ContentDocument: this.fileList[i].ContentDocument,
                    CreatedDate: this.fileList[i].CreatedDate,
                    thumbnailFileCard:
                        "/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=" +
                        this.fileList[i].Id +
                        "&operationContext=CHATTER&contentId=" +
                        this.fileList[i].ContentDocumentId,
                    downloadUrl:
                        "/sfc/servlet.shepherd/document/download/" +
                        this.fileList[i].ContentDocumentId
                };
                this.files.push(file);
            }
            this.loaded = true;
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error loading Files",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
    }

    /*--------------------------------Wire (openQuickResponses)---------------------------------*/
    @wire(openQuickResponses, { searchKey: '$searchKey', selectOption: '$selectOption' })
    response(result) {
        this.refreshResponse = result;
        if (result.data) {
            this.responseList = result.data;
            console.log('data' + JSON.stringify(result.data));
        }
    }
    /*--------------------------------Wire (getRecord)---------------------------------*/
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    memberRecord;

    get fullName() {
        console.log('ActualCMemData----->', JSON.stringify(this.memberRecord));
        if (this.memberRecord.data) {
            return this.memberRecord.data.fields.Member_Full_Name__c.value;
        }
    }

    get mobileNumber() {
        if (this.memberRecord.data) {
            return this.memberRecord.data.fields.Narne_Official_Number__c.value;
        }
    }
    /*--------------------------------renderedCallback (to load static resource styles)---------------------------------*/
    renderedCallback() {
        Promise.all([loadStyle(this, UtilityBarStyling)]);
    }
    
    /*--------------------------------handleRefresh (refresh button)---------------------------------*/
    handleRefresh() {
        console.log('Refresh');
        refreshApex(this.updateMessages);
        refreshApex(self.wiredActivities);
        //his.loadMessages();
    }

    /*--------------------------------loadMessages (getMessages)---------------------------------*/
    loadMessages() {
        let oldMessagesList = [...this.listofMessages];
        let tempList = [];
        getMessages({ recordId: this.recordId, nextPageLink: this.nextPageLink })
            .then(result => {
                console.log('getMessages----->' + JSON.stringify(result));
                this.updateMessages = result.watiMessagesList;
                if (result) {
                    if (result.isSuccess == true) {
                        console.log('link----->' + JSON.stringify(result.nextPageLink));
                        this.listofMessages = [...this.listofMessages, ...result.watiMessagesList];
                        if (result.nextPageLink != undefined) {
                            this.nextPageLink = result.nextPageLink;
                        } else {
                            this.nextPageLink = '';
                        }
                    }

                    console.log('listofMessagesLength----->' + this.listofMessages.length);
                    // this.listofMessages = [...this.listofMessages,...result.watiMessagesList];
                    // console.log('Message List: '+JSON.stringify(this.listofMessages));
                    // console.log('listofMessagesLength----->'+this.listofMessages.length);
                }
            })
            .catch(error => {
                this.error = error;
                console.log('Error' + this.error);
            });

    }

    /*--------------------------------handleInputChange (Message input field change )---------------------------------*/
    handleInputChange(event) {
        this.message = event.detail.value;
    }

    /*--------------------------------handleEnterPress (enter key press)---------------------------------*/
    handleEnterPress(event) {
        if (event.key === 'Enter') {
            if (!this.enterKeyPressed) {
                this.handleClick();
                this.enterKeyPressed = true;

                // Perform your action here
                console.log('Enter key pressed');
            }
            event.preventDefault();
            setTimeout(() => {
                this.enterKeyPressed = false;
            }, 1000);

        }
    }

    /*--------------------------------handleDownloadClick (fileIcon onclick)---------------------------------*/
    handleDownloadClick(event) {
        console.log('Download');
        console.log('File Id: ' + event.target.value);
        console.log('File Id: ' + event.target.title);
        var fileId = event.target.value;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: fileId
            }
        })
    }

    /*--------------------------------handleClick (send message button)---------------------------------*/
    handleClick(event) {
        let recid = 'Sun'
        let ta = this.template.querySelector(`[data-id="maininput"]`);
        this.message = ta.value;
        console.log('taValue----->', ta.value);

        console.log('Record Id==' + this.recordId);
        console.log('Record Id==' + this.message);
        //this.disabled = true;
        this.buttonClicked = true;
        sendMessage({ recordId: this.recordId, textMessage: this.message })
            .then(result => {
                this.message = '';
                ta.value = '';
                console.log('result=' + JSON.stringify(result.errorMessage));
                if (result.isSuccess == false) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'ERROR',
                            message: JSON.stringify(result.errorMessage),
                            variant: 'error'
                        }));
                }
                refreshApex(this.updateMessages);
                setTimeout(() => {
                    this.buttonClicked = false;
                }, 2000);
            })
            .catch(error => {
                this.error = error;
                console.log('Error' + JSON.stringify(this.error));
            });
    }

    /*--------------------------------handleSelect (plus icon on click)---------------------------------*/
    handleSelect(event) {
        let selectedItemValue = event.detail.value;
        //alert('You are other action---->'+selectedItemValue);
        if (event.detail.value == 'attachment') {
            this.showUpload = true;
        }
        if (event.detail.value == 'quickreply') {
            this.showQuickreply = true;
        }

    }

    /*--------------------------------handleNotification (scroll bar)---------------------------------*/
    handleNotification(event) {
        try {
            let messagesDiv = this.template.querySelector('.messages');
            let scrollTop = messagesDiv.scrollTop;
            let scrollHeight = messagesDiv.scrollHeight;
            let offsetHeight = messagesDiv.offsetHeight;
            console.log('scrollTop------->' + scrollTop);
            console.log('scrollHeight------->' + scrollHeight);
            console.log('offsetHeight------->' + offsetHeight);
            if (Math.ceil(Math.abs(scrollTop)) === (scrollHeight - offsetHeight) || Math.ceil(Math.abs(scrollTop) + 1) === (scrollHeight - offsetHeight)) {
                console.log('AT THE TOP');
                console.log('AT THE TOP--->nextPageLink-->' + this.nextPageLink);
                if (this.nextPageLink != undefined && this.nextPageLink != '') {
                    this.loadMessages();
                }
            }
            if (scrollTop == 0) {
                console.log('AT THE BOTTOM');
                refreshApex(this.updateMessages);
            }

        } catch (e) {
            console.log(e);
        }
    }
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpeg', '.jpg'];
    }

    /*--------------------------------handleUploadFinished (handleUploadFinished)---------------------------------*/
    handleUploadFinished(event) {
        try {
            const uploadedFiles = event.detail.files;
            console.log('UploadeFiles------>', JSON.stringify(uploadedFiles));
            //alert('No. of files uploaded------->',uploadedFiles.length);
            this.closeUpload();
            this.previewFile = true;
            // this.sendFiles();
            refreshApex(this.wiredActivities);
        } catch (e) {
            console.log('e--->' + e);
        }

    }

    /*--------------------------------sendFile (send file button)---------------------------------*/
    sendFile() {
        this.sendFiles();

    }
    sendFiles() {
        this.filebutton = true;
        uploadFiles({ recordId: this.recordId })
            .then(result => {
                console.log('uploadFiles------->', JSON.stringify(result));
                if (result.fileError != undefined) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'ERROR',
                            message: 'File Cannot be More than 1.5MB',
                            variant: 'error'
                        }));
                }
                if (result.isSuccess == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'SUCCESS',
                            message: 'File sent successfully',
                            variant: 'success'
                        }));
                    this.filebutton = false;
                    this.closePreview();
                }

                refreshApex(this.updateMessages);
            })
            .catch(error => {
                console.log('error------->', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'ERROR',
                        message: JSON.stringify(error.message),
                        variant: 'error'
                    }));
            });
    }

    /*--------------------------------Quick Response Methods----------------------------------*/
    handleKeyChange(event) {
        this.searchKey = event.target.value;
    }
    handleCreateQuickResponse() {
        this.showQuickreply = false;
        this.createQuickResponse = true;
    }
    handleSubmit(event) {
        this.showQuickreply = true;
        this.createQuickResponse = false;
    }
    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Response Created Successfully',
                message: 'Response Created Successfully',
                variant: 'success'
            }));
        this.responseObj = {};
        refreshApex(this.refreshResponse);
    }
    handleCloseCreateQuickResponse() {
        this.showQuickreply = true;
        this.createQuickResponse = false;
        this.responseObj = {};
    }
    handleCloseQuickreply() {
        this.showQuickreply = false;
    }
    handleEditResponse(event) {
        this.showQuickreply = false;
        this.createQuickResponse = true;
        let index = event.target.dataset.id;
        this.responseObj = this.responseList[index];
        console.log('this.responseObj edit', JSON.stringify(this.responseObj));
    }
    handleSelectChange(event) {
        this.selectOption = event.target.value;
        console.log('selectOption', JSON.stringify(this.selectOption));
    }
    handleSendMsg(event) {
        let index = event.target.dataset.id;
        this.template.querySelector(`[data-id="maininput"]`).value = this.responseList[index].DhruvsoftWATI__Description__c;


        console.log('message----->' + this.message);
        this.showQuickreply = false;
        //this.handleClick();
        updateQuickResponse({ updateResponse: this.responseList[index] })
            .then(data => {
                                                             
            })
            .catch(error => {

            });
    }
    handleDeleteResponse(event) {
        console.log('this.responseList length 1', JSON.stringify(this.responseList.length));
        let index = event.target.dataset.id;
        let responseList = [];
        let deleteResponse = [];

        for (let i = 0; i < this.responseList.length; i++) {
            if (i != parseInt(index)) {
                responseList.push(this.responseList[i]);
            }
            else {
                deleteResponse.push(this.responseList[i]);
            }
        }
        this.responseList = responseList;
        console.log('deleteResponse', JSON.stringify(deleteResponse));
        deleteQuickResponse({ deleteResponse: deleteResponse })
            .then(data => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Response deleted Successfully',
                        message: 'Response deleted Successfully',
                        variant: 'success'
                    }));
                refreshApex(this.refreshResponse);
            })
            .catch(error => {

            });



        console.log('this.responseList length 2', JSON.stringify(this.responseList.length));
    }

    /*--------------------------------file methods---------------------------------*/
    showFile(event) {
        console.log(event.target.value)
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.value
            }
        })
    }
    closeUpload() {
        this.showUpload = false;
    }
    closePreview() {
        this.previewFile = false;
    }
    
    /*--------------------------------platform event methods (WEBHOOK)---------------------------------*/
    handleSubscribe() {

        const self = this;
        const messageCallback = function (response) {
            console.log('New message received 1: ', JSON.stringify(response));
            console.log('New message received 2: ', response);
            var obj = JSON.parse(JSON.stringify(response));
            console.log(obj.data.payload);
            console.log(obj.data.payload.Message__c);
            console.log(self.channelName);
            let objData = obj.data.payload;
            console.log('objData: ' + JSON.stringify(objData))
            let textMessage = objData.Message__c;
            let createdDate = objData.createdDate__c;
            let messageStatus = objData.messageStatus__c;
            let type = objData.Type__c;
            let objList = { createdDate, messageStatus, textMessage };
            console.log('objList: ' + JSON.stringify(objList));
            //if(type = 'text'){
            refreshApex(self.updateMessages);

            refreshApex(self.wiredActivities);

            console.log('Messages: ' + JSON.stringify(self.listofMessages));
            self.ShowToast('New Message', textMessage, 'success', 'dismissable');

        };
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(self.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            self.subscription = response;
            console.log('Message: ' + self.subscription);

        });
    }
    //handle Error
    registerErrorListener() {
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }
    ShowToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}