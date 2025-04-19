//
//  ShapeSettings.swift
//  Planets
//
//  Created by Paul Delestrac on 08/12/2024.
//

import Foundation

@Observable class ShapeSettings: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    var resolution: Int = 10
    var planetRadius: Float = 1.0
    var noiseLayers: [NoiseLayer] = [NoiseLayer]()
    var isChanging = false
    var needsUpdate: Bool = true
    var isColorChanging = false
    var colorNeedsUpdate: Bool = true
    var faceRenderMask: Planet.FaceRenderMask = .All

    init() {
        self.id = UUID()
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    init(planetRadius: Float) {
        self.id = UUID()
        self.planetRadius = planetRadius
    }

    func addNoiseLayer() {
        self.noiseLayers.append(NoiseLayer())
    }

    class NoiseLayer: Identifiable, Codable {
        var id: UUID = UUID()
        var noiseSettings: NoiseSettings = NoiseSettings()
        var enabled: Bool = true
        var useFirstLayerAsMask: Bool = true
    }
}
