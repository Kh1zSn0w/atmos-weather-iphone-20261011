import SwiftUI

private enum Theme {
    static let base = Color(red: 0.035, green: 0.055, blue: 0.095)
    static let card = Color(red: 0.085, green: 0.115, blue: 0.17)
    static let muted = Color(red: 0.62, green: 0.68, blue: 0.77)
    static let accent = Color(red: 0.49, green: 0.83, blue: 1.00)
}

struct WeatherHomeView: View {
    @StateObject private var store = WeatherStore()
    @State private var showSearch = false
    @AppStorage("weather.fahrenheit") private var fahrenheit = false

    private func degrees(_ celsius: Double) -> String {
        let value = fahrenheit ? celsius * 9 / 5 + 32 : celsius
        return "\(Int(value.rounded()))°"
    }

    var body: some View {
        ZStack {
            Theme.base.ignoresSafeArea()
            GeometryReader { proxy in
                Circle()
                    .fill(Color(red: 0.11, green: 0.27, blue: 0.43))
                    .frame(width: 370, height: 370)
                    .blur(radius: 125)
                    .position(x: proxy.size.width + 45, y: 100)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar

                    if let weather = store.data {
                        hero(weather)
                        hourlyCard(weather)
                        weeklyCard(weather)
                        metricGrid(weather)
                        footer
                    } else if store.isLoading {
                        loadingView
                    } else {
                        unavailableView
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 44)
            }
            .refreshable { await store.refresh() }
        }
        .sheet(isPresented: $showSearch) {
            CitySearchView(store: store)
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.base)
        }
        .alert("Weather update", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Theme.accent.opacity(0.13))
                        .frame(width: 42, height: 42)
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Theme.accent, .white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("A T M O S")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white)
                    Text("Your weather, beautifully.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer()
            Button {
                fahrenheit.toggle()
            } label: {
                Text(fahrenheit ? "°F" : "°C")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(width: 41, height: 41)
                    .background(Theme.card, in: Circle())
            }
            .accessibilityLabel("Toggle Celsius and Fahrenheit")

            Button { store.requestCurrentLocation() } label: {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 41, height: 41)
                    .background(Theme.card, in: Circle())
            }
            .accessibilityLabel("Use my location")

            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 41, height: 41)
                    .background(Theme.card, in: Circle())
            }
            .accessibilityLabel("Search for a city")
        }
        .foregroundStyle(.white)
    }

    private func hero(_ weather: WeatherForecast) -> some View {
        let current = weather.current
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("CURRENT CONDITIONS", systemImage: "circle.fill")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(Theme.accent)
                        .labelStyle(.titleAndIcon)
                    Text(store.city)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.68)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    Text(store.country.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(degrees(current.temperature2m))
                        .font(.system(size: 92, weight: .thin, design: .rounded))
                        .tracking(-7)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)
                    Text(WeatherAppearance.description(for: current.weatherCode))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
                Spacer(minLength: 0)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.48, green: 0.77, blue: 1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 60)
                        .opacity(0.53)
                    Image(systemName: WeatherAppearance.symbol(for: current.weatherCode, day: current.isDay == 1))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(red: 0.98, green: 0.77, blue: 0.43))
                        .font(.system(size: 91, weight: .ultraLight))
                        .shadow(color: Theme.accent.opacity(0.4), radius: 26)
                }
                .frame(width: 128, height: 145)
            }
            .padding(.top, 25)
            .padding(.bottom, 24)

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)
            HStack {
                Label("Feels like \(degrees(current.apparentTemperature))", systemImage: "thermometer.medium")
                Spacer()
                Text("H: \(degrees(weather.daily.temperature2mMax.first ?? current.temperature2m))")
                Text("L: \(degrees(weather.daily.temperature2mMin.first ?? current.temperature2m))")
                    .foregroundStyle(.white.opacity(0.65))
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.top, 17)
        }
        .padding(25)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    colors: [Color(red: 0.16, green: 0.32, blue: 0.52), Color(red: 0.075, green: 0.15, blue: 0.30), Color(red: 0.075, green: 0.12, blue: 0.23)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
        }
    }

    private func hourlyCard(_ weather: WeatherForecast) -> some View {
        let start = max(0, weather.hourly.time.firstIndex(where: { $0 >= String(weather.current.time.prefix(13)) }) ?? 0)
        let end = min(weather.hourly.time.count, start + 18)
        return VStack(alignment: .leading, spacing: 18) {
            sectionHeader("Next 18 hours", icon: "clock")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(start..<end, id: \.self) { index in
                        VStack(spacing: 13) {
                            Text(index == start ? "Now" : hourLabel(weather.hourly.time[index]))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(index == start ? .white : Theme.muted)
                            Image(systemName: WeatherAppearance.symbol(for: weather.hourly.weatherCode[index], day: isDaytime(weather.hourly.time[index])))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color(red: 1, green: 0.78, blue: 0.46))
                                .font(.system(size: 23))
                                .frame(height: 28)
                            Text(degrees(weather.hourly.temperature2m[index]))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            HStack(spacing: 3) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 9))
                                Text("\(weather.hourly.precipitationProbability[index])%")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Theme.accent)
                        }
                        .frame(minWidth: 44)
                    }
                }
                .padding(.trailing, 15)
            }
        }
        .padding(21)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
    }

    private func weeklyCard(_ weather: WeatherForecast) -> some View {
        let daily = weather.daily
        let count = min(7, daily.time.count)
        let minTemp = daily.temperature2mMin.min() ?? 0
        let maxTemp = daily.temperature2mMax.max() ?? 40
        let spread = max(1, maxTemp - minTemp)
        return VStack(alignment: .leading, spacing: 17) {
            sectionHeader("7-day forecast", icon: "calendar")
            ForEach(0..<count, id: \.self) { i in
                if i > 0 {
                    Rectangle().fill(.white.opacity(0.065)).frame(height: 1)
                }
                HStack(spacing: 11) {
                    Text(dayLabel(daily.time[i], i))
                        .font(.system(size: 13, weight: i == 0 ? .bold : .medium))
                        .frame(width: 52, alignment: .leading)
                    Image(systemName: WeatherAppearance.symbol(for: daily.weatherCode[i]))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color(red: 1, green: 0.78, blue: 0.46))
                        .font(.system(size: 19))
                        .frame(width: 31)
                    HStack(spacing: 3) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 9))
                        Text("\(daily.precipitationProbabilityMax[i])%")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(width: 41)
                    Text(degrees(daily.temperature2mMin[i]))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 34, alignment: .trailing)
                    GeometryReader { geo in
                        let offset = CGFloat((daily.temperature2mMin[i] - minTemp) / spread)
                        let width = CGFloat((daily.temperature2mMax[i] - daily.temperature2mMin[i]) / spread)
                        Capsule().fill(.white.opacity(0.09))
                            .frame(height: 5)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(LinearGradient(colors: [Theme.accent, Color(red: 1, green: 0.78, blue: 0.44)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(5, geo.size.width * width), height: 5)
                                    .offset(x: geo.size.width * offset)
                            }
                            .frame(maxHeight: .infinity)
                    }
                    .frame(height: 15)
                    Text(degrees(daily.temperature2mMax[i]))
                        .foregroundStyle(.white)
                        .frame(width: 34, alignment: .trailing)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            }
        }
        .padding(21)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
    }

    private func metricGrid(_ weather: WeatherForecast) -> some View {
        let c = weather.current
        let d = weather.daily
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metric("UV INDEX", value: String(format: "%.1f", d.uvIndexMax.first ?? 0), detail: "Today's maximum", icon: "sun.max.fill", color: Color(red: 1, green: 0.78, blue: 0.45))
            metric("HUMIDITY", value: "\(c.relativeHumidity2m)%", detail: "Relative humidity", icon: "humidity.fill", color: Theme.accent)
            metric("WIND", value: "\(Int(c.windSpeed10m.rounded()))", detail: "km/h  ·  \(windCompass(c.windDirection10m))", icon: "wind", color: Theme.accent)
            metric("PRESSURE", value: "\(Int(c.surfacePressure.rounded()))", detail: "hPa at surface", icon: "gauge.medium", color: Color(red: 0.77, green: 0.7, blue: 1))
            metric("SUNRISE", value: clockLabel(d.sunrise.first ?? ""), detail: "Local time", icon: "sunrise.fill", color: Color(red: 1, green: 0.76, blue: 0.53))
            metric("SUNSET", value: clockLabel(d.sunset.first ?? ""), detail: "Local time", icon: "sunset.fill", color: Color(red: 1, green: 0.6, blue: 0.50))
        }
    }

    private func metric(_ title: String, value: String, detail: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).foregroundStyle(Theme.muted)
                    .tracking(1.2)
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer(minLength: 19)
            Text(value)
                .font(.system(size: 31, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 117, alignment: .leading)
        .padding(19)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 23))
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).foregroundStyle(Theme.accent)
            Text(title).foregroundStyle(.white)
            Spacer()
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
            if let date = store.updatedAt {
                Text("Updated \(date.formatted(date: .omitted, time: .shortened))")
            }
            Spacer()
            Text("Weather by Open-Meteo")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(Theme.muted)
        .padding(.horizontal, 5)
        .padding(.top, 4)
    }

    private var loadingView: some View {
        VStack(spacing: 22) {
            ProgressView().tint(Theme.accent).scaleEffect(1.5)
            Text("Reading the skies…")
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 35))
                .foregroundStyle(Theme.accent)
            Text("Forecast unavailable").font(.system(size: 23, weight: .semibold))
            Button("Try again") { Task { await store.refresh() } }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }

    private func hourLabel(_ iso: String) -> String {
        let parts = iso.split(separator: "T")
        guard parts.count > 1, let hour = Int(parts[1].prefix(2)) else { return "" }
        if hour == 0 { return "12 AM" }
        if hour == 12 { return "12 PM" }
        return hour > 12 ? "\(hour - 12) PM" : "\(hour) AM"
    }

    private func isDaytime(_ iso: String) -> Bool {
        let parts = iso.split(separator: "T")
        guard parts.count > 1, let hour = Int(parts[1].prefix(2)) else { return true }
        return (6..<19).contains(hour)
    }

    private func dayLabel(_ iso: String, _ index: Int) -> String {
        if index == 0 { return "Today" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: iso) else { return "Day \(index + 1)" }
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func clockLabel(_ iso: String) -> String {
        let parts = iso.split(separator: "T")
        guard parts.count > 1 else { return "—" }
        let clock = parts[1].split(separator: ":")
        guard clock.count >= 2, let h = Int(clock[0]) else { return "—" }
        return "\(h % 12 == 0 ? 12 : h % 12):\(clock[1]) \(h < 12 ? "AM" : "PM")"
    }

    private func windCompass(_ degrees: Int) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return directions[Int((Double(degrees) / 45).rounded()) % 8]
    }
}

private struct CitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WeatherStore
    @State private var query = ""
    @State private var results: [WeatherPlace] = []
    @State private var searching = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.base.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Theme.accent)
                        TextField("Search any city", text: $query)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .tint(Theme.accent)
                        if !query.isEmpty {
                            Button { query = ""; results = [] } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(17)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 17))

                    if searching {
                        ProgressView().tint(Theme.accent).padding(.top, 15)
                    }
                    if query.isEmpty {
                        Text("Find weather anywhere in the world.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                    }
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { place in
                                Button {
                                    dismiss()
                                    Task { await store.select(place) }
                                } label: {
                                    HStack(spacing: 13) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 27))
                                            .foregroundStyle(Theme.accent)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(place.name)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text(place.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Theme.muted)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.muted)
                                    }
                                    .padding(.vertical, 16)
                                }
                                Divider().overlay(.white.opacity(0.07))
                            }
                        }
                    }
                }
                .padding(22)
            }
            .navigationTitle("Explore cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .task(id: query) {
            let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 2 else { results = []; searching = false; return }
            searching = true
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            do { results = try await WeatherAPI.search(text) }
            catch { results = [] }
            searching = false
        }
    }
}
