var $ = jQuery.noConflict();

// This JS adds classes to the .ui-widget elements on the body of a community page.
// .ui-widget elements are siblings containing LWC and other components inside
// so we add the component tag to the .ui-widget element, so we can identify siblings
// like a hero + hero + hero for example, and add custom CSS for those special situations

// It also adds styles to some components for example max-width related to topbar max-width,
// which by default isn't stored in any variable so it can't be used for custom LWCs

function identifyComponents(){
    console.log(localStorage.getItem('theme'))
    // Detect current theme on page load from localStorage
    let body = $($("body")[0]);
    let currentTheme = localStorage.getItem('theme');
    if(currentTheme === "dark"){
        console.log("adding dark class")
        body.addClass("arc-theme-dark");
    }
    // console.log("Component Identifier Working. Run for your life")
    let builderInterval = setInterval(() => {
        let uiWidgets = Array.from($(".ui-widget"));
        if(uiWidgets.length > 0){

            let topbarMaxWidth = $(".themeHeaderInner")[0].style.width

            let themeChanger = $(".themeLayoutStarterWrapper").find(".arc-community-theme-change");
            if(themeChanger.length > 0) {
                // console.log("Theme Changer Detected")
                themeChanger[0].style.width = topbarMaxWidth+40;
                // In case this user is assigned a different theme than the one loaded from localStorage, refresh LocalStorage theme and remove the dark class
                if(currentTheme === "dark" && $($(themeChanger[0]).children()[0]).data("theme") !== "dark"){
                    window.localStorage.setItem('theme', "light");
                    body.removeClass("arc-theme-dark");
                }else if(currentTheme !== "dark" && $($(themeChanger[0]).children()[0]).data("theme") === "dark"){
                    window.localStorage.setItem('theme', "dark");
                    body.addClass("arc-theme-dark");
                }
            }

            let profileInitials = $(".themeLayoutStarterWrapper").find(".user-profile-initials");
            if(profileInitials.length > 0) profileInitials[0].style.width = topbarMaxWidth+40;
        }
        uiWidgets.forEach(function(el){
            let child = $(el).children()[0];
            if($(child).hasClass("actualNode")){
                child = $(child).children()[0];
                $(el).addClass(child.tagName);
            }else{
                $(el).addClass(child.tagName);
                clearInterval(builderInterval);
            }
        })
    }, 1000);
}

function identifyFlexibleSections(){
    let builderInterval = setInterval(() => {
        let sections = Array.from($(".cb-section"));
        if(sections.length > 0){
            if($(".siteforceDesignTimeSection").length < 1) clearInterval(builderInterval)
            sections.forEach(function(el){
                let isTransparent = false;
                let bg = $($(el).find('.cb-section_background'));
                let bgBackgroundColor = /\(([^)]+)\)/.exec(bg.css("background"))[1];
                bgBackgroundColor = bgBackgroundColor.split(",");
                if(bgBackgroundColor.length === 4){
                    if(parseFloat(bgBackgroundColor[3]) === 0) isTransparent = true;
                }
                if(!isTransparent){
                    $(el).addClass("arc-section-colored");
                }
            })
        }
    }, 1000);
}

// Theme change event, save theme to localStorage for styles to change quickly on page load
window.addEventListener('themeChange', function(e){
    window.localStorage.setItem('theme', e.detail);
});

window.addEventListener('pageChange', function(){
    console.log("RUNNING COMPONENT IDENTIFIER");
    identifyComponents();
    identifyFlexibleSections();
});
$(window).on('load', function(){
    console.log("RUNNING COMPONENT IDENTIFIER");
    identifyComponents();
    identifyFlexibleSections();
});