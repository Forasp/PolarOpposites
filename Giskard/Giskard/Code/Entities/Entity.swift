//
//  Entity.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation
import Spatial

struct Entity: Codable{
    // External Facing
    var id: UUID
    var name: String
    var isPhysical: Bool
    var position: Point3D
    var rotation: Rotation3D
    var children: [UUID]
    
    // Internal facing
    var childEntities: [Entity] = []
    
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
