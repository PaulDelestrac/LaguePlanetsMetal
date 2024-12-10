//
//  NoiseSettings.swift
//  Planets
//
//  Created by Paul Delestrac on 09/12/2024.
//

import Foundation

class NoiseSettings {
    var strength: Float = 1.0
    var numLayers: Int = 1
    var baseRoughness: Float = 1.0
    var roughness: Float = 2.0
    var persistence: Float = 0.5
    var center: float3 = float3(0.0, 0.0, 0.0)
    var minValue: Float = 0.0
}
