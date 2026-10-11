import Foundation
import Combine
import CoreLocation

struct WeatherForecast: Decodable {
    let timezone: String
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
}

struct CurrentWeather: Decodable {
    let time: String
    let temperature2m: Double
    let relativeHumidity2m: Int
    let apparentTemperature: Double
    let isDay: Int
    let precipitation: Double
    let weatherCode: Int
    let windSpeed10m: Double
    let windDirection10m: Int
    let surfacePressure: Double
}

struct HourlyWeather: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let precipitationProbability: [Int]
    let weatherCode: [Int]
}

struct DailyWeather: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double]
    let precipitationProbabilityMax: [Int]
}

struct WeatherPlace: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let country: String?
    let admin1: String?
    let latitude: Double
    let longitude: Double

    var subtitle: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static func == (lhs: WeatherPlace, rhs: WeatherPlace) -> Bool { lhs.id == rhs.id }
}

private struct PlacesResponse: Decodable {
    let results: [WeatherPlace]?
}

enum WeatherAppearance {
    static func symbol(for code: Int, day: Bool = true) -> String {
        switch code {
        case 0: return day ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return day ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }

    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mostly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Misty and foggy"
        case 51...57: return "Light drizzle"
        case 61, 80: return "Light rain"
        case 63, 81: return "Rain showers"
        case 65, 67, 82: return "Heavy rain"
        case 71...77, 85, 86: return "Snowfall"
        case 95...99: return "Thunderstorms"
        default: return "Changing skies"
        }
    }
}

enum WeatherAPI {
    static func search(_ query: String) async throws -> [WeatherPlace] {
        var c = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        c.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        let (data, response) = try await URLSession.shared.data(from: c.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(PlacesResponse.self, from: data).results ?? []
    }

    static func forecast(lat: Double, lon: Double) async throws -> WeatherForecast {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        let (data, response) = try await URLSession.shared.data(from: c.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WeatherForecast.self, from: data)
    }
}

@MainActor
final class WeatherStore: ObservableObject {
    @Published var city = "Abu Dhabi"
    @Published var country = "United Arab Emirates"
    @Published var data: WeatherForecast?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var updatedAt: Date?
    private let locator = DeviceLocation()

    init() {
        let savedCity = UserDefaults.standard.string(forKey: "weather.city") ?? "Abu Dhabi"
        let savedCountry = UserDefaults.standard.string(forKey: "weather.country") ?? "United Arab Emirates"
        let latitude = UserDefaults.standard.object(forKey: "weather.lat") as? Double ?? 24.4539
        let longitude = UserDefaults.standard.object(forKey: "weather.lon") as? Double ?? 54.3773
        city = savedCity
        country = savedCountry
        locator.didLocate = { [weak self] lat, lon in
            Task { @MainActor in await self?.useCurrentPosition(lat: lat, lon: lon) }
        }
        locator.didFail = { [weak self] message in
            Task { @MainActor in self?.errorMessage = message }
        }
        Task { await refresh(lat: latitude, lon: longitude) }
    }

    func select(_ place: WeatherPlace) async {
        city = place.name
        country = place.country ?? ""
        save(lat: place.latitude, lon: place.longitude)
        await refresh(lat: place.latitude, lon: place.longitude)
    }

    func refresh() async {
        let lat = UserDefaults.standard.object(forKey: "weather.lat") as? Double ?? 24.4539
        let lon = UserDefaults.standard.object(forKey: "weather.lon") as? Double ?? 54.3773
        await refresh(lat: lat, lon: lon)
    }

    func requestCurrentLocation() {
        locator.request()
    }

    private func useCurrentPosition(lat: Double, lon: Double) async {
        let location = CLLocation(latitude: lat, longitude: lon)
        if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first {
            city = placemark.locality ?? placemark.subAdministrativeArea ?? "My location"
            country = placemark.country ?? ""
        } else {
            city = "My location"
            country = ""
        }
        save(lat: lat, lon: lon)
        await refresh(lat: lat, lon: lon)
    }

    private func save(lat: Double, lon: Double) {
        UserDefaults.standard.set(city, forKey: "weather.city")
        UserDefaults.standard.set(country, forKey: "weather.country")
        UserDefaults.standard.set(lat, forKey: "weather.lat")
        UserDefaults.standard.set(lon, forKey: "weather.lon")
    }

    private func refresh(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        do {
            data = try await WeatherAPI.forecast(lat: lat, lon: lon)
            updatedAt = Date()
        } catch {
            errorMessage = "Could not update the forecast. Check your connection and try again."
        }
        isLoading = false
    }
}

final class DeviceLocation: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var didLocate: ((Double, Double) -> Void)?
    var didFail: ((String) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            didFail?("Location access is disabled. Enable it in iPhone Settings, or search for a city.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let point = locations.last else { return }
        didLocate?(point.coordinate.latitude, point.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFail?("Unable to find your location. Try searching for a city.")
    }
}
