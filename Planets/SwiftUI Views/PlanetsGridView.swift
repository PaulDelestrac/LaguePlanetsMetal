//
//  PlanetsGridView.swift
//  Planets
//
//  Created by Paul Delestrac on 24/04/2025.
//

import MetalKit
import SwiftData
import SwiftUI
import Glur

struct PlanetsGridView: View {
    @Query var optionsList: [Options]
    @State private var refreshMiniatures: Bool = false
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150)),
    ]

    var body: some View {
        NavigationSplitView {
            // TODO add categories
        } detail: {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(optionsList) { options in
                            NavigationLink {
                                PlanetContentView()
                                    .environment(\.options, options)
                                    .onDisappear {
                                        refreshMiniatures.toggle()
                                    }
                            } label: {
                                PlanetItemView(refreshMiniatures: $refreshMiniatures)
                                    .environment(\.options, options)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct PlanetsGridView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Options.self,
            configurations: config
        )

        for _ in 1..<10 {
            let options = Options()
            container.mainContext.insert(options)
        }

        return PlanetsGridView()
            .modelContainer(container)
    }
}

struct PlanetItemView: View {
    @Environment(\.options) private var options: Options
    @Binding var refreshMiniatures: Bool

    @State var gameSceneFovRadians: Float?
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 16.0))
                    .glur(radius: 8.0, offset: 0.7, interpolation: 0.2, direction: .down)
                    .clipShape(
                        .rect(
                            cornerRadii: RectangleCornerRadii(
                                bottomLeading: 16.0, bottomTrailing: 16.0
                            )
                        )
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text("\(options.name)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding()
                    }
            } else {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            }
        }
        .onAppear {
            Task {
                renderPlanet()
            }
        }
        .onChange(of: refreshMiniatures) {
            renderPlanet()
            refreshMiniatures = false
        }
    }

    private func renderPlanet() {
        var gameScene = GameScene()
        gameSceneFovRadians = gameScene.camera.fov
        gameScene.camera.distance = options.getIdealDistance(
            fovRadians: gameSceneFovRadians ?? Float(70).degreesToRadians,
            fovRatio: 0.6
        )
        gameScene.update(deltaTime: 0.0)

        let metalView = MTKView()
        let renderer = Renderer(metalView: metalView, options: options)
        if let cgImage = renderer.captureFrame(
            scene: gameScene,
            in: metalView,
            options: options
        ) {
            let nsImage = NSImage(
                cgImage: cgImage,
                size: CGSize(width: cgImage.width, height: cgImage.height)
            )
            image = nsImage
            options.image = nsImage
        }
    }
}
