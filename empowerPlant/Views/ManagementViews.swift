//
//  ManagementViews.swift
//  empowerPlant
//
//  Comprehensive management system views
//

import SwiftUI

// MARK: - Irrigation Management

struct IrrigationManagementView: View {
    @State private var irrigationStatus: IrrigationStatus?
    @State private var sensors: [IrrigationSensor] = []
    @State private var diagnostics: IrrigationDiagnostics?
    @State private var serialPorts: [SerialPort] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingScheduler = false
    @State private var showingArduinoConnection = false
    @State private var selectedCommand: IrrigationCommandType?
    @State private var pumpLevel: Double = 50.0
    
    // Mock zones for UI demonstration
    @State private var zones = [
        IrrigationZone(id: "A1", name: "Greenhouse A", status: .active, moistureLevel: 65, schedule: "Every 6h"),
        IrrigationZone(id: "B1", name: "Greenhouse B", status: .scheduled, moistureLevel: 45, schedule: "Every 8h"),
        IrrigationZone(id: "C1", name: "Outdoor Plot", status: .maintenance, moistureLevel: 30, schedule: "Daily")
    ]
    @State private var totalWaterUsage = 245.8
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Water Usage Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Water Usage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(totalWaterUsage, specifier: "%.1f")L")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("Total consumed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("85%")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text("Efficiency")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Quick Actions
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    QuickActionCard(
                        icon: "play.circle.fill",
                        title: "Start All",
                        subtitle: "Begin irrigation",
                        color: .green,
                        action: { }
                    )
                    
                    QuickActionCard(
                        icon: "pause.circle.fill",
                        title: "Pause All",
                        subtitle: "Stop current cycles",
                        color: .orange,
                        action: { }
                    )
                    
                    QuickActionCard(
                        icon: "calendar.badge.plus",
                        title: "Schedule",
                        subtitle: "Set timing",
                        color: .blue,
                        action: { showingScheduler = true }
                    )
                    
                    QuickActionCard(
                        icon: "gear",
                        title: "Settings",
                        subtitle: "Configure zones",
                        color: .gray,
                        action: { }
                    )
                }
                
                // Zone Management
                VStack(alignment: .leading, spacing: 16) {
                    Text("Irrigation Zones")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(zones, id: \.id) { zone in
                        IrrigationZoneCard(zone: zone)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Irrigation Management")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingScheduler) {
            IrrigationSchedulerView()
        }
    }
}

// MARK: - Fertilizer Management

