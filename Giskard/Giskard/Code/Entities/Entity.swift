//
//  Entity.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation
import Spatial

class Entity: Codable{
    // External Facing
    public var id: UUID
    public var name: String
    public var isPhysical: Bool
    public var position: Point3D
    public var rotation: Rotation3D
    public var children: [UUID]
    public var capabilities: [Capability.Type] = []
    
    public init(_ name: String, uuid: UUID = UUID(), physical: Bool = true, pos: Point3D = .zero, rot: Rotation3D = .identity, child:[UUID] = [], caps: [Capability.Type] = [])
    {
        id = uuid
        self.name = name
        isPhysical = physical
        position = pos
        rotation = rot
        children = child
        capabilities = caps
    }
    
    // Internal facing
    private var childEntities: [Entity] = []
    
    // Choose Encodable Properties
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isPhysical
        case position
        case rotation
        case children
    }
}
