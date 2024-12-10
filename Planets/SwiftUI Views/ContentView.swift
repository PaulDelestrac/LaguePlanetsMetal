///// Copyright (c) 2023 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct ContentView: View {
    @State var options = Options()
    @State public var isEditing = false
    @State private var refreshList = false
    @State private var refreshEye = false
    @State private var refreshMask = false
    var body: some View {
        HStack {
            MetalView(options: options, isEditing: $isEditing)
                .border(Color.black, width: 2)
            VStack {
                VStack {
                    Text("Color (RGB)")
                    Slider(
                        value: $options.color.x,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.red)
                    Slider(
                        value: $options.color.y,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.green)
                    Slider(
                        value: $options.color.z,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.blue)
                }
                .padding()
                VStack {
                    Text("Radius: \(options.shapeSettings.planetRadius)")
                    Slider(
                        value: $options.shapeSettings.planetRadius,
                        in: 0.1...10,
                        onEditingChanged: { editing in
                            isEditing = editing
                            options.shapeSettings.hasChanged = editing
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
                Divider()
                Button("Add layer") {
                    let noiseLayer = ShapeSettings.NoiseLayer()
                    options.shapeSettings.noiseLayers.append(noiseLayer)
                    refreshList.toggle()
                }
                List {
                    ForEach(Array(zip(options.shapeSettings.noiseLayers.indices, options.shapeSettings.noiseLayers)), id: \.0) { index, layer in
                        Section("Layer #\(index)") {
                            HStack{
                                Button {
                                    options.shapeSettings.noiseLayers[index].useFirstLayerAsMask.toggle()
                                    refreshMask.toggle()
                                } label: {
                                    if options.shapeSettings.noiseLayers[index].useFirstLayerAsMask {
                                        Image(systemName: "square.3.layers.3d.down.left")
                                    } else {
                                        Image(systemName: "square.3.layers.3d.down.left.slash")
                                    }
                                }.id(refreshMask)
                                Button {
                                    options.shapeSettings.noiseLayers[index].enabled.toggle()
                                    refreshEye.toggle()
                                } label: {
                                    if options.shapeSettings.noiseLayers[index].enabled {
                                        Image(systemName: "eye")
                                    } else {
                                        Image(systemName: "eye.slash")
                                    }
                                }.id(refreshEye)
                                Spacer()
                                Button {
                                    options.shapeSettings.noiseLayers.remove(at: index)
                                    refreshList.toggle()
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            Stepper(
                                value: $options.shapeSettings.noiseLayers[index].noiseSettings.numLayers,
                                in: 1...8,
                                step: 1
                            ) {
                                Text("Inner noise layers: \(layer.noiseSettings.numLayers)")
                            }
                            VStack {
                                Text("Center: (\(layer.noiseSettings.center.x), \(layer.noiseSettings.center.y), \(layer.noiseSettings.center.z))")
                                HStack {
                                    Text("x")
                                    Slider(
                                        value: $options.shapeSettings.noiseLayers[index].noiseSettings.center.x,
                                        in: 0...2,
                                        onEditingChanged: { editing in
                                            isEditing = editing
                                            options.shapeSettings.hasChanged = editing
                                        }
                                    )
                                    .tint(Color.black)
                                }
                                HStack {
                                    Text("y")
                                    Slider(
                                        value: $options.shapeSettings.noiseLayers[index].noiseSettings.center.y,
                                        in: 0...2,
                                        onEditingChanged: { editing in
                                            isEditing = editing
                                            options.shapeSettings.hasChanged = editing
                                        }
                                    )
                                    .tint(Color.black)
                                }
                                HStack {
                                    Text("z")
                                    Slider(
                                        value: $options.shapeSettings.noiseLayers[index].noiseSettings.center.z,
                                        in: 0...2,
                                        onEditingChanged: { editing in
                                            isEditing = editing
                                            options.shapeSettings.hasChanged = editing
                                        }
                                    )
                                    .tint(Color.black)
                                }
                            }
                            VStack {
                                Text("Height (minValue): \(layer.noiseSettings.minValue)")
                                Slider(
                                    value: $options.shapeSettings.noiseLayers[index].noiseSettings.minValue,
                                    in: 0...2,
                                    onEditingChanged: { editing in
                                        isEditing = editing
                                        options.shapeSettings.hasChanged = editing
                                    }
                                )
                                .tint(Color.black)
                            }
                            VStack {
                                Text("Noise Strength: \(layer.noiseSettings.strength)")
                                Slider(
                                    value: $options.shapeSettings.noiseLayers[index].noiseSettings.strength,
                                    in: 0...5,
                                    onEditingChanged: { editing in
                                        isEditing = editing
                                        options.shapeSettings.hasChanged = editing
                                    }
                                )
                            }
                            VStack {
                                Text("Roughness: \(layer.noiseSettings.roughness)")
                                Slider(
                                    value: $options.shapeSettings.noiseLayers[index].noiseSettings.roughness,
                                    in: 0...5,
                                    onEditingChanged: { editing in
                                        isEditing = editing
                                        options.shapeSettings.hasChanged = editing
                                    }
                                )
                            }
                            VStack {
                                Text("Base Roughness: \(layer.noiseSettings.baseRoughness)")
                                Slider(
                                    value: $options.shapeSettings.noiseLayers[index].noiseSettings.baseRoughness,
                                    in: 0...5,
                                    onEditingChanged: { editing in
                                        isEditing = editing
                                        options.shapeSettings.hasChanged = editing
                                    }
                                )
                            }
                            VStack {
                                Text("Persistence: \(layer.noiseSettings.persistence)")
                                Slider(
                                    value: $options.shapeSettings.noiseLayers[index].noiseSettings.persistence,
                                    in: 0...5,
                                    onEditingChanged: { editing in
                                        isEditing = editing
                                        options.shapeSettings.hasChanged = editing
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .listStyle(InsetListStyle())
                .id(refreshList)
            }
            .frame(width: 250)
        }
    }
    
    func addLayer() async {
        options.shapeSettings.addNoiseLayer()
    }
}


#Preview {
    ContentView()
}
