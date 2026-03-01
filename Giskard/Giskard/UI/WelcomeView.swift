//
//  WelcomeView.swift
//  Giskard
//
//  Created by Timothy Powell on 8/25/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showOpen = false
    @State private var recentProjects: [URL] = []
    @State private var automationStatus: String? = nil
    @Binding var showCreateProjectSheet: Bool
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        VStack(spacing: 16) {
            Text("Giskard").font(.largeTitle).bold()
            Button("Open Project") { showOpen = true }
            Button("Create Project") {
                openWindow(id: "editor")
                dismissWindow(id: "welcome")
                showCreateProjectSheet = true;
            }
            if !recentProjects.isEmpty {
                Divider()
                Text("Recent Projects")
                    .font(.headline)

                ForEach(recentProjects, id: \.path) { url in
                    Button {
                        openProject(at: url)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent)
                                .font(.body)
                            Text(url.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            if let automationStatus {
                Divider()
                Text(automationStatus)
                    .font(.caption)
                    .accessibilityIdentifier("automationStatusText")
            }
        }
        .padding(40)
        .onAppear {
            recentProjects = Array(GiskardApp.recentProjectURLs().prefix(5))
            TestAutomationRunner.startIfNeeded { status in
                automationStatus = status
            }
        }
        .fileImporter(isPresented: $showOpen, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                openProject(at: url)
            }
        }
    }

    private func openProject(at url: URL) {
        let resolvedURL = GiskardApp.resolveRecentProjectURL(url)
        guard FileManager.default.fileExists(atPath: resolvedURL.path) else {
            GiskardApp.removeRecentProject(url)
            if resolvedURL.standardizedFileURL.path != url.standardizedFileURL.path {
                GiskardApp.removeRecentProject(resolvedURL)
            }
            recentProjects = Array(GiskardApp.recentProjectURLs().prefix(5))
            return
        }

        let didStartAccessing = resolvedURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                resolvedURL.stopAccessingSecurityScopedResource()
            }
        }

        FileSys.shared.SetRootURL(url: resolvedURL)
        let didLoad = GiskardApp.loadProjectFromDirectory(resolvedURL)
        if didLoad {
                openWindow(id: "editor")
                recentProjects = Array(GiskardApp.recentProjectURLs().prefix(5))
                withTransaction(\.dismissBehavior, .destructive) {
                    dismissWindow(id: "welcome")
                }
        }
    }
}
