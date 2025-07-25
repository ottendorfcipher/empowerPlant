//
//  Models.swift
//  EmpowerPlant
//

import Foundation
import CoreLocation

// MARK: - User Models

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let roles: [String]
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case roles
        case isActive = "is_active"
        case createdAt = "created_at"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var isPremiumUser: Bool {
        roles.contains("farmer") || roles.contains("admin")
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let roles: [String]
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case firstName = "first_name"
        case lastName = "last_name"
        case roles
    }
}

// MARK: - Sensor Models

struct Sensor: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: SensorType
    let location: String
    let status: SensorStatus
    let lastReadingAt: Date?
    let batteryLevel: Double?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, status
        case type = "sensor_type"
        case lastReadingAt = "last_reading_at"
        case batteryLevel = "battery_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SensorType: String, Codable, CaseIterable {
    case soilMoisture = "soil_moisture"
    case temperature = "temperature"
    case humidity = "humidity"
    case light = "light"
    case pH = "ph"
    case conductivity = "conductivity"
    case waterFlow = "water_flow"
    case pressure = "pressure"
    
    var displayName: String {
        switch self {
        case .soilMoisture: return "Soil Moisture"
        case .temperature: return "Temperature"
        case .humidity: return "Humidity"
        case .light: return "Light"
        case .pH: return "pH Level"
        case .conductivity: return "Conductivity"
        case .waterFlow: return "Water Flow"
        case .pressure: return "Pressure"
        }
    }
    
    var unit: String {
        switch self {
        case .soilMoisture: return "%"
        case .temperature: return "°C"
        case .humidity: return "%"
        case .light: return "lux"
        case .pH: return ""
        case .conductivity: return "μS/cm"
        case .waterFlow: return "L/min"
        case .pressure: return "bar"
        }
    }
    
    var icon: String {
        switch self {
        case .soilMoisture: return "drop.fill"
        case .temperature: return "thermometer"
        case .humidity: return "humidity"
        case .light: return "sun.max.fill"
        case .pH: return "flask.fill"
        case .conductivity: return "bolt.fill"
        case .waterFlow: return "water.waves"
        case .pressure: return "gauge"
        }
    }
}

enum SensorStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case error = "error"
    case maintenance = "maintenance"
    
    var color: String {
        switch self {
        case .active: return "green"
        case .inactive: return "gray"
        case .error: return "red"
        case .maintenance: return "orange"
        }
    }
}

struct SensorReading: Codable, Identifiable {
    let id: UUID
    let sensorId: UUID
    let value: Double
    let unit: String
    let timestamp: Date
    let qualityScore: Double?
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sensorId = "sensor_id"
        case value, unit, timestamp
        case qualityScore = "quality_score"
        case metadata
    }
}

// MARK: - Plant Models

struct Plant: Codable, Identifiable {
    let id: UUID
    let name: String
    let variety: String
    let plantingDate: Date
    let location: String
    let growthStage: GrowthStage
    let healthStatus: HealthStatus
    let imageURL: URL?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, variety, location, notes
        case plantingDate = "planting_date"
        case growthStage = "growth_stage"
        case healthStatus = "health_status"
        case imageURL = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var daysFromPlanting: Int {
        Calendar.current.dateComponents([.day], from: plantingDate, to: Date()).day ?? 0
    }
}

enum GrowthStage: String, Codable, CaseIterable {
    case seed = "seed"
    case germination = "germination"
    case seedling = "seedling"
    case vegetative = "vegetative"
    case flowering = "flowering"
    case fruiting = "fruiting"
    case mature = "mature"
    case harvest = "harvest"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .seed: return "circle.fill"
        case .germination: return "leaf.fill"
        case .seedling: return "tree.fill"
        case .vegetative: return "tree"
        case .flowering: return "leaf.circle.fill"
        case .fruiting: return "apple.logo"
        case .mature: return "tree.circle.fill"
        case .harvest: return "basket.fill"
        }
    }
}

enum HealthStatus: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "mint"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Weather Models

struct WeatherData: Codable, Identifiable {
    let id: UUID
    let location: String
    let temperature: Double
    let humidity: Double
    let rainfall: Double
    let windSpeed: Double
    let windDirection: Double
    let solarRadiation: Double?
    let uvIndex: Double?
    let timestamp: Date
    let forecast: [WeatherForecast]?
    
    enum CodingKeys: String, CodingKey {
        case id, location, temperature, humidity, rainfall, timestamp, forecast
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case solarRadiation = "solar_radiation"
        case uvIndex = "uv_index"
    }
}

struct WeatherForecast: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let temperature: TemperatureRange
    let condition: WeatherCondition
    let precipitation: Double
    let humidity: Double
    
    enum CodingKeys: String, CodingKey {
        case date, temperature, condition, precipitation, humidity
    }
}

