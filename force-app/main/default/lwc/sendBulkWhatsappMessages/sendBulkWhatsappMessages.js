import { LightningElement,api,track,wire } from 'lwc';
import getTemplates from '@salesforce/apex/WhatsAppController.getTemplates';
import sendTemplates from '@salesforce/apex/WhatsAppController.sendTemplates';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';

// importing Custom Label
import Close from '@salesforce/label/c.Close';
import SendMessage from '@salesforce/label/c.Send_Message';
import ListViewMessage from '@salesforce/label/c.Please_select_atleast_2_Member_Records_to_send_a_message';   
import Cancel from '@salesforce/label/c.Cancel';
import send from '@salesforce/label/c.send';
import Template_Message from '@salesforce/label/c.Template_Message';
import SentMessage from '@salesforce/label/c.Template_Message_Sent_Successfully'; 
import Result from '@salesforce/label/c.Result';
import PhoneError from '@salesforce/label/c.Invalid_Phone_Number_Format';  
import Contact_Name from '@salesforce/label/c.Contact_Name';
import Contact_Phone from '@salesforce/label/c.Contact_Phone';
import Done from '@salesforce/label/c.Done';

const coll = [
                   
    { label: 'Template Name', type:'text', fieldName: 'tempName'},
    { label: 'Message', type:'text', fieldName: 'tempBody'},
    { label: 'Action', type: 'button',
                        typeAttributes: {
                            label: 'View Message',  
                            name: 'Show',  
                            title: 'Show',  
                            disabled: false,  
                            value: 'Show',  
                            iconPosition: 'left' 
                        }
                    }
]

export default class SendBulkWhatsappMessages extends NavigationMixin(LightningElement) {
    label = {
        Close,
        SendMessage,
        ListViewMessage,
        Template_Message,
        send,
        Cancel,
        SentMessage,
        Result,
        PhoneError,
        Contact_Name,
        Contact_Phone,
        Done
    };

    @track openModal=false;
    @track memberRecordId;
    @api listofMembers=[];
    @track listofMemberstrack;
    @track showMessage = false;
    @track hideModal= false;
    @track templateName;
    @api recordId;
    @track validCount;
    @track memberName=[];
    @track memberMobileNumber=[];
    @track invalidMemberList=[];
    @track resultinvalid;
    @track sendbutton= true;
    @track displayTemplates = false;
    @track displayInvalNo= false;
    @track displayErrorMessage = false;
    @track customparam;
    @track customparam;
    mycolumns = coll;
    @track data;
    connectedCallback()
    {
        this.openModal=true;
        this.hideModal = true;
        var members = this.listofMembers.toString();
        var splitMembers = members.split(',');
        console.log('listofMembers',this.listofMembers);
        console.log('listofMembers',members);
        console.log('listofMembers',splitMembers);
        console.log('listofMembers',this.listofMembers.length);
        if(splitMembers.length < 2)
        {
           this.displayErrorMessage = true;
           this.sendbutton = false;
        }
        else{
            this.displayTemplates = true;
        }
    }
    @wire(getTemplates)
     tempdata({data, error})
     {
        //loadStyle(this, LightningModal);
        console.log('data'+JSON.stringify(this.data));
        console.log('recordId=='+this.recordId)
        this.memberRecordId = this.recordId;
        if(data)
        {
            this.data = data;
            console.log('data'+JSON.stringify(this.data));
            let templates = data.watiTemplatesList
            console.log('data'+JSON.stringify(this.data));
            let TempList = []; 
            templates.forEach((record) => {
                let tempData = Object.assign({}, record);  
                tempData.tempName = tempData.templateName;
                tempData.tempBody = tempData.templatebody;
                tempData.customparam = JSON.stringify(tempData.recCustPar);
                console.log('Name='+tempData.tempName);
                console.log('Body='+tempData.tempBody);
                console.log('Body='+tempData.customparam); 
                TempList.push(tempData);
            });
            this.data = TempList;
            
        }
     }
     callRowAction(event)
     {
      
        console.log('Test'+JSON.stringify(event.detail.row.templatebody));
     this.templateebody = event.detail.row.templatebody;
   
        this.showMessage = true;
        this.hideModal = false;
     }
     hideDisplayModalBox()
     {
        this.showMessage = false;
        this.hideModal = true;
     }
     handleRowSelection = event =>
     {
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
       
        if(selectedRecords.length > 0){
            console.log('selectedRows====>>>'+ JSON.stringify(selectedRecords));
   
            let templateName = '';
            let custpar = '';
            selectedRecords.forEach(currentItem => {
                templateName = currentItem.tempName;
                custpar = currentItem.customparam;
                console.log('Name='+templateName);
                console.log('custpar='+custpar);
            });
        this.templateName = templateName;
        this.customparam = custpar;
            
        }   
        /*var selectedRows = event.detail.selectedRows;
        console.log('selectedRows====>>>'+ JSON.stringify(selectedRows));
        console.log(selectedRows);
        this.tempData = selectedRows[0];
        console.log('tempData===>>>'+ JSON.stringify(this.tempData));*/
     }
     handleClick(event)
     {
        console.log('Member Record Idssss===='+JSON.stringify(this.listofMembers));
        console.log('Member Record Id===='+this.templateName);
        console.log('Member Record Id===='+this.customparam);
        if(this.templateName===undefined)
        {
            console.log('114Test');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning!!',
                message: 'Please select message template',
                variant: 'warning'
            }));
        }
        else{
        sendTemplates({ recordsIdSet: this.listofMembers,templateName:this.templateName })
        .then((result) => {
            console.log('Result==='+JSON.stringify(result));
            console.log('Result==='+JSON.stringify(result.validMemCount));
            console.log('Result==='+JSON.stringify(result.isSuccess));
            console.log('Result==='+result.invalidWhatsappNumbers);
            console.log('Result==='+JSON.stringify(result.validMemCount));
            if(result.isSuccess === true)
            {
                var conts = result.invalidMemberMap;
                for(var key in conts){
                    this.invalidMemberList.push({value:conts[key], key:key});
                }
                console.log('list==='+this.invalidMemberList);
                this.resultinvalid = true;
                this.hideModal=false;
                this.validCount = result.validMemCount;
                this.memberName = result.invalidMemberNames;
                this.memberMobileNumber = result.invalidWhatsappNumbers;
                if(result.invalidWhatsappNumbers.length >=1)
                {
                    console.log('length=='+result.invalidWhatsappNumbers.length );
                    this.displayInvalNo = true;
                }
                
            }
            else{
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: 'Failed.... Invalid Mobile Numbers. Please Check Mobile Number ',
                    variant: 'error'
                }));
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.contacts = undefined;
        });
    }
     }
    Cancel(){
        this.openModal=false;
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'home',
            },
        });
    }
    navigatetoView()
    {
        console.log('Test');
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Contact',
                actionName: 'list',
                filterName: 'RecentlyViewed'
            }
        });
    }

}