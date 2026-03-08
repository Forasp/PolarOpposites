//
//  BuildSettingsView.swift
//  Giskard
//

import SwiftUI
import UniformTypeIdentifiers

struct BuildSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var configuration = BuildConfiguration(
        applicationName: "",
        bundleIdentifier: "",
        version: "",
        iconPath: nil,
        includedScenePaths: [],
        entryScenePath: nil
    )
    @State private var availableScenePaths: [String] = []
    @State private var statusText: String? = nil

    let onComplete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Build Settings")
                .font(.title3.bold())

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("App Name")
                    TextField("Game Name", text: $configuration.applicationName)
                }
                GridRow {
                    Text("Bundle ID")
                    TextField("com.example.game", text: $configuration.bundleIdentifier)
                }
                GridRow {
                    Text("Version")
                    TextField("0.1.0", text: $configuration.version)
                }
                GridRow {
                    Text("Icon Asset")
                    TextField(
                        "Assets/AppIcon.icns",
                        text: Binding(
                            get: { configuration.iconPath ?? "" },
                            set: { configuration.iconPath = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                        )
                    )
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        handleIconDrop(providers: providers)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Included Scenes")
                    .font(.headline)

                if availableScenePaths.isEmpty {
                    Text("No .scene files were found in the current project.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(availableScenePaths, id: \.self) { scenePath in
                    Toggle(
                        scenePath,
                        isOn: Binding(
                            get: { configuration.includedScenePaths.contains(scenePath) },
                            set: { isIncluded in
                                updateIncludedScene(scenePath, isIncluded: isIncluded)
                            }
                        )
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Entry Scene")
                    .font(.headline)

                Picker("Entry Scene", selection: Binding(
                    get: { configuration.entryScenePath ?? "" },
                    set: { configuration.entryScenePath = $0.isEmpty ? nil : $0 }
                )) {
                    Text("None").tag("")
                    ForEach(configuration.includedScenePaths, id: \.self) { scenePath in
                        Text(scenePath).tag(scenePath)
                    }
                }
                .pickerStyle(.menu)
                .disabled(configuration.includedScenePaths.isEmpty)
            }

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    saveConfiguration()
                }
            }
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 420)
        .onAppear {
            loadConfiguration()
        }
    }

    private func loadConfiguration() {
        let project = GiskardApp.getProject()
        configuration = EditorProjectSupport.loadBuildConfiguration(project: project)
        availableScenePaths = EditorProjectSupport.discoverProjectFiles(
            withExtension: "scene",
            in: project.projectPath
        )
    }

    private func saveConfiguration() {
        let project = GiskardApp.getProject()
        let didSave = EditorProjectSupport.saveBuildConfiguration(configuration, for: project)
        if didSave {
            onComplete("Build settings saved.")
            dismiss()
        } else {
            statusText = "Failed to save build settings."
        }
    }

    private func updateIncludedScene(_ scenePath: String, isIncluded: Bool) {
        if isIncluded {
            if !configuration.includedScenePaths.contains(scenePath) {
                configuration.includedScenePaths.append(scenePath)
                configuration.includedScenePaths.sort()
            }
        } else {
            configuration.includedScenePaths.removeAll { $0 == scenePath }
        }

        if let entryScenePath = configuration.entryScenePath,
           !configuration.includedScenePaths.contains(entryScenePath) {
            configuration.entryScenePath = configuration.includedScenePaths.first
        } else if configuration.entryScenePath == nil {
            configuration.entryScenePath = configuration.includedScenePaths.first
        }
    }

    private func handleIconDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let pathNSString = object as? NSString else {
                return
            }

            let fileURL = URL(fileURLWithPath: pathNSString as String)
            let relativePath = EditorProjectSupport.relativeProjectPath(for: fileURL) ?? fileURL.lastPathComponent
            DispatchQueue.main.async {
                configuration.iconPath = relativePath
            }
        }

        return true
    }
}

#Preview {
    BuildSettingsView { _ in }
}
