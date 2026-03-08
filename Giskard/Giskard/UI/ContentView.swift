//
//  ContentView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI
import SwiftData
import Renderer

enum InspectorTypes {
    case EntityInspector
    case ImageInspector
    case SceneInspector

    init?(notificationValue: String) {
        switch notificationValue {
        case "entity":
            self = .EntityInspector
        case "image":
            self = .ImageInspector
        case "scene":
            self = .SceneInspector
        default:
            return nil
        }
    }

    var notificationValue: String {
        switch self {
        case .EntityInspector:
            return "entity"
        case .ImageInspector:
            return "image"
        case .SceneInspector:
            return "scene"
        }
    }
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
    @State private var projectLoadedObserver: NSObjectProtocol?
    @State private var inspectorSelectionObserver: NSObjectProtocol?
    @State private var activeInspectorType: InspectorTypes = .EntityInspector
    @State private var sceneExplorerHeight: CGFloat = 220
    @State private var automationStatus: String? = nil
    
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
                SceneWorkspaceView(sceneExplorerHeight: $sceneExplorerHeight)
            }
            .sheet(isPresented: $showCreateProjectSheet) {
                CreateProjectView()
            }
            .onAppear {
                onProjectLoaded()
                activeInspectorType = GiskardApp.mainInspectorType
                TestAutomationRunner.startIfNeeded { status in
                    automationStatus = status
                }
                projectLoadedObserver = NotificationCenter.default.addObserver(forName: .projectLoaded, object: nil, queue: .main) { _ in
                    self.onProjectLoaded()
                }
                inspectorSelectionObserver = NotificationCenter.default.addObserver(forName: .inspectorSelectionChanged, object: nil, queue: .main) { notification in
                    if let rawValue = notification.userInfo?["inspectorType"] as? String,
                       let parsedType = InspectorTypes(notificationValue: rawValue) {
                        self.activeInspectorType = parsedType
                    } else {
                        self.activeInspectorType = GiskardApp.mainInspectorType
                    }
                    self.showInspector = true
                }
            }
            .onDisappear {
                if let observer = projectLoadedObserver {
                    NotificationCenter.default.removeObserver(observer)
                    projectLoadedObserver = nil
                }
                if let observer = inspectorSelectionObserver {
                    NotificationCenter.default.removeObserver(observer)
                    inspectorSelectionObserver = nil
                }
            }
            .fileImporter(
                isPresented: $showOpenProjectPanel,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    FileSys.shared.SetRootURL(url: url)
                    _ = GiskardApp.loadProjectFromDirectory(url)
                }
            }
            .navigationTitle(loadedProjectName)
            .inspector(isPresented:$showInspector){
                if (showInspector){
                    switch(activeInspectorType) {
                    case InspectorTypes.EntityInspector:
                        EntityEditorView()
                    case InspectorTypes.ImageInspector:
                        ImageInspectorView()
                    case InspectorTypes.SceneInspector:
                        SceneInspectorView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .bottomLeading) {
                if let automationStatus {
                    Text(automationStatus)
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("automationStatusText")
                }
            }
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

private struct SceneWorkspaceView: View {
    @Binding var sceneExplorerHeight: CGFloat

    private let dividerHeight: CGFloat = 8
    private let minRendererHeight: CGFloat = 180
    private let minExplorerHeight: CGFloat = 120
    @State private var dragStartHeight: CGFloat?
    @State private var renderDiagnostics = RendererFrameSnapshot()

    private var renderDiagnosticsText: String {
        let cameraValue = renderDiagnostics.hasCameraCommand ? "yes" : "no"
        let issueCount = renderDiagnostics.issues.count
        return "Render 2D=\(renderDiagnostics.renderable2DCount) 3D=\(renderDiagnostics.renderable3DCount) camera=\(cameraValue) issues=\(issueCount)"
    }

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            let maxExplorerHeight = max(minExplorerHeight, totalHeight - dividerHeight - minRendererHeight)
            let clampedExplorerHeight = min(max(sceneExplorerHeight, minExplorerHeight), maxExplorerHeight)
            let rendererHeight = max(minRendererHeight, totalHeight - dividerHeight - clampedExplorerHeight)

            VStack(spacing: 0) {
                SceneRenderView { snapshot in
                    renderDiagnostics = snapshot
                }
                .frame(maxWidth: .infinity)
                .frame(height: rendererHeight)
                .overlay(alignment: .topLeading) {
                    Text(renderDiagnosticsText)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.28))
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("renderDiagnosticsText")
                        .padding(8)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.16))
                    .frame(height: dividerHeight)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if dragStartHeight == nil {
                                    dragStartHeight = clampedExplorerHeight
                                }

                                let startingHeight = dragStartHeight ?? clampedExplorerHeight
                                let proposedHeight = startingHeight - value.translation.height
                                sceneExplorerHeight = min(max(proposedHeight, minExplorerHeight), maxExplorerHeight)
                            }
                            .onEnded { _ in
                                dragStartHeight = nil
                            }
                    )

                SceneBrowserView()
                    .frame(maxWidth: .infinity)
                    .frame(height: clampedExplorerHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView(showCreateProjectSheet: .constant(false), currentProject: .constant(nil), showOpenProjectPanel: .constant(false), inspectorType: .constant(.EntityInspector))
        .modelContainer(for: Item.self, inMemory: true)
}

extension Notification.Name {
    static let projectLoaded = Notification.Name("projectLoaded")
    static let inspectorSelectionChanged = Notification.Name("inspectorSelectionChanged")
    static let sceneFileUpdated = Notification.Name("sceneFileUpdated")
}
