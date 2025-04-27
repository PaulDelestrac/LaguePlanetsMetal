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

import MetalKit

// swiftlint:disable implicitly_unwrapped_optional

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    var pipelineState: MTLRenderPipelineState!
    let depthStencilState: MTLDepthStencilState?
    let metalClearColor = MTLClearColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)

    var uniforms = Uniforms()
    var params = Params()

    var planet: Planet

    var needsUpdate: Bool = true
    var oldOptions: Options

    init(metalView: MTKView, options: Options) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("GPU not available")
        }
        self.oldOptions = options
        Self.device = device
        Self.commandQueue = commandQueue
        metalView.device = device

        self.planet = Planet(
            device: device,
            shapeSettings: options.shapeSettings
        )

        // create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction =
            library?.makeFunction(name: "fragment_main")

        // create the pipeline state object
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat =
            metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexDescriptor =
            MTLVertexDescriptor.defaultLayout
        do {
            pipelineState =
                try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
        depthStencilState = Renderer.buildDepthStencilState()
        super.init()
        metalView.clearColor = self.metalClearColor
        metalView.depthStencilPixelFormat = .depth32Float
        mtkView(
            metalView,
            drawableSizeWillChange: metalView.drawableSize)
    }

    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(
            descriptor: descriptor)
    }
}

extension Renderer {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) {
    }

    func updateUniforms(scene: GameScene) {
        uniforms.viewMatrix = scene.camera.viewMatrix
        uniforms.projectionMatrix = scene.camera.projectionMatrix
        params.lightCount = UInt32(scene.lighting.lights.count)
        params.cameraPosition = scene.camera.position
    }

    func draw(scene: GameScene, in view: MTKView, options: Options) {
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor,
            let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: descriptor)
        else {
            return
        }

        updateUniforms(scene: scene)

        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)

        var lights = scene.lighting.lights
        renderEncoder.setFragmentBytes(
            &lights,
            length: MemoryLayout<Light>.stride * lights.count,
            index: LightBuffer.index)

        if options.isColorChanging || options.colorNeedsUpdate {
            self.planet.updateColor(options.color)
            oldOptions = options
            options.colorNeedsUpdate = false
        }
        if options.shapeSettings.isChanging || options.shapeSettings.needsUpdate {
            self.planet.updateShape(settings: options.shapeSettings)
            oldOptions = options
            options.shapeSettings.needsUpdate = false
        }

        //renderEncoder.setTriangleFillMode(.lines)

        self.planet.render(encoder: renderEncoder, uniforms: uniforms, params: params)

        // Debug lights
        /*DebugLights.draw(
         lights: scene.lighting.lights,
         encoder: renderEncoder,
         uniforms: uniforms)*/

        // Debug normals
        //assert(self.planet.normals.count == self.planet.rawMesh.vertices.count)
        // for (vertex, normal) in zip(self.planet.rawMesh.vertices, self.planet.normals) {
        //     DebugLights.debugDrawLine(
        //         renderEncoder: renderEncoder, uniforms: uniforms, position: vertex,
        //         direction: normal, color: float3(1, 0, 0))
        // }

        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func captureFrame(scene: GameScene, in view: MTKView, options: Options) -> CGImage? {
        let textureWidth: Int = 256
        let textureHeight: Int = 256

        // Create a texture descriptor matching the view size
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.colorPixelFormat,
            width: textureWidth,
            height: textureHeight,
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]

        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: textureWidth,
            height: textureHeight,
            mipmapped: false
        )
        depthDescriptor.usage = [.renderTarget]

        // Create render target texture and depth buffer
        guard let renderTargetTexture = Self.device.makeTexture(descriptor: textureDescriptor),
            let depthTexture = Self.device.makeTexture(
                descriptor: depthDescriptor)
        else {
            return nil
        }

        // Create render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderTargetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = self.metalClearColor
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 1.0

        // Create command buffer
        guard let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(
                    descriptor: renderPassDescriptor)
        else {
            return nil
        }

        // Render the scene
        updateUniforms(scene: scene)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(pipelineState)

        var lights = scene.lighting.lights
        renderEncoder.setFragmentBytes(
            &lights,
            length: MemoryLayout<Light>.stride * lights.count,
            index: LightBuffer.index)

        planet.updateColor(options.color)
        planet.render(encoder: renderEncoder, uniforms: uniforms, params: params)
        renderEncoder.endEncoding()

        // Complete rendering
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Create CGImage from texture
        return self.createCGImage(from: renderTargetTexture)
    }

    private func createCGImage(from texture: MTLTexture) -> CGImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4

        // Create a buffer to hold texture data
        var data = [UInt8](repeating: 0, count: width * height * 4)

        // Copy texture data to buffer
        texture.getBytes(
            &data,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue:
                CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        guard
            let context = CGContext(
                data: &data,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            )
        else {
            return nil
        }

        return context.makeImage()
    }
}

// swiftlint:enable implicitly_unwrapped_optional
