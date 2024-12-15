//
//  NoiseFilter.swift
//  Planets
//
//  Created by Paul Delestrac on 10/12/2024.
//

import Foundation

protocol NoiseFilter {
    func evaluate(point: float3) -> Float
    var noise: Noise { get }
    var settings: NoiseSettings { get }
}

struct NoiseFilterManager {
    static func createNoiseFilter(settings: NoiseSettings) -> NoiseFilter {
        switch settings.filterType {
        case .Simple:
            return SimpleNoiseFilter(settings: settings)
        case .Ridgid:
            return RidgidNoiseFilter(settings: settings)
        }
    }
}
