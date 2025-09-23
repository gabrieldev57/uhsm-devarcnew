var $ = jQuery.noConflict();

function findFixedTopbar(){
    // set interval to find topbar
    let interval = setInterval(() => {
        let header = $(".header");
        if(header.length > 0){
            let bg = $($(header).find(".themeBgImage"))
            clearInterval(interval);
            // if header has position: fixed, then apply the added functionality
            if($(header).css('position') == 'fixed'){
                let replaceColor;
                // add arc class to show and hide the topbar
                $(header).addClass("arc-showhide-topbar");
                // if the topbar doesn't have a background, then the page background color
                // will be applied after a certain amount of scrolling down
                if($(bg).css('background-color').endsWith(",0)") || $(bg).css('background-color').endsWith(", 0)")) replaceColor = true;
                // Logic for showing / Hiding the topbar on scroll
                var prevScrollpos = window.pageYOffset;
                var lockedScrollpos = window.pageYOffset;
                window.onscroll = function() {
                    var currentScrollPos = window.pageYOffset;
                    if (currentScrollPos < lockedScrollpos - 100 || currentScrollPos < 160) {
                        $(header).removeClass("arc-showhide-topbar-hide");
                    }
                    else $(header).addClass("arc-showhide-topbar-hide");
                    if(replaceColor) {
                        if(200 < currentScrollPos) $(header).addClass("arc-showhide-topbar-replacecolors");
                        else $(header).removeClass("arc-showhide-topbar-replacecolors");
                    }
                    if(prevScrollpos < currentScrollPos) lockedScrollpos = currentScrollPos;
                    prevScrollpos = currentScrollPos;
                }
                ///////////////////////////////////////////////////
            }
        }
    }, 1000);
}
window.addEventListener('pageChange', function(){
    findFixedTopbar();
});
$(function() {
    findFixedTopbar();
});