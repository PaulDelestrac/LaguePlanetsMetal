//
//  ShapeSettings.swift
//  Planets
//
//  Created by Paul Delestrac on 08/12/2024.
//

import Foundation

@Observable class ShapeSettings {
    var resolution: Int = 10
    var planetRadius: Float = 1.0
    var noiseLayers = [NoiseLayer]()
    var isChanging = false
    var needsUpdate: Bool = true
    var faceRenderMask: Planet.FaceRenderMask = .All
    
    init() {
    }
    
    func addNoiseLayer() {
        self.noiseLayers.append(NoiseLayer())
    }
    
    init(planetRadius: Float) {
        self.planetRadius = planetRadius
    }
    
    class NoiseLayer : Identifiable {
        let id: UUID = UUID()
        var noiseSettings: NoiseSettings = NoiseSettings()
        var enabled: Bool = true
        var useFirstLayerAsMask: Bool = true
    }
}
