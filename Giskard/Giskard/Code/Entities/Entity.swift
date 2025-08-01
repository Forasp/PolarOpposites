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
    public var capabilities: [String] = []
    
    public init(_ name: String, uuid: UUID = UUID(), physical: Bool = true, pos: Point3D = .zero, rot: Rotation3D = .identity, child:[UUID] = [], caps: [String] = [])
    {
        id = uuid
        self.name = name
        isPhysical = physical
        position = pos
        rotation = rot
        children = child
        capabilities = caps
        capabilitiesInternal = []
        for cap in caps {
            if let capType = CapabilitySystem.StringToCapability(cap) {
                capabilitiesInternal.append(capType)
            }
        }
    }
    
    public func AddCapability(capability: String){
        capabilities.append(capability)
    }
    
    public func RemoveCapability(capability: String){
        if let index = capabilities.firstIndex(of: capability) {
            capabilities.remove(at: index)
        }
    }
    
    public func RemoveAllCapabilities(){
        capabilities.removeAll()
    }
    
    // Internal facing
    private var childEntities: [Entity] = []
    private var capabilitiesInternal: [Capability.Type] = []
    
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
