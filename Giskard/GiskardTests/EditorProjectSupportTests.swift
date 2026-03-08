import Foundation
import Testing
import GiskardEngine
@testable import Giskard

@Suite(.serialized)
struct EditorProjectSupportTests {

    @Test func legacyAssetsDecodeWithoutScriptPaths() throws {
        let scene = SceneFile(
            sceneName: "Main Scene",
            scriptPaths: ["Scripts/Scene.gs"],
            entities: [
                SceneEntityNode(
                    name: "Player",
                    scriptPaths: ["Scripts/Player.gs"],
                    capabilities: ["Movable"]
                )
            ]
        )
        let entity = Entity(
            "Standalone",
            scriptPaths: ["Scripts/Standalone.gs"]
        )

        let legacySceneData = try removeJSONKeys(["scriptPaths"], from: JSONEncoder().encode(scene))
        let legacyEntityData = try removeJSONKeys(["scriptPaths"], from: JSONEncoder().encode(entity))

        let decodedScene = try JSONDecoder().decode(SceneFile.self, from: legacySceneData)
        let decodedEntity = try JSONDecoder().decode(Entity.self, from: legacyEntityData)

        #expect(decodedScene.scriptPaths.isEmpty)
        #expect(decodedScene.entities.first?.scriptPaths.isEmpty == true)
        #expect(decodedEntity.scriptPaths.isEmpty)
    }

    @Test func buildConfigurationRoundTripsAndUsesProjectEntryScene() throws {
        let projectRoot = try makeTemporaryProjectRoot(named: "BuildConfigRoundTrip")
        defer { try? FileManager.default.removeItem(at: projectRoot) }

        FileSys.shared.SetRootURL(url: projectRoot)
        let project = ProjectInformation(
            projectVersion: 1,
            projectName: "Spec Project",
            projectAuthor: "Tester",
            projectPath: projectRoot,
            description: "Build config coverage",
            creationDate: ISO8601DateFormatter().string(from: Date()),
            mainScenePath: "Main.scene"
        )

        try writeProjectSettings(project, to: projectRoot)
        try writeScene(named: "Main", to: projectRoot.appendingPathComponent("Main.scene"))
        try writeScene(named: "Sandbox", to: projectRoot.appendingPathComponent("Sandbox.scene"))

        let configuration = EditorProjectSupport.defaultBuildConfiguration(project: project)
        #expect(configuration.includedScenePaths == ["Main.scene", "Sandbox.scene"])
        #expect(configuration.entryScenePath == "Main.scene")

        #expect(EditorProjectSupport.saveBuildConfiguration(configuration, for: project))
        let reloaded = EditorProjectSupport.loadBuildConfiguration(project: project)

        #expect(reloaded == configuration)
    }

    @Test func buildConfigurationNormalizesMissingScenesAndSyncsProjectEntry() throws {
        let projectRoot = try makeTemporaryProjectRoot(named: "BuildConfigNormalize")
        defer { try? FileManager.default.removeItem(at: projectRoot) }

        FileSys.shared.SetRootURL(url: projectRoot)
        let project = ProjectInformation(
            projectVersion: 1,
            projectName: "Normalize Project",
            projectAuthor: "Tester",
            projectPath: projectRoot,
            description: nil,
            creationDate: ISO8601DateFormatter().string(from: Date()),
            mainScenePath: nil
        )

        try writeProjectSettings(project, to: projectRoot)
        try writeScene(named: "Main", to: projectRoot.appendingPathComponent("Main.scene"))

        let invalidConfiguration = BuildConfiguration(
            applicationName: "Normalize Project",
            bundleIdentifier: "com.test.normalize",
            version: "0.1.0",
            iconPath: nil,
            includedScenePaths: ["Missing.scene", "Main.scene", "Main.scene"],
            entryScenePath: "Missing.scene"
        )

        #expect(EditorProjectSupport.saveBuildConfiguration(invalidConfiguration, for: project))
        let reloaded = EditorProjectSupport.loadBuildConfiguration(project: project)

        #expect(reloaded.includedScenePaths == ["Main.scene"])
        #expect(reloaded.entryScenePath == "Main.scene")
        #expect(project.mainScenePath == "Main.scene")
    }

    @Test func debugRunPlanWritesManifestAndLauncher() throws {
        let projectRoot = try makeTemporaryProjectRoot(named: "DebugRunPlan")
        defer { try? FileManager.default.removeItem(at: projectRoot) }

        FileSys.shared.SetRootURL(url: projectRoot)
        let project = ProjectInformation(
            projectVersion: 1,
            projectName: "Debuggable",
            projectAuthor: "Tester",
            projectPath: projectRoot,
            description: nil,
            creationDate: ISO8601DateFormatter().string(from: Date()),
            mainScenePath: "Main.scene"
        )

        try writeProjectSettings(project, to: projectRoot)
        try writeScene(named: "Main", to: projectRoot.appendingPathComponent("Main.scene"))

        let configuration = BuildConfiguration(
            applicationName: "Debuggable",
            bundleIdentifier: "com.test.debuggable",
            version: "1.0.0",
            iconPath: "Assets/AppIcon.icns",
            includedScenePaths: ["Main.scene"],
            entryScenePath: "Main.scene"
        )
        #expect(EditorProjectSupport.saveBuildConfiguration(configuration, for: project))

        let bundleURL = URL(fileURLWithPath: "/Applications/Giskard.app")
        let plan = try EditorProjectSupport.makeDebugRunLaunchPlan(project: project, bundleURL: bundleURL)
        let manifest = try #require(EditorProjectSupport.loadDebugRunManifest(from: plan.manifestURL))
        let launcherContents = try String(contentsOf: plan.launcherURL, encoding: .utf8)

        #expect(manifest.entryScenePath == "Main.scene")
        #expect(manifest.buildConfiguration == configuration)
        #expect(launcherContents.contains(bundleURL.path))
        #expect(launcherContents.contains("--giskard-debug-run-manifest"))
        #expect(plan.arguments == ["--giskard-debug-run-manifest", plan.manifestURL.path])
    }

