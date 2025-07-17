//
//  FileBrowserView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import SwiftUI
import AppKit
struct FileBrowserView: View {
    @State private var selectedFolder: FileNodeView? = nil
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
                    .frame(height: geo.size.height * 0.60)
                }
            }
        }
    }
    
    public func setSelectedFolder(_ node: FileNodeView?) {
        selectedFolder?.setSelected(false)
        selectedFolder = node;
        selectedFolder?.setSelected(true)
    }
}

#Preview {
    let documentsNode = loadFileNode(for: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
    FileBrowserView(rootNode:documentsNode)
}