struct FertilizerManagementView: View {
    @State private var fertilizers = [
        FertilizerRecord(name: "Nitrogen Mix", nextApplication: Date().addingTimeInterval(86400), concentration: "10-5-5", zones: ["A1", "B1"]),
        FertilizerRecord(name: "Phosphorus Boost", nextApplication: Date().addingTimeInterval(172800), concentration: "5-15-5", zones: ["C1"]),
        FertilizerRecord(name: "Potassium Complex", nextApplication: Date().addingTimeInterval(259200), concentration: "5-5-20", zones: ["A1", "C1"])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Application Schedule
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upcoming Applications")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(fertilizers, id: \.name) { fertilizer in
                        FertilizerCard(fertilizer: fertilizer)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Nutrient Status
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrient Levels")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        NutrientBar(name: "Nitrogen (N)", level: 0.78, optimal: 0.80, color: .green)
                        NutrientBar(name: "Phosphorus (P)", level: 0.65, optimal: 0.75, color: .orange)
                        NutrientBar(name: "Potassium (K)", level: 0.85, optimal: 0.80, color: .blue)
                        NutrientBar(name: "pH Level", level: 0.72, optimal: 0.70, color: .purple)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Fertilizer Management")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Pest Management

struct PestManagementView: View {
    @State private var alerts = [
        PestAlert(type: "Aphids", severity: .high, location: "Greenhouse A", detectedAt: Date().addingTimeInterval(-3600)),
        PestAlert(type: "Spider Mites", severity: .medium, location: "Greenhouse B", detectedAt: Date().addingTimeInterval(-7200)),
        PestAlert(type: "Whiteflies", severity: .low, location: "Outdoor Plot", detectedAt: Date().addingTimeInterval(-14400))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Detection Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Pest Detection")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Active Monitoring")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Text("24/7 image analysis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "eye.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Active Alerts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Active Alerts")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(alerts, id: \.type) { alert in
                        PestAlertCard(alert: alert)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Treatment History
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Treatments")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        TreatmentRow(treatment: "Neem Oil Spray", date: Date().addingTimeInterval(-86400), effectiveness: 85)
                        TreatmentRow(treatment: "Beneficial Insects", date: Date().addingTimeInterval(-259200), effectiveness: 92)
                        TreatmentRow(treatment: "Copper Fungicide", date: Date().addingTimeInterval(-432000), effectiveness: 78)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Pest Management")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Soil Analysis

struct SoilAnalysisView: View {
    @State private var selectedSample = "Sample A1"
    private let samples = ["Sample A1", "Sample B1", "Sample C1"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sample Selection
                Picker("Soil Sample", selection: $selectedSample) {
                    ForEach(samples, id: \.self) { sample in
                        Text(sample).tag(sample)
                    }
                }
                .pickerStyle(.segmented)
                
                // Soil Health Score
                VStack(spacing: 16) {
                    Text("Soil Health Score")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: 0.78)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("78")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Score")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Soil Metrics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Soil Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        SoilMetricCard(title: "pH Level", value: "6.8", optimal: "6.5-7.0", status: .good)
                        SoilMetricCard(title: "Organic Matter", value: "3.2%", optimal: "3-5%", status: .good)
                        SoilMetricCard(title: "Nitrogen", value: "45 ppm", optimal: "40-60 ppm", status: .good)
                        SoilMetricCard(title: "Phosphorus", value: "25 ppm", optimal: "30-50 ppm", status: .low)
                        SoilMetricCard(title: "Potassium", value: "180 ppm", optimal: "150-200 ppm", status: .good)
                        SoilMetricCard(title: "Moisture", value: "35%", optimal: "30-40%", status: .good)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommendations")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        RecommendationCard(
                            icon: "leaf.fill",
                            title: "Add Phosphorus",
                            description: "Apply bone meal or rock phosphate to boost phosphorus levels",
                            priority: .medium,
                            action: "Schedule"
                        )
                        
                        RecommendationCard(
                            icon: "drop.circle",
                            title: "Monitor Drainage",
                            description: "Ensure proper drainage to prevent waterlogging",
                            priority: .low,
                            action: "Note"
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Soil Analysis")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Supporting Models and Views

struct IrrigationZone {
    let id: String
    let name: String
    let status: Status
    let moistureLevel: Int
    let schedule: String
    
    enum Status {
        case active, scheduled, maintenance, offline
        
        var color: Color {
            switch self {
            case .active: return .green
            case .scheduled: return .blue
            case .maintenance: return .orange
            case .offline: return .red
            }
        }
        
        var text: String {
            switch self {
            case .active: return "Active"
            case .scheduled: return "Scheduled"
            case .maintenance: return "Maintenance"
            case .offline: return "Offline"
            }
        }
    }
}

struct FertilizerRecord {
    let name: String
    let nextApplication: Date
    let concentration: String
    let zones: [String]
}

struct PestAlert {
    let type: String
    let severity: Severity
    let location: String
    let detectedAt: Date
    
    enum Severity {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .yellow
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IrrigationZoneCard: View {
    let zone: IrrigationZone
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Zone \(zone.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(zone.schedule)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(zone.moistureLevel)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Moisture")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text(zone.status.text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(zone.status.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FertilizerCard: View {
    let fertilizer: FertilizerRecord
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(fertilizer.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(fertilizer.concentration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Zones: \(fertilizer.zones.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(fertilizer.nextApplication, style: .date)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(fertilizer.nextApplication, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutrientBar: View {
    let name: String
    let level: Double
    let optimal: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(level * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(level >= optimal * 0.9 ? .green : .orange)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * level, height: 8)
                        .cornerRadius(4)
                    
                    // Optimal indicator
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * optimal - 1, y: -2)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PestAlertCard: View {
    let alert: PestAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "ant.circle.fill")
                .font(.title2)
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(alert.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Detected \(alert.detectedAt, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Treat") {
                // Handle treatment
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(alert.severity.color)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TreatmentRow: View {
    let treatment: String
    let date: Date
    let effectiveness: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(treatment)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(effectiveness)%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(effectiveness > 80 ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}

struct SoilMetricCard: View {
    let title: String
    let value: String
    let optimal: String
    let status: MetricStatus
    
    enum MetricStatus {
        case good, low, high
        
        var color: Color {
            switch self {
            case .good: return .green
            case .low: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .low: return "arrow.down.circle.fill"
            case .high: return "arrow.up.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: status.icon)
                    .font(.caption)
                    .foregroundColor(status.color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Optimal: \(optimal)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Placeholder Views

struct IrrigationSchedulerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Irrigation Scheduler")
                .navigationTitle("Schedule")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct EnvironmentalDataView: View {
    var body: some View {
        Text("Environmental Data View")
            .navigationTitle("Environmental Data")
    }
}

struct WaterDataView: View {
    var body: some View {
        Text("Water Data View")
            .navigationTitle("Water Quality")
    }
}

struct ComplianceView: View {
    var body: some View {
        Text("Compliance View")
            .navigationTitle("Compliance")
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            List {
                Section("Units & Display") {
                    HStack {
                        Label("Temperature Unit", systemImage: "thermometer")
                        Spacer()
                        Picker("Temperature Unit", selection: $appSettings.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Label("24-Hour Time", systemImage: "clock")
                        Spacer()
                        Toggle("", isOn: $appSettings.use24HourTime)
                    }
                }
                
                Section("Notifications") {
                    HStack {
                        Label("Enable Notifications", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: $appSettings.enableNotifications)
                    }
                    
                    if appSettings.enableNotifications {
                        HStack {
                            Label("Auto Refresh", systemImage: "arrow.clockwise")
                            Spacer()
                            Picker("Refresh Interval", selection: $appSettings.autoRefreshInterval) {
                                Text("15 seconds").tag(15)
                                Text("30 seconds").tag(30)
                                Text("1 minute").tag(60)
                                Text("5 minutes").tag(300)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                Section("Data & Privacy") {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                    Label("Privacy Settings", systemImage: "hand.raised")
                    Label("Data Usage", systemImage: "chart.bar")
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("2025.01")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Reset All Settings") {
                        resetAllSettings()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func resetAllSettings() {
        appSettings.temperatureUnit = .fahrenheit
        appSettings.use24HourTime = false
        appSettings.enableNotifications = true
        appSettings.autoRefreshInterval = 30
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Help & Support View")
                .navigationTitle("Help")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("About View")
                .navigationTitle("About")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
