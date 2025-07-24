//
//  Movable.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation
import Spatial

class Movable: Capability {
    public var velocity: Vector3D = .zero
    public var acceleration: Vector3D = .zero
}
