//
//  TestEmpowerPlantApp.swift
//  EmpowerPlant Test Version
//
//  This is a simplified version for testing the app functionality
//

import SwiftUI
import Foundation
import Combine

// MARK: - Simple Test App

@main
struct TestEmpowerPlantApp: App {
    var body: some Scene {
        WindowGroup {
            TestAppContentView()
        }
    }
}

struct TestAppContentView: View {
    @StateObject private var testStore = TestDataStore()
    
    var body: some View {
        TabView {
            TestDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .environmentObject(testStore)
            
            TestPlantsView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("Plants")
                }
                .environmentObject(testStore)
            
            TestSensorsView()
                .tabItem {
                    Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    Text("Sensors")
                }
                .environmentObject(testStore)
            
            TestWeatherView()
                .tabItem {
                    Image(systemName: "cloud.sun.fill")
                    Text("Weather")
                }
                .environmentObject(testStore)
        }
    }
}

// MARK: - Test Data Store

class TestDataStore: ObservableObject {
    @Published var plants: [TestPlant] = []
    @Published var sensors: [TestSensor] = []
    @Published var weatherData: TestWeatherData?
    @Published var alerts: [TestAlert] = []
    
    init() {
        loadTestData()
    }
    
    private func loadTestData() {
        // Mock plants
        plants = [
            TestPlant(id: UUID(), name: "Tomato Garden A", variety: "Cherokee Purple", healthStatus: "Good", location: "Greenhouse A"),
            TestPlant(id: UUID(), name: "Lettuce Hydroponic", variety: "Buttercrunch", healthStatus: "Excellent", location: "Hydroponic Bay 2"),
            TestPlant(id: UUID(), name: "Bell Pepper Plot", variety: "California Wonder", healthStatus: "Fair", location: "Outdoor Plot 3")
        ]
        
        // Mock sensors
        sensors = [
            TestSensor(id: UUID(), name: "Soil Moisture - A1", type: "Soil Moisture", value: 65.5, unit: "%", status: "Active"),
            TestSensor(id: UUID(), name: "Temperature - A1", type: "Temperature", value: 22.3, unit: "°C", status: "Active"),
            TestSensor(id: UUID(), name: "pH Sensor - B2", type: "pH", value: 6.2, unit: "", status: "Warning")
        ]
        
        // Mock weather
        weatherData = TestWeatherData(
            temperature: 24.5,
            humidity: 68.0,
            windSpeed: 12.5,
            condition: "Partly Cloudy"
        )
        
        // Mock alerts
        alerts = [
            TestAlert(id: UUID(), title: "Low Soil Moisture", message: "Greenhouse A soil moisture has dropped to 35%", severity: "High", isRead: false),
            TestAlert(id: UUID(), title: "Sensor Offline", message: "pH sensor in Hydroponic Bay 2 has not reported for 2 hours", severity: "Medium", isRead: false)
        ]
    }
}

// MARK: - Test Models

struct TestPlant: Identifiable {
    let id: UUID
    let name: String
    let variety: String
    let healthStatus: String
    let location: String
}

struct TestSensor: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let value: Double
    let unit: String
    let status: String
}

struct TestWeatherData {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let condition: String
}

struct TestAlert: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let severity: String
    let isRead: Bool
}

// MARK: - Test Views

struct TestDashboardView: View {
    @EnvironmentObject var testStore: TestDataStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("EmpowerPlant User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            if let weather = testStore.weatherData {
                                VStack(alignment: .trailing) {
                                    Text("\(weather.temperature, specifier: "%.0f")°C")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text(weather.condition)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        TestStatCard(title: "Plants", value: "\(testStore.plants.count)", icon: "leaf.fill", color: .green)
                        TestStatCard(title: "Sensors", value: "\(testStore.sensors.count)", icon: "sensor.tag.radiowaves.forward.fill", color: .blue)
                        TestStatCard(title: "Water Today", value: "125L", icon: "drop.fill", color: .cyan)
                        TestStatCard(title: "Alerts", value: "\(testStore.alerts.filter { !$0.isRead }.count)", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVStack(spacing: 8) {
                            TestActivityRow(icon: "drop.fill", title: "Irrigation Completed", subtitle: "Greenhouse A - Main", time: "2h ago", color: .blue)
                            TestActivityRow(icon: "camera.fill", title: "Plant Photo Analyzed", subtitle: "Health Score: 85%", time: "4h ago", color: .green)
                            TestActivityRow(icon: "exclamationmark.triangle.fill", title: "Alert Generated", subtitle: "Low soil moisture detected", time: "6h ago", color: .orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Chart Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sensor Data Trends")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        TestChartView()
                            .frame(height: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct TestPlantsView: View {
    @EnvironmentObject var testStore: TestDataStore
    @State private var showingAddPlant = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(testStore.plants) { plant in
                        TestPlantCard(plant: plant)
                    }
                }
                .padding()
            }
            .navigationTitle("Plants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlant = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                TestAddPlantView()
            }
        }
    }
}

struct TestSensorsView: View {
    @EnvironmentObject var testStore: TestDataStore
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(testStore.sensors) { sensor in
                        TestSensorCard(sensor: sensor)
                    }
                }
                .padding()
            }
            .navigationTitle("Sensors")
        }
    }
}

struct TestWeatherView: View {
    @EnvironmentObject var testStore: TestDataStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let weather = testStore.weatherData {
                    VStack(spacing: 16) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("\(weather.temperature, specifier: "%.0f")°C")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(weather.condition)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("Humidity")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(weather.humidity, specifier: "%.0f")%")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack {
                                Text("Wind")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(weather.windSpeed, specifier: "%.0f") km/h")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Weather")
        }
    }
}

// MARK: - Supporting Views

struct TestStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2)
    }
}

struct TestPlantCard: View {
    let plant: TestPlant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(plant.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(plant.variety)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(plant.location)
                    .font(.caption)
                
                Spacer()
                
                Text(plant.healthStatus)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2)
    }
}

struct TestSensorCard: View {
    let sensor: TestSensor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(sensor.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(sensor.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(sensor.status == "Active" ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
            
            HStack {
                Text("\(sensor.value, specifier: "%.1f")\(sensor.unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Updated now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2)
    }
}

struct TestActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TestChartView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Sensor Data Chart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Real-time visualization")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TestAddPlantView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var variety = ""
    @State private var location = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plant Information") {
                    TextField("Plant Name", text: $name)
                    TextField("Variety", text: $variety)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}
