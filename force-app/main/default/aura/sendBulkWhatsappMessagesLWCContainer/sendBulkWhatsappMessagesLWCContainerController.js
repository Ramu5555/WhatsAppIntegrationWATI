({
	doInIt : function(cmp, event, helper) {
        try{
            var myPageRef = cmp.get("v.pageReference");
        var mem = myPageRef.state.c__listofMembers;
        console.log('listofMembers',JSON.stringify(mem));
        cmp.set("v.listofMembers",mem);
        //split the account ids by comma and continue logic
        }catch(e){
            console.log('e--->',e);
        }
        
	},
    reInit : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
         var pageRef = component.get("v.pageReference");
        let test = component.get("v.pageReference").state.c__recordId;
        console.log('expauraId--->',test);  
        component.set('v.recordId',test);
    }
})