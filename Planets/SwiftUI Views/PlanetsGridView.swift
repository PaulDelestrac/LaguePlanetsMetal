//
//  PlanetsGridView.swift
//  Planets
//
//  Created by Paul Delestrac on 24/04/2025.
//

import MetalKit
import SwiftData
import SwiftUI

struct PlanetsGridView: View {
    @Query var optionsList: [Options]
    let columns = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150)),
    ]
    @State private var isEditing: Bool = false
    @State private var isScrolling: Bool = false
    @State var gameSceneFovRadians: Float?
    @State private var localImage: NSImage? = nil
    @State private var localImageHasChanged: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(optionsList) { options in
                        NavigationLink {
                            MetalView(
                                isEditing: $isEditing,
                                isScrolling: $isScrolling
                            )
                            .environment(\.options, options)
                        } label: {
                            PlanetItemView(options: options, gameSceneFovRadians: $gameSceneFovRadians)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(Text("Planets"))
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
//.navigationDestination(for: Recipe.self) { recipe in
//    RecipeDetail(recipe: recipe)
//}

struct PlanetItemView: View {
    let options: Options
    @Binding var gameSceneFovRadians: Float?
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                ZStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 16.0))
                    VStack {
                        Spacer()
                        Text("\(options.name)")
                            .frame(maxWidth: .infinity)
                            .font(.title2)
                            .padding()
                            .background(.thinMaterial, in: .rect(
                                cornerRadii: RectangleCornerRadii(
                                    bottomLeading: 16.0,
                                    bottomTrailing: 16.0
                                )
                            ))
                            .foregroundStyle(.black)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            }
        }
        .onAppear {
            renderPlanet()
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
