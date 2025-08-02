//
//  ContentView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI
import SwiftData

enum InspectorTypes {
    case EntityInspector
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showCreateProjectSheet: Bool
    @Binding var currentProject: ProjectInformation?
    @Binding var showOpenProjectPanel: Bool
    @Binding var inspectorType:InspectorTypes
    @Query private var items: [Item]
    @State private var loadedProjectName: String = "Giskard"
    @State private var fileRoot: FileNode? = nil
    @State private var showInspector:Bool = false
    
    func onProjectLoaded() {
        fileRoot = nil;
        loadedProjectName = "Giskard";
        if let projectName = GiskardApp.getProject().projectName {
            loadedProjectName = projectName
        }
        
        if let projectPath = GiskardApp.getProject().projectPath{
            fileRoot = loadFileNode(projectPath)
        }
    }
    
    var body: some View {
        HStack{
            NavigationSplitView {
                if let fileRoot {
                    FileBrowserView(rootNode: fileRoot)
                } else {
                    Text("No Project Loaded")
                }
            } detail: {
                Text("Select an item")
            }
            .sheet(isPresented: $showCreateProjectSheet) {
                CreateProjectView()
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: .projectLoaded, object: nil, queue: .main) { _ in
                    self.onProjectLoaded()
                }
            }
            .fileImporter(
                isPresented: $showOpenProjectPanel,
                allowedContentTypes: [.folder], // or UTType.json if you prefer
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    do {
                        FileSys.shared.SetRootURL(url: url)
                        if let data = FileSys.shared.ReadFile(url.appendingPathComponent("Giskard_Project_Settings").path){
                            let loadedProject = try JSONDecoder().decode(ProjectInformation.self, from: data)
                            loadedProject.projectPath = url;
                            GiskardApp.loadProject(loadedProject)
                        }
                    } catch {
                        print("Failed to load project: \(error)")
                    }
                }
            }
            .navigationTitle(loadedProjectName)
            .inspector(isPresented:$showInspector){
                if (showInspector){
                    switch(inspectorType) {
                    case InspectorTypes.EntityInspector:
                        EntityEditorView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .toolbar{
            Button(action: { showInspector.toggle() }) {
                Label("Toggle Inspector", systemImage: "sidebar.right")
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView(showCreateProjectSheet: .constant(false), currentProject: .constant(nil), showOpenProjectPanel: .constant(false), inspectorType: .constant(.EntityInspector))
        .modelContainer(for: Item.self, inMemory: true)
}

extension Notification.Name {
    static let projectLoaded = Notification.Name("projectLoaded")
}
