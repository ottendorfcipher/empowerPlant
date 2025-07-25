//
//  IrrigationModels.swift
//  empowerPlant
//
//  Created for irrigation system integration
//

import Foundation

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String
}

// MARK: - Irrigation Status
struct IrrigationStatus: Codable, Identifiable {
    let id: String
    let pumpActive: Bool
    let pumpPwmLevel: Int
    let solenoidActive: Bool
    let waterLevelOk: Bool
    let flowRate: Double
    let voltage: Double
    let systemUptime: Int
    let lastCommand: String?
    let errorMessage: String?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case pumpActive = "pump_active"
        case pumpPwmLevel = "pump_pwm_level"
        case solenoidActive = "solenoid_active"
        case waterLevelOk = "water_level_ok"
        case flowRate = "flow_rate"
        case voltage
        case systemUptime = "system_uptime"
        case lastCommand = "last_command"
        case errorMessage = "error_message"
        case timestamp
    }
}

// MARK: - Irrigation Command
struct IrrigationCommand: Codable {
    let command: String
    let parameters: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case command, parameters
    }
    
    // Custom encoding for parameters
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(command, forKey: .command)
        if let parameters = parameters {
            try container.encode(AnyCodable(parameters), forKey: .parameters)
        }
    }
}

// MARK: - Irrigation Sensors
struct IrrigationSensor: Codable, Identifiable {
    let id: String
    let name: String
    let sensorType: String
    let location: String
    let status: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, location, status
        case sensorType = "sensor_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Irrigation Diagnostics
struct IrrigationDiagnostics: Codable, Identifiable {
    let id: String
    let pumpCurrent: Double?
    let pumpTemperature: Double?
    let pumpRuntimeHours: Double?
    let pumpCycles: Int?
    let solenoidResistance: Double?
    let solenoidActivations: Int?
    let solenoidResponseTime: Int?
    let supplyVoltage: Double?
    let currentDraw: Double?
    let powerConsumption: Double?
    let efficiency: Double?
    let thermalStatus: String?
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp
        case pumpCurrent = "pump_current"
        case pumpTemperature = "pump_temperature"
        case pumpRuntimeHours = "pump_runtime_hours"
        case pumpCycles = "pump_cycles"
        case solenoidResistance = "solenoid_resistance"
        case solenoidActivations = "solenoid_activations"
        case solenoidResponseTime = "solenoid_response_time"
        case supplyVoltage = "supply_voltage"
        case currentDraw = "current_draw"
        case powerConsumption = "power_consumption"
        case efficiency
        case thermalStatus = "thermal_status"
    }
}

// MARK: - Serial Port
struct SerialPort: Codable, Identifiable {
    let id = UUID()
    let portName: String
    let portType: String?
    
    enum CodingKeys: String, CodingKey {
        case portName = "port_name"
        case portType = "port_type"
    }
}

// MARK: - Arduino Connection Request
struct ArduinoConnectionRequest: Codable {
    let port: String
    let baudRate: Int?
    
    enum CodingKeys: String, CodingKey {
        case port
        case baudRate = "baud_rate"
    }
}

// MARK: - Command Types
enum IrrigationCommandType: String, CaseIterable {
    case startPump = "START_PUMP"
    case stopPump = "STOP_PUMP"
    case setPumpLevel = "SET_PUMP_LEVEL"
    case openSolenoid = "OPEN_SOLENOID"
    case closeSolenoid = "CLOSE_SOLENOID"
    case getStatus = "GET_STATUS"
    case getSensors = "GET_SENSORS"
    case getDiagnostics = "GET_DIAGNOSTICS"
    case emergencyStop = "EMERGENCY_STOP"
    case runTest = "RUN_TEST"
    
    var displayName: String {
        switch self {
        case .startPump: return "Start Pump"
        case .stopPump: return "Stop Pump"
        case .setPumpLevel: return "Set Pump Level"
        case .openSolenoid: return "Open Solenoid"
        case .closeSolenoid: return "Close Solenoid"
        case .getStatus: return "Get Status"
        case .getSensors: return "Get Sensors"
        case .getDiagnostics: return "Get Diagnostics"
        case .emergencyStop: return "Emergency Stop"
        case .runTest: return "Run Test"
        }
    }
    
    var icon: String {
        switch self {
        case .startPump: return "play.fill"
        case .stopPump: return "stop.fill"
        case .setPumpLevel: return "slider.horizontal.3"
        case .openSolenoid: return "arrow.up.circle.fill"
        case .closeSolenoid: return "arrow.down.circle.fill"
        case .getStatus: return "info.circle"
        case .getSensors: return "sensor.tag.radiowaves.forward.fill"
        case .getDiagnostics: return "stethoscope"
        case .emergencyStop: return "exclamationmark.octagon.fill"
        case .runTest: return "checkmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .startPump: return "green"
        case .stopPump: return "red"
        case .setPumpLevel: return "blue"
        case .openSolenoid: return "cyan"
        case .closeSolenoid: return "orange"
        case .getStatus: return "gray"
        case .getSensors: return "purple"
        case .getDiagnostics: return "indigo"
        case .emergencyStop: return "red"
        case .runTest: return "mint"
        }
    }
}

// MARK: - Helper for Any Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let value = value as? String {
            try container.encode(value)
        } else if let value = value as? Int {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? [String: Any] {
            let dict = value.mapValues { AnyCodable($0) }
            try container.encode(dict)
        } else {
            try container.encodeNil()
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else {
            self.value = NSNull()
        }
    }
}
