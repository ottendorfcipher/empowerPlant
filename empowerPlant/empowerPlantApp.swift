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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
