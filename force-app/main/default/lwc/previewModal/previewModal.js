import { LightningElement,api } from 'lwc';
// importing Custom Label
import Close from '@salesforce/label/c.Close';
export default class PreviewModal extends LightningElement {

  label = {
    Close
};
    @api url;
    @api fileExtension;
    showFrame = false;
    showModal = false;
    @api show() {
      console.log('URL',this.url);
      console.log("###showFrame : " + this.fileExtension);
      if (this.fileExtension === "pdf") {
        console.log('PDF->');
        this.showFrame = true;
      }
     
      else this.showFrame = false;
      this.showModal = true;
    }
    closeModal() {
      this.showModal = false;
    }
}