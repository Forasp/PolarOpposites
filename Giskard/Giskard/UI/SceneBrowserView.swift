//
//  SceneBrowserView.swift
//  Giskard
//

import SwiftUI
import UniformTypeIdentifiers

struct SceneBrowserView: View {
    @State private var sceneURL: URL? = GiskardApp.selectedSceneFileURL
    @State private var scene: SceneFile? = nil
    @State private var selectedPath: [UUID] = []
    @State private var loadError: String? = nil

    private let columnWidth: CGFloat = 160

    private var columns: [[SceneEntityNode]] {
        guard let scene else { return [] }

        var result: [[SceneEntityNode]] = [scene.entities]
        var currentLevel = scene.entities

        for selectedID in selectedPath {
            guard let selectedNode = currentLevel.first(where: { $0.id == selectedID }) else {
                break
            }
            guard !selectedNode.children.isEmpty else {
                break
            }
            result.append(selectedNode.children)
            currentLevel = selectedNode.children
        }

        return result
    }

    var body: some View {
        Group {
            if let loadError {
                Text(loadError)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
            } else if scene == nil {
                Text("Select a .scene file to browse entities.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(columns.enumerated()), id: \.offset) { depth, nodes in
                            SceneBrowserColumn(
                                nodes: nodes,
                                selectedID: selectedPath.indices.contains(depth) ? selectedPath[depth] : nil,
                                onSelect: { selectedNode in
                                    selectNode(selectedNode, at: depth)
                                },
                                onDropOnNode: { targetNode, providers in
                                    handleDropOnNode(targetNode, providers: providers)
                                },
                                onDropAsSiblingAfter: { targetNode, providers in
                                    handleDropAsSiblingAfter(targetNode, providers: providers)
                                },
                                onDropInColumn: { providers in
                                    handleDropInColumn(depth: depth, providers: providers)
                                }
                            )
                            .frame(width: columnWidth)
                            .frame(maxHeight: .infinity)

                            if depth < columns.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .background(Color.black.opacity(0.18))
        .onAppear {
            if let selectedSceneURL = GiskardApp.selectedSceneFileURL {
                loadScene(from: selectedSceneURL)
            } else if let sceneURL {
                loadScene(from: sceneURL)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .inspectorSelectionChanged)) { _ in
            handleInspectorSelectionChanged()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sceneFileUpdated)) { notification in
            guard let updatedSceneURL = notification.userInfo?["sceneURL"] as? URL else {
                return
            }
            guard updatedSceneURL == sceneURL else {
                return
            }
            loadScene(from: updatedSceneURL, preserveSelectionPath: true)
        }
    }

    private func handleInspectorSelectionChanged() {
        // Preserve currently loaded scene unless a scene file was explicitly selected.
        guard let selectedSceneURL = GiskardApp.selectedSceneFileURL else {
            return
        }
        guard selectedSceneURL != sceneURL else {
            return
        }
        loadScene(from: selectedSceneURL)
    }

    private func loadScene(from sceneURL: URL, preserveSelectionPath: Bool = false) {
        let previousSelection = selectedPath
        self.sceneURL = sceneURL
        guard let data = FileSys.shared.ReadFile(sceneURL.path) else {
            scene = nil
            selectedPath = []
            loadError = "Unable to read scene file."
            return
        }

        guard let decodedScene = try? JSONDecoder().decode(SceneFile.self, from: data) else {
            scene = nil
            selectedPath = []
            loadError = "Unable to parse scene file."
            return
        }

        scene = decodedScene
        loadError = nil
        if preserveSelectionPath {
            selectedPath = validatedSelectionPath(previousSelection, in: decodedScene)
        } else {
            selectedPath.removeAll()
        }
    }

    private func selectNode(_ node: SceneEntityNode, at depth: Int) {
        if selectedPath.count > depth {
            selectedPath[depth] = node.id
            selectedPath = Array(selectedPath.prefix(depth + 1))
        } else {
            selectedPath.append(node.id)
        }
        if let sceneURL {
            GiskardApp.selectSceneNode(node, sceneURL: sceneURL)
        }
    }

    private func validatedSelectionPath(_ path: [UUID], in scene: SceneFile) -> [UUID] {
        guard !path.isEmpty else { return [] }

        var validated: [UUID] = []
        var currentLevel = scene.entities

        for id in path {
            guard let matchingNode = currentLevel.first(where: { $0.id == id }) else {
                break
            }
            validated.append(id)
            currentLevel = matchingNode.children
        }

        return validated
    }

    private func handleDropOnNode(_ targetNode: SceneEntityNode, providers: [NSItemProvider]) -> Bool {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let didInsert = insertChildNode(into: &currentScene.entities, parentID: targetNode.id, child: uniqueNode)
            guard didInsert else { return }
            scene = currentScene
            persistSceneChanges()
        }
    }

    private func handleDropAsSiblingAfter(_ targetNode: SceneEntityNode, providers: [NSItemProvider]) -> Bool {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let didInsert = insertSiblingNode(into: &currentScene.entities, afterNodeID: targetNode.id, sibling: uniqueNode)
            guard didInsert else { return }
            scene = currentScene
            persistSceneChanges()
        }
    }

