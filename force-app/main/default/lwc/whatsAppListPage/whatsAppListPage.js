import { LightningElement, track, api, wire } from 'lwc';

import getMessages1 from '@salesforce/apex/WhatsAppController.getMessages1';
import sendMessage from '@salesforce/apex/WhatsAppController.sendMessageListPage';
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
import refreshMessagesListPage from "@salesforce/apex/WhatsAppController.refreshMessagesListPage";
import getContactList from '@salesforce/apex/WhatsAppController.getContactList';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

import whatAppBlankProfile from '@salesforce/resourceUrl/WhatsAppBlankProfile';
import WhatsAppIcon from '@salesforce/resourceUrl/WhatsAppIcon';
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
import WhatsApp from '@salesforce/label/c.WhatsApp';
import Create_a_new_quick_response from '@salesforce/label/c.Create_a_new_quick_response';

const FIELDS = [
    'Narne_New_Member__c.Member_Full_Name__c',
    'Narne_New_Member__c.Narne_Official_Number__c',
    'Narne_New_Member__c.Name',
];

export default class WhatsAppListPage extends NavigationMixin(LightningElement) {
    @track contactList;

    @track listofMessages = [];
    @track message = '';
    error;
    activeTab = '';
    @track recordId;
    @track whatAppBlankProfile = whatAppBlankProfile;
    @track WhatsAppIcon = WhatsAppIcon;
    @track updateMessages;
    @track showUpload = false;
    @track previewFile = false;
    @track showQuickreply = false;
    @track createQuickResponse = false;
    @track responseList = [];
    @track refreshResponse = [];
    @track responseObj = {};
    @track searchKey = '';
    @track selectOption = 'MostUsed';
    @track nextPageLink = '';
    @track loaded = false;
    @track phoneNumber;
    @track fileList;
    @track files = [];
    subscription = {};
    @track contactName;
    @track contactNamee;
    @track contactPhone;
    @track leadPhone;
    @track leadNamee;
    @track phoneList = [];
    leadPhoneList = [];
    leadContactPhoneList = [];
    //@track contactMatch = false;
    buttonClicked = false;
    filebutton = false;
    @track radioSelect = false;
    @track contactRadioSelect = false;
    @track leadRadioSelect = false;
    enterKeyPressed = false;
    @track shownewModal = false;
    @track conName;
    @track conPhone;
    @api channelName = '/event/WATI_Event__e';
    @api compHeight;
    @track calculatedHeight;
    @track iconClass = '';
    @track isHovered = false;
    @track contactIconTitle;
    @track LeadIconTitle;
    @track sendTemplate = false;
    @track recPhoneNumber;
    @track recContactName;
    @track filterValue = 'All Chats';

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
        Search,
        WhatsApp
    };

    /*-------------------------connectedCallback (get Contact List)-------------------------------*/
    connectedCallback() {
        getContactList({ searchName: '' })
            .then((result) => {
                this.contactList = JSON.parse(JSON.stringify(result.contact_list));
                this.phoneList = result.phoneList;
                let contactMap = result.contactPhoneMap;
                let leadMap = result.leadPhoneMap;
                this.leadPhoneList = result.leadPhoneList;
                this.leadContactPhoneList = this.phoneList.concat(this.leadPhoneList);

                for (let i = 0; i < this.contactList.length; i++) {
                    for (let key in contactMap) {
                        if (this.contactList[i].phone === key) {
                            this.contactList[i].contactMatch = true;
                            this.contactList[i].recId = contactMap[key];
                        }
                    }
                }
                for (let i = 0; i < this.contactList.length; i++) {
                    for (let key in leadMap) {
                        if (this.contactList[i].phone === key) {
                            this.contactList[i].leadMatch = true;
                            this.contactList[i].recId = leadMap[key];
                        }
                    }
                }
                for (let i = 0; i < this.contactList.length; i++) {
                    for (let j = 0; j < this.leadContactPhoneList.length; j++) {
                        if (this.contactList[i].leadMatch === true || this.contactList[i].contactMatch === true) {
                            this.contactList[i].newLead = false;
                        } else if (this.contactList[i].leadMatch === false || this.contactList[i].contactMatch === false) {
                            this.contactList[i].newLead = true;
                        }
                        else {

                        }
                    }
                }
                this.activeTab = this.contactList[0].fullName;
                this.contactName = this.contactList[0].fullName;
                this.phoneNumber = this.contactList[0].phone;
                this.recordId = this.contactList[0].recId;
            })
            .catch((error) => {
                console.log('Error:: ' + JSON.stringify(error));
            });
    }

    /*-------------------------handleKeyUp (Search field)-------------------------------*/
    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        let seacrhText = evt.target.value;
        if (isEnterKey) {
            getContactList({ searchName: seacrhText })
                .then((result) => {
                    this.contactList = JSON.parse(JSON.stringify(result.contact_list));
                    this.phoneList = result.phoneList;
                    let contactMap = result.contactPhoneMap;
                    let leadMap = result.leadPhoneMap;
                    this.leadPhoneList = result.leadPhoneList;
                    this.leadContactPhoneList = this.phoneList.concat(this.leadPhoneList);

                    for (let i = 0; i < this.contactList.length; i++) {
                        for (let key in contactMap) {
                            if (this.contactList[i].phone === key) {
                                this.contactList[i].contactMatch = true;
                                this.contactList[i].recId = contactMap[key];
                            }
                        }
                    }
                    for (let i = 0; i < this.contactList.length; i++) {
                        for (let key in leadMap) {
                            if (this.contactList[i].phone === key) {
                                this.contactList[i].leadMatch = true;
                                this.contactList[i].recId = leadMap[key];
                            }
                        }
                    }
                    for (let i = 0; i < this.contactList.length; i++) {
                        for (let j = 0; j < this.leadContactPhoneList.length; j++) {
                            if (this.contactList[i].leadMatch === true || this.contactList[i].contactMatch === true) {
                                this.contactList[i].newLead = false;
                            } else if (this.contactList[i].leadMatch === false || this.contactList[i].contactMatch === false) {
                                this.contactList[i].newLead = true;
                            }
                            else {

                            }
                        }
                    }
                    this.activeTab = this.contactList[0].fullName;
                    this.contactName = this.contactList[0].fullName;
                    this.phoneNumber = this.contactList[0].phone;
                    this.recordId = this.contactList[0].recId;
                })
                .catch((error) => {
                    console.log('Error:: ' + JSON.stringify(error));
                });
        }
    }

    /*-------------------------Contact List methods---------------------------------*/
    handleContactMouseOver(event) {
        let conName = event.target.conname;
        let conPhone = event.target.conphone;
        this.contactIconTitle = 'Contact Name: ' + conName + '\nContact Phone: ' + conPhone;
    }
    handleLeadMouseOver(event) {
        let leadName = event.target.leadname;
        let leadPhone = event.target.leadphone;
        this.LeadIconTitle = 'Lead Name: ' + leadName + '\nLead Phone: ' + leadPhone;
    }
    
    get acceptedFormats() {
        return [".pdf", ".png", ".jpg", ".jpeg"];
    }
    get options() {
        return [
            { label: 'Most Used', value: 'MostUsed' },
            { label: 'Newest First', value: 'NewestFirst' }
        ];
    }
    get filterOptions() {
        return [
            { label: 'All Chats', value: 'All Chats' },
            { label: 'Active Chats', value: 'Active Chats' },
            { label: 'Expired Chats', value: 'Expired Chats' }
        ]
    }
    get radiooptions() {
        return [
            { label: 'Contact', value: 'Contact' },
            { label: 'Lead', value: 'Lead' },
        ];
    }
    handleContactClick(event) {
        console.log('ConId: ' + event.target.contactid);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.contactid,
                actionName: 'view'
            }
        });
    }
    handleLeadClick(event) {
        console.log('LeadId: ' + event.target.leadid);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.leadid,
                actionName: 'view'
            }
        });
    }
    handleNewClick(event) {
        this.shownewModal = true;
        this.radioSelect = true;
        this.conName = event.target.value;
        this.conPhone = event.target.phone;
    }
    handleRadioChange(event) {

        this.radioSelect = false;
        let val = event.target.value;
        if (val === 'Contact') {
            this.contactRadioSelect = true;
            this.contactNamee = this.conName;
            this.contactPhone = this.conPhone;
        }
        if (val === 'Lead') {
            this.leadRadioSelect = true;
            this.leadNamee = this.conName;
            this.leadPhone = this.conPhone;
        }
    }
    handleSuccessContact(event) {
        let conId = event.detail.id;
        let recordName = event.detail.fields.LastName.value;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'SUCCESS',
                message: 'Contact ' + recordName + ' was created',
                variant: 'success'
            }));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: conId,
                actionName: 'view'
            }
        });
        this.shownewModal = false;
    }
    handleSuccessLead(event) {
        let leadId = event.detail.id;
        let recordName = event.detail.fields.LastName.value;
        console.log('Name: ' + recordName);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'SUCCESS',
                message: 'Lead ' + recordName + ' was created',
                variant: 'success'
            }));
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                actionName: 'view'
            }
        });
        this.shownewModal = false;
    }
    handleContactCancel() {
        this.shownewModal = false;
        this.contactRadioSelect = false;
        this.leadRadioSelect = false;
    }
    handleActive(event) {
        this.listofMessages = [];

        if (event.target.getAttribute('value') != undefined) {
            this.contactName = event.target.getAttribute('value');
        }
        this.activeTab = event.target.getAttribute('value');
        this.loadMessages(event.target.getAttribute('phone'));
        if (event.target.getAttribute('phone') != undefined) {
            this.phoneNumber = event.target.getAttribute('phone');
        }
        this.recordId = event.target.getAttribute('contactid');
    }
    handleNameClick(event) {
        this.listofMessages = [];
        this.contactName = event.currentTarget.dataset.value;
        this.activeTab = event.currentTarget.dataset.value;
        this.loadMessages(event.currentTarget.dataset.phone);
        this.phoneNumber = event.currentTarget.dataset.phone;
    }
   
    handleSendTemplate() {
        this.sendTemplate = true;
        this.recPhoneNumber = this.phoneNumber;
        this.recContactName = this.contactName;
    }
    handleChildEvent(event) {
        const dataFromChild = event.detail.data;
        this.sendTemplate = dataFromChild;
    }
    cancelChild() {
        this.sendTemplate = false;
    }
   
    /*-------------------------wire (refreshMessagesListPage)---------------------------------*/
    @wire(refreshMessagesListPage, { mobNumber: '$phoneNumber', nextPageLink: '' })
    getUpdatedMessages(result) {
        this.updateMessages = result;
        if (result.data) {
            if (result.data.isSuccess == true) {
                this.listofMessages = result.data.watiMessagesList;
            }
        } else if (result.error) {
        }
    }

    /*-----------------------------wire (getFileVersions)-----------------------------*/
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

    /*-----------------------------wire (openQuickResponses)-----------------------------*/
    @wire(openQuickResponses, { searchKey: '$searchKey', selectOption: '$selectOption' })
    response(result) {
        this.refreshResponse = result;
        if (result.data) {
            this.responseList = result.data;
            console.log('data' + JSON.stringify(result.data));
        }
    }

    /*-----------------------------wire (getRecord)-----------------------------*/
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
    /*-----------------------------renderedCallback styles-----------------------------*/
    renderedCallback() {
        Promise.all([loadStyle(this, UtilityBarStyling)]);

        let heightt = window.innerHeight;
        const ULelement = this.template.querySelector('.slds-vertical-tabs__nav');
        if (ULelement) {
            ULelement.style.height = heightt - 218 + 'px';
        }
        const frameelement = this.template.querySelector('.frame');
        if (frameelement) {
            frameelement.style.height = heightt - 309 + 'px';
        }
        const messageslement = this.template.querySelector('.messages');
        console.log('styles:' + JSON.stringify(messageslement));
        if (messageslement) {
            messageslement.style.height = heightt - 309 + 'px';
        }
    }
   
    /*-----------------------------handleRefresh (refresh messages)-----------------------------*/
    handleRefresh() {
        console.log('Refresh');
        refreshApex(this.updateMessages);
        refreshApex(self.wiredActivities);
        //his.loadMessages();
        console.log('Updated');
    }

    /*-----------------------------Get Messages-----------------------------*/
    loadMessages(Phone) {
        let oldMessagesList = [...this.listofMessages];
        let tempList = [];
        getMessages1({ mobNumber: Phone, nextPageLink: this.nextPageLink })
            .then(result => {
                if (result) {
                    if (result.isSuccess == true) {
                        this.listofMessages = [...this.listofMessages, ...result.watiMessagesList];
                        if (result.nextPageLink != undefined) {
                            this.nextPageLink = result.nextPageLink;
                        } else {
                            this.nextPageLink = '';
                        }
                    }
                }
            })
            .catch(error => {
                this.error = error;
                console.log('Error' + this.error);
            });

    }

    /*-----------------------------handleInputChange (message input change)-----------------------------*/
    handleInputChange(event) {
        this.message = event.detail.value;
    }

    /*-----------------------------handleEnterPress (enter key press)-----------------------------*/
    handleEnterPress(event) {
        if (event.key === 'Enter') {
            if (!this.enterKeyPressed) {
                this.handleClick();
                this.enterKeyPressed = true;
            }
            event.preventDefault();
            setTimeout(() => {
                this.enterKeyPressed = false;
            }, 1000);

        }
    }

    /*-----------------------------handleDownloadClick (file icon click)-----------------------------*/
    handleDownloadClick(event) {
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

    /*-----------------------------handleClick (sned message)-----------------------------*/
    handleClick(event) {
        let ta = this.template.querySelector(`[data-id="maininput"]`);
        this.message = ta.value;
        this.buttonClicked = true;
        sendMessage({ mobNumber: this.phoneNumber, textMessage: this.message })
            .then(result => {
                this.message = '';
                ta.value = '';
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

    /*-------------------------handleSelect (plus icon click)-------------------------*/
    handleSelect(event) {
        let selectedItemValue = event.detail.value;
        if (event.detail.value == 'attachment') {
            this.showUpload = true;
        }
        if (event.detail.value == 'quickreply') {
            this.showQuickreply = true;
        }

    }

    /*-----------------------------------scroll bar--------------------------------------*/
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

    /*-----------------------------send file methods-----------------------------*/
    handleUploadFinished(event) {
        try {
            const uploadedFiles = event.detail.files;
            this.closeUpload();
            this.previewFile = true;
            refreshApex(this.wiredActivities);
        } catch (e) {
            console.log('e--->' + e);
        }
    }
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

    /*----------------------------- Quick response methods-----------------------------*/
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

    handleSubscribe() {

        // Callback invoked whenever a new event message is received
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
            let messageStatus = objData.messageStatus__c; A
            let type = objData.Type__c;
            let objList = { createdDate, messageStatus, textMessage };
            console.log('objList: ' + JSON.stringify(objList));
            //if(type = 'text'){
            refreshApex(self.updateMessages);
            //self.listofMessages.unshift(objList);
            //}else{
            refreshApex(self.wiredActivities);
            //}


            //this.listofMessages = [objList, this.listofMessages];

            console.log('Messages: ' + JSON.stringify(self.listofMessages));
            self.ShowToast('New Message', textMessage, 'success', 'dismissable');
            //refreshApex(self.updateMessages);

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