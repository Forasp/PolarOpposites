//
//  SceneBrowserView.swift
//  Giskard
//

import SwiftUI
import UniformTypeIdentifiers
import GiskardEngine

struct SceneBrowserView: View {
    @State private var sceneURL: URL? = GiskardApp.selectedSceneFileURL
    @State private var scene: SceneFile? = nil
    @State private var selectedPath: [UUID] = []
    @State private var loadError: String? = nil
    @State private var copiedNode: SceneEntityNode? = nil
    @State private var renameTargetNodeID: UUID? = nil
    @State private var renameValue: String = ""
    @State private var showingRenamePrompt = false

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
                                selectedID: selectedPath.indices.contains(depth)
                                    ? selectedPath[depth] : nil,
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
                                },
                                onCopyNode: { node in
                                    copyNode(node)
                                },
                                onDuplicateNode: { node in
                                    duplicateNode(node)
                                },
                                onRenameNode: { node in
                                    beginRenaming(node)
                                },
                                onDeleteNode: { node in
                                    deleteNode(node)
                                },
                                onPasteInColumn: {
                                    pasteInColumn(depth: depth)
                                },
                                onCreateEntityInColumn: {
                                    createEntityInColumn(depth: depth)
                                },
                                canPasteInColumn: copiedNode != nil
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
        .alert(
            "Rename Entity",
            isPresented: $showingRenamePrompt,
            actions: {
                TextField("Entity Name", text: $renameValue)
                Button("Rename") {
                    applyRename()
                }
                Button("Cancel", role: .cancel) {
                    cancelRename()
                }
            }
        )
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

    private func handleDropOnNode(_ targetNode: SceneEntityNode, providers: [NSItemProvider])
        -> Bool
    {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let didInsert = insertChildNode(
                into: &currentScene.entities, parentID: targetNode.id, child: uniqueNode)
            guard didInsert else { return }
            scene = currentScene
            persistSceneChanges()
        }
    }

    private func handleDropAsSiblingAfter(
        _ targetNode: SceneEntityNode, providers: [NSItemProvider]
    ) -> Bool {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let didInsert = insertSiblingNode(
                into: &currentScene.entities, afterNodeID: targetNode.id, sibling: uniqueNode)
            guard didInsert else { return }
            scene = currentScene
            persistSceneChanges()
        }
    }

    private func handleDropInColumn(depth: Int, providers: [NSItemProvider]) -> Bool {
        withDroppedSceneNode(from: providers) { droppedNode in
            guard var currentScene = scene else { return }
            let uniqueNode = nodeWithUniqueID(droppedNode, in: currentScene)
            let parentID =
                depth == 0
                ? nil : (selectedPath.indices.contains(depth - 1) ? selectedPath[depth - 1] : nil)

            if let parentID {
                let didInsert = insertChildNode(
                    into: &currentScene.entities, parentID: parentID, child: uniqueNode)
                guard didInsert else { return }
            } else {
                currentScene.entities.append(uniqueNode)
            }

            scene = currentScene
            persistSceneChanges()
        }
    }

    private func withDroppedSceneNode(
        from providers: [NSItemProvider], onNode: @escaping (SceneEntityNode) -> Void
    ) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) })
        else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let pathString = object as? String else {
                return
            }

            let fileURL = URL(fileURLWithPath: pathString)
            guard fileURL.pathExtension.lowercased() == "entity",
                let data = FileSys.shared.ReadFile(fileURL.path),
                let entity = try? JSONDecoder().decode(Entity.self, from: data)
            else {
                return
            }

            let node = SceneEntityNode(
                id: UUID(),
                fileUUID: entity.fileUUID,
                name: entity.name,
                isPhysical: entity.isPhysical,
                position: [entity.position.x, entity.position.y, entity.position.z],
                rotation: [
                    entity.rotation.vector.x, entity.rotation.vector.y, entity.rotation.vector.z,
                    entity.rotation.vector.w,
                ],
                capabilities: entity.capabilities,
                children: []
            )

            DispatchQueue.main.async {
                onNode(node)
            }
        }

        return true
    }

    private func insertChildNode(
        into nodes: inout [SceneEntityNode], parentID: UUID, child: SceneEntityNode
    ) -> Bool {
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

    private func insertSiblingNode(
        into nodes: inout [SceneEntityNode], afterNodeID: UUID, sibling: SceneEntityNode
    ) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == afterNodeID {
                nodes.insert(sibling, at: index + 1)
                return true
            }
            if insertSiblingNode(
                into: &nodes[index].children, afterNodeID: afterNodeID, sibling: sibling)
            {
                return true
            }
        }
        return false
    }

    private func nodeWithUniqueID(_ node: SceneEntityNode, in scene: SceneFile) -> SceneEntityNode {
        var result = node
        let existingIDs = Set(allNodeIDs(in: scene.entities))
        while existingIDs.contains(result.id) || result.id == result.fileUUID {
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

    private func copyNode(_ node: SceneEntityNode) {
        copiedNode = node
    }

    private func duplicateNode(_ node: SceneEntityNode) {
        guard var currentScene = scene else { return }
        var duplicate = node
        assignNewIDsRecursively(&duplicate)

        let didInsert = insertSiblingNode(
            into: &currentScene.entities,
            afterNodeID: node.id,
            sibling: duplicate
        )
        guard didInsert else { return }

        scene = currentScene
        selectedPath = pathToNode(id: duplicate.id, in: currentScene.entities) ?? selectedPath
        if let sceneURL {
            GiskardApp.selectSceneNode(duplicate, sceneURL: sceneURL)
        }
        persistSceneChanges()
    }

    private func beginRenaming(_ node: SceneEntityNode) {
        renameTargetNodeID = node.id
        renameValue = node.name
        showingRenamePrompt = true
    }

    private func cancelRename() {
        renameTargetNodeID = nil
        renameValue = ""
    }

    private func applyRename() {
        guard let targetID = renameTargetNodeID else {
            cancelRename()
            return
        }
        let trimmedName = renameValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, var currentScene = scene else {
            cancelRename()
            return
        }

        let didRename = renameNode(in: &currentScene.entities, targetID: targetID, newName: trimmedName)
        guard didRename else {
            cancelRename()
            return
        }

        scene = currentScene
        persistSceneChanges()
        cancelRename()
    }

    private func deleteNode(_ node: SceneEntityNode) {
        guard var currentScene = scene else { return }
        let didDelete = removeNode(in: &currentScene.entities, targetID: node.id)
        guard didDelete else { return }

        scene = currentScene
        selectedPath = validatedSelectionPath(selectedPath, in: currentScene)
        persistSceneChanges()
    }

    private func pasteInColumn(depth: Int) {
        guard let copiedNode, var currentScene = scene else { return }
        var pastedNode = copiedNode
        assignNewIDsRecursively(&pastedNode)

        let parentID =
            depth == 0
            ? nil : (selectedPath.indices.contains(depth - 1) ? selectedPath[depth - 1] : nil)

        if let parentID {
            let didInsert = insertChildNode(
                into: &currentScene.entities, parentID: parentID, child: pastedNode)
            guard didInsert else { return }
        } else {
            currentScene.entities.append(pastedNode)
        }

        scene = currentScene
        selectedPath = pathToNode(id: pastedNode.id, in: currentScene.entities) ?? selectedPath
        if let sceneURL {
            GiskardApp.selectSceneNode(pastedNode, sceneURL: sceneURL)
        }
        persistSceneChanges()
    }

    private func createEntityInColumn(depth: Int) {
        guard var currentScene = scene else { return }
        let parentID =
            depth == 0
            ? nil : (selectedPath.indices.contains(depth - 1) ? selectedPath[depth - 1] : nil)

        let siblingNames: [String]
        if let parentID, let parentNode = findNode(id: parentID, in: currentScene.entities) {
            siblingNames = parentNode.children.map(\.name)
        } else {
            siblingNames = currentScene.entities.map(\.name)
        }

        let newNode = SceneEntityNode(
            name: uniqueEntityName(in: siblingNames)
        )

        if let parentID {
            let didInsert = insertChildNode(
                into: &currentScene.entities, parentID: parentID, child: newNode)
            guard didInsert else { return }
        } else {
            currentScene.entities.append(newNode)
        }

        scene = currentScene
        selectedPath = pathToNode(id: newNode.id, in: currentScene.entities) ?? selectedPath
        if let sceneURL {
            GiskardApp.selectSceneNode(newNode, sceneURL: sceneURL)
        }
        persistSceneChanges()
    }

    private func assignNewIDsRecursively(_ node: inout SceneEntityNode) {
        node.id = UUID()
        while node.id == node.fileUUID {
            node.id = UUID()
        }
        for index in node.children.indices {
            assignNewIDsRecursively(&node.children[index])
        }
    }

    private func removeNode(in nodes: inout [SceneEntityNode], targetID: UUID) -> Bool {
        if let index = nodes.firstIndex(where: { $0.id == targetID }) {
            nodes.remove(at: index)
            return true
        }
        for index in nodes.indices {
            if removeNode(in: &nodes[index].children, targetID: targetID) {
                return true
            }
        }
        return false
    }

    private func renameNode(in nodes: inout [SceneEntityNode], targetID: UUID, newName: String) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == targetID {
                nodes[index].name = newName
                return true
            }
            if renameNode(in: &nodes[index].children, targetID: targetID, newName: newName) {
                return true
            }
        }
        return false
    }

    private func findNode(id: UUID, in nodes: [SceneEntityNode]) -> SceneEntityNode? {
        for node in nodes {
            if node.id == id {
                return node
            }
            if let match = findNode(id: id, in: node.children) {
                return match
            }
        }
        return nil
    }

    private func pathToNode(id: UUID, in nodes: [SceneEntityNode]) -> [UUID]? {
        for node in nodes {
            if node.id == id {
                return [node.id]
            }
            if let childPath = pathToNode(id: id, in: node.children) {
                return [node.id] + childPath
            }
        }
        return nil
    }

    private func uniqueEntityName(in names: [String]) -> String {
        let baseName = "New Entity"
        guard names.contains(baseName) else {
            return baseName
        }

        var index = 2
        while names.contains("\(baseName) \(index)") {
            index += 1
        }
        return "\(baseName) \(index)"
    }
}

private struct SceneBrowserColumn: View {
    let nodes: [SceneEntityNode]
    let selectedID: UUID?
    let onSelect: (SceneEntityNode) -> Void
    let onDropOnNode: (SceneEntityNode, [NSItemProvider]) -> Bool
    let onDropAsSiblingAfter: (SceneEntityNode, [NSItemProvider]) -> Bool
    let onDropInColumn: ([NSItemProvider]) -> Bool
    let onCopyNode: (SceneEntityNode) -> Void
    let onDuplicateNode: (SceneEntityNode) -> Void
    let onRenameNode: (SceneEntityNode) -> Void
    let onDeleteNode: (SceneEntityNode) -> Void
    let onPasteInColumn: () -> Void
    let onCreateEntityInColumn: () -> Void
    let canPasteInColumn: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
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
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (selectedID == node.id)
                                    ? Color.accentColor.opacity(0.32) : Color.clear
                            )
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Copy") {
                                onCopyNode(node)
                            }
                            Button("Duplicate") {
                                onDuplicateNode(node)
                            }
                            Button("Rename") {
                                onRenameNode(node)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                onDeleteNode(node)
                            }
                        }
                        .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                            onDropOnNode(node, providers)
                        }

                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 4)
                            .contentShape(Rectangle())
                            .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) {
                                providers in
                                onDropAsSiblingAfter(node, providers)
                            }
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .padding(8)
                .onDrop(of: [UTType.plainText.identifier], isTargeted: nil) { providers in
                    onDropInColumn(providers)
                }
                .contextMenu {
                    Button("Paste") {
                        onPasteInColumn()
                    }
                    .disabled(!canPasteInColumn)

                    Button("Create New Entity") {
                        onCreateEntityInColumn()
                    }
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
