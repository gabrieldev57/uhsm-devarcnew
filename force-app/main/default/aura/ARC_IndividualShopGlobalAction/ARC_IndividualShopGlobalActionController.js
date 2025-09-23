({
    doInit: function(cmp) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c:individualShopDEPRECATEDEnglish&c__layout=newport&c__tabIcon=custom:custom18&c__tabLabel=DEPRECATED Shop/Enroll"
        });        
   urlEvent.fire();
   }
})