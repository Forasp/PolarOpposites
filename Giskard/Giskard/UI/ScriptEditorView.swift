//
//  ScriptEditorView.swift
//  Giskard
//

import SwiftUI

struct ScriptEditorView: View {
    @State private var scriptURL: URL? = GiskardApp.selectedScriptFileURL
    @State private var scriptText: String = ""
    @State private var isDirty = false
    @State private var statusText: String? = nil

    private var scriptName: String {
        scriptURL?.lastPathComponent ?? "No Script Selected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scriptName)
                    .font(.headline)
                Spacer()
                Button("Save") {
                    saveScript()
                }
                .disabled(!isDirty || scriptURL == nil)
            }

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextEditor(text: $scriptText)
                .font(.system(.body, design: .monospaced))
                .border(Color.secondary.opacity(0.2))
                .onChange(of: scriptText) { _, _ in
                    isDirty = true
                }
        }
        .padding()
        .onAppear {
            reloadFromSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .inspectorSelectionChanged)) { _ in
            reloadFromSelection()
        }
    }

    private func reloadFromSelection() {
        scriptURL = GiskardApp.selectedScriptFileURL
        statusText = nil

        guard let scriptURL else {
            scriptText = ""
            isDirty = false
            return
        }

        if let data = FileSys.shared.ReadFile(scriptURL.path),
           let contents = String(data: data, encoding: .utf8) {
            scriptText = contents
            isDirty = false
            return
        }

        scriptText = EditorProjectSupport.defaultScriptTemplate
        isDirty = true
    }

    private func saveScript() {
        guard let scriptURL else {
            return
        }

        guard let data = scriptText.data(using: .utf8) else {
            statusText = "The current script contents could not be encoded as UTF-8."
            return
        }

        if FileSys.shared.WriteFile(scriptURL.path, data: data) {
            isDirty = false
            statusText = "Saved."
        } else {
            statusText = "Failed to save \(scriptURL.lastPathComponent)."
        }
    }
}

#Preview {
    ScriptEditorView()
}
