//
//  FileBrowserView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import SwiftUI
import AppKit
import Foundation

struct FileBrowserView: View {
    @State private var selectedFolder: FileNodeView? = nil
    @State private var selectedFile: FileNode? = nil
    @State private var showingNewEntityPrompt = false
    @State private var newEntityName = ""
    var rootNode: FileNode

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    List {
                        FileNodeView(levelsNested: .constant(0), onSelectFolder: .constant(setSelectedFolder), node: rootNode)
                    }
                    .listStyle(SidebarListStyle())
                    .frame(height: geo.size.height * 0.40)
                    Divider()
                    Divider()
                    VStack(alignment: .leading)  {
                        let columns = [
                            GridItem(.adaptive(minimum: 60), spacing: 16)
                        ]

                        VStack(alignment: .leading) {
                            if let folder = selectedFolder?.node, let files = folder.children?.filter({ !$0.isDirectory }) {
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 24) {
                                        ForEach(files) { file in
                                            Button(action: {
                                                do {
                                                    selectedFile = file
                                                    guard let data = FileSys.shared.ReadFile(file.url.path) else { print("Failed to decode Entity: \(file.url.path)");return}
                                                    let entity = try JSONDecoder().decode(Entity.self, from: data)
                                                    GiskardApp.selectEntity(entity)
                                                }
                                                catch {
                                                    print("Failed to decode Entity: \(error)")
                                                }
                                            }) {
                                                VStack {
                                                    Image(nsImage: NSWorkspace.shared.icon(forFile: file.url.path))
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 40, height: 40)
                                                    Text(file.url.lastPathComponent)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                        .frame(maxWidth: 72)
                                                }
                                                .frame(width: 80)
                                                .padding(6)
                                                .background(selectedFile?.id == file.id ? Color.accentColor.opacity(0.25) : Color.clear)
                                                .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
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
                    HStack (alignment: .top){
                        Button(action: {
                            newEntityName = ""
                            showingNewEntityPrompt = true
                        }) {
                            Image(systemName: "plus")
                                .imageScale(.small)
                                .padding(2)
                        }
                        .help("Create an Entity") // <-- hover text on macOS
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
    }
    
    public func createNewEntityFile() {
        
        guard let baseURL = selectedFolder?.node.url else { return }
        let sanitizedEntityName = newEntityName.replacingOccurrences(of: " ", with: "") + ".json"
        
        var didStartAccessing = false
            
        do {
            let emptyEntity:Entity = Entity(sanitizedEntityName);
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(emptyEntity)
            
            // Write the settings file
            let fileURL = baseURL.appendingPathComponent(sanitizedEntityName)
            if (FileSys.shared.CreateFile(fileURL.absoluteString, data: data)){
                selectedFolder?.node.children?.append(FileNode(url: fileURL, isDirectory: false))
            }
            else {
                print("Error writing entity file: \(fileURL.absoluteString)")
            }
        }
        catch {
            print("Error writing entity file: \(error)")
        }
    }
    
    public func setSelectedFolder(_ node: FileNodeView?) {
        if (selectedFolder?.node.id != node?.node.id) {
            selectedFolder?.setSelected(false)
            selectedFolder = node;
        }
        
        selectedFolder?.setSelected(true)
    }
}

#Preview {
    if let documentsNode = loadFileNode(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!){
        FileBrowserView(rootNode:documentsNode)
    }
}
