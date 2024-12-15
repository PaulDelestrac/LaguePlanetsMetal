//
//  NoiseFilter.swift
//  Planets
//
//  Created by Paul Delestrac on 09/12/2024.
//

import Foundation

class SimpleNoiseFilter : NoiseFilter {    
    let noise: Noise = Noise()
    let settings: NoiseSettings
    
    init(settings: NoiseSettings) {
        self.settings = settings
    }
    
    func evaluate(point: float3) -> Float {
        var noiseValue: Float = 0
        var frequency = settings.baseRoughness
        var amplitude: Float = 1
        
        for _ in 0..<settings.numLayers {
            let value = noise.Evaluate(point: point * frequency + settings.center)
            noiseValue += (value + 1) * 0.5 * amplitude
            frequency *= settings.roughness
            amplitude *= settings.persistence
        }
        noiseValue = max(0, noiseValue - settings.minValue)
        return noiseValue * settings.strength
    }
}
