({
    onRecordIdChange : function(component, event, helper) {
        let newRecordId = component.get("v.recordId");
        console.log('memberidFromAURA----->',newRecordId);
        if(newRecordId != null && newRecordId != undefined){
            var utilityAPI = component.find("utilitybar");
            var eventHandler = function(response){
                console.log('initHandler');
            };
            utilityAPI.onUtilityClick({ 
                utilityId : "utilitybar",
                eventHandler: eventHandler 
            }).then(function(result){
                console.log('Click:');
                debugger;
                component.set("v.memberId",newRecordId);
            component.set("v.passData",true);
                console.log('Record Id: '+component.get("v.memberId"));
                console.log('Pass Data: '+component.get("v.passData"));
            }).catch(function(error){
                console.log('error '+error);
            });
        }
        if(newRecordId == null && newRecordId == undefined)
        {
            var utilityAPI = component.find("utilitybar");
            console.log('utilityAPI'+utilityAPI);
            utilityAPI.minimizeUtility();
            component.set("v.passData",false);
            console.log('Pass Data: '+component.get("v.passData"));
        }
    }
})