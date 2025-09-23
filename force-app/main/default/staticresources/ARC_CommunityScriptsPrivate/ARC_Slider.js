
var $ = jQuery.noConflict();

function getSliderElements(){
    return $(".siteforceContentArea").find(".arc-slider").not(".swiper-initialized");
}

function handler(){
    let retryIntervalTimeCurrent = 0;
    // Create an interval which checks for .parallax elements on page load
    let sliderInterval = setInterval(() => {
        // Interval tries until 10 seconds pass (For 3G times for loading the page)
        if(retryIntervalTimeCurrent > 14000) return clearInterval(sliderInterval);
        elems = getSliderElements();
        // If there are parallax elements, add the parallax to the first element (at the top)
        if(elems.length > 0){
            clearInterval(sliderInterval);
            for(let i = 0; i < elems.length; i++) {
                let loop = $(elems[i]).data("loop");
                let autoplay = $(elems[i]).data("autoplay");
                let slidesPerViewS = $(elems[i]).data("slides-per-view-s");
                let slidesPerViewM = $(elems[i]).data("slides-per-view-m");
                let slidesPerViewL = $(elems[i]).data("slides-per-view-l");
                new Swiper(elems[i], {
                    loop: loop ? true : false,
                    autoplay: autoplay ? {delay: 6000} : false,
                    navigation: {
                        nextEl: $(elems[i]).find(".swiper-button-next")[0],
                        prevEl: $(elems[i]).find(".swiper-button-prev")[0],
                    },
                    scrollbar: {
                        el: $(elems[i]).find(".swiper-scrollbar")[0],
                        hide: true,
                    },
                    pagination: {
                        el: $(elems[i]).find(".swiper-pagination")[0],
                        clickable: true,
                    },
                    breakpoints: {
                        320: {
                            slidesPerView: slidesPerViewS ? slidesPerViewS : 1,
                            centeredSlides: slidesPerViewS !== "auto" ? false : true,
                            spaceBetween: 20,
                        },
                        768: {
                            slidesPerView: slidesPerViewM ? slidesPerViewM : "auto",
                            centeredSlides: slidesPerViewM !== "auto" ? false : true,
                            spaceBetween: 20,
                        },
                        1280: {
                            slidesPerView: slidesPerViewL ? slidesPerViewL : "auto",
                            centeredSlides: slidesPerViewL !== "auto" ? false : true,
                            spaceBetween: 20,
                        },
                    },
                })
            }
        }
        retryIntervalTimeCurrent = retryIntervalTimeCurrent + 500;
    }, 500)
};


// jQuery
$(function() {
    handler();
});