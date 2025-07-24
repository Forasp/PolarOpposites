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

func loadFileNode(_ url: URL) -> FileNode? {
    let accessGranted = url.startAccessingSecurityScopedResource()
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir){
        let isDirectory = isDir.boolValue

        var children: [FileNode] = []
        if isDirectory {
            do {
                FileManager.default.changeCurrentDirectoryPath(url.path)
                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for itemURL in contents {
                    if let fileNode = loadFileNode(url.appendingPathComponent(itemURL.lastPathComponent)){
                        children.append(fileNode)
                    }
                    FileManager.default.changeCurrentDirectoryPath(url.path)
                }
            }
            catch{
                print("Error info: \(error)")
            }
        }
        if(accessGranted){
            url.stopAccessingSecurityScopedResource()
        }
        return FileNode(url: url, isDirectory: isDirectory, children: children)
    }
    
    if(accessGranted){
        url.stopAccessingSecurityScopedResource()
    }
    return nil
}
