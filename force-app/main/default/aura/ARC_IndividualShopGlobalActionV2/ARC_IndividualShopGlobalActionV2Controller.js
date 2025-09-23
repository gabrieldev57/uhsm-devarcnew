({
    doInit: function(cmp) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c:individualShopProductsUpdatePAEnglish&c__layout=newport&c__tabIcon=custom:custom18&c__tabLabel=Shop/Enroll Products Update"
        });        
   urlEvent.fire();
   }
})