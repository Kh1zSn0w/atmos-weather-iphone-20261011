# Atmos Weather
A standalone native iPhone weather application using SwiftUI and the Open-Meteo API.

Features: live local weather, city search, GPS weather, Celsius/Fahrenheit, next 18 hours, 7-day forecast, wind, humidity, UV, pressure, sunrise and sunset, and pull-to-refresh.

Build: `xcodegen generate --spec project.yml` then `xcodebuild -project WeatherGlass.xcodeproj -scheme WeatherGlass -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`.

IPA created by GitHub Actions is unsigned and intended for signing with Sideloadly. No private credentials or proprietary binaries are stored in this repository.

Weather information by Open-Meteo. Data attribution: https://open-meteo.com/
