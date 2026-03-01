//
//  SceneInspectorView.swift
//  Giskard
//

import SwiftUI
import GiskardEngine

struct SceneInspectorView: View {
    @State private var sceneURL: URL? = GiskardApp.selectedSceneFileURL
    @State private var entityCount: Int = 0

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
            return
        }

        func recursiveCount(_ nodes: [SceneEntityNode]) -> Int {
            nodes.reduce(0) { partialResult, node in
                partialResult + 1 + recursiveCount(node.children)
            }
        }

        entityCount = recursiveCount(scene.entities)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
}

#Preview {
    SceneInspectorView()
}
