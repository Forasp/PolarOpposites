//
//  CapabilitySystem.swift
//  Giskard
//
//  Created by Timothy Powell on 7/24/25.
//

import Foundation

class CapabilitySystem {
    public static var AllCapabilities: [Capability.Type] = [Movable.self]
    
    public static func CapabilityToString<T: Capability>(_ capability: T.Type) -> String {
        String(describing: capability)
    }
    
    public static func StringToCapability<T: Capability>(_ string: String) -> T.Type? {
        (CapabilitySystem.AllCapabilities as [AnyObject.Type]).compactMap {
            $0 as? T.Type
        }.first {
            String(describing: $0) == string
        }
    }
}
