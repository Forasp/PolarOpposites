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

struct FileBrowserView: View {
    @State private var selectedFolder: FileNode? = nil
    @State private var selectedFile: FileNode? = nil
    @State private var showingNewEntityPrompt = false
    @State private var newEntityName = ""
    var rootNode: FileNode

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    List {
                        FileNodeView(
                            levelsNested: 0,
                            onSelectFolder: setSelectedFolder,
                            node: rootNode,
                            selectedFolderID: selectedFolder?.id,
                            selectedFolderPath: selectedFolder?.url.path
                        )
                    }
                    .listStyle(SidebarListStyle())
                    .frame(height: geo.size.height * 0.40)
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
                                                Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 40, height: 40)
                                                Text(item.url.lastPathComponent)
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
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            } else {
                                Text("Select a folder to view its files.")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: geo.size.height * 0.53)
                    Divider()
                    Divider()
                    HStack(alignment: .top) {
                        Button(action: {
                            newEntityName = ""
                            showingNewEntityPrompt = true
                        }) {
                            Image(systemName: "plus")
                                .imageScale(.small)
                                .padding(2)
                        }
                        .help("Create an Entity")
                        Spacer()
                    }
                    .alert("New Entity Name", isPresented: $showingNewEntityPrompt, actions: {
                        TextField("Entity Name", text: $newEntityName)
                        Button("Create") {
                            createNewEntityFile()
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
        let sanitizedEntityName = newEntityName.replacingOccurrences(of: " ", with: "") + ".json"

        do {
            let emptyEntity: Entity = Entity(sanitizedEntityName)

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(emptyEntity)

            let fileURL = baseURL.appendingPathComponent(sanitizedEntityName)
            if FileSys.shared.CreateFile(fileURL.absoluteString, data: data) {
                selectedFolder?.children?.append(FileNode(url: fileURL, isDirectory: false))
            } else {
                print("Error writing entity file: \(fileURL.absoluteString)")
            }
        } catch {
            print("Error writing entity file: \(error)")
        }
    }

    public func setSelectedFolder(_ node: FileNode) {
        selectedFolder = node
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
}

#Preview {
    if let documentsNode = loadFileNode(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) {
        FileBrowserView(rootNode: documentsNode)
    }
}
