//
//  FileNode.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import Foundation

struct FileNode: Identifiable {
    let id = UUID()
    let url: URL
    var isDirectory: Bool
    var children: [FileNode]? = nil
}

func loadFileNode(for url: URL) -> FileNode {
    var isDir: ObjCBool = false
    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
    let isDirectory = isDir.boolValue

    var children: [FileNode]? = nil
    if isDirectory {
        if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
            children = contents.map { loadFileNode(for: $0) }
        }
    }
    return FileNode(url: url, isDirectory: isDirectory, children: children)
}
