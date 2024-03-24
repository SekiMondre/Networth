//
//  NetworthApp.swift
//  Networth
//
//  Created by André Vants on 16/01/24.
//

import SwiftUI
import SwiftData

@main
struct NetworthApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
//            ContentView()
//            AssetAllocationView(controller: AssetAllocationController(type: .crypto))
        }
        .modelContainer(sharedModelContainer)
    }
}
