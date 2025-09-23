var $ = jQuery.noConflict();

let retryInterval;
let svgInterval;

function checkForSVGInjection(){
    if(retryInterval) clearInterval(retryInterval);
    let retryIntervalTimeCurrent = 0;
    // Create Interval that checks if page has <meta name="svginject"> on the Head
    retryInterval = setInterval(() => {
        // Interval tries until 10 seconds pass (For 3G times for loading the page)
        if(retryIntervalTimeCurrent > 14000) return clearInterval(retryInterval);
        // If it finds the metadata, trigger injecting of SVGs on that page and stop the interval
        if($("meta[name='svginject']").length > 0){
            // Add a class to the site content so that img which will be injected will have a lower opacity
            $(".siteforceContentArea").addClass("arc-svg-injecting");
            clearInterval(retryInterval);
            retryInterval = null;
            omniscriptSVGInject();
            // Reset the Injecting interval mentioned above when clicking (for OS steps)
            $(document).on('click', function(){
                omniscriptSVGInject();
            });
        }
        retryIntervalTimeCurrent = retryIntervalTimeCurrent + 500;
    }, 500);
}

function getSVGElements(){
    return $(".siteforceContentArea").find("img[src$=svg]");
}

function omniscriptSVGInject(){
    // Create a super fast interval that checks until it finds an SVG to inject
    if(svgInterval) clearInterval(svgInterval);
    svgInterval = setInterval(() => {
        elems = getSVGElements();
        if(elems.length > 0){
            clearInterval(svgInterval);
            svgInterval = null;
            SVGInject(elems);
        }
    }, 5)
}

// Check for SVG Injection on Page Load
$(window).on('load', function (){
    checkForSVGInjection()
});
// Check for SVG Injection on Page change
window.addEventListener('pageChange', function(){
    checkForSVGInjection()
});
// Check for SVG Injection on popstate (history navigation)
window.addEventListener('popstate', function(){
    checkForSVGInjection()
});

function manualSVGInject(elem){
    SVGInject(elem);
}

// Manual SVG Injection
window.addEventListener('injectSVG', function(e){
    manualSVGInject(e.detail)
});