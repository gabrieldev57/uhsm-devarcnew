window.addEventListener('getCookies', function (event) {
    event.detail.value = document.cookie;  // Get all cookies
    return event;
});