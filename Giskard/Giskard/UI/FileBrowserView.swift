//
//  FileBrowserView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers
import GiskardEngine

struct FileBrowserView: View {
    private enum NamePromptAction {
        case entity
        case scene
        case folder
        case rename
    }

    @State private var selectedFolder: FileNode? = nil
    @State private var selectedFile: FileNode? = nil
    @State private var showingNamePrompt = false
    @State private var namePromptAction: NamePromptAction = .entity
    @State private var renameTarget: FileNode? = nil
    @State private var newFileName = ""
    @State private var copiedItemURL: URL? = nil
    var rootNode: FileNode

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    List {
                        FileNodeView(
                            levelsNested: 0,
                            onSelectFolder: setSelectedFolder,
                            onCopyNode: { node in
                                copyItem(node)
                            },
                            onRenameNode: { node in
                                beginRenaming(node)
                            },
                            onDeleteNode: { node in
                                deleteItem(node)
                            },
                            node: rootNode,
                            selectedFolderID: selectedFolder?.id,
                            selectedFolderPath: selectedFolder?.url.path
                        )
                    }
                    .listStyle(SidebarListStyle())
                    .frame(height: geo.size.height * 0.40)
                    .contextMenu {
                        emptySpaceContextMenu
                    }
                    Divider()
                    Divider()
                    VStack(alignment: .leading) {
                        let columns = [
                            GridItem(.adaptive(minimum: 60), spacing: 16)
                        ]

                        VStack(alignment: .leading) {
                            let folder = selectedFolder ?? rootNode
                            if let items = folder.children {
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 24) {
                                        ForEach(items) { item in
                                            VStack {
                                                fileIcon(for: item)
                                                Text(displayLabel(for: item))
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .frame(maxWidth: 72)
                                            }
                                            .frame(width: 80)
                                            .padding(6)
                                            .background(selectedFile?.id == item.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                            .cornerRadius(8)
                                            .contentShape(Rectangle())
                                            .onTapGesture(count: 1) {
                                                selectedFile = item
                                            }
                                            .onTapGesture(count: 2) {
                                                activateItem(item)
                                            }
                                            .onDrag {
                                                NSItemProvider(object: item.url.path as NSString)
                                            }
                                            .contextMenu {
                                                Button("Copy") {
                                                    copyItem(item)
                                                }
                                                Button("Rename") {
                                                    beginRenaming(item)
                                                }
                                                Divider()
                                                Button("Delete", role: .destructive) {
                                                    deleteItem(item)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            } else {
                                Text("Select a folder to view its files.")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            emptySpaceContextMenu
                        }
                    }
                    .frame(height: geo.size.height * 0.53)
                    Divider()
                    Divider()
                    HStack(alignment: .top) {
                        Menu {
                            Button("Folder") {
                                beginCreatingFolder()
                            }
                            Button("Scene") {
                                beginCreatingScene()
                            }
                            Button("Entity") {
                                beginCreatingEntity()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .imageScale(.small)
                                .padding(2)
                        }
                        .help("Add")
                        Spacer()
                    }
                    .alert(
                        namePromptTitle,
                        isPresented: $showingNamePrompt,
                        actions: {
                        TextField(
                            namePromptPlaceholder,
                            text: $newFileName
                        )
                        Button(namePromptConfirmTitle) {
                            performNamePromptAction()
                        }
                        Button("Cancel", role: .cancel) { }
                    })
                    .frame(height: geo.size.height * 0.07)
                }
            }
        }
        .onAppear {
            if selectedFolder == nil {
                selectedFolder = rootNode
            }
        }
    }

    public func createNewEntityFile() {
        guard let baseURL = selectedFolder?.url else { return }
        let sanitizedEntityName = sanitizedName(newFileName) + ".entity"
        guard sanitizedEntityName != ".entity" else { return }

        do {
            let emptyEntity: Entity = Entity(sanitizedEntityName)

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(emptyEntity)

            let fileURL = baseURL.appendingPathComponent(sanitizedEntityName)
            if FileSys.shared.CreateFile(fileURL.absoluteString, data: data) {
                refreshTreePreservingSelection()
            } else {
                print("Error writing entity file: \(fileURL.absoluteString)")
            }
        } catch {
            print("Error writing entity file: \(error)")
        }
    }

    public func createNewSceneFile() {
        guard let baseURL = selectedFolder?.url else { return }
        let sanitizedSceneName = sanitizedName(newFileName) + ".scene"
        guard sanitizedSceneName != ".scene" else { return }

        do {
            let scene = SceneFile.defaultScene(named: sanitizedSceneName)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(scene)

            let fileURL = baseURL.appendingPathComponent(sanitizedSceneName)
            if FileSys.shared.CreateFile(fileURL.absoluteString, data: data) {
                refreshTreePreservingSelection()
            } else {
                print("Error writing scene file: \(fileURL.absoluteString)")
            }
        } catch {
            print("Error writing scene file: \(error)")
        }
    }

    public func setSelectedFolder(_ node: FileNode) {
        selectedFolder = node
    }

    private var emptySpaceContextMenu: some View {
        Group {
            Button("Paste") {
                pasteIntoSelectedFolder()
            }
            .disabled(copiedItemURL == nil)

            Divider()

            Button("New Folder") {
                beginCreatingFolder()
            }
            Button("New Scene") {
                beginCreatingScene()
            }
            Button("New Entity") {
                beginCreatingEntity()
            }
        }
    }

    private var namePromptTitle: String {
        switch namePromptAction {
        case .entity:
            return "New Entity Name"
        case .scene:
            return "New Scene Name"
        case .folder:
            return "New Folder Name"
        case .rename:
            return "Rename Item"
        }
    }

    private var namePromptPlaceholder: String {
        switch namePromptAction {
        case .entity:
            return "Entity Name"
        case .scene:
            return "Scene Name"
        case .folder:
            return "Folder Name"
        case .rename:
            return "Item Name"
        }
    }

    private var namePromptConfirmTitle: String {
        switch namePromptAction {
        case .rename:
            return "Rename"
        default:
            return "Create"
        }
    }

    private func beginCreatingEntity() {
        namePromptAction = .entity
        renameTarget = nil
        newFileName = ""
        showingNamePrompt = true
    }

    private func beginCreatingScene() {
        namePromptAction = .scene
        renameTarget = nil
        newFileName = ""
        showingNamePrompt = true
    }

    private func beginCreatingFolder() {
        namePromptAction = .folder
        renameTarget = nil
        newFileName = ""
        showingNamePrompt = true
    }

    private func beginRenaming(_ node: FileNode) {
        namePromptAction = .rename
        renameTarget = node
        newFileName = node.url.deletingPathExtension().lastPathComponent
        if node.isDirectory {
            newFileName = node.url.lastPathComponent
        }
        showingNamePrompt = true
    }

    private func performNamePromptAction() {
        switch namePromptAction {
        case .entity:
            createNewEntityFile()
        case .scene:
            createNewSceneFile()
        case .folder:
            createNewFolder()
        case .rename:
            applyRename()
        }
    }

    private func createNewFolder() {
        guard let baseURL = selectedFolder?.url else { return }
        let name = sanitizedName(newFileName)
        guard !name.isEmpty else { return }
        let folderURL = baseURL.appendingPathComponent(name)
        guard performSecuredFileOperation({
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: false
            )
        }) else {
            return
        }
        refreshTreePreservingSelection()
    }

    private func copyItem(_ item: FileNode) {
        copiedItemURL = item.url
    }

    private func pasteIntoSelectedFolder() {
        guard let sourceURL = copiedItemURL else { return }
        guard let targetFolder = selectedFolder?.url else { return }
        let destinationURL = uniqueDestinationURL(
            in: targetFolder,
            forName: sourceURL.lastPathComponent
        )
        guard performSecuredFileOperation({
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }) else {
            return
        }
        refreshTreePreservingSelection()
    }

    private func deleteItem(_ item: FileNode) {
        guard performSecuredFileOperation({
            try FileManager.default.removeItem(at: item.url)
        }) else {
            return
        }
        if selectedFile?.url == item.url {
            selectedFile = nil
        }
        refreshTreePreservingSelection()
    }

    private func applyRename() {
        guard let target = renameTarget else { return }
        let trimmed = newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let destinationName: String
        if target.isDirectory {
            destinationName = trimmed
        } else {
            let ext = target.url.pathExtension
            if ext.isEmpty || trimmed.lowercased().hasSuffix(".\(ext.lowercased())") {
                destinationName = trimmed
            } else {
                destinationName = "\(trimmed).\(ext)"
            }
        }

        let destinationURL = target.url.deletingLastPathComponent().appendingPathComponent(destinationName)
        guard destinationURL != target.url else { return }

        guard performSecuredFileOperation({
            try FileManager.default.moveItem(at: target.url, to: destinationURL)
        }) else {
            return
        }
        renameTarget = nil
        refreshTreePreservingSelection()
    }

    private func uniqueDestinationURL(in folderURL: URL, forName name: String) -> URL {
        var candidateURL = folderURL.appendingPathComponent(name)
        if !FileManager.default.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        let sourceURL = URL(fileURLWithPath: name)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        var suffix = 2

        while true {
            let candidateName: String
            if ext.isEmpty {
                candidateName = "\(baseName) \(suffix)"
            } else {
                candidateName = "\(baseName) \(suffix).\(ext)"
            }
            candidateURL = folderURL.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            suffix += 1
        }
    }

    private func performSecuredFileOperation(_ operation: () throws -> Void) -> Bool {
        let rootURL = rootNode.url
        let didStartAccessing = rootURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                rootURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try operation()
            return true
        } catch {
            print("File operation failed: \(error)")
            return false
        }
    }

    private func refreshTreePreservingSelection() {
        let selectedFolderPath = selectedFolder?.url.path
        let selectedFilePath = selectedFile?.url.path

        guard let refreshedRoot = loadFileNode(rootNode.url) else {
            return
        }
        rootNode.children = refreshedRoot.children

        selectedFolder = findNode(withPath: selectedFolderPath, in: rootNode) ?? rootNode
        selectedFile = findNode(withPath: selectedFilePath, in: rootNode)
    }

    private func findNode(withPath path: String?, in node: FileNode) -> FileNode? {
        guard let path else { return nil }
        if node.url.path == path {
            return node
        }
        guard let children = node.children else { return nil }
        for child in children {
            if let match = findNode(withPath: path, in: child) {
                return match
            }
        }
        return nil
    }

    private func sanitizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ":", with: "")
    }

    @ViewBuilder
    private func fileIcon(for item: FileNode) -> some View {
        if !item.isDirectory,
           item.url.pathExtension.lowercased() == "entity" {
            Image("EntityIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
        } else {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
        }
    }

    private func activateItem(_ item: FileNode) {
        if item.isDirectory {
            selectedFile = nil
            setSelectedFolder(item)
            return
        }

        selectedFile = item

        if item.url.pathExtension.lowercased() == "png" {
            GiskardApp.selectImage(item.url)
            return
        }

        if item.url.pathExtension.lowercased() == "scene" {
            GiskardApp.selectScene(item.url)
            return
        }

        if item.url.pathExtension.lowercased() != "entity" {
            return
        }

        do {
            guard let data = FileSys.shared.ReadFile(item.url.path) else {
                print("Failed to decode Entity: \(item.url.path)")
                return
            }
            let entity = try JSONDecoder().decode(Entity.self, from: data)
            GiskardApp.selectEntity(entity, fileURL: item.url)
        } catch {
            print("Failed to decode Entity: \(error)")
        }
    }

    private func displayLabel(for item: FileNode) -> String {
        guard !item.isDirectory else {
            return item.url.lastPathComponent
        }
        if item.url.pathExtension.lowercased() == "entity" {
            return item.url.deletingPathExtension().lastPathComponent
        }
        return item.url.lastPathComponent
    }
}

#Preview {
    if let documentsNode = loadFileNode(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) {
        FileBrowserView(rootNode: documentsNode)
    }
}
