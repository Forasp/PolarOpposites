//
//  SceneInspectorView.swift
//  Giskard
//

import SwiftUI
import GiskardEngine

struct SceneInspectorView: View {
    @State private var sceneURL: URL? = GiskardApp.selectedSceneFileURL
    @State private var entityCount: Int = 0
    @State private var scriptPaths: [String] = []
    @State private var isDirty = false
    @State private var statusText: String? = nil

    private var sceneName: String {
        guard let sceneURL else { return "-" }
        return sceneURL.deletingPathExtension().lastPathComponent
    }

    private var fileSizeText: String {
        guard let sceneURL else { return "-" }
        let values = try? sceneURL.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values?.fileSize else { return "-" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private func refreshSceneStats() {
        guard let sceneURL,
              let data = FileSys.shared.ReadFile(sceneURL.path),
              let scene = try? JSONDecoder().decode(SceneFile.self, from: data) else {
            entityCount = 0
            scriptPaths = []
            return
        }

        func recursiveCount(_ nodes: [SceneEntityNode]) -> Int {
            nodes.reduce(0) { partialResult, node in
                partialResult + 1 + recursiveCount(node.children)
            }
        }

        entityCount = recursiveCount(scene.entities)
        scriptPaths = scene.scriptPaths
        isDirty = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scene")
                    .font(.headline)
                Spacer()
                Button("Save") {
                    saveScene()
                }
                .disabled(!isDirty || sceneURL == nil)
            }

            HStack {
                Text("Scene Name")
                Spacer()
                Text(sceneName).foregroundColor(.secondary)
            }
            HStack {
                Text("File Size")
                Spacer()
                Text(fileSizeText).foregroundColor(.secondary)
            }
            HStack {
                Text("Entity Count")
                Spacer()
                Text("\(entityCount)").foregroundColor(.secondary)
            }

            ScriptAttachmentListView(
                title: "Scene Scripts",
                emptyStateText: "Attach .gs files that should belong to the scene.",
                scriptPaths: $scriptPaths,
                onChanged: {
                    isDirty = true
                }
            )

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            sceneURL = GiskardApp.selectedSceneFileURL
            refreshSceneStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .inspectorSelectionChanged)) { _ in
            sceneURL = GiskardApp.selectedSceneFileURL
            refreshSceneStats()
        }
    }

    private func saveScene() {
        guard let sceneURL,
              let data = FileSys.shared.ReadFile(sceneURL.path),
              var scene = try? JSONDecoder().decode(SceneFile.self, from: data) else {
            statusText = "Unable to load the selected scene."
            return
        }

        scene.scriptPaths = scriptPaths.filter { !$0.isEmpty }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(scene)
            if FileSys.shared.WriteFile(sceneURL.path, data: encoded) {
                isDirty = false
                statusText = "Saved."
                NotificationCenter.default.post(
                    name: .sceneFileUpdated,
                    object: nil,
                    userInfo: ["sceneURL": sceneURL]
                )
            } else {
                statusText = "Failed to save \(sceneURL.lastPathComponent)."
            }
        } catch {
            statusText = "Unable to encode the scene file."
        }
    }
}

#Preview {
    SceneInspectorView()
}
