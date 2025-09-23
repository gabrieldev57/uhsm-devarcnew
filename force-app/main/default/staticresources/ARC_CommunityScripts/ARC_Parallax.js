
var $ = jQuery.noConflict();

function getParallaxElements(){
    return $(".siteforceContentArea").find(".parallax");
}

function handler(){
    let retryIntervalTimeCurrent = 0;
    // Create an interval which checks for .parallax elements on page load
    let parallaxInterval = setInterval(() => {
        // Interval tries until 10 seconds pass (For 3G times for loading the page)
        if(retryIntervalTimeCurrent > 14000) return clearInterval(parallaxInterval);
        elems = getParallaxElements();
        // If there are parallax elements, add the parallax to the first element (at the top)
        if(elems.length > 0){
            clearInterval(parallaxInterval)
            for(let i = 0; i < elems.length; i++) {
                let rellax = Rellax(elems[i], {
                    speed: -10,
                    center: true
                });
                setTimeout(() => {
                    rellax.refresh();
                }, 3000);
            }
        }
        retryIntervalTimeCurrent = retryIntervalTimeCurrent + 500;
    }, 500)
};


// jQuery
$(window).on('load', handler);
window.addEventListener('pageChange', function(){
    handler()
});
window.addEventListener('popstate', function(){
    handler()
});