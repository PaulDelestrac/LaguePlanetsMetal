//
//  NoiseSettings.swift
//  Planets
//
//  Created by Paul Delestrac on 09/12/2024.
//

import Foundation
import SwiftData

@Model
class NoiseSettings {
    
    enum FilterType: Int, Codable, Hashable {
        case Simple
        case Ridgid
    }
    var filterType: FilterType = FilterType.Simple

    var strength: Float = 1.0
    var numLayers: Int = 1
    var baseRoughness: Float = 1.0
    var roughness: Float = 2.0
    var persistence: Float = 0.5
    var center: float3 = float3(0.0, 0.0, 0.0)
    var minValue: Float = 0.0
    
    var weightMultiplier: Float = 0.8

    init() {}
}
