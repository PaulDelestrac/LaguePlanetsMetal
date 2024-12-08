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
    
    init(settings: ShapeSettings) {
        self.settings = settings
    }
    
    func calculatePointOnPlanet(pointOnUnitSphere: float3) -> float3 {
        let radius = settings.planetRadius
        return pointOnUnitSphere * radius
    }
}