    private func handleDropInColumn(depth: Int, providers: [NSItemProvider]) -> Bool {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let parentID = depth == 0 ? nil : (selectedPath.indices.contains(depth - 1) ? selectedPath[depth - 1] : nil)

            if let parentID {
                let didInsert = insertChildNode(into: &currentScene.entities, parentID: parentID, child: uniqueNode)
                guard didInsert else { return }
            } else {
                currentScene.entities.append(uniqueNode)
            }

            scene = currentScene
            persistSceneChanges()
        }
    }

    private func withDroppedSceneNode(from providers: [NSItemProvider], onNode: @escaping (SceneEntityNode) -> Void) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let pathString = object as? String else {
                return
            }

            let fileURL = URL(fileURLWithPath: pathString)
            guard fileURL.pathExtension.lowercased() == "entity",
                  let data = FileSys.shared.ReadFile(fileURL.path),
                  let entity = try? JSONDecoder().decode(Entity.self, from: data) else {
                return
            }

            let node = SceneEntityNode(
                id: entity.id,
                name: entity.name,
                isPhysical: entity.isPhysical,
                position: [entity.position.x, entity.position.y, entity.position.z],
                rotation: [entity.rotation.vector.x, entity.rotation.vector.y, entity.rotation.vector.z, entity.rotation.vector.w],
                capabilities: entity.capabilities,
                children: []
            )

            DispatchQueue.main.async {
                onNode(node)
            }
        }

        return true
    }

    private func insertChildNode(into nodes: inout [SceneEntityNode], parentID: UUID, child: SceneEntityNode) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == parentID {
                nodes[index].children.append(child)
                return true
            }
            if insertChildNode(into: &nodes[index].children, parentID: parentID, child: child) {
                return true
            }
        }
        return false
    }

    private func insertSiblingNode(into nodes: inout [SceneEntityNode], afterNodeID: UUID, sibling: SceneEntityNode) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == afterNodeID {
                nodes.insert(sibling, at: index + 1)
                return true
            }
            if insertSiblingNode(into: &nodes[index].children, afterNodeID: afterNodeID, sibling: sibling) {
                return true
            }
        }
        return false
    }

    private func nodeWithUniqueID(_ node: SceneEntityNode, in scene: SceneFile) -> SceneEntityNode {
        var result = node
        let existingIDs = Set(allNodeIDs(in: scene.entities))
        while existingIDs.contains(result.id) {
            result.id = UUID()
        }
        return result
    }

    private func allNodeIDs(in nodes: [SceneEntityNode]) -> [UUID] {
        var ids: [UUID] = []
        for node in nodes {
            ids.append(node.id)
            ids.append(contentsOf: allNodeIDs(in: node.children))
        }
        return ids
    }

    private func persistSceneChanges() {
        guard let sceneURL, let scene else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(scene) else { return }
        _ = FileSys.shared.WriteFile(sceneURL.path, data: data)
    }
}

private struct SceneBrowserColumn: View {
    let nodes: [SceneEntityNode]
    let selectedID: UUID?
    let onSelect: (SceneEntityNode) -> Void
    let onDropOnNode: (SceneEntityNode, [NSItemProvider]) -> Bool
    let onDropAsSiblingAfter: (SceneEntityNode, [NSItemProvider]) -> Bool
    let onDropInColumn: ([NSItemProvider]) -> Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(nodes) { node in
                        Button {
                            onSelect(node)
                        } label: {
                            HStack {
                                Text(displayName(for: node.name))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                Spacer()
                                if !node.children.isEmpty {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (selectedID == node.id) ? Color.accentColor.opacity(0.32) : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                            onDropOnNode(node, providers)
                        }

                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 8)
                            .contentShape(Rectangle())
                            .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                                onDropAsSiblingAfter(node, providers)
                            }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(minHeight: geometry.size.height, alignment: .top)
                .contentShape(Rectangle())
                .padding(8)
                .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                    onDropInColumn(providers)
                }
            }
        }
    }

    private func displayName(for name: String) -> String {
        guard name.lowercased().hasSuffix(".entity") else {
            return name
        }
        return String(name.dropLast(".entity".count))
    }
}

#Preview {
    SceneBrowserView()
}
