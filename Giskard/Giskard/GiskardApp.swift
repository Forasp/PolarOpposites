//
//  GiskardApp.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI
import SwiftData

@main
struct GiskardApp: App {
    @State private var showCreateProjectSheet:Bool = false
    
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
            ContentView(showCreateProjectSheet:$showCreateProjectSheet)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Create Project") {
                    showCreateProjectSheet = true
                }
                .keyboardShortcut("N", modifiers: [.command, .shift])
            }
        }
    }
}
