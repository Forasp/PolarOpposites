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
    @State static var mainInspectorType:InspectorTypes = InspectorTypes.EntityInspector
    @State static var mainSelectedEntity:Entity? = nil
    @State var updater: Bool = false
    
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
                        currentProject: .constant(GiskardApp.currentProject), showOpenProjectPanel:$showOpenProjectPanel, inspectorType: .constant(GiskardApp.mainInspectorType), selectedEntity: .constant(GiskardApp.mainSelectedEntity))
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
                Button("Force Refresh") {
                    updater.toggle()
                }
                .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF5FunctionKey)!)))
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
    
    public static func selectEntity(_ entity: Entity) {
        mainSelectedEntity = entity
        mainInspectorType = .EntityInspector
    }
    
    public static func deselectEntity() {
        mainSelectedEntity = nil
    }
}
