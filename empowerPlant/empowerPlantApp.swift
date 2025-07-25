//
//  empowerPlantApp.swift
//  empowerPlant
//
//  Created by Nicholas Weiner on 7/24/25.
//

import SwiftUI

@main
struct empowerPlantApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appSettings)
        }
    }
}
