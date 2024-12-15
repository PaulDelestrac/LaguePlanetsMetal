//
//  NoiseLayerSettingsView.swift
//  Planets
//
//  Created by Paul Delestrac on 10/12/2024.
//

import SwiftUI

struct NoiseLayerSettingsView: View {
    @Binding var noiseLayer: ShapeSettings.NoiseLayer
    @Binding var index: Int
    @Environment(\.options) private var options: Options
    @Binding var isEditing: Bool
    @Binding var refreshList: Bool
    @Binding var refreshEye: Bool
    @Binding var refreshMask: Bool
    var body: some View {
        @Bindable var options = options
        HStack {
            Picker("Type", selection: $noiseLayer.noiseSettings.filterType) {
                Text("Simple").tag(NoiseSettings.FilterType.Simple)
                Text("Ridgid").tag(NoiseSettings.FilterType.Ridgid)
            }.onChange(of: $noiseLayer.noiseSettings.filterType.wrappedValue) {
                options.shapeSettings.needsUpdate = true
            }
            Button {
                $options.shapeSettings.noiseLayers.wrappedValue.remove(at: index)
                options.shapeSettings.needsUpdate = true
            } label: {
                Image(systemName: "trash")
            }
        }
        HStack{
            Text("Mask with First Layer")
            Spacer()
            Button {
                noiseLayer.useFirstLayerAsMask.toggle()
                refreshMask.toggle()
                options.shapeSettings.needsUpdate = true
            } label: {
                if noiseLayer.useFirstLayerAsMask {
                    Image(systemName: "square.3.layers.3d.down.left")
                } else {
                    Image(systemName: "square.3.layers.3d.down.left.slash")
                }
            }.id(refreshMask)
        }
        HStack {
            Text("Enable layer")
            Spacer()
            Button {
                noiseLayer.enabled.toggle()
                refreshEye.toggle()
                options.shapeSettings.needsUpdate = true
            } label: {
                if noiseLayer.enabled {
                    Image(systemName: "eye")
                } else {
                    Image(systemName: "eye.slash")
                }
            }.id(refreshEye)
        }
        Stepper(
            value: $noiseLayer.noiseSettings.numLayers,
            in: 1...8,
            step: 1
        ) {
            Text("Inner noise layers: \(noiseLayer.noiseSettings.numLayers)")
        }
        .onChange(of: $noiseLayer.noiseSettings.numLayers.wrappedValue) {
            refreshList.toggle()
            options.shapeSettings.needsUpdate = true
        }
        VStack {
            Text("Center: (\(noiseLayer.noiseSettings.center.x), \(noiseLayer.noiseSettings.center.y), \(noiseLayer.noiseSettings.center.z))")
            HStack {
                Text("x")
                Slider(
                    value: $noiseLayer.noiseSettings.center.x,
                    in: 0...2,
                    onEditingChanged: { editing in
                        isEditing = editing
                        options.shapeSettings.isChanging = editing
                    }
                )
                .tint(Color.black)
            }
            HStack {
                Text("y")
                Slider(
                    value: $noiseLayer.noiseSettings.center.y,
                    in: 0...2,
                    onEditingChanged: { editing in
                        isEditing = editing
                        options.shapeSettings.isChanging = editing
                    }
                )
                .tint(Color.black)
            }
            HStack {
                Text("z")
                Slider(
                    value: $noiseLayer.noiseSettings.center.z,
                    in: 0...2,
                    onEditingChanged: { editing in
                        isEditing = editing
                        options.shapeSettings.isChanging = editing
                    }
                )
                .tint(Color.black)
            }
        }
        VStack {
            Text("Height (minValue): \(noiseLayer.noiseSettings.minValue)")
            Slider(
                value: $noiseLayer.noiseSettings.minValue,
                in: 0...2,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.shapeSettings.isChanging = editing
                }
            )
            .tint(Color.black)
        }
        VStack {
            Text("Noise Strength: \(noiseLayer.noiseSettings.strength)")
            Slider(
                value: $noiseLayer.noiseSettings.strength,
                in: 0...5,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.shapeSettings.isChanging = editing
                }
            )
        }
        VStack {
            Text("Roughness: \(noiseLayer.noiseSettings.roughness)")
            Slider(
                value: $noiseLayer.noiseSettings.roughness,
                in: 0...5,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.shapeSettings.isChanging = editing
                }
            )
        }
        VStack {
            Text("Base Roughness: \(noiseLayer.noiseSettings.baseRoughness)")
            Slider(
                value: $noiseLayer.noiseSettings.baseRoughness,
                in: 0...5,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.shapeSettings.isChanging = editing
                }
            )
        }
        VStack {
            Text("Persistence: \(noiseLayer.noiseSettings.persistence)")
            Slider(
                value: $noiseLayer.noiseSettings.persistence,
                in: 0...5,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.shapeSettings.isChanging = editing
                }
            )
        }
        if noiseLayer.noiseSettings.filterType == .Ridgid {
            VStack {
                Text("Weight Mul: \(noiseLayer.noiseSettings.weightMultiplier)")
                Slider(
                    value: $noiseLayer.noiseSettings.weightMultiplier,
                    in: 0...5,
                    onEditingChanged: { editing in
                        isEditing = editing
                        options.shapeSettings.isChanging = editing
                    }
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var noiseLayer: ShapeSettings.NoiseLayer = ShapeSettings.NoiseLayer()
    @Previewable @State var index: Int = 0
    @Previewable @State var isEditing: Bool = false
    @Previewable @State var refreshList: Bool = false
    @Previewable @State var refreshEye: Bool = false
    @Previewable @State var refreshMask: Bool = false
    NoiseLayerSettingsView(noiseLayer: $noiseLayer, index: $index, isEditing: $isEditing, refreshList: $refreshList, refreshEye: $refreshEye, refreshMask: $refreshMask)
}
