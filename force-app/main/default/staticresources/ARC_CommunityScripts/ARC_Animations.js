var $ = jQuery.noConflict();

// Get elements to animate which hasn't been animated yet
function getAnimatedElements(){
    return $(".siteforceContentArea").find('[class*="arc-scrollanim"]').not('.arc-scrollanim-in');
}

// Check if the element is in viewport
function isScrolledIntoView(elem){
    var docViewTop = $(window).scrollTop();
    let viewHeight = $(window).height();
    
    var elemTop = $(elem).offset().top + ($(elem).height()/2 > 300 ? 300 : $(elem).height()/2) - viewHeight/1.5;

    return (docViewTop >= elemTop);
}

function handler(){
    // Get elements that should be animated on scroll
    let elems = getAnimatedElements();
    // Important - Activate this line if you want animations to run all at once
    //              on the Experience Builder
    // if($(".siteforceDesignTimeComponent").length > 0) return fadeAll(elems);
    for(let i = 0; i < elems.length; i++) {
        // For each element, check if it has reached the viewport
        if(isScrolledIntoView(elems[i])) {
            $(elems[i]).addClass("arc-scrollanim-in");
            // If the element is a rising number, activate the JS to animate it
            if($(elems[i]).hasClass("arc-scrollanim-risingnumber")){
                $(elems[i]).countTo();
            }
        }
    }
};


// jQuery
$(window).on('load resize scroll', handler);
window.addEventListener('pageChange', function(){
    handler()
});
window.addEventListener('popstate', function(){
    handler()
});