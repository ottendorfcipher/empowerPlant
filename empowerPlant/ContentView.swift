//
//  ContentView.swift
//  empowerPlant
//
//  Created by Nicholas Weiner on 7/24/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var showingNotifications = false
    @State private var showingProfile = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            NavigationStack {
                DashboardView()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showingProfile = true }) {
                                ProfileAvatarView()
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showingNotifications = true }) {
                                NotificationBadgeView(count: 3)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(0)
            
            // Plants Tab
            NavigationStack {
                PlantsView()
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Plants", systemImage: "leaf.fill")
            }
            .tag(1)
            
            // Analytics Tab
            NavigationStack {
                AnalyticsView()
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.xaxis")
            }
            .tag(2)
            
            // Sensors Tab
            NavigationStack {
                SensorsView()
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Sensors", systemImage: "sensor.tag.radiowaves.forward.fill")
            }
            .tag(3)
            
            // More Tab
            NavigationStack {
                MoreView()
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("More", systemImage: "ellipsis")
            }
            .tag(4)
        }
        .tint(.green)
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Individual Tab Views

struct DashboardView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
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
                        
                        VStack(alignment: .trailing) {
                            Text(appSettings.formatTemperatureInteger(24.0))
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Partly Cloudy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Plant Photo Gallery
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Garden")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            PlantPhotoCard(plantName: "Tomato Garden", imageName: "tomato")
                            PlantPhotoCard(plantName: "Lettuce Patch", imageName: "lettuce")
                            PlantPhotoCard(plantName: "Bell Peppers", imageName: "bell_pepper")
                            AddPlantCard()
                            PlantPhotoCard(plantName: "Carrots", imageName: "carrot")
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Quick Stats
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(title: "Water Today", value: "125L", icon: "drop.fill", color: .cyan)
                    LiveViewCard()
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    LazyVStack(spacing: 8) {
                        ActivityRow(icon: "drop.fill", title: "Irrigation Completed", subtitle: "Greenhouse A - Main", time: "2h ago", color: .blue)
                        ActivityRow(icon: "camera.fill", title: "Plant Photo Analyzed", subtitle: "Health Score: 85%", time: "4h ago", color: .green)
                        ActivityRow(icon: "exclamationmark.triangle.fill", title: "Alert Generated", subtitle: "Low soil moisture detected", time: "6h ago", color: .orange)
                    }
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

struct PlantsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                PlantCard(name: "Tomato Garden A", variety: "Cherokee Purple", location: "Greenhouse A", status: "Good")
                PlantCard(name: "Lettuce Hydroponic", variety: "Buttercrunch", location: "Hydroponic Bay 2", status: "Excellent")
                PlantCard(name: "Bell Pepper Plot", variety: "California Wonder", location: "Outdoor Plot 3", status: "Fair")
            }
            .padding()
        }
        .navigationTitle("Plants")
    }
}

struct SensorsView: View {
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SensorCard(name: "Soil Moisture - A1", type: "Soil Moisture", value: "65.5%", status: "Active")
                TemperatureSensorCard(name: "Temperature - A1", type: "Temperature", celsiusValue: 22.3, status: "Active")
                SensorCard(name: "pH Sensor - B2", type: "pH", value: "6.2", status: "Warning")
            }
            .padding()
        }
        .navigationTitle("Sensors")
    }
}

struct WeatherView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("24°C")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Partly Cloudy")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 40) {
                    VStack {
                        Text("Humidity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("68%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack {
                        Text("Wind")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("12 km/h")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Weather")
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
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
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.08), radius: 1)
    }
}

struct PlantPhotoCard: View {
    let plantName: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder using SF Symbols with plant-themed colors
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                // Using SF Symbols as plant placeholders
                Image(systemName: getPlantSymbol(for: imageName))
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
            
            Text(plantName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .onTapGesture {
            // Handle plant selection
        }
    }
    
    private func getPlantSymbol(for imageName: String) -> String {
        switch imageName {
        case "tomato":
            return "circle.fill" // Represents tomato
        case "lettuce":
            return "leaf.fill"
        case "bell_pepper":
            return "diamond.fill" // Represents pepper shape
        case "carrot":
            return "triangle.fill" // Represents carrot shape
        default:
            return "leaf.fill"
        }
    }
}

struct AddPlantCard: View {
    @State private var showingAddPlant = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Text("Add Plant")
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .onTapGesture {
            showingAddPlant = true
        }
        .sheet(isPresented: $showingAddPlant) {
            AddPlantView()
        }
    }
}

