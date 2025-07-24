//
//  EntitySystem.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation

class EntitySystem {
    static private var entities: [Entity] = []
    static private var rootEntity: Entity?
    
    static func addEntity(_ entity: Entity) {
        
        if let index = entities.firstIndex(where: { $0.id == entity.id }) {
            return;
        }
        
        entities.append(entity)
    }
    
    static func removeEntity(_ entity: Entity) {
        if let index = entities.firstIndex(where: { $0.id == entity.id }) {
            entities.remove(at: index)
        }
    }
    
    static func getEntityById(_ id: UUID) -> Entity? {
        return entities.first(where: { $0.id == id })
    }
}