    @MainActor
    @Test func sceneNodeSelectionKeepsInspectorInSceneSaveMode() {
        resetSelectionState()

        let entityFileURL = URL(fileURLWithPath: "/tmp/Player.entity")
        let nodeID = UUID()
        let fileUUID = UUID()
        let node = SceneEntityNode(id: nodeID, fileUUID: fileUUID, name: "Player")

        GiskardApp.entityFileURLs[fileUUID] = entityFileURL
        GiskardApp.selectSceneNode(
            node,
            sceneURL: URL(fileURLWithPath: "/tmp/Main.scene"),
            indexPath: [0]
        )

        let view = EntityEditorView()
        view.updateEntity(GiskardApp.selectedEntities[0])

        #expect(GiskardApp.selectedEntityContext == .sceneNode)
        #expect(GiskardApp.selectedEntityFileURL == nil)
        #expect(GiskardApp.selectedSceneNodeID == nodeID)
        #expect(GiskardApp.selectedSceneNodeIndexPath == [0])
    }

    @MainActor
    @Test func fileSelectionRestoresInspectorFileSaveMode() {
        resetSelectionState()

        let entityFileURL = URL(fileURLWithPath: "/tmp/Standalone.entity")
        let fileUUID = UUID()
        let entity = Entity("Standalone", fileUUID: fileUUID)

        GiskardApp.selectEntity(entity, fileURL: entityFileURL)

        let view = EntityEditorView()
        view.updateEntity(entity)

        #expect(GiskardApp.selectedEntityContext == .file)
        #expect(GiskardApp.selectedEntityFileURL == entityFileURL)
        #expect(GiskardApp.selectedSceneNodeID == nil)
    }

    @Test func sceneNodeUpdateFallsBackToIndexPathWhenIDLookupMisses() {
        let originalRootID = UUID()
        let originalChildID = UUID()
        var nodes = [
            SceneEntityNode(
                id: originalRootID,
                fileUUID: UUID(),
                name: "Root",
                children: [
                    SceneEntityNode(id: originalChildID, fileUUID: UUID(), name: "Child")
                ]
            )
        ]
        let updatedEntity = Entity("Renamed Child", uuid: originalChildID, fileUUID: UUID())

        let didUpdate = EntityEditorView.updateSceneNode(
            in: &nodes,
            targetNodeID: UUID(),
            targetNodeIndexPath: [0, 0],
            from: updatedEntity
        )

        #expect(didUpdate)
        #expect(nodes[0].children[0].name == "Renamed Child")
    }

    @Test func capabilityEntriesRoundTripKnownAndCustomValues() {
        let entries = EntityEditorView.makeCapabilityEntries(
            from: ["camera", "Renderable3D", "MyCustomCapability", "camera"]
        )

        #expect(entries.count == 4)
        #expect(entries[0].isCustom == false)
        #expect(entries[0].knownValue == "Camera")
        #expect(entries[1].isCustom == false)
        #expect(entries[1].knownValue == "Renderable3D")
        #expect(entries[2].isCustom == true)
        #expect(entries[2].customValue == "MyCustomCapability")

        let resolved = EntityEditorView.resolvedCapabilities(from: entries)

        #expect(resolved == ["Camera", "Renderable3D", "MyCustomCapability"])
    }

    private func makeTemporaryProjectRoot(named name: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("GiskardTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString + "-" + name, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeProjectSettings(_ project: ProjectInformation, to rootURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(project)
        let settingsURL = rootURL.appendingPathComponent("Giskard_Project_Settings")
        try data.write(to: settingsURL, options: .atomic)
    }

    private func writeScene(named name: String, to url: URL) throws {
        let scene = SceneFile.defaultScene(named: name)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(scene)
        try data.write(to: url, options: .atomic)
    }

    private func removeJSONKeys(_ keys: Set<String>, from data: Data) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: data)
        let stripped = removeJSONKeys(keys, from: object)
        return try JSONSerialization.data(withJSONObject: stripped, options: [.prettyPrinted])
    }

    private func removeJSONKeys(_ keys: Set<String>, from object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dictionary where !keys.contains(key) {
                result[key] = removeJSONKeys(keys, from: value)
            }
            return result
        }

        if let array = object as? [Any] {
            return array.map { removeJSONKeys(keys, from: $0) }
        }

        return object
    }

    private func resetSelectionState() {
        GiskardApp.selectedEntities = []
        GiskardApp.selectedEntityFileURL = nil
        GiskardApp.selectedEntityContext = .none
        GiskardApp.selectedImageFileURL = nil
        GiskardApp.selectedScriptFileURL = nil
        GiskardApp.selectedSceneFileURL = nil
        GiskardApp.selectedSceneNodeID = nil
        GiskardApp.selectedSceneNodeIndexPath = nil
        GiskardApp.entityFileURLs = [:]
    }
}
