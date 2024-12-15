//
//  RigidNoiseFilter.swift
//  Planets
//
//  Created by Paul Delestrac on 10/12/2024.
//

import Foundation

class RidgidNoiseFilter : NoiseFilter {
    let noise: Noise = Noise()
    let settings: NoiseSettings
    
    init(settings: NoiseSettings) {
        self.settings = settings
    }
    
    func evaluate(point: float3) -> Float {
        var noiseValue: Float = 0
        var frequency = settings.baseRoughness
        var amplitude: Float = 1
        var weight: Float = 1
        
        for _ in 0..<settings.numLayers {
            var value = 1 - abs(noise.Evaluate(point: point * frequency + settings.center))
            value *= value
            value *= weight
            weight = simd_clamp(value * settings.weightMultiplier, 0, 1)
            
            noiseValue += value * amplitude
            frequency *= settings.roughness
            amplitude *= settings.persistence
        }
        noiseValue = max(0, noiseValue - settings.minValue)
        return noiseValue * settings.strength
    }
}
