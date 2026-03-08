//
//  DebugRunView.swift
//  Giskard
//

import SwiftUI

struct DebugRunView: View {
    let manifestURL: URL

    @State private var manifest: DebugRunManifest? = nil
    @State private var loadError: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let manifest {
                Text(manifest.buildConfiguration.applicationName)
                    .font(.largeTitle.bold())

                Text("Debug Run")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(manifest.buildConfiguration.bundleIdentifier)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Version")
                    Spacer()
                    Text(manifest.buildConfiguration.version)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Entry Scene")
                    Spacer()
                    Text(manifest.entryScenePath)
                        .foregroundColor(.secondary)
                }

                SceneRenderView()
                    .frame(minHeight: 320)

                Text("Attached scripts remain disabled in this visual debug-run preview until runtime scripting is implemented.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let loadError {
                Text(loadError)
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
            }
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 560)
        .onAppear {
            loadManifest()
        }
    }

    private func loadManifest() {
        guard let manifest = EditorProjectSupport.loadDebugRunManifest(from: manifestURL) else {
            loadError = "Unable to load debug run manifest."
            return
        }

        let projectURL = URL(fileURLWithPath: manifest.projectPath)
        FileSys.shared.SetRootURL(url: projectURL)

        if GiskardApp.loadProjectFromDirectory(projectURL),
           let entrySceneURL = EditorProjectSupport.absoluteProjectURL(
                for: manifest.entryScenePath,
                projectRoot: projectURL
           ) {
            GiskardApp.selectScene(entrySceneURL)
            self.manifest = manifest
        } else {
            loadError = "Unable to load project \(manifest.projectName) for debug run."
        }
    }
}

#Preview {
    DebugRunView(manifestURL: URL(fileURLWithPath: "/tmp/DebugRunManifest.json"))
}
