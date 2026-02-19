//
//  FileSys.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation

class FileSys{
    static let shared = FileSys()
    
    var fileManager:FileManager = .default
    var rootURL:URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    var rootURLDelimier:String = ""
    
    private init(){
        
    }
    
    public func PathToURL(path: String) -> URL{
        if path.isEmpty {
            return rootURL
        }

        if path.hasPrefix("file://"), let url = URL(string: path), url.isFileURL {
            return url
        }

        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }

        return rootURL.appendingPathComponent(path)
    }
    
    public func SetRootURL(url: URL){
        rootURL = url
        rootURLDelimier = String(url.path.dropFirst(10)).appending("/")
    }
    
    private func IsPathDirectory(url: URL) -> Bool{
        
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        var isDir: ObjCBool = false;
        fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    private func CreateFolder(url: URL) -> Bool{
        
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // Create the project directory if it doesn't exist
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            return true
        }
        catch {
            // Handle error (show alert or log)
            print("Failed to create folder: \(error.localizedDescription)")
            return false
        }
    }
    
    private func CreateFile(url: URL, data:Data?) -> Bool{
        
        var didStartAccessing = false
        var bSuccess = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        bSuccess = fileManager.createFile(atPath: url.path, contents: data)
        
        return bSuccess
    }
    
    private func DoesFileExist(url: URL) -> Bool{
        
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private func GetFilesInDirectory(url: URL, folders:Bool = false) -> [String]{
        
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do{
            var retArray:[String] = []
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for itemURL in contents {
                if IsPathDirectory(url: itemURL) == folders{
                    retArray.append(itemURL.lastPathComponent)
                }
            }
            
            return retArray
        }
        catch{
            return []
        }
    }
    
    private func ReadFile(url: URL) -> Data?{
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        return fileManager.contents(atPath:url.path)
    }

    private func WriteFile(url: URL, data: Data) -> Bool {
        var didStartAccessing = false
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            print("Failed to write file: \(error)")
            return false
        }
    }
    
    public func IsPathDirectory(_ path: String) -> Bool{
        
        return IsPathDirectory(url:PathToURL(path: path))
    }
    
    public func CreateFolder(_ path: String) -> Bool{
        
        return CreateFolder(url:PathToURL(path: path))
    }
    
    public func CreateFile(_ path: String, data:Data?) -> Bool{
        
        return CreateFile(url:PathToURL(path: path), data:data)
    }
    
    public func DoesFileExist(_ path: String) -> Bool{
        
        return DoesFileExist(url:PathToURL(path: path))
    }
    
    public func GetFilesInDirectory(_ path: String) -> [String]{
        return GetFilesInDirectory(url:PathToURL(path: path), folders:false)
    }
    
    public func GetFoldersInDirectory(_ path: String) -> [String]{
        return GetFilesInDirectory(url:PathToURL(path: path), folders:true)
    }
    
    public func ReadFile(_ path: String) -> Data?{
        
        return ReadFile(url:PathToURL(path: path))
    }

    public func WriteFile(_ path: String, data: Data) -> Bool {
        return WriteFile(url: PathToURL(path: path), data: data)
    }
    
}
