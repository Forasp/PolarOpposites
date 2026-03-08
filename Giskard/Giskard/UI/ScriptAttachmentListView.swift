//
//  ScriptAttachmentListView.swift
//  Giskard
//

import SwiftUI
import UniformTypeIdentifiers

struct ScriptAttachmentListView: View {
    let title: String
    let emptyStateText: String
    @Binding var scriptPaths: [String]
    var onChanged: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Add Script") {
                    scriptPaths.append("")
                    onChanged?()
                }
            }

            if scriptPaths.isEmpty {
                Text(emptyStateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(scriptPaths.indices), id: \.self) { index in
                HStack(spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .leading)

                    TextField("relative/path/script.gs", text: binding(for: index))
                        .textFieldStyle(.roundedBorder)
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            handleDrop(providers: providers, at: index)
                        }

                    Button {
                        scriptPaths.remove(at: index)
                        onChanged?()
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Scripts are standalone .gs files. Begin, Tick, and End are authoring-time conventions only and do not execute during visual preview.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { scriptPaths[index] },
            set: { newValue in
                scriptPaths[index] = normalizedScriptPath(newValue)
                onChanged?()
            }
        )
    }

    private func handleDrop(providers: [NSItemProvider], at index: Int) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let pathNSString = object as? NSString else {
                return
            }

            let fileURL = URL(fileURLWithPath: pathNSString as String)
            guard fileURL.pathExtension.lowercased() == "gs" else {
                return
            }

            let relativePath = EditorProjectSupport.relativeProjectPath(for: fileURL) ?? fileURL.lastPathComponent
            DispatchQueue.main.async {
                guard scriptPaths.indices.contains(index) else {
                    return
                }
                scriptPaths[index] = normalizedScriptPath(relativePath)
                onChanged?()
            }
        }

        return true
    }

    private func normalizedScriptPath(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
