//
//  FileNodeView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import SwiftUI

struct FileNodeView: View {
    let levelsNested: Int
    let onSelectFolder: (FileNode) -> Void
    let onCopyNode: (FileNode) -> Void
    let onRenameNode: (FileNode) -> Void
    let onDeleteNode: (FileNode) -> Void
    let node: FileNode
    let selectedFolderID: UUID?
    let selectedFolderPath: String?

    @State private var expanded = false

    var body: some View {
        if node.isDirectory {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Image(systemName: "folder")
                    Text(node.url.lastPathComponent)
                        .lineLimit(1)
                }
                .padding(.vertical, 3)
                .padding(.leading, CGFloat(levelsNested * 12))
                .contentShape(Rectangle())
                .background(selectedFolderID == node.id ? Color.accentColor.opacity(0.25) : Color.clear)
                .onTapGesture {
                    expanded.toggle()
                    onSelectFolder(node)
                }
                .contextMenu {
                    Button("Copy") {
                        onCopyNode(node)
                    }
                    Button("Rename") {
                        onRenameNode(node)
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        onDeleteNode(node)
                    }
                }

                if expanded, let children = node.children {
                    ForEach(children.filter(\.isDirectory)) { child in
                        FileNodeView(
                            levelsNested: levelsNested + 1,
                            onSelectFolder: onSelectFolder,
                            onCopyNode: onCopyNode,
                            onRenameNode: onRenameNode,
                            onDeleteNode: onDeleteNode,
                            node: child,
                            selectedFolderID: selectedFolderID,
                            selectedFolderPath: selectedFolderPath
                        )
                    }
                }
            }
            .onAppear {
                if shouldAutoExpand {
                    expanded = true
                }
            }
            .onChange(of: selectedFolderPath) { _, _ in
                if shouldAutoExpand {
                    expanded = true
                }
            }
        }
    }

    private var shouldAutoExpand: Bool {
        guard let selectedFolderPath else {
            return false
        }
        let nodePath = node.url.path
        return selectedFolderPath == nodePath || selectedFolderPath.hasPrefix(nodePath + "/")
    }
}

#Preview {
    if let documentsNode = loadFileNode(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) {
        FileNodeView(
            levelsNested: 0,
            onSelectFolder: { _ in },
            onCopyNode: { _ in },
            onRenameNode: { _ in },
            onDeleteNode: { _ in },
            node: documentsNode,
            selectedFolderID: nil,
            selectedFolderPath: nil
        )
    }
}
