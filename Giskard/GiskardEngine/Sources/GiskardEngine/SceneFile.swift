//
//  SceneFile.swift
//  Giskard
//

import Foundation

public struct SceneFile: Codable {
    public var sceneVersion: Int
    public var sceneName: String
    public var scriptPaths: [String]
    public var entities: [SceneEntityNode]

    public init(
        sceneVersion: Int = 1,
        sceneName: String,
        scriptPaths: [String] = [],
        entities: [SceneEntityNode] = []
    ) {
        self.sceneVersion = sceneVersion
        self.sceneName = sceneName
        self.scriptPaths = scriptPaths
        self.entities = entities
    }

    enum CodingKeys: String, CodingKey {
        case sceneVersion
        case sceneName
        case scriptPaths
        case entities
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sceneVersion = try container.decodeIfPresent(Int.self, forKey: .sceneVersion) ?? 1
        sceneName = try container.decode(String.self, forKey: .sceneName)
        scriptPaths = try container.decodeIfPresent([String].self, forKey: .scriptPaths) ?? []
        entities = try container.decodeIfPresent([SceneEntityNode].self, forKey: .entities) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sceneVersion, forKey: .sceneVersion)
        try container.encode(sceneName, forKey: .sceneName)
        try container.encode(scriptPaths, forKey: .scriptPaths)
        try container.encode(entities, forKey: .entities)
    }

    public static func defaultScene(named name: String = "Main Scene") -> SceneFile {
        let strippedName = (name as NSString).deletingPathExtension
        let rootEntityName = strippedName.isEmpty ? name : strippedName
        let rootEntity = SceneEntityNode(name: rootEntityName, isPhysical: false)
        return SceneFile(sceneName: name, entities: [rootEntity])
    }
}

public struct SceneEntityNode: Codable, Identifiable {
    public var id: UUID
    public var fileUUID: UUID
    public var name: String
    public var isPhysical: Bool
    public var position: [Double]
    public var rotation: [Double]
    public var scriptPaths: [String]
    public var capabilities: [String]
    public var children: [SceneEntityNode]

    public init(
        id: UUID = UUID(),
        fileUUID: UUID = UUID(),
        name: String,
        isPhysical: Bool = true,
        position: [Double] = [0, 0, 0],
        rotation: [Double] = [0, 0, 0, 1],
        scriptPaths: [String] = [],
        capabilities: [String] = [],
        children: [SceneEntityNode] = []
    ) {
        self.fileUUID = fileUUID
        self.id = SceneEntityNode.makeInstanceUUID(id, fileUUID: fileUUID)
        self.name = name
        self.isPhysical = isPhysical
        self.position = position
        self.rotation = rotation
        self.scriptPaths = scriptPaths
        self.capabilities = capabilities
        self.children = children
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fileUUID
        case name
        case isPhysical
        case position
        case rotation
        case scriptPaths
        case capabilities
        case children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try container.decode(UUID.self, forKey: .id)
        let decodedFileUUID = try container.decodeIfPresent(UUID.self, forKey: .fileUUID) ?? decodedID
        id = SceneEntityNode.makeInstanceUUID(decodedID, fileUUID: decodedFileUUID)
        fileUUID = decodedFileUUID
        name = try container.decode(String.self, forKey: .name)
        isPhysical = try container.decode(Bool.self, forKey: .isPhysical)
        position = try container.decode([Double].self, forKey: .position)
        rotation = try container.decode([Double].self, forKey: .rotation)
        scriptPaths = try container.decodeIfPresent([String].self, forKey: .scriptPaths) ?? []
        capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities) ?? []
        children = try container.decodeIfPresent([SceneEntityNode].self, forKey: .children) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileUUID, forKey: .fileUUID)
        try container.encode(name, forKey: .name)
        try container.encode(isPhysical, forKey: .isPhysical)
        try container.encode(position, forKey: .position)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scriptPaths, forKey: .scriptPaths)
        try container.encode(capabilities, forKey: .capabilities)
        try container.encode(children, forKey: .children)
    }

    private static func makeInstanceUUID(_ candidate: UUID, fileUUID: UUID) -> UUID {
        if candidate != fileUUID {
            return candidate
        }
        var generated = UUID()
        while generated == fileUUID {
            generated = UUID()
        }
        return generated
    }
}
