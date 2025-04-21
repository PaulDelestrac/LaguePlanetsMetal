//
//  SettingsView.swift
//  Planets
//
//  Created by Paul Delestrac on 10/12/2024.
//

import SwiftUI

struct SettingsContainerView: View {
    @Environment(\.options) private var options: Options
    @Binding var isScrolling: Bool

    var body: some View {
        SettingsView(
            isScrolling: $isScrolling
        )
        .environment(\.options, options)
    }
}

struct SettingsView: View {
    @Environment(\.options) private var options: Options
    @State var isEditing: Bool = false
    @Binding var isScrolling: Bool
    @State var refreshList = false
    @State var refreshEye = false
    @State var refreshMask = false

    var body: some View {
        @Bindable var options: Options = options
        VStack {
            Picker(
                "Face render mask",
                selection: $options.shapeSettings.faceRenderMask
            ) {
                Text("All").tag(Planet.FaceRenderMask.All)
                Text("Top").tag(Planet.FaceRenderMask.Top)
                Text("Bottom").tag(Planet.FaceRenderMask.Bottom)
                Text("Left").tag(Planet.FaceRenderMask.Left)
                Text("Right").tag(Planet.FaceRenderMask.Right)
                Text("Front").tag(Planet.FaceRenderMask.Front)
                Text("Back").tag(Planet.FaceRenderMask.Back)
            }
            .onChange(of: options.shapeSettings.faceRenderMask) {
                options.shapeSettings.needsUpdate = true
            }
            ColorSettingsView(isEditing: $isEditing)
                .padding()
                .environment(\.options, options)
            VStack {
                Text("Radius: \(options.shapeSettings.planetRadius)")
                Slider(
                    value: $options.shapeSettings.planetRadius,
                    in: 0.1...10,
                    onEditingChanged: { editing in
                        isEditing = editing
                        $options.shapeSettings.isChanging.wrappedValue = editing
                    }
                )
                .tint(Color.black)
            }
            .padding(.horizontal)
            Stepper(
                value: $options.shapeSettings.resolution,
                in: 10...200,
                step: 10
            ) {
                Text("Resolution: \(options.shapeSettings.resolution)")
            }
            .onChange(of: $options.shapeSettings.resolution.wrappedValue) {
                options.shapeSettings.needsUpdate = true
            }
            Divider()
            Button("Add layer") {
                let noiseLayer = ShapeSettings.NoiseLayer()
                $options.shapeSettings.noiseLayers.wrappedValue.append(noiseLayer)
                //refreshList.toggle()
                options.shapeSettings.needsUpdate = true
            }
            layerListView
                .padding(.horizontal)
                .listStyle(InsetListStyle())
                .id(refreshList)

        }
    }

    private var layerListView: some View {
        if #available(macOS 15.0, *) {
            return ScrollView {
                if options.shapeSettings.noiseLayers.isEmpty {
                    Text("No layers")
                } else {
                    ForEach(options.shapeSettings.noiseLayers.indices, id: \.self) { index in
                        if index < options.shapeSettings.noiseLayers.count {
                            layerSection(index)
                        }
                    }
                }
            }
            .onScrollPhaseChange { old, new in
                switch new {
                case .interacting, .decelerating, .animating:
                    isScrolling = true
                default:
                    isScrolling = false
                }
            }
        } else {
            return List {
                if options.shapeSettings.noiseLayers.isEmpty {
                    Text("No layers")
                } else {
                    ForEach(options.shapeSettings.noiseLayers.indices, id: \.self) { index in
                        if index < options.shapeSettings.noiseLayers.count {
                            layerSection(index)
                        }
                    }
                }
            }
        }
    }

    private func layerSection(_ index: Int) -> some View {
        @Bindable var options: Options = options
        return Section("Layer #\(index)") {
            NoiseLayerSettingsView(
                noiseLayer: $options.shapeSettings.noiseLayers[index],
                index: Binding(
                    get: { index },
                    set: { _ in }
                ),
                isEditing: $isEditing,
                refreshList: $refreshList,
                refreshEye: $refreshEye,
                refreshMask: $refreshMask
            )
            .environment(\.options, options)
            Divider()
        }
    }
}

#Preview {
    @Previewable @State var isScrolling: Bool = false
    @Previewable @State var selectedOption = Options()

    VStack {
        SettingsView(isScrolling: $isScrolling)
        Divider()
        SettingsContainerView(
            isScrolling: $isScrolling
        )
    }
}
