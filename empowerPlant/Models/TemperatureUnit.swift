//
//  TemperatureUnit.swift
//  empowerPlant
//
//  Temperature unit configuration and conversion utilities
//

import Foundation

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "°F"
    case celsius = "°C"
    
    var displayName: String {
        switch self {
        case .fahrenheit:
            return "Fahrenheit (°F)"
        case .celsius:
            return "Celsius (°C)"
        }
    }
    
    /// Convert temperature from Celsius to the selected unit
    func convert(fromCelsius celsius: Double) -> Double {
        switch self {
        case .celsius:
            return celsius
        case .fahrenheit:
            return (celsius * 9/5) + 32
        }
    }
    
    /// Convert temperature to Celsius from the selected unit
    func convertToCelsius(_ temperature: Double) -> Double {
        switch self {
        case .celsius:
            return temperature
        case .fahrenheit:
            return (temperature - 32) * 5/9
        }
    }
    
    /// Format temperature value for display
    func format(_ temperature: Double) -> String {
        return String(format: "%.1f%@", temperature, rawValue)
    }
    
    /// Format temperature value as integer for display
    func formatInteger(_ temperature: Double) -> String {
        return String(format: "%.0f%@", temperature, rawValue)
    }
}

// MARK: - App Settings Manager

class AppSettings: ObservableObject {
    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
        }
    }
    
    @Published var use24HourTime: Bool {
        didSet {
            UserDefaults.standard.set(use24HourTime, forKey: "use24HourTime")
        }
    }
    
    @Published var enableNotifications: Bool {
        didSet {
            UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        }
    }
    
    @Published var autoRefreshInterval: Int {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: "autoRefreshInterval")
        }
    }
    
    init() {
        // Load temperature unit (default to Fahrenheit)
        if let unitString = UserDefaults.standard.string(forKey: "temperatureUnit"),
           let unit = TemperatureUnit(rawValue: unitString) {
            self.temperatureUnit = unit
        } else {
            self.temperatureUnit = .fahrenheit
        }
        
        // Load other settings
        self.use24HourTime = UserDefaults.standard.bool(forKey: "use24HourTime")
        self.enableNotifications = UserDefaults.standard.object(forKey: "enableNotifications") as? Bool ?? true
        self.autoRefreshInterval = UserDefaults.standard.object(forKey: "autoRefreshInterval") as? Int ?? 30
    }
    
    /// Get formatted temperature for display
    func formatTemperature(_ celsiusValue: Double) -> String {
        let convertedValue = temperatureUnit.convert(fromCelsius: celsiusValue)
        return temperatureUnit.format(convertedValue)
    }
    
    /// Get formatted temperature as integer for display
    func formatTemperatureInteger(_ celsiusValue: Double) -> String {
        let convertedValue = temperatureUnit.convert(fromCelsius: celsiusValue)
        return temperatureUnit.formatInteger(convertedValue)
    }
}
