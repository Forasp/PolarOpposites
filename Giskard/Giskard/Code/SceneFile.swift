//
//  SceneFile.swift
//  Giskard
//

import Foundation

struct SceneFile: Codable {
    var sceneVersion: Int
    var sceneName: String
    var entities: [SceneEntityNode]

    init(sceneVersion: Int = 1, sceneName: String, entities: [SceneEntityNode] = []) {
        self.sceneVersion = sceneVersion
        self.sceneName = sceneName
        self.entities = entities
    }

    static func defaultScene(named name: String = "Main Scene") -> SceneFile {
        let strippedName = (name as NSString).deletingPathExtension
        let rootEntityName = strippedName.isEmpty ? name : strippedName
        let rootEntity = SceneEntityNode(name: rootEntityName, isPhysical: false)
        return SceneFile(sceneName: name, entities: [rootEntity])
    }
}

struct SceneEntityNode: Codable, Identifiable {
    var id: UUID
    var name: String
    var isPhysical: Bool
    var position: [Double]
    var rotation: [Double]
    var capabilities: [String]
    var children: [SceneEntityNode]

    init(
        id: UUID = UUID(),
        name: String,
        isPhysical: Bool = true,
        position: [Double] = [0, 0, 0],
        rotation: [Double] = [0, 0, 0, 1],
        capabilities: [String] = [],
        children: [SceneEntityNode] = []
    ) {
        self.id = id
        self.name = name
        self.isPhysical = isPhysical
        self.position = position
        self.rotation = rotation
        self.capabilities = capabilities
        self.children = children
    }
}
