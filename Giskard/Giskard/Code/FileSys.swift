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
    
    private func PathToURL(path: String) -> URL{
        let components = path.components(separatedBy: rootURLDelimier)
        var pathString:String = ""
        switch components.count {
        case 0:
            // Empty string, or malformed root directory. Error out.
            exit(404)
            break
        case 1:
            // String was likely relative path
            pathString = components[0]
            break
        default:
            // String was likely file:// formatted
            pathString = components[1]
        }
        
        if (pathString.count > 0)
        {
            return rootURL.appendingPathComponent(pathString)
        }
        else
        {
            return rootURL
        }
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
        if rootURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }

        defer {
           if didStartAccessing {
               rootURL.stopAccessingSecurityScopedResource()
            }
        }
        
        return fileManager.createFile(atPath: url.path, contents: data)
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
    
}
