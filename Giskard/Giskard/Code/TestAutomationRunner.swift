//
//  TestAutomationRunner.swift
//  Giskard
//

import AppKit
import Foundation
import GiskardEngine
import Spatial

enum TestAutomationRunner {
    private static let launchArgument = "--giskard-ui-automation"
    private static var hasStarted = false

    static func startIfNeeded(onComplete: @escaping (String) -> Void) {
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else {
            return
        }
        guard !hasStarted else {
            return
        }
        hasStarted = true

        Task {
            let report = runScenario()
            writeReport(report)
            DispatchQueue.main.async {
                onComplete(formatStatus(for: report))
                if ProcessInfo.processInfo.environment["GISKARD_AUTOMATION_EXIT"] == "1" {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private static func formatStatus(for report: SmokeTestReport) -> String {
        if report.success {
            return "AUTOMATION_SUCCESS scenes=\(report.createdSceneCount) folders=\(report.createdFolderCount) entityFiles=\(report.createdEntityFileCount) sceneEntities=\(report.createdSceneEntityCount) cameras=\(report.cameraCount) render2D=\(report.renderable2DCount) render3D=\(report.renderable3DCount)"
        }
        return "AUTOMATION_FAILURE \(report.errors.joined(separator: " | "))"
    }

    private static func runScenario() -> SmokeTestReport {
        var report = SmokeTestReport()

        do {
            let random = SeededRandom()
            let rootURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("GiskardAutomation", isDirectory: true)
                .appendingPathComponent("EditorSmokeProject", isDirectory: true)

            try recreateDirectory(at: rootURL)
            FileSys.shared.SetRootURL(url: rootURL)

            let project = ProjectInformation(
                projectVersion: 1,
                projectName: "EditorSmokeProject",
                projectAuthor: "UITest",
                projectPath: rootURL,
                description: "Automated smoke test project",
                creationDate: ISO8601DateFormatter().string(from: Date())
            )

            try writeProjectSettings(project, at: rootURL)
            GiskardApp.loadProject(project)

            let mainSceneURL = rootURL.appendingPathComponent("Main.scene")
            let mainScene = SceneFile.defaultScene(named: "Main Scene")
            try writeScene(mainScene, to: mainSceneURL)

            let extraSceneURL = rootURL.appendingPathComponent("Sandbox.scene")
            let extraScene = buildAutomationPreviewScene()
            try writeScene(extraScene, to: extraSceneURL)
            report.createdSceneCount = 2

            let folderCount = random.int(in: 2...10)
            report.createdFolderCount = folderCount
            let folders = try createRandomFolders(count: folderCount, rootURL: rootURL)

            let entityFileCount = random.int(in: 2...10)
            report.createdEntityFileCount = entityFileCount
            _ = try createRandomEntityFiles(
                count: entityFileCount,
                rootURL: rootURL,
                folderURLs: folders,
                random: random
            )

            GiskardApp.selectScene(extraSceneURL)

            if let data = FileSys.shared.ReadFile(extraSceneURL.path) {
                let decoded = try JSONDecoder().decode(SceneFile.self, from: data)
                report.createdSceneEntityCount = countNodes(decoded.entities)
                report.editedEntityCount = report.createdSceneEntityCount
                report.cameraCount = countNodes(withCapability: "Camera", in: decoded.entities)
                report.renderable2DCount = countNodes(withCapability: "Renderable2D", in: decoded.entities)
                report.renderable3DCount = countNodes(withCapability: "Renderable3D", in: decoded.entities)

                if report.cameraCount != 1 {
                    report.errors.append("Expected exactly one camera node")
                }
                if report.renderable2DCount != 1 {
                    report.errors.append("Expected exactly one 2D renderable node")
                }
                if report.renderable3DCount != 1 {
                    report.errors.append("Expected exactly one 3D renderable node")
                }
                if countNodes(decoded.entities) != 4 {
                    report.errors.append("Decoded scene entity count mismatch")
                }
            } else {
                report.errors.append("Failed to read populated scene file")
            }
        } catch {
            report.errors.append("Scenario exception: \(error.localizedDescription)")
        }

        report.success = report.errors.isEmpty
        return report
    }

    private static func recreateDirectory(at url: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static func writeProjectSettings(_ project: ProjectInformation, at rootURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(project)
        let settingsURL = rootURL.appendingPathComponent("Giskard_Project_Settings")
        guard FileSys.shared.CreateFile(settingsURL.path, data: data) else {
            throw SmokeError.ioFailure("Failed to create project settings")
        }
    }

    private static func writeScene(_ scene: SceneFile, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(scene)
        guard FileSys.shared.CreateFile(url.path, data: data) || FileSys.shared.WriteFile(url.path, data: data) else {
            throw SmokeError.ioFailure("Failed to write scene file: \(url.path)")
        }
    }

    private static func createRandomFolders(count: Int, rootURL: URL) throws -> [URL] {
        var folders: [URL] = []
        for index in 0..<count {
            let folderURL = rootURL.appendingPathComponent("Folder_\(index + 1)")
            guard FileSys.shared.CreateFolder(folderURL.path) else {
                throw SmokeError.ioFailure("Failed to create folder: \(folderURL.lastPathComponent)")
            }
            folders.append(folderURL)
        }
        return folders
    }

    private static func createRandomEntityFiles(
        count: Int,
        rootURL: URL,
        folderURLs: [URL],
        random: SeededRandom
    ) throws -> [UUID] {
        var uuids: [UUID] = []

        for index in 0..<count {
            let destinationFolder: URL
            if folderURLs.isEmpty {
                destinationFolder = rootURL
            } else {
                destinationFolder = folderURLs[random.int(in: 0...(folderURLs.count - 1))]
            }

            let entity = Entity("Entity_\(index + 1)")
            entity.position.x = random.double(in: -1000...1000)
            entity.position.y = random.double(in: -1000...1000)
            entity.position.z = random.double(in: -1000...1000)
            entity.rotation.vector.x = random.double(in: -1...1)
            entity.rotation.vector.y = random.double(in: -1...1)
            entity.rotation.vector.z = random.double(in: -1...1)
            entity.rotation.vector.w = random.double(in: -1...1)
            entity.capabilities = random.capabilities()

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entity)
            let fileURL = destinationFolder.appendingPathComponent("Entity_\(index + 1).entity")
            guard FileSys.shared.CreateFile(fileURL.path, data: data) else {
                throw SmokeError.ioFailure("Failed to create entity file: \(fileURL.lastPathComponent)")
            }

            uuids.append(entity.fileUUID)
        }

        return uuids
    }

    private static func buildAutomationPreviewScene() -> SceneFile {
        let cameraNode = SceneEntityNode(
            name: "Preview Camera",
            isPhysical: false,
            position: [0, 0, -25],
            rotation: [0, 0, 0, 1],
            capabilities: ["Camera"]
        )
        let spriteNode = SceneEntityNode(
            name: "Preview Sprite",
            isPhysical: false,
            position: [-12, 6, 0],
            rotation: [0, 0, 0, 1],
            capabilities: ["Renderable2D"]
        )
        let meshNode = SceneEntityNode(
            name: "Preview Mesh",
            isPhysical: false,
            position: [10, -4, 12],
            rotation: [0, 0, 0.3826834, 0.9238795],
            capabilities: ["Renderable3D"]
        )
        let helperNode = SceneEntityNode(
            name: "Preview Helper",
            isPhysical: false,
            position: [0, 18, 0],
            rotation: [0, 0, 0, 1],
            capabilities: ["Movable"]
        )

        return SceneFile(
            sceneVersion: 1,
            sceneName: "Sandbox Scene",
            entities: [cameraNode, spriteNode, meshNode, helperNode]
        )
    }

    private static func countNodes(_ nodes: [SceneEntityNode]) -> Int {
        nodes.reduce(0) { partial, node in
            partial + 1 + countNodes(node.children)
        }
    }

    private static func countNodes(withCapability capability: String, in nodes: [SceneEntityNode]) -> Int {
        nodes.reduce(0) { partial, node in
            let ownCount = node.capabilities.contains(where: {
                $0.caseInsensitiveCompare(capability) == .orderedSame
            }) ? 1 : 0
            return partial + ownCount + countNodes(withCapability: capability, in: node.children)
        }
    }

    private static func writeReport(_ report: SmokeTestReport) {
        guard let path = ProcessInfo.processInfo.environment["GISKARD_TEST_REPORT_PATH"], !path.isEmpty else {
            return
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(report) else {
            return
        }

        let reportURL = URL(fileURLWithPath: path)
        _ = try? data.write(to: reportURL, options: .atomic)
    }
}

private struct SmokeTestReport: Codable {
    var success: Bool = false
    var createdSceneCount: Int = 0
    var createdFolderCount: Int = 0
    var createdEntityFileCount: Int = 0
    var createdSceneEntityCount: Int = 0
    var editedEntityCount: Int = 0
    var cameraCount: Int = 0
    var renderable2DCount: Int = 0
    var renderable3DCount: Int = 0
    var errors: [String] = []
}

private enum SmokeError: Error {
    case ioFailure(String)
}

private final class SeededRandom {
    func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }

    func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }

    func capabilities() -> [String] {
        let options = ["Movable"]
        let count = Int.random(in: 1...options.count)
        return Array(options.shuffled().prefix(count))
    }
}
