public with sharing class sendBulkWhatsappMessages {
    
    public List<Contact> selMemLst;
    public String memIds;
    Set<Id> membeIds;
    public sendBulkWhatsappMessages(ApexPages.StandardSetController cntlr){
    selMemLst = cntlr.getSelected(); 
        system.debug('selMemLst=== '+selMemLst);
        memIds = '';
        for(Contact mem : selMemLst){
            memIds += mem.Id + ','; 
        }
        memIds = memIds.removeEnd(',');
        system.debug('memIds-->'+memIds);
     }
     public PageReference redirectToLC(){
         system.debug('member Ids:: '+memIds);
        String returnUrl = '/lightning/cmp/DhruvsoftWATI__sendBulkWhatsappMessagesLWCContainer?c__listofMembers='+memIds;
        PageReference pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        return pgReturnPage;
    }
   
}