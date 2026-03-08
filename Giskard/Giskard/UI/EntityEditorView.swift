//
//  EntityEditorView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/28/25.
//

import Spatial
import SwiftUI
import UniformTypeIdentifiers
import GiskardEngine

struct EntityEditorView: View {
    @State var entity: Entity
    @State private var isDirty: Bool = false
    @State private var pitch: Double = 0
    @State private var yaw: Double = 0
    @State private var roll: Double = 0
    @State private var magnitude: Double = 0
    @State private var capabilityText: String = ""
    @State private var updateTask: Task<Void, Never>? = nil
    @State private var childCountText: String = "0"
    @State private var childEntryDisplayValues: [String] = []
    @State private var childEntryIDs: [UUID?] = []
    @State private var positionXText: String = "0"
    @State private var positionYText: String = "0"
    @State private var positionZText: String = "0"
    @State private var rotationXText: String = "0"
    @State private var rotationYText: String = "0"
    @State private var rotationZText: String = "0"
    @State private var rotationWText: String = "0"
    @State private var scriptPaths: [String] = []

    init() {
        if GiskardApp.selectedEntities.count > 0 {
            self.entity = GiskardApp.selectedEntities[0]
        } else {
            self.entity = Entity("Sample Entity")
        }
        self.isDirty = false
        self.pitch = self.entity.rotation.vector.x
        self.yaw = self.entity.rotation.vector.y
        self.roll = self.entity.rotation.vector.z
        self.magnitude = self.entity.rotation.vector.w
        self.capabilityText = self.entity.capabilities.joined(separator: ", ")
        self.childCountText = "\(self.entity.children.count)"
        self.childEntryDisplayValues = self.entity.childEntityPaths
        self.childEntryIDs = self.entity.children.map { Optional($0) }
        if self.childEntryDisplayValues.count < self.childEntryIDs.count {
            self.childEntryDisplayValues.append(
                contentsOf: Array(
                    repeating: "",
                    count: self.childEntryIDs.count - self.childEntryDisplayValues.count))
        } else if self.childEntryDisplayValues.count > self.childEntryIDs.count {
            self.childEntryDisplayValues = Array(
                self.childEntryDisplayValues.prefix(self.childEntryIDs.count))
        }
        self.positionXText = formatNumericText(self.entity.position.x)
        self.positionYText = formatNumericText(self.entity.position.y)
        self.positionZText = formatNumericText(self.entity.position.z)
        self.rotationXText = formatNumericText(self.entity.rotation.vector.x)
        self.rotationYText = formatNumericText(self.entity.rotation.vector.y)
        self.rotationZText = formatNumericText(self.entity.rotation.vector.z)
        self.rotationWText = formatNumericText(self.entity.rotation.vector.w)
        self.scriptPaths = self.entity.scriptPaths
    }

    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Section(header: Text("Basic").font(.system(size: 14, weight: .bold))) {
                    HStack(spacing: 8) {
                        Text("Entity Name")
                            .frame(width: 72, alignment: .leading)
                        TextField("", text: $entity.name)
                            .textFieldStyle(.plain)
                            .controlSize(.small)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                            .onChange(of: entity.name) { _, _ in isDirty = true }
                    }
                }

