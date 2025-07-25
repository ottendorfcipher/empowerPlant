//
//  ContentView.swift
//  EmpowerPlant
//
//  Created by Warp AI.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.green)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationViewModel())
            .environmentObject(SensorDataStore())
            .environmentObject(WeatherDataStore())
            .environmentObject(PlantDataStore())
            .environmentObject(IrrigationManager())
    }
}
