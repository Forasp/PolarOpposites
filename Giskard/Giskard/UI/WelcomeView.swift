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
        }
        .padding(40)
        .onAppear {
            recentProjects = Array(GiskardApp.recentProjectURLs().prefix(5))
        }
        .fileImporter(isPresented: $showOpen, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                openProject(at: url)
            }
        }
    }

    private func openProject(at url: URL) {
        let resolvedURL = GiskardApp.resolveRecentProjectURL(url)
        let didStartAccessing = resolvedURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                resolvedURL.stopAccessingSecurityScopedResource()
            }
        }

        FileSys.shared.SetRootURL(url: resolvedURL)
        if GiskardApp.loadProjectFromDirectory(resolvedURL) {
                openWindow(id: "editor")
                recentProjects = Array(GiskardApp.recentProjectURLs().prefix(5))
                withTransaction(\.dismissBehavior, .destructive) {
                    dismissWindow(id: "welcome")
                }
        }
    }
}