struct TemperatureRange: Codable {
    let min: Double
    let max: Double
}

enum WeatherCondition: String, Codable, CaseIterable {
    case sunny = "sunny"
    case partlyCloudy = "partly_cloudy"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case stormy = "stormy"
    case snowy = "snowy"
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.fill"
        case .snowy: return "cloud.snow.fill"
        }
    }
}

// MARK: - Irrigation Models

struct IrrigationZone: Codable, Identifiable {
    let id: UUID
    let name: String
    let area: Double
    let cropType: String
    let soilType: String
    let isActive: Bool
    let lastIrrigation: Date?
    let nextScheduled: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, area
        case cropType = "crop_type"
        case soilType = "soil_type"
        case isActive = "is_active"
        case lastIrrigation = "last_irrigation"
        case nextScheduled = "next_scheduled"
    }
}

struct IrrigationEvent: Codable, Identifiable {
    let id: UUID
    let zoneId: UUID
    let duration: TimeInterval
    let waterAmount: Double
    let triggerType: TriggerType
    let startedAt: Date
    let completedAt: Date?
    let isSuccessful: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case zoneId = "zone_id"
        case duration
        case waterAmount = "water_amount"
        case triggerType = "trigger_type"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case isSuccessful = "is_successful"
    }
}

enum TriggerType: String, Codable, CaseIterable {
    case manual = "manual"
    case scheduled = "scheduled"
    case sensorBased = "sensor_based"
    case weatherBased = "weather_based"
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .scheduled: return "Scheduled"
        case .sensorBased: return "Sensor Based"
        case .weatherBased: return "Weather Based"
        }
    }
}

// MARK: - Alert Models

struct Alert: Codable, Identifiable {
    let id: UUID
    let type: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let source: String
    let isAcknowledged: Bool
    let acknowledgedBy: UUID?
    let acknowledgedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, severity, title, message, source
        case isAcknowledged = "acknowledged"
        case acknowledgedBy = "acknowledged_by"
        case acknowledgedAt = "acknowledged_at"
        case createdAt = "created_at"
    }
}

enum AlertType: String, Codable, CaseIterable {
    case sensorFailure = "sensor_failure"
    case lowMoisture = "low_moisture"
    case extremeTemperature = "extreme_temperature"
    case systemError = "system_error"
    case maintenanceRequired = "maintenance_required"
    case weatherAlert = "weather_alert"
    
    var displayName: String {
        switch self {
        case .sensorFailure: return "Sensor Failure"
        case .lowMoisture: return "Low Soil Moisture"
        case .extremeTemperature: return "Extreme Temperature"
        case .systemError: return "System Error"
        case .maintenanceRequired: return "Maintenance Required"
        case .weatherAlert: return "Weather Alert"
        }
    }
    
    var icon: String {
        switch self {
        case .sensorFailure: return "sensor.tag.radiowaves.forward.fill"
        case .lowMoisture: return "drop.fill"
        case .extremeTemperature: return "thermometer.sun.fill"
        case .systemError: return "exclamationmark.triangle.fill"
        case .maintenanceRequired: return "wrench.fill"
        case .weatherAlert: return "cloud.bolt.fill"
        }
    }
}

enum AlertSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - API Response Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: Date
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let total: Int
    let page: Int
    let perPage: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case data, total, page
        case perPage = "per_page"
        case totalPages = "total_pages"
    }
}

// MARK: - Dashboard Models

struct DashboardData: Codable {
    let summary: DashboardSummary
    let recentAlerts: [Alert]
    let sensorReadings: [SensorReading]
    let weatherData: WeatherData?
    let irrigationStatus: IrrigationStatus
}

struct DashboardSummary: Codable {
    let totalPlants: Int
    let activeSensors: Int
    let pendingAlerts: Int
    let waterUsageToday: Double
    let avgSoilMoisture: Double
    let currentTemperature: Double
    
    enum CodingKeys: String, CodingKey {
        case totalPlants = "total_plants"
        case activeSensors = "active_sensors"
        case pendingAlerts = "pending_alerts"
        case waterUsageToday = "water_usage_today"
        case avgSoilMoisture = "avg_soil_moisture"
        case currentTemperature = "current_temperature"
    }
}

struct IrrigationStatus: Codable {
    let isRunning: Bool
    let currentZone: IrrigationZone?
    let estimatedCompletion: Date?
    let todayUsage: Double
    let weeklyUsage: Double
    
    enum CodingKeys: String, CodingKey {
        case isRunning = "is_running"
        case currentZone = "current_zone"
        case estimatedCompletion = "estimated_completion"
        case todayUsage = "today_usage"
        case weeklyUsage = "weekly_usage"
    }
}