                Section {
                    Text("Transform")
                    VStack(alignment: .leading) {
                        HStack(spacing: 8) {
                            Text("Position")
                                .font(.system(size: 12))
                                .frame(width: 52, alignment: .leading)
                            axisInput(label: "X", text: $positionXText) { value in
                                entity.position.x = value
                            }
                            axisInput(label: "Y", text: $positionYText) { value in
                                entity.position.y = value
                            }
                            axisInput(label: "Z", text: $positionZText) { value in
                                entity.position.z = value
                            }
                        }

                        HStack(spacing: 8) {
                            Text("Rotation")
                                .font(.system(size: 12))
                                .frame(width: 52, alignment: .leading)
                            axisInput(label: "X", text: $rotationXText) { value in
                                entity.rotation.vector.x = value
                            }
                            axisInput(label: "Y", text: $rotationYText) { value in
                                entity.rotation.vector.y = value
                            }
                            axisInput(label: "Z", text: $rotationZText) { value in
                                entity.rotation.vector.z = value
                            }
                            axisInput(label: "W", text: $rotationWText) { value in
                                entity.rotation.vector.w = value
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Capabilities (Comma Separated)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("", text: $capabilityText)
                            .textFieldStyle(.plain)
                            .controlSize(.small)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                            .onChange(of: capabilityText) { _, newValue in
                                let items =
                                    newValue
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                                entity.RemoveAllCapabilities()
                                for item in items {
                                    entity.AddCapability(capability: item)
                                }
                                isDirty = true
                            }
                    }

                    ScriptAttachmentListView(
                        title: "Scripts",
                        emptyStateText: "Attach one or more .gs files to this entity.",
                        scriptPaths: $scriptPaths,
                        onChanged: {
                        isDirty = true
                        entity.scriptPaths = scriptPaths.filter { !$0.isEmpty }
                        }
                    )
                }

            }
            .frame(alignment: .leading)
            .padding()
            .navigationTitle(entity.name.isEmpty ? "Entity" : entity.name)
            .toolbar {
                Button("Save") {
                    saveEntity()
                }
                .keyboardShortcut("S", modifiers: .command)
                .disabled(!isDirty)
            }
        }
        .onAppear {
            // Ensure first open reflects current selection immediately.
            if let selected = GiskardApp.selectedEntities.first {
                updateEntity(selected)
            }
            refreshChildDisplayValuesFromIDs()
            if updateTask == nil {
                updateTask = Task {
                    await update()
                }
            }
        }
        .onDisappear {
            updateTask?.cancel()
            updateTask = nil
        }
    }

    func updateEntity(_ entity: Entity) {
        self.entity = entity
        self.isDirty = false
        if GiskardApp.selectedEntityContext == .file {
            GiskardApp.selectedEntityFileURL = GiskardApp.fileURL(for: entity.fileUUID)
        } else if GiskardApp.selectedEntityContext == .sceneNode {
            GiskardApp.selectedEntityFileURL = nil
        }
        self.pitch = self.entity.rotation.vector.x
        self.yaw = self.entity.rotation.vector.y
        self.roll = self.entity.rotation.vector.z
        self.magnitude = self.entity.rotation.vector.w
        self.capabilityText = self.entity.capabilities.joined(separator: ", ")
        self.childCountText = "\(self.entity.children.count)"
        self.childEntryDisplayValues = self.entity.childEntityPaths
        self.childEntryIDs = self.entity.children.map { Optional($0) }
        if self.childEntryDisplayValues.count < self.childEntryIDs.count {
            self.childEntryDisplayValues.append(
                contentsOf: Array(
                    repeating: "",
                    count: self.childEntryIDs.count - self.childEntryDisplayValues.count))
        } else if self.childEntryDisplayValues.count > self.childEntryIDs.count {
            self.childEntryDisplayValues = Array(
                self.childEntryDisplayValues.prefix(self.childEntryIDs.count))
        }
        self.positionXText = formatNumericText(self.entity.position.x)
        self.positionYText = formatNumericText(self.entity.position.y)
        self.positionZText = formatNumericText(self.entity.position.z)
        self.rotationXText = formatNumericText(self.entity.rotation.vector.x)
        self.rotationYText = formatNumericText(self.entity.rotation.vector.y)
        self.rotationZText = formatNumericText(self.entity.rotation.vector.z)
        self.rotationWText = formatNumericText(self.entity.rotation.vector.w)
        self.scriptPaths = self.entity.scriptPaths
        refreshChildDisplayValuesFromIDs()
    }

    func saveEntity() {
        entity.scriptPaths = scriptPaths.filter { !$0.isEmpty }
        if GiskardApp.selectedEntityContext == .sceneNode {
            if saveSelectedSceneNode() {
                return
            }
            print("Failed to save selected scene node.")
            return
        }

        guard
            let selectedEntityFileURL = GiskardApp.selectedEntityFileURL
                ?? GiskardApp.fileURL(for: entity.fileUUID)
        else {
            print("No entity file selected for saving.")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entity)
            if FileSys.shared.WriteFile(selectedEntityFileURL.path, data: data) {
                isDirty = false
            } else {
                print("Failed to save entity: \(selectedEntityFileURL.path)")
            }
        } catch {
            print("Failed to save entity: \(error)")
        }
    }

    private func saveSelectedSceneNode() -> Bool {
        guard let sceneURL = GiskardApp.selectedSceneFileURL,
            GiskardApp.selectedEntityContext == .sceneNode
        else {
            return false
        }

        guard let data = FileSys.shared.ReadFile(sceneURL.path),
            var sceneFile = try? JSONDecoder().decode(SceneFile.self, from: data)
        else {
            return false
        }

        guard Self.updateSceneNode(
            in: &sceneFile.entities,
            targetNodeID: GiskardApp.selectedSceneNodeID,
            targetNodeIndexPath: GiskardApp.selectedSceneNodeIndexPath,
            from: entity
        )
        else {
            return false
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(sceneFile)
            if FileSys.shared.WriteFile(sceneURL.path, data: encoded) {
                isDirty = false
                NotificationCenter.default.post(
                    name: .sceneFileUpdated,
                    object: nil,
                    userInfo: ["sceneURL": sceneURL]
                )
                return true
            }
        } catch {
        }

        return false
    }

    static func updateSceneNode(
        in nodes: inout [SceneEntityNode], targetNodeID: UUID, from entity: Entity
    ) -> Bool {
        updateSceneNode(
            in: &nodes,
            targetNodeID: Optional(targetNodeID),
            targetNodeIndexPath: nil,
            from: entity
        )
    }

    static func updateSceneNode(
        in nodes: inout [SceneEntityNode],
        targetNodeID: UUID?,
        targetNodeIndexPath: [Int]?,
        from entity: Entity
    ) -> Bool {
        if let targetNodeID,
           updateSceneNodeByID(in: &nodes, targetNodeID: targetNodeID, from: entity) {
            return true
        }

        if let targetNodeIndexPath,
           updateSceneNodeByIndexPath(in: &nodes, targetNodeIndexPath: targetNodeIndexPath, from: entity)
        {
            return true
        }

        return false
    }

    private static func updateSceneNodeByID(
        in nodes: inout [SceneEntityNode], targetNodeID: UUID, from entity: Entity
    ) -> Bool {
        for index in nodes.indices {
            if nodes[index].id == targetNodeID {
                applyEntity(entity, to: &nodes[index])
                return true
            }

            if updateSceneNodeByID(in: &nodes[index].children, targetNodeID: targetNodeID, from: entity)
            {
                return true
            }
        }
        return false
    }

    private static func updateSceneNodeByIndexPath(
        in nodes: inout [SceneEntityNode], targetNodeIndexPath: [Int], from entity: Entity
    ) -> Bool {
        guard let head = targetNodeIndexPath.first,
              nodes.indices.contains(head) else {
            return false
        }

        if targetNodeIndexPath.count == 1 {
            applyEntity(entity, to: &nodes[head])
            return true
        }

        return updateSceneNodeByIndexPath(
            in: &nodes[head].children,
            targetNodeIndexPath: Array(targetNodeIndexPath.dropFirst()),
            from: entity
        )
    }

    private static func applyEntity(_ entity: Entity, to node: inout SceneEntityNode) {
        node.name = entity.name
        node.isPhysical = entity.isPhysical
        node.position = [entity.position.x, entity.position.y, entity.position.z]
        node.rotation = [
            entity.rotation.vector.x,
            entity.rotation.vector.y,
            entity.rotation.vector.z,
            entity.rotation.vector.w,
        ]
        node.scriptPaths = entity.scriptPaths
        node.capabilities = entity.capabilities
    }

    func update() async {
        while !Task.isCancelled {
            do {
                if GiskardApp.selectedEntities.count > 0
                    && GiskardApp.selectedEntities[0].id != entity.id
                {
                    updateEntity(GiskardApp.selectedEntities[0])
                }
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                if Task.isCancelled {
                    return
                }
            }
        }
    }

    private var currentChildCount: Int {
        Int(childCountText) ?? 0
    }

    private func incrementChildCount() {
        setChildCount(currentChildCount + 1)
    }

    private func decrementChildCount() {
        setChildCount(max(0, currentChildCount - 1))
    }

    private func applyChildCountText(_ text: String) {
        let digitsOnly = text.filter { $0.isNumber }
        let normalized = digitsOnly.isEmpty ? "0" : digitsOnly
        let count = max(0, Int(normalized) ?? 0)
        setChildCount(count, updateText: true)
    }

    private func setChildCount(_ count: Int, updateText: Bool = true) {
        let boundedCount = max(0, count)
        if updateText {
            childCountText = "\(boundedCount)"
        }

        if childEntryDisplayValues.count < boundedCount {
            let delta = boundedCount - childEntryDisplayValues.count
            childEntryDisplayValues.append(contentsOf: Array(repeating: "", count: delta))
            childEntryIDs.append(contentsOf: Array(repeating: nil, count: delta))
        } else if childEntryDisplayValues.count > boundedCount {
            childEntryDisplayValues = Array(childEntryDisplayValues.prefix(boundedCount))
            childEntryIDs = Array(childEntryIDs.prefix(boundedCount))
        }

        syncChildrenFromEntries()
    }

    private func bindingForChildDisplay(at index: Int) -> Binding<String> {
        Binding(
            get: { childEntryDisplayValues[index] },
            set: { newValue in
                childEntryDisplayValues[index] = newValue
                // Manual edits cannot reliably resolve a UUID, so clear linkage until dropped again.
                childEntryIDs[index] = nil
                syncChildrenFromEntries()
            }
        )
    }

    private func syncChildrenFromEntries() {
        entity.children = childEntryIDs.compactMap { $0 }
        entity.childEntityPaths = childEntryIDs.enumerated().compactMap { index, id in
            guard id != nil, index < childEntryDisplayValues.count else { return nil }
            return childEntryDisplayValues[index]
        }
        isDirty = true
    }

    private func handleChildEntityDrop(providers: [NSItemProvider], at index: Int) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) })
        else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let pathNSString = object as? NSString else {
                return
            }
            let pathString = pathNSString as String

            let fileURL = URL(fileURLWithPath: pathString)
            guard fileURL.pathExtension.lowercased() == "entity" else {
                return
            }
            guard let fileData = FileSys.shared.ReadFile(fileURL.path),
                let droppedEntity = try? JSONDecoder().decode(Entity.self, from: fileData)
            else {
                return
            }

            let relativePath = relativePathForChild(from: fileURL)
            let displayValue = "\(relativePath)"

            DispatchQueue.main.async {
                guard index < childEntryDisplayValues.count else {
                    return
                }
                childEntryDisplayValues[index] = displayValue
                childEntryIDs[index] = droppedEntity.fileUUID
                syncChildrenFromEntries()
            }
        }

        return true
    }

    private func relativePathForChild(from fileURL: URL) -> String {
        guard let projectRoot = GiskardApp.getProject().projectPath else {
            return fileURL.lastPathComponent
        }
        let rootPath = projectRoot.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        if filePath.hasPrefix(rootPath + "/") {
            return String(filePath.dropFirst(rootPath.count + 1))
        }
        return fileURL.lastPathComponent
    }

    private func axisInput(
        label: String, text: Binding<String>, onValueChanged: @escaping (Double) -> Void
    ) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .frame(width: 8, alignment: .leading)
                .fixedSize(horizontal: true, vertical: false)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 35, height: 24)
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    .frame(width: 35, height: 24)
                TextField("", text: text)
                    .labelsHidden()
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .clipped()
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        let filtered = filterNumericInput(newValue)
                        if filtered != newValue {
                            text.wrappedValue = filtered
                        }
                        onValueChanged(Double(filtered) ?? 0)
                        isDirty = true
                    }
            }
            .frame(width: 35, height: 24)
        }
    }

    private func filterNumericInput(_ text: String) -> String {
        var result = ""
        var sawDecimal = false
        var sawSign = false
        for (index, character) in text.enumerated() {
            if character.isNumber {
                result.append(character)
                continue
            }
            if character == ".", !sawDecimal {
                sawDecimal = true
                result.append(character)
                continue
            }
            if character == "-", index == 0, !sawSign {
                sawSign = true
                result.append(character)
                continue
            }
        }
        return result
    }

    private func formatNumericText(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }

    private func refreshChildDisplayValuesFromIDs() {
        let targetIDs = Set(childEntryIDs.compactMap { $0 })
        guard !targetIDs.isEmpty else {
            childEntryDisplayValues = Array(repeating: "", count: childEntryIDs.count)
            return
        }

        // Prefer persisted paths when present (authoritative for this editor feature).
        if entity.childEntityPaths.count == childEntryIDs.count && !entity.childEntityPaths.isEmpty
        {
            childEntryDisplayValues = entity.childEntityPaths
            return
        }

        let pathIndex = buildEntityPathIndex(for: targetIDs)
        childEntryDisplayValues = childEntryIDs.map { id in
            guard let id else { return "" }
            return pathIndex[id] ?? ""
        }
    }

    private func buildEntityPathIndex(for ids: Set<UUID>) -> [UUID: String] {
        guard let projectRoot = GiskardApp.getProject().projectPath else {
            return [:]
        }

        var unresolvedIDs = ids
        var index: [UUID: String] = [:]
        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: projectRoot, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles])
        else {
            return [:]
        }

        for case let fileURL as URL in enumerator {
            if unresolvedIDs.isEmpty {
                break
            }
            if fileURL.pathExtension.lowercased() != "entity" {
                continue
            }
            guard let data = FileSys.shared.ReadFile(fileURL.path) else {
                continue
            }
            guard let childEntity = try? JSONDecoder().decode(Entity.self, from: data) else {
                continue
            }
            guard unresolvedIDs.contains(childEntity.fileUUID) else {
                continue
            }

            index[childEntity.fileUUID] = relativePathForChild(from: fileURL)
            unresolvedIDs.remove(childEntity.fileUUID)
        }
        return index
    }
}

#Preview {
    EntityEditorView()
}
