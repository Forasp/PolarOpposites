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
    @State private var showOpenProjectPanel = false
    private static var currentProject: ProjectInformation? = nil  // Holds the current project, nil by default
    
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
            ContentView(showCreateProjectSheet:$showCreateProjectSheet,
                        currentProject: .constant(GiskardApp.currentProject), showOpenProjectPanel:$showOpenProjectPanel)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Create Project") {
                    showCreateProjectSheet = true
                }
                .keyboardShortcut("N", modifiers: [.command, .shift])
                
                Button("Open Project") {
                    showOpenProjectPanel = true
                }
                .keyboardShortcut("O", modifiers: [.command, .shift])
            }
        }
    }
    
    public static func loadProject(_ project: ProjectInformation) {
        // TODO : Handle case where there's an existing project.
        currentProject = project;
        NotificationCenter.default.post(name: .projectLoaded, object: nil)
    }
    
    public static func getProject() -> ProjectInformation {
        if (currentProject == nil)
        {
            currentProject = ProjectInformation();
        }
        
        return currentProject!;
    }
}
