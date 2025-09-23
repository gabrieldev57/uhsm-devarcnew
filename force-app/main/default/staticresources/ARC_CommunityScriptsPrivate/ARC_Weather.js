var $ = jQuery.noConflict();

function identifyWeatherClass(){
    let interval = setInterval(() => {
        let climate = Array.from($(".arc-climate"));
        if(climate.length > 0){
            clearInterval(interval);
            fetch('http://api.openweathermap.org/data/2.5/weather?q=Aruba&appid=d3a6cb99996120928bef01a63e791883')
                .then(response => response.json())
                .then(data => {
                    climate.forEach(function(el){
                        $(el).find(".arc-climate-temperature").text(Math.round(data.main.temp-273.15)+"°");
                        $(el).find(".arc-climate-description").text(data.weather[0].description);
                    })
                });
        }
    }, 1000);
}

$(window).on('load', function(){
    identifyWeatherClass();
});