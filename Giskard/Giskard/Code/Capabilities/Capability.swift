//
//  Capability.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation

class Capability: Codable {
    
    init(_ entityID: UUID, enabled: Bool = true) {
        self.entity = entityID
        self.entityInstance = EntitySystem.getEntityById(entityID)
        self.enabled = enabled
    }
    
    init(_ entity: Entity, enabled: Bool = true) {
        self.entityInstance = entity
        self.entity = entity.id
        self.enabled = enabled
    }
    
    public var enabled: Bool = true
    public var entity: UUID
    
    private var entityInstance: Entity?
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case entity
    }
}
