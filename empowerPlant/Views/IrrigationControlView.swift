//
//  IrrigationControlView.swift
//  empowerPlant
//
//  Enhanced irrigation control with backend integration
//

import SwiftUI

struct IrrigationControlView: View {
    @State private var irrigationStatus: IrrigationStatus?
    @State private var sensors: [IrrigationSensor] = []
    @State private var diagnostics: IrrigationDiagnostics?
    @State private var serialPorts: [SerialPort] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingArduinoConnection = false
    @State private var selectedCommand: IrrigationCommandType?
    @State private var pumpLevel: Double = 50.0
    @State private var autoRefreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status
                    connectionStatusCard
                    
                    // Current Status
                    if let status = irrigationStatus {
                        currentStatusCard(status: status)
                    } else {
                        placeholderStatusCard
                    }
                    
                    // Quick Controls
                    quickControlsSection
                    
                    // Sensor Data
                    if !sensors.isEmpty {
                        sensorsSection
                    }
                    
                    // Diagnostics
                    if let diagnostics = diagnostics {
                        diagnosticsSection(diagnostics: diagnostics)
                    }
                    
                    // Command History
                    commandHistorySection
                }
                .padding()
            }
            .navigationTitle("Irrigation Control")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Connect Arduino") {
                        showingArduinoConnection = true
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingArduinoConnection) {
                ArduinoConnectionView()
            }
            .onAppear {
                Task {
                    await loadInitialData()
                }
                startAutoRefresh()
            }
            .onDisappear {
                stopAutoRefresh()
            }
        }
    }
    
    // MARK: - View Components
    
    private var connectionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(irrigationStatus != nil ? "Connected" : "Disconnected")
                        .font(.subheadline)
                        .foregroundColor(irrigationStatus != nil ? .green : .red)
                    
                    Text("Arduino Controller")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: irrigationStatus != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(irrigationStatus != nil ? .green : .red)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func currentStatusCard(status: IrrigationStatus) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatusMetricCard(
                    title: "Pump",
                    value: status.pumpActive ? "ON" : "OFF",
                    subtitle: "PWM: \(status.pumpPwmLevel)%",
                    color: status.pumpActive ? .green : .gray,
                    icon: "drop.circle.fill"
                )
                
                StatusMetricCard(
                    title: "Solenoid",
                    value: status.solenoidActive ? "OPEN" : "CLOSED",
                    subtitle: "Main valve",
                    color: status.solenoidActive ? .blue : .gray,
                    icon: "arrow.up.arrow.down.circle.fill"
                )
                
                StatusMetricCard(
                    title: "Water Level",
                    value: status.waterLevelOk ? "OK" : "LOW",
                    subtitle: "Tank status",
                    color: status.waterLevelOk ? .green : .orange,
                    icon: "drop.triangle.fill"
                )
                
                StatusMetricCard(
                    title: "Flow Rate",
                    value: String(format: "%.1f", status.flowRate),
                    subtitle: "L/min",
                    color: .cyan,
                    icon: "speedometer"
                )
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Voltage: \(String(format: "%.1f", status.voltage))V")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Uptime: \(formatUptime(status.systemUptime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let lastCommand = status.lastCommand {
                    Text("Last: \(lastCommand)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var placeholderStatusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Connection")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect to Arduino to view irrigation status")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Connect Arduino") {
                showingArduinoConnection = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var quickControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ControlButton(
                    command: .startPump,
                    isEnabled: irrigationStatus != nil,
                    action: { executeCommand(.startPump) }
                )
                
                ControlButton(
                    command: .stopPump,
                    isEnabled: irrigationStatus != nil,
                    action: { executeCommand(.stopPump) }
                )
                
                ControlButton(
                    command: .openSolenoid,
                    isEnabled: irrigationStatus != nil,
                    action: { executeCommand(.openSolenoid) }
                )
                
                ControlButton(
                    command: .closeSolenoid,
                    isEnabled: irrigationStatus != nil,
                    action: { executeCommand(.closeSolenoid) }
                )
            }
            
            // Pump Level Control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pump Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(pumpLevel))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Slider(value: $pumpLevel, in: 0...100, step: 5)
                    .accentColor(.blue)
                
                Button("Set Pump Level") {
                    executeCommand(.setPumpLevel, parameters: ["level": Int(pumpLevel)])
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(irrigationStatus != nil ? Color.blue : Color.gray)
                .cornerRadius(8)
                .disabled(irrigationStatus == nil)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var sensorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sensors")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(sensors) { sensor in
                SensorRowView(sensor: sensor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func diagnosticsSection(diagnostics: IrrigationDiagnostics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Diagnostics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                if let pumpCurrent = diagnostics.pumpCurrent {
                    DiagnosticCard(title: "Pump Current", value: "\(String(format: "%.1f", pumpCurrent))A")
                }
                
                if let efficiency = diagnostics.efficiency {
                    DiagnosticCard(title: "Efficiency", value: "\(String(format: "%.1f", efficiency))%")
                }
                
                if let powerConsumption = diagnostics.powerConsumption {
                    DiagnosticCard(title: "Power", value: "\(String(format: "%.1f", powerConsumption))W")
                }
                
                if let thermalStatus = diagnostics.thermalStatus {
                    DiagnosticCard(title: "Thermal", value: thermalStatus)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var commandHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Commands")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                CommandHistoryRow(command: "START_PUMP", time: "2 min ago", success: true)
                CommandHistoryRow(command: "SET_PUMP_LEVEL", time: "5 min ago", success: true)
                CommandHistoryRow(command: "GET_STATUS", time: "1 min ago", success: true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func loadInitialData() async {
        await refreshData()
        await loadSensors()
        await loadDiagnostics()
        await loadSerialPorts()
    }
    
    private func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        // This would call the actual API
        APIService.shared.getIrrigationStatus { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let status):
                    irrigationStatus = status
                    errorMessage = nil
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadSensors() async {
        // Simulate API call - replace with actual implementation
        sensors = [
            IrrigationSensor(id: "1", name: "Water Level", sensorType: "water_level", location: "Tank", status: "active", createdAt: "", updatedAt: ""),
            IrrigationSensor(id: "2", name: "Flow Rate", sensorType: "flow_rate", location: "Main Line", status: "active", createdAt: "", updatedAt: ""),
            IrrigationSensor(id: "3", name: "Pressure", sensorType: "pressure", location: "Main Line", status: "active", createdAt: "", updatedAt: "")
        ]
    }
    
    private func loadDiagnostics() async {
        // This would call the actual API for diagnostics
    }
    
    private func loadSerialPorts() async {
        // This would call the actual API for serial ports
    }
    
    private func executeCommand(_ command: IrrigationCommandType, parameters: [String: Any]? = nil) {
        // This would execute the actual command via API
        print("Executing command: \(command.rawValue) with parameters: \(parameters ?? [:])")
    }
    
    private func formatUptime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func startAutoRefresh() {
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await refreshData()
            }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
}

// MARK: - Supporting Views

struct StatusMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ControlButton: View {
    let command: IrrigationCommandType
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: command.icon)
                    .font(.title2)
                    .foregroundColor(colorForCommand(command.color))
                
                Text(command.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color(.systemGray6) : Color(.systemGray5))
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForCommand(_ colorString: String) -> Color {
        switch colorString {
        case "green": return .green
        case "red": return .red
        case "blue": return .blue
        case "cyan": return .cyan
        case "orange": return .orange
        case "purple": return .purple
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .gray
        }
    }
}

struct SensorRowView: View {
    let sensor: IrrigationSensor
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sensor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(sensor.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Circle()
                    .fill(sensor.status == "active" ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(sensor.sensorType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiagnosticCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CommandHistoryRow: View {
    let command: String
    let time: String
    let success: Bool
    
    var body: some View {
        HStack {
            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(command)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ArduinoConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Arduino Connection Setup")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This would show serial port selection and connection options")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Connect Arduino")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IrrigationControlView()
}