struct AddPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: AddPlantMethod = .scan
    @State private var plantName = ""
    @State private var plantType = ""
    @State private var location = ""
    @State private var showingCamera = false
    
    enum AddPlantMethod: String, CaseIterable {
        case scan = "Scan Plant"
        case manual = "Add Manually"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Method Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("How would you like to add your plant?")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        ForEach(AddPlantMethod.allCases, id: \.self) { method in
                            MethodSelectionCard(
                                method: method,
                                isSelected: selectedMethod == method
                            ) {
                                selectedMethod = method
                            }
                        }
                    }
                }
                
                if selectedMethod == .scan {
                    ScanPlantSection(showingCamera: $showingCamera)
                } else {
                    ManualPlantSection(
                        plantName: $plantName,
                        plantType: $plantType,
                        location: $location
                    )
                }
                
                Spacer()
                
                // Action Button
                Button(action: {
                    if selectedMethod == .scan {
                        showingCamera = true
                    } else {
                        // Handle manual plant addition
                        addPlantManually()
                    }
                }) {
                    HStack {
                        Image(systemName: selectedMethod == .scan ? "camera.fill" : "plus.circle.fill")
                        Text(selectedMethod == .scan ? "Start Scanning" : "Add Plant")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .disabled(selectedMethod == .manual && (plantName.isEmpty || plantType.isEmpty))
            }
            .padding()
            .navigationTitle("Add New Plant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView()
        }
    }
    
    private func addPlantManually() {
        // Handle manual plant addition logic here
        print("Adding plant: \(plantName), Type: \(plantType), Location: \(location)")
        dismiss()
    }
}

struct MethodSelectionCard: View {
    let method: AddPlantView.AddPlantMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: method == .scan ? "camera.viewfinder" : "pencil.and.outline")
                .font(.system(size: 32))
                .foregroundColor(isSelected ? .green : .gray)
            
            Text(method.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .green : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            action()
        }
    }
}

struct ScanPlantSection: View {
    @Binding var showingCamera: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Smart Plant Recognition")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Point your camera at the plant and we'll automatically identify the species, care requirements, and optimal growing conditions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                FeatureItem(icon: "leaf.fill", text: "Species ID")
                FeatureItem(icon: "drop.fill", text: "Care Tips")
                FeatureItem(icon: "sun.max.fill", text: "Light Needs")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ManualPlantSection: View {
    @Binding var plantName: String
    @Binding var plantType: String
    @Binding var location: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Plant Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("e.g., My Tomato Plant", text: $plantName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Plant Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("e.g., Cherry Tomato", text: $plantType)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("e.g., Greenhouse A", text: $location)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Camera viewfinder placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                
                                Text("Position plant in frame")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        )
                    
                    Spacer()
                    
                    // Camera controls
                    HStack(spacing: 60) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Simulate plant scan
                            captureAndAnalyzePlant()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 3)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func captureAndAnalyzePlant() {
        // Simulate plant analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// MARK: - Live View Components

struct LiveViewCard: View {
    @State private var showingLiveView = false
    @State private var cameraConfigured = false // This would be managed by app state in production
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: cameraConfigured ? "video.fill" : "video.slash.fill")
                    .font(.title3)
                    .foregroundColor(cameraConfigured ? .green : .orange)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cameraConfigured ? "LIVE" : "Setup")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Live View")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.08), radius: 1)
        .onTapGesture {
            showingLiveView = true
        }
        .sheet(isPresented: $showingLiveView) {
            if cameraConfigured {
                LiveViewInterface()
            } else {
                CameraSetupFlow(isConfigured: $cameraConfigured)
            }
        }
    }
}

struct CameraSetupFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isConfigured: Bool
    @State private var currentStep = 0
    @State private var cameraName = ""
    @State private var selectedLocation = "Garden Overview"
    @State private var wifiNetwork = ""
    @State private var wifiPassword = ""
    
    let setupSteps = [
        "Connect Camera",
        "Configure Network",
        "Set Location",
        "Test Connection"
    ]
    
    let locationOptions = [
        "Garden Overview",
        "Greenhouse A",
        "Greenhouse B",
        "Outdoor Plot 1",
        "Outdoor Plot 2",
        "Custom Location"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Progress indicator
                VStack(spacing: 12) {
                    HStack {
                        ForEach(0..<setupSteps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                            
                            if index < setupSteps.count - 1 {
                                Rectangle()
                                    .fill(index < currentStep ? Color.green : Color.gray.opacity(0.3))
                                    .frame(height: 2)
                            }
                        }
                    }
                    
                    Text("Step \(currentStep + 1) of \(setupSteps.count): \(setupSteps[currentStep])")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        ConnectCameraStep(cameraName: $cameraName)
                    case 1:
                        ConfigureNetworkStep(wifiNetwork: $wifiNetwork, wifiPassword: $wifiPassword)
                    case 2:
                        SetLocationStep(selectedLocation: $selectedLocation, locationOptions: locationOptions)
                    case 3:
                        TestConnectionStep()
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == setupSteps.count - 1 ? "Complete Setup" : "Continue") {
                        if currentStep == setupSteps.count - 1 {
                            completeSetup()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                    .disabled(!canProceed)
                }
            }
            .padding()
            .navigationTitle("Camera Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !cameraName.isEmpty
        case 1:
            return !wifiNetwork.isEmpty && !wifiPassword.isEmpty
        case 2:
            return !selectedLocation.isEmpty
        case 3:
            return true
        default:
            return false
        }
    }
    
    private func completeSetup() {
        // Simulate setup completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isConfigured = true
            dismiss()
        }
    }
}

struct ConnectCameraStep: View {
    @Binding var cameraName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Connect Your Garden Camera")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect your external camera to monitor your garden remotely. Make sure your camera is powered on and in pairing mode.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Camera Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("e.g., Main Garden Camera", text: $cameraName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

struct ConfigureNetworkStep: View {
    @Binding var wifiNetwork: String
    @Binding var wifiPassword: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Configure Network")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect your camera to your Wi-Fi network to enable remote monitoring and streaming.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wi-Fi Network")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Network Name", text: $wifiNetwork)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Wi-Fi Password", text: $wifiPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
}

struct SetLocationStep: View {
    @Binding var selectedLocation: String
    let locationOptions: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Set Camera Location")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose where your camera is positioned to help organize your garden monitoring.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Camera Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(locationOptions, id: \.self) { location in
                        Button(action: {
                            selectedLocation = location
                        }) {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(selectedLocation == location ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedLocation == location ? Color.green : Color(.systemGray6))
                                )
                        }
                    }
                }
            }
        }
    }
}

struct TestConnectionStep: View {
    @State private var testingConnection = false
    @State private var connectionSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: connectionSuccess ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(connectionSuccess ? .green : .orange)
                .scaleEffect(testingConnection ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: testingConnection)
            
            VStack(spacing: 12) {
                Text(connectionSuccess ? "Connection Successful!" : "Test Connection")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(connectionSuccess ? 
                     "Your camera is connected and ready to stream live video from your garden." :
                     "We'll test the connection to your camera and verify the video stream is working properly.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !connectionSuccess {
                Button("Test Connection") {
                    testConnection()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(testingConnection)
            }
        }
        .onAppear {
            // Auto-start connection test
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                testConnection()
            }
        }
    }
    
    private func testConnection() {
        testingConnection = true
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            testingConnection = false
            connectionSuccess = true
        }
    }
}

struct LiveViewInterface: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isFullScreen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // Live video placeholder
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        
                        VStack(spacing: 16) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            Text("Garden Overview")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .cornerRadius(12)
                    .onTapGesture {
                        isFullScreen.toggle()
                    }
                    
                    if !isFullScreen {
                        // Camera controls
                        HStack(spacing: 24) {
                            ControlButton(icon: "speaker.wave.2.fill", label: "Audio")
                            ControlButton(icon: "record.circle", label: "Record")
                            ControlButton(icon: "camera.fill", label: "Snapshot")
                            ControlButton(icon: "gearshape.fill", label: "Settings")
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(isFullScreen ? 0 : 16)
            }
            .navigationTitle(isFullScreen ? "" : "Live Garden View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isFullScreen)
            .toolbar {
                if !isFullScreen {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .onTapGesture {
            if isFullScreen {
                isFullScreen = false
            }
        }
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {}) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct PlantCard: View {
    let name: String
    let variety: String
    let location: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(variety)
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
                
                Text(location)
                    .font(.caption)
                
                Spacer()
                
                Text(status)
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

struct SensorCard: View {
    let name: String
    let type: String
    let value: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(status == "Active" ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
            
            HStack {
                Text(value)
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

struct TemperatureSensorCard: View {
    @EnvironmentObject var appSettings: AppSettings
    let name: String
    let type: String
    let celsiusValue: Double
    let status: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(status == "Active" ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
            
            HStack {
                Text(appSettings.formatTemperature(celsiusValue))
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

struct ActivityRow: View {
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

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

