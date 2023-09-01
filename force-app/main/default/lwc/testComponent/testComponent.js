import { LightningElement,wire } from 'lwc';
import getObjectDetails from '@salesforce/apex/WhatsAppController.getObjectDetails';

export default class TestComponent extends LightningElement {

    @wire(getObjectDetails)
    objectData(result) {
        console.log('Result----->',JSON.stringify(result));
    }
    handleChange(event){
        console.log('inputValue----->',event.detail.value);
    }
}