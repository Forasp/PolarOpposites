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
    public var childEntityPaths: [String] = []
    public var capabilities: [String] = []
    
    public init(_ name: String, uuid: UUID = UUID(), physical: Bool = true, pos: Point3D = .zero, rot: Rotation3D = .identity, child:[UUID] = [], childPaths: [String] = [], caps: [String] = [])
    {
        id = uuid
        self.name = name
        isPhysical = physical
        position = pos
        rotation = rot
        children = child
        childEntityPaths = childPaths
        capabilities = caps
        capabilitiesInternal = []
        for cap in caps {
            if let capType = CapabilitySystem.StringToCapability(cap) {
                capabilitiesInternal.append(capType)
            }
        }
        registerExistingCapabilities()
    }
    
    public func AddCapability(capability: String){
        guard !capabilities.contains(capability) else {
            return
        }

        capabilities.append(capability)
        if let capType = CapabilitySystem.StringToCapability(capability) {
            capabilitiesInternal.append(capType)
        }
        CapabilitySystem.AddCapability(capability, entity: self)
    }
    
    public func RemoveCapability(capability: String){
        if let index = capabilities.firstIndex(of: capability) {
            capabilities.remove(at: index)
        }
        capabilitiesInternal.removeAll {
            String(describing: $0) == capability
        }
        CapabilitySystem.RemoveCapability(capability, entity: self)
    }
    
    public func RemoveAllCapabilities(){
        let existingCapabilities = capabilities
        for capability in existingCapabilities {
            RemoveCapability(capability: capability)
        }
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
        case childEntityPaths
        case capabilities
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isPhysical = try container.decode(Bool.self, forKey: .isPhysical)
        position = try container.decode(Point3D.self, forKey: .position)
        rotation = try container.decode(Rotation3D.self, forKey: .rotation)
        children = try container.decodeIfPresent([UUID].self, forKey: .children) ?? []
        childEntityPaths = try container.decodeIfPresent([String].self, forKey: .childEntityPaths) ?? []
        capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities) ?? []

        capabilitiesInternal = []
        for cap in capabilities {
            if let capType = CapabilitySystem.StringToCapability(cap) {
                capabilitiesInternal.append(capType)
            }
        }
        registerExistingCapabilities()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isPhysical, forKey: .isPhysical)
        try container.encode(position, forKey: .position)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(children, forKey: .children)
        try container.encode(childEntityPaths, forKey: .childEntityPaths)
        try container.encode(capabilities, forKey: .capabilities)
    }

    private func registerExistingCapabilities() {
        for capability in capabilities {
            CapabilitySystem.AddCapability(capability, entity: self)
        }
    }
}
