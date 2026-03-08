//
//  CapabilitySystem.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation

public class CapabilitySystem {
    public static var AllCapabilities: [Capability.Type] = [
        Movable.self,
        Camera.self,
        Renderable2D.self,
        Renderable3D.self,
    ]
    private static var Entities: [String: [Entity]] = [:]
    
    public static func CapabilityToString<T: Capability>(_ capability: T.Type) -> String {
        String(describing: capability)
    }
    
    public static func StringToCapability<T: Capability>(_ string: String) -> T.Type? {
        let normalized = GetCapabilityKey(for: string)
        return (CapabilitySystem.AllCapabilities as [AnyObject.Type]).compactMap {
            $0 as? T.Type
        }.first {
            String(describing: $0) == normalized
        }
    }

    public static func AddCapability(_ capability: String, entity: Entity) {
        let key = GetCapabilityKey(for: capability)
        var entities = Entities[key] ?? []
        guard !entities.contains(where: { $0.id == entity.id }) else {
            return
        }
        entities.append(entity)
        Entities[key] = entities
    }

    public static func RemoveCapability(_ capability: String, entity: Entity) {
        let key = GetCapabilityKey(for: capability)
        guard var entities = Entities[key] else {
            return
        }
        entities.removeAll { $0.id == entity.id }
        Entities[key] = entities
    }

    private static func GetCapabilityKey(for capability: String) -> String {
        let trimmed = capability.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return capability
        }

        if let matchingCapability = AllCapabilities.first(where: {
            String(describing: $0).caseInsensitiveCompare(trimmed) == .orderedSame
        }) {
            return String(describing: matchingCapability)
        }
        return trimmed
    }
}
