var $ = jQuery.noConflict();

// This JS adds classes to the .ui-widget elements on the body of a community page.
// .ui-widget elements are siblings containing LWC and other components inside
// so we add the component tag to the .ui-widget element, so we can identify siblings
// like a hero + hero + hero for example, and add custom CSS for those special situations

// It also adds styles to some components for example max-width related to topbar max-width,
// which by default isn't stored in any variable so it can't be used for custom LWCs


window.addEventListener('themeChange', function(e){
    window.localStorage.setItem('theme', e.detail);
});

// Scrolling to a document position, used in Hero Component
window.addEventListener('scrollTo', function(e){
    let scroll;
    if(e.detail.endOfElement){
        scroll = $(e.detail.endOfElement).offset().top + $(e.detail.endOfElement).height();
    }else{
        scroll = e.detail
    }
    window.scrollTo({
        left: 0,
        top: scroll,
        behavior: 'smooth'});
});

function checkDarkTheme(){
    let body = $($("body")[0]);
    let topbarMaxWidth = $(".themeHeaderInner")[0].style.width;

    let currentTheme = localStorage.getItem('theme');
    if(currentTheme === "dark") body.addClass("arc-theme-dark");
    
    let themeChanger = $(".themeLayoutStarterWrapper").find(".arc-community-theme-change");
    if(themeChanger.length > 0) {
        themeChanger[0].style.width = topbarMaxWidth+40;
        let lwcThemeDataFind = setInterval(() => {
            let lwcThemeData = $($(themeChanger[0]).children()[0]).data("theme");

            if(lwcThemeData){
                clearInterval(lwcThemeDataFind);
                // In case this user is assigned a different theme than the one loaded from localStorage, refresh LocalStorage theme and remove the dark class
                if(currentTheme === "dark" && lwcThemeData && lwcThemeData !== "dark"){
                    window.localStorage.setItem('theme', "light");
                    body.removeClass("arc-theme-dark");
                }else if(currentTheme !== "dark" && lwcThemeData && lwcThemeData === "dark"){
                    window.localStorage.setItem('theme', "dark");
                    body.addClass("arc-theme-dark");
                }
            }
        }, 500);
    }
}

function setProfileInitialsMaxWidth(){
    let topbarMaxWidth = $(".themeHeaderInner")[0].style.width;
    let profileInitials = $(".themeLayoutStarterWrapper").find(".user-profile-initials");
    if(profileInitials.length > 0) profileInitials[0].style.width = topbarMaxWidth+40;
}

function processUiWidgets(uiWidgets){
    uiWidgets.forEach(function(el){
        let child = $(el).children()[0];
        if($(child).hasClass("actualNode")){
            child = $(child).children()[0];
            $(el).addClass(child.tagName);
        }else $(el).addClass(child.tagName);
    })
}


// Weather API used for Banner Demo
function setWeather(){
    let interval = setInterval(() => {
        let climate = Array.from($(".arc-climate"));
        if(climate.length > 0){
            clearInterval(interval);
            try{
                fetch('http://api.openweathermap.org/data/2.5/weather?q=Aruba&appid=d3a6cb99996120928bef01a63e791883')
                    .then(response => response.json())
                    .then(data => {
                        climate.forEach(function(el){
                            $(el).find(".arc-climate-temperature").text(Math.round(data.main.temp-273.15)+"°");
                            $(el).find(".arc-climate-description").text(data.weather[0].description);
                        })
                    });
            }catch(err){
                console.error(err)
            }
        }
    }, 1000);
}

// Detect Flexible Sections for backgrounds
function processSections(sections){
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

function utilityHandler(){
    // Theme loader from localStorage
    let body = $($("body")[0]);

    let currentTheme = localStorage.getItem('theme');
    if(currentTheme === "dark") body.addClass("arc-theme-dark");

    let uiWIdgetRunTimes = 2;
    let uiWidgetInterval = setInterval(() => {
        let uiWidgets = Array.from($(".ui-widget"));
        if(uiWidgets.length > 0 && uiWIdgetRunTimes > 0){
            uiWIdgetRunTimes--;
            if($(".siteforceDesignTimeSection").length < 1 && uiWIdgetRunTimes === 0) clearInterval(uiWidgetInterval);
            checkDarkTheme();
            setProfileInitialsMaxWidth();
            processUiWidgets(uiWidgets);
            setWeather();
        }
    }, 1000);
    let sectionInterval = setInterval(() => {
        let sections = Array.from($(".cb-section"));
        if(sections.length > 0){
            if($(".siteforceDesignTimeSection").length < 1) clearInterval(sectionInterval)
            processSections(sections);
        }
    }, 1000);
}

window.addEventListener('pageChange', function(){
    utilityHandler()
});
$(function() {
    utilityHandler();
});