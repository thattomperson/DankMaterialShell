pragma Singleton

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property int refCount: 0

    property var weather: ({
                               "available": false,
                               "loading": true,
                               "temp": 0,
                               "tempF": 0,
                               "city": "",
                               "country": "",
                               "wCode": 0,
                               "humidity": 0,
                               "wind": "",
                               "sunrise": "06:00",
                               "sunset": "18:00",
                               "uv": 0,
                               "pressure": 0,
                               "precipitationProbability": 0,
                               "isDay": true
                           })

    property var location: null
    property int updateInterval: 300000 // 5 minutes
    property int retryAttempts: 0
    property int maxRetryAttempts: 3
    property int retryDelay: 30000
    property int lastFetchTime: 0
    property int minFetchInterval: 30000
    property int persistentRetryCount: 0

    property var weatherIcons: ({
                                    "0": "clear_day",
                                    "1": "clear_day",
                                    "2": "partly_cloudy_day",
                                    "3": "cloud",
                                    "45": "foggy",
                                    "48": "foggy",
                                    "51": "rainy",
                                    "53": "rainy",
                                    "55": "rainy",
                                    "56": "rainy",
                                    "57": "rainy",
                                    "61": "rainy",
                                    "63": "rainy",
                                    "65": "rainy",
                                    "66": "rainy",
                                    "67": "rainy",
                                    "71": "cloudy_snowing",
                                    "73": "cloudy_snowing",
                                    "75": "snowing_heavy",
                                    "77": "cloudy_snowing",
                                    "80": "rainy",
                                    "81": "rainy",
                                    "82": "rainy",
                                    "85": "cloudy_snowing",
                                    "86": "snowing_heavy",
                                    "95": "thunderstorm",
                                    "96": "thunderstorm",
                                    "99": "thunderstorm"
                                })
    
    property var nightWeatherIcons: ({
                                        "0": "clear_night",
                                        "1": "clear_night",
                                        "2": "partly_cloudy_night",
                                        "3": "cloud",
                                        "45": "foggy",
                                        "48": "foggy",
                                        "51": "rainy",
                                        "53": "rainy",
                                        "55": "rainy",
                                        "56": "rainy",
                                        "57": "rainy",
                                        "61": "rainy",
                                        "63": "rainy",
                                        "65": "rainy",
                                        "66": "rainy",
                                        "67": "rainy",
                                        "71": "cloudy_snowing",
                                        "73": "cloudy_snowing",
                                        "75": "snowing_heavy",
                                        "77": "cloudy_snowing",
                                        "80": "rainy",
                                        "81": "rainy",
                                        "82": "rainy",
                                        "85": "cloudy_snowing",
                                        "86": "snowing_heavy",
                                        "95": "thunderstorm",
                                        "96": "thunderstorm",
                                        "99": "thunderstorm"
                                    })

    function getWeatherIcon(code, isDay) {
        if (typeof isDay === "undefined") {
            isDay = weather.isDay
        }
        const iconMap = isDay ? weatherIcons : nightWeatherIcons
        return iconMap[String(code)] || "cloud"
    }
    
    function formatTime(isoString) {
        if (!isoString) return "--"
        
        try {
            const date = new Date(isoString)
            const format = SettingsData.use24HourClock ? "HH:mm" : "h:mm AP"
            return date.toLocaleTimeString(Qt.locale(), format)
        } catch (e) {
            return "--"
        }
    }

    function getWeatherApiUrl() {
        if (!location) {
            return null
        }
        
        const params = [
            "latitude=" + location.latitude,
            "longitude=" + location.longitude,
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m",
            "daily=sunrise,sunset",
            "timezone=auto",
            "forecast_days=1"
        ]
        
        if (SettingsData.useFahrenheit) {
            params.push("temperature_unit=fahrenheit")
        }
        
        return "https://api.open-meteo.com/v1/forecast?" + params.join('&')
    }
    
    function getGeocodingUrl(query) {
        return "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=1&language=en&format=json"
    }

    function addRef() {
        refCount++

        if (refCount === 1 && !weather.available && SettingsData.weatherEnabled) {
            fetchWeather()
        }
    }

    function removeRef() {
        refCount = Math.max(0, refCount - 1)
    }

    function updateLocation() {
        if (SettingsData.useAutoLocation) {
            getLocationFromIP()
        } else {
            const coords = SettingsData.weatherCoordinates
            if (coords) {
                const parts = coords.split(",")
                if (parts.length === 2) {
                    const lat = parseFloat(parts[0])
                    const lon = parseFloat(parts[1])
                    if (!isNaN(lat) && !isNaN(lon)) {
                        getLocationFromCoords(lat, lon)
                        return
                    }
                }
            }
            
            const cityName = SettingsData.weatherLocation
            if (cityName) {
                getLocationFromCity(cityName)
            }
        }
    }
    
    function getLocationFromCoords(lat, lon) {
        reverseGeocodeFetcher.command = ["bash", "-c", "curl -s --connect-timeout 10 --max-time 30 'https://nominatim.openstreetmap.org/reverse?lat=" + lat + "&lon=" + lon + "&format=json&addressdetails=1&accept-language=en' -H 'User-Agent: DankMaterialShell Weather Widget'"]
        reverseGeocodeFetcher.running = true
    }
    
    function getLocationFromCity(city) {
        cityGeocodeFetcher.command = ["bash", "-c", "curl -s --connect-timeout 10 --max-time 30 '" + getGeocodingUrl(city) + "'"]
        cityGeocodeFetcher.running = true
    }
    
    function getLocationFromIP() {
        ipLocationFetcher.running = true
    }

    function fetchWeather() {
        if (root.refCount === 0 || !SettingsData.weatherEnabled) {
            return
        }

        if (!location) {
            updateLocation()
            return
        }

        if (weatherFetcher.running) {
            console.log("Weather fetch already in progress, skipping")
            return
        }

        const now = Date.now()
        if (now - root.lastFetchTime < root.minFetchInterval) {
            console.log("Weather fetch throttled, too soon since last fetch")
            return
        }

        const apiUrl = getWeatherApiUrl()
        if (!apiUrl) {
            console.warn("Cannot fetch weather: no location available")
            return
        }

        console.log("Fetching weather from:", apiUrl)
        root.lastFetchTime = now
        root.weather.loading = true
        weatherFetcher.command = ["bash", "-c", "curl -s --connect-timeout 10 --max-time 30 '" + apiUrl + "'"]
        weatherFetcher.running = true
    }

    function forceRefresh() {
        console.log("Force refreshing weather")
        root.lastFetchTime = 0 // Reset throttle
        fetchWeather()
    }

    function handleWeatherSuccess() {
        root.retryAttempts = 0
        root.persistentRetryCount = 0
        if (persistentRetryTimer.running) {
            persistentRetryTimer.stop()
        }
        if (updateTimer.interval !== root.updateInterval) {
            updateTimer.interval = root.updateInterval
        }
    }

    function handleWeatherFailure() {
        root.retryAttempts++
        if (root.retryAttempts < root.maxRetryAttempts) {
            console.log("Weather fetch failed, retrying in " + (root.retryDelay / 1000) + "s (attempt " + root.retryAttempts + "/" + root.maxRetryAttempts + ")")
            retryTimer.start()
        } else {
            console.warn("Weather fetch failed after maximum retry attempts, will keep trying...")
            root.weather.available = false
            root.weather.loading = false
            root.retryAttempts = 0
            const backoffDelay = Math.min(60000 * Math.pow(2, persistentRetryCount), 300000)
            persistentRetryCount++
            console.log("Scheduling persistent retry in " + (backoffDelay / 1000) + "s")
            persistentRetryTimer.interval = backoffDelay
            persistentRetryTimer.start()
        }
    }

    Process {
        id: ipLocationFetcher
        command: ["curl", "-s", "--connect-timeout", "5", "--max-time", "10", "http://ipinfo.io/json"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "{") {
                    console.warn("No valid IP location data received")
                    root.handleWeatherFailure()
                    return
                }

                try {
                    const data = JSON.parse(raw)
                    const coords = data.loc
                    const city = data.city
                    
                    if (!coords || !city) {
                        throw new Error("Missing location data")
                    }
                    
                    const coordsParts = coords.split(",")
                    if (coordsParts.length !== 2) {
                        throw new Error("Invalid coordinates format")
                    }
                    
                    const lat = parseFloat(coordsParts[0])
                    const lon = parseFloat(coordsParts[1])
                    
                    if (isNaN(lat) || isNaN(lon)) {
                        throw new Error("Invalid coordinate values")
                    }
                    
                    console.log("Got IP-based location:", lat, lon, "at", city)
                    root.location = {
                        city: city,
                        latitude: lat,
                        longitude: lon
                    }
                    fetchWeather()
                } catch (e) {
                    console.warn("Failed to parse IP location data:", e.message)
                    root.handleWeatherFailure()
                }
            }
        }
        
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("IP location fetch failed with exit code:", exitCode)
                root.handleWeatherFailure()
            }
        }
    }
    
    Process {
        id: reverseGeocodeFetcher
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "{") {
                    console.warn("No valid reverse geocode data received")
                    root.handleWeatherFailure()
                    return
                }

                try {
                    const data = JSON.parse(raw)
                    const address = data.address || {}
                    
                    root.location = {
                        city: address.hamlet || address.city || address.town || address.village || "Unknown",
                        country: address.country || "Unknown",
                        latitude: parseFloat(data.lat),
                        longitude: parseFloat(data.lon)
                    }
                    
                    console.log("Location updated:", root.location.city, root.location.country)
                    fetchWeather()
                } catch (e) {
                    console.warn("Failed to parse reverse geocode data:", e.message)
                    root.handleWeatherFailure()
                }
            }
        }
        
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Reverse geocode failed with exit code:", exitCode)
                root.handleWeatherFailure()
            }
        }
    }
    
    Process {
        id: cityGeocodeFetcher
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "{") {
                    console.warn("No valid geocode data received")
                    root.handleWeatherFailure()
                    return
                }

                try {
                    const data = JSON.parse(raw)
                    const results = data.results
                    
                    if (!results || results.length === 0) {
                        throw new Error("No results found")
                    }
                    
                    const result = results[0]
                    
                    root.location = {
                        city: result.name,
                        country: result.country,
                        latitude: result.latitude,
                        longitude: result.longitude
                    }
                    
                    console.log("Location updated:", root.location.city, root.location.country)
                    fetchWeather()
                } catch (e) {
                    console.warn("Failed to parse geocode data:", e.message)
                    root.handleWeatherFailure()
                }
            }
        }
        
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("City geocode failed with exit code:", exitCode)
                root.handleWeatherFailure()
            }
        }
    }

    Process {
        id: weatherFetcher
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw || raw[0] !== "{") {
                    console.warn("No valid weather data received")
                    root.handleWeatherFailure()
                    return
                }

                try {
                    const data = JSON.parse(raw)
                    
                    if (!data.current || !data.daily) {
                        throw new Error("Required weather data fields missing")
                    }

                    const current = data.current
                    const daily = data.daily
                    const currentUnits = data.current_units || {}
                    
                    const tempC = current.temperature_2m || 0
                    const tempF = SettingsData.useFahrenheit ? tempC : (tempC * 9/5 + 32)
                    
                    root.weather = {
                        "available": true,
                        "loading": false,
                        "temp": Math.round(tempC),
                        "tempF": Math.round(tempF),
                        "city": root.location?.city || "Unknown",
                        "country": root.location?.country || "Unknown",
                        "wCode": current.weather_code || 0,
                        "humidity": Math.round(current.relative_humidity_2m || 0),
                        "wind": Math.round(current.wind_speed_10m || 0) + " " + (currentUnits.wind_speed_10m || 'm/s'),
                        "sunrise": formatTime(daily.sunrise?.[0]) || "06:00",
                        "sunset": formatTime(daily.sunset?.[0]) || "18:00",
                        "uv": 0,
                        "pressure": Math.round(current.surface_pressure || 0),
                        "precipitationProbability": Math.round(current.precipitation || 0),
                        "isDay": Boolean(current.is_day)
                    }

                    const displayTemp = SettingsData.useFahrenheit ? root.weather.tempF : root.weather.temp
                    const unit = SettingsData.useFahrenheit ? "°F" : "°C"
                    console.log("Weather updated:", root.weather.city, displayTemp + unit)

                    root.handleWeatherSuccess()
                } catch (e) {
                    console.warn("Failed to parse weather data:", e.message)
                    root.handleWeatherFailure()
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Weather fetch failed with exit code:", exitCode)
                root.handleWeatherFailure()
            }
        }
    }

    Timer {
        id: updateTimer
        interval: root.updateInterval
        running: root.refCount > 0 && SettingsData.weatherEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.fetchWeather()
        }
    }

    Timer {
        id: retryTimer
        interval: root.retryDelay
        running: false
        repeat: false
        onTriggered: {
            root.fetchWeather()
        }
    }

    Timer {
        id: persistentRetryTimer
        interval: 60000
        running: false
        repeat: false
        onTriggered: {
            console.log("Persistent retry attempt...")
            root.fetchWeather()
        }
    }

    Component.onCompleted: {
        
        SettingsData.weatherCoordinatesChanged.connect(() => {
                                                           console.log("Weather coordinates changed, refreshing location")
                                                           root.location = null
                                                           root.weather = {
                                                               "available": false,
                                                               "loading": true,
                                                               "temp": 0,
                                                               "tempF": 0,
                                                               "city": "",
                                                               "country": "",
                                                               "wCode": 0,
                                                               "humidity": 0,
                                                               "wind": "",
                                                               "sunrise": "06:00",
                                                               "sunset": "18:00",
                                                               "uv": 0,
                                                               "pressure": 0,
                                                               "precipitationProbability": 0,
                                                               "isDay": true
                                                           }
                                                           root.lastFetchTime = 0
                                                           root.forceRefresh()
                                                       })

        SettingsData.weatherLocationChanged.connect(() => {
                                                        console.log("Weather location display name changed, refreshing location")
                                                        root.location = null
                                                        root.lastFetchTime = 0
                                                        root.forceRefresh()
                                                    })

        SettingsData.useAutoLocationChanged.connect(() => {
                                                        console.log("Auto location setting changed, refreshing location")
                                                        root.location = null
                                                        root.weather = {
                                                            "available": false,
                                                            "loading": true,
                                                            "temp": 0,
                                                            "tempF": 0,
                                                            "city": "",
                                                            "country": "",
                                                            "wCode": 0,
                                                            "humidity": 0,
                                                            "wind": "",
                                                            "sunrise": "06:00",
                                                            "sunset": "18:00",
                                                            "uv": 0,
                                                            "pressure": 0,
                                                            "precipitationProbability": 0,
                                                            "isDay": true
                                                        }
                                                        root.lastFetchTime = 0
                                                        root.forceRefresh()
                                                    })
                                                    
        SettingsData.useFahrenheitChanged.connect(() => {
                                                       console.log("Temperature unit changed, refreshing weather")
                                                       root.lastFetchTime = 0
                                                       root.forceRefresh()
                                                   })

        SettingsData.weatherEnabledChanged.connect(() => {
                                                       console.log("Weather enabled setting changed:", SettingsData.weatherEnabled)
                                                       if (SettingsData.weatherEnabled && root.refCount > 0 && !root.weather.available) {
                                                           root.forceRefresh()
                                                       } else if (!SettingsData.weatherEnabled) {
                                                           updateTimer.stop()
                                                           retryTimer.stop()
                                                           persistentRetryTimer.stop()
                                                           if (weatherFetcher.running) {
                                                               weatherFetcher.running = false
                                                           }
                                                       }
                                                   })
    }
}
