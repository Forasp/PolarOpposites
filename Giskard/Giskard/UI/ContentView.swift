//
//  ContentView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showCreateProjectSheet: Bool
    @Binding var currentProject: ProjectInformation?
    @Binding var showOpenProjectPanel: Bool
    @Query private var items: [Item]
    @State private var loadedProjectName: String = "Giskard"
    
    func onProjectLoaded() {
        if let projectName = GiskardApp.getProject().projectName
        {
            loadedProjectName = projectName
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
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
            allowedContentTypes: [.data], // or UTType.json if you prefer
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                var didStart = url.startAccessingSecurityScopedResource()
                defer {
                    if didStart {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    let data = try Data(contentsOf: url)
                    let loadedProject = try JSONDecoder().decode(ProjectInformation.self, from: data)
                    GiskardApp.loadProject(loadedProject)
                } catch {
                    print("Failed to load project: \(error)")
                }
            }
        }
        .navigationTitle(loadedProjectName)
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
    ContentView(showCreateProjectSheet: .constant(false), currentProject: .constant(nil), showOpenProjectPanel: .constant(false))
        .modelContainer(for: Item.self, inMemory: true)
}

extension Notification.Name {
    static let projectLoaded = Notification.Name("projectLoaded")
}
