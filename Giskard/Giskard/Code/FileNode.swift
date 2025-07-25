//
//  FileNode.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import Foundation

class FileNode: Identifiable {
    public let id = UUID()
    public var url: URL = URL(fileURLWithPath: "")
    public var isDirectory: Bool = false
    public var children: [FileNode]? = nil
    
    init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.isDirectory = isDirectory
        self.children = children
        self.url = url
    }
}

func loadFileNode(_ url: URL) -> FileNode? {
    if FileSys.shared.DoesFileExist(url.absoluteString){
        let isDirectory = FileSys.shared.IsPathDirectory(url.absoluteString)

        var children: [FileNode] = []
        if isDirectory {
            // Add folders first
            FileSys.shared.GetFoldersInDirectory(url.absoluteString).forEach {
                if let fileNode = loadFileNode(url.appendingPathComponent($0)){
                    children.append(fileNode)
                }
            }
            // Add files second
            FileSys.shared.GetFilesInDirectory(url.absoluteString).forEach {
                if let fileNode = loadFileNode(url.appendingPathComponent($0)){
                    children.append(fileNode)
                }
            }
        }
        return FileNode(url: url, isDirectory: isDirectory, children: children)
    }
    return nil
}
