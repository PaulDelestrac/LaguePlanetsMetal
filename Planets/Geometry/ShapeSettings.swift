//
//  ShapeSettings.swift
//  Planets
//
//  Created by Paul Delestrac on 08/12/2024.
//

import Foundation
import SwiftData

@Model
class ShapeSettings {
    var resolution: Int = 10
    var planetRadius: Float = 1.0
    var noiseLayers: [NoiseLayer] = [NoiseLayer]()
    var isChanging = false
    var needsUpdate: Bool = true
    var faceRenderMask: Planet.FaceRenderMask = Planet.FaceRenderMask.All

    init() {}

    init(planetRadius: Float) {
        self.planetRadius = planetRadius
    }

    func addNoiseLayer() {
        self.noiseLayers.append(NoiseLayer())
    }

    @Model
    class NoiseLayer {
        var enabled: Bool = true
        var useFirstLayerAsMask: Bool = true

        // Store NoiseSettings separately - this avoids SIMD persistence issues
        @Relationship(deleteRule: .cascade) var noiseSettingsData = NoiseSettingsData()

        // Transient computed property that converts between persistable data and SIMD types
        @Transient var noiseSettings: NoiseSettings {
            get {
                let settings = NoiseSettings()
                settings.filterType = self.noiseSettingsData.filterType
                settings.strength = self.noiseSettingsData.strength
                settings.numLayers = self.noiseSettingsData.numLayers
                settings.baseRoughness = self.noiseSettingsData.baseRoughness
                settings.roughness = self.noiseSettingsData.roughness
                settings.persistence = self.noiseSettingsData.persistence
                settings.center = float3(
                    self.noiseSettingsData.centerX,
                    self.noiseSettingsData.centerY,
                    self.noiseSettingsData.centerZ
                )
                settings.minValue = self.noiseSettingsData.minValue
                settings.weightMultiplier = self.noiseSettingsData.weightMultiplier
                return settings
            }
            set {
                self.noiseSettingsData.filterType = newValue.filterType
                self.noiseSettingsData.strength = newValue.strength
                self.noiseSettingsData.numLayers = newValue.numLayers
                self.noiseSettingsData.baseRoughness = newValue.baseRoughness
                self.noiseSettingsData.roughness = newValue.roughness
                self.noiseSettingsData.persistence = newValue.persistence
                self.noiseSettingsData.centerX = newValue.center.x
                self.noiseSettingsData.centerY = newValue.center.y
                self.noiseSettingsData.centerZ = newValue.center.z
                self.noiseSettingsData.minValue = newValue.minValue
                self.noiseSettingsData.weightMultiplier = newValue.weightMultiplier
            }
        }

        init() {}
    }
}

// Persistable version of NoiseSettings without SIMD types
@Model
class NoiseSettingsData {
    var filterType: NoiseSettings.FilterType = NoiseSettings.FilterType.Simple
    var strength: Float = 1.0
    var numLayers: Int = 1
    var baseRoughness: Float = 1.0
    var roughness: Float = 2.0
    var persistence: Float = 0.5

    // Decomposed float3 into individual components
    var centerX: Float = 0.0
    var centerY: Float = 0.0
    var centerZ: Float = 0.0

    var minValue: Float = 0.0
    var weightMultiplier: Float = 0.8

    init() {}
}
