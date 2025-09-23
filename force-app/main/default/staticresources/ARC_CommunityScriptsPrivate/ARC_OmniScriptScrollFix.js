var $ = jQuery.noConflict();

function checkActiveChartItem() {
    let active;
    Array.from($(".themeLayoutStarterWrapper").find(".nds-progress__item")).forEach((chartElement, index) => {
        if ($(chartElement).attr('class').includes("nds-is-active")) active = index;
    });
    return active;
}

function scrollToTop() {
    window.scrollTo({
        left: 0,
        top: 0,
        behavior: 'smooth'
    });
}

$(window).on('load', function () {
    let currentChartItemActive;
    // While pressing the mouse click
    $(document).on('mousedown', '.themeLayoutStarterWrapper', function () {
        // get and save the current active step chart item
        currentChartItemActive = checkActiveChartItem();
    });
    // When releasing the mouse click
    $(document).on('click', '.themeLayoutStarterWrapper', function () {
        setTimeout(() => {
            // Check if spinner is active, if it is, ignore everything and just scroll to top at once
            if ($(".themeLayoutStarterWrapper").find(".nds-spinner_brand").length > 0) return scrollToTop();
            // If not, compare with the new active chart item, if it differs, scroll
            else if (currentChartItemActive !== checkActiveChartItem()) scrollToTop();
        }, 10);
    });
});