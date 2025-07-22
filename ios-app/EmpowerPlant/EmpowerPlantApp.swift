import SwiftUI

@main
struct EmpowerPlantApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var sensorDataStore = SensorDataStore()
    @StateObject private var weatherDataStore = WeatherDataStore()
    @StateObject private var plantDataStore = PlantDataStore()
    @StateObject private var irrigationManager = IrrigationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(sensorDataStore)
                .environmentObject(weatherDataStore)
                .environmentObject(plantDataStore)
                .environmentObject(irrigationManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize WebSocket connections for real-time data
        if authViewModel.isAuthenticated {
            sensorDataStore.startRealTimeUpdates()
            weatherDataStore.startRealTimeUpdates()
            plantDataStore.startRealTimeUpdates()
        }
        
        // Configure app settings
        configureAppearance()
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}
