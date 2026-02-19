//
//  GiskardApp.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI
import SwiftData

fileprivate extension Scene {
    func disableRestorationBehavior() -> some Scene {
        if #available(macOS 15.0, *) {
            return self.restorationBehavior(.disabled)
        } else {
            return self
        }
    }
}

@main
struct GiskardApp: App {
    @State private var showCreateProjectSheet:Bool = false
    @State private var showOpenProjectPanel = false
    private static var currentProject: ProjectInformation? = nil  // Holds the current project, nil by default
    static var mainInspectorType:InspectorTypes = InspectorTypes.EntityInspector
    @State var updater: Bool = false
    static var selectedEntities:[Entity] = []
    static var selectedEntityFileURL: URL? = nil
    static var selectedImageFileURL: URL? = nil
    static var entityFileURLs: [UUID: URL] = [:]
    private static let recentProjectsDefaultsKey = "giskard.recentProjectPaths"
    private static let recentProjectsBookmarksKey = "giskard.recentProjectBookmarks"
    
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
        // Welcome first
        WindowGroup("Welcome", id: "welcome") {
            WelcomeView(showCreateProjectSheet:$showCreateProjectSheet)
        }
        .disableRestorationBehavior()
        
        WindowGroup("Editor", id: "editor") {
            ContentView(showCreateProjectSheet:$showCreateProjectSheet,
                        currentProject: .constant(GiskardApp.currentProject), showOpenProjectPanel:$showOpenProjectPanel, inspectorType: .constant(GiskardApp.mainInspectorType))
        }
        .disableRestorationBehavior()
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
        if let projectPath = project.projectPath {
            recordRecentProject(projectPath)
        }
        NotificationCenter.default.post(name: .projectLoaded, object: nil)
    }
    
    public static func getProject() -> ProjectInformation {
        if (currentProject == nil)
        {
            currentProject = ProjectInformation();
        }
        
        return currentProject!;
    }
    
    public static func selectEntity(_ entity: Entity, fileURL: URL? = nil) {
        if let fileURL {
            entityFileURLs[entity.id] = fileURL
        }
        selectedImageFileURL = nil
        selectedEntityFileURL = entityFileURLs[entity.id]
        selectedEntities.insert(entity, at: 0)
        mainInspectorType = .EntityInspector
        // Todo: update flag?
        // Deselect previous entity
        if (selectedEntities.count > 1)
        {
            deselectEntity(selectedEntities[selectedEntities.count-1])
        }
        NotificationCenter.default.post(
            name: .inspectorSelectionChanged,
            object: nil,
            userInfo: ["inspectorType": InspectorTypes.EntityInspector.notificationValue]
        )
    }
    
    public static func deselectEntity(_ entity: Entity) {
        for i in 0..<selectedEntities.count {
            if (selectedEntities[i].id == entity.id) {
                selectedEntities.remove(at: i)
                if selectedEntities.isEmpty {
                    selectedEntityFileURL = nil
                }
                return
            }
        }
    }

    public static func selectImage(_ fileURL: URL) {
        selectedImageFileURL = fileURL
        selectedEntityFileURL = nil
        selectedEntities.removeAll()
        mainInspectorType = .ImageInspector
        NotificationCenter.default.post(
            name: .inspectorSelectionChanged,
            object: nil,
            userInfo: ["inspectorType": InspectorTypes.ImageInspector.notificationValue]
        )
    }

    public static func recentProjectURLs() -> [URL] {
        let storedPaths = UserDefaults.standard.stringArray(forKey: recentProjectsDefaultsKey) ?? []
        return storedPaths
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    public static func recordRecentProject(_ url: URL) {
        let normalizedPath = url.standardizedFileURL.path
        var storedPaths = UserDefaults.standard.stringArray(forKey: recentProjectsDefaultsKey) ?? []
        storedPaths.removeAll { $0 == normalizedPath }
        storedPaths.insert(normalizedPath, at: 0)
        storedPaths = Array(storedPaths.prefix(5))
        UserDefaults.standard.set(storedPaths, forKey: recentProjectsDefaultsKey)

        var bookmarks = UserDefaults.standard.dictionary(forKey: recentProjectsBookmarksKey) as? [String: Data] ?? [:]
        if let bookmarkData = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
            bookmarks[normalizedPath] = bookmarkData
        }
        let validPathSet = Set(storedPaths)
        bookmarks = bookmarks.filter { validPathSet.contains($0.key) }
        UserDefaults.standard.set(bookmarks, forKey: recentProjectsBookmarksKey)
    }

    public static func resolveRecentProjectURL(_ url: URL) -> URL {
        let normalizedPath = url.standardizedFileURL.path
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: recentProjectsBookmarksKey) as? [String: Data],
              let bookmarkData = bookmarks[normalizedPath] else {
            return url
        }

        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return url
        }

        if isStale {
            recordRecentProject(resolvedURL)
        }

        return resolvedURL
    }

    public static func fileURL(for entityID: UUID) -> URL? {
        entityFileURLs[entityID]
    }

    public static func loadProjectFromDirectory(_ folderURL: URL) -> Bool {
        do {
            guard let settingsURL = findProjectSettingsFile(in: folderURL) else {
                print("Selected folder is not a Giskard project: \(folderURL.path)")
                return false
            }

            let data = try Data(contentsOf: settingsURL)
            let project = try JSONDecoder().decode(ProjectInformation.self, from: data)
            project.projectPath = folderURL
            loadProject(project)
            return true
        } catch {
            print("Failed to load project: \(error)")
            return false
        }
    }

    private static func findProjectSettingsFile(in folderURL: URL) -> URL? {
        let exactSettingsURL = folderURL.appendingPathComponent("Giskard_Project_Settings")
        if FileManager.default.fileExists(atPath: exactSettingsURL.path) {
            return exactSettingsURL
        }

        guard let directoryItems = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return nil
        }

        return directoryItems.first { url in
            let name = url.lastPathComponent
            let isSettingsLikeName = name.hasPrefix("Giskard_Project")
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return isSettingsLikeName && !isDirectory
        }
    }
}
