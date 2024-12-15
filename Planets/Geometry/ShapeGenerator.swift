//
//  ShapeGenerator.swift
//  Planets
//
//  Created by Paul Delestrac on 08/12/2024.
//

import Foundation
import MetalKit

class ShapeGenerator {
    let settings: ShapeSettings
    var noiseFilters: [NoiseFilter]
    
    init(settings: ShapeSettings) {
        self.settings = settings
        self.noiseFilters = []
        for noiseLayer in settings.noiseLayers {
            self.noiseFilters.append(NoiseFilterManager.createNoiseFilter(settings: noiseLayer.noiseSettings))
        }
    }
    
    func calculatePointOnPlanet(pointOnUnitSphere: float3) -> float3 {
        var firstLayerValue: Float = 0
        var elevation: Float = 0
        if (noiseFilters.count > 0) {
            firstLayerValue = noiseFilters[0].evaluate(point: pointOnUnitSphere)
            if settings.noiseLayers[0].enabled {
                elevation = firstLayerValue
            }
        }
        for (index, noiseFilter) in noiseFilters.enumerated() {
            if index == 0 {
                continue
            }
            if settings.noiseLayers[index].enabled {
                let mask: Float = (settings.noiseLayers[index].useFirstLayerAsMask ? firstLayerValue : 1)
                elevation += noiseFilter.evaluate(point: pointOnUnitSphere) * mask
            }
        }
        let radius = settings.planetRadius
        return pointOnUnitSphere * radius * (1 + elevation)
    }
}
