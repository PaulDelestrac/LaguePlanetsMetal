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

// swiftlint:disable force_try

class Model: Transformable {
    var transform = Transform()
    var meshes: [Mesh] = []
    var name: String = "Untitled"
    var tiling: UInt32 = 1
    
    init() {}
    
    init(name: String) {
        guard let assetURL = Bundle.main.url(
            forResource: name,
            withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(
            url: assetURL,
            vertexDescriptor: .defaultLayout,
            bufferAllocator: allocator)
        asset.loadTextures()
        let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(
            asset: asset,
            device: Renderer.device)
        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        self.name = name
    }
    
    init(name: String, vertices: [float3], indices: [UInt16]) {
        self.name = name
        guard !vertices.isEmpty, !indices.isEmpty else {
            fatalError("Cannot create Model with empty vertices or indices")
        }
        
        // Create a mesh buffer allocator
        let bufferAllocator = MTKMeshBufferAllocator(device: Renderer.device)
        
        // Create a vertex buffer
        var combinedVertexData = [Float]()
        var newVertices: [SIMD4<Float>] = []
        for vertex in vertices {
            newVertices.append(SIMD4<Float>(vertex, 0))
            let normals = normalize(vertex)
            newVertices.append(SIMD4<Float>(normals, 0))
            combinedVertexData.append(vertex.x)
            combinedVertexData.append(vertex.y)
            combinedVertexData.append(vertex.z)
            combinedVertexData.append(1)
            combinedVertexData.append(normals.x)
            combinedVertexData.append(normals.y)
            combinedVertexData.append(normals.z)
            combinedVertexData.append(1)
        }
        let data = Data.init(bytes: combinedVertexData, count: combinedVertexData.count * MemoryLayout<SIMD4<Float>>.stride)
        let vertexBuffer = bufferAllocator.newBuffer(with: data, type: .vertex)
        
        // Create an index buffer
        let indexData = Data.init(bytes: indices, count: indices.count * MemoryLayout<UInt16>.stride)
        let indexBuffer = bufferAllocator.newBuffer(with: indexData, type: .index)
        
        // Create a UV buffer of vertices size (type float2)
        /*var uvs = [SIMD2<Float>]()
        for vertex in vertices {
            uvs.append(SIMD2<Float>(vertex.x, vertex.y))
        }
        let uvData = Data.init(bytes: uvs, count: vertices.count * MemoryLayout<float2>.stride)
        let uvBuffer = bufferAllocator.newBuffer(with: uvData, type: .vertex)*/
        
        // Create vertex descriptor
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        vertexDescriptor.attributes[Position.index] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: offset, bufferIndex: VertexBuffer.index)
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.attributes[Normal.index] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: offset, bufferIndex: VertexBuffer.index)
        offset += MemoryLayout<float3>.stride
        vertexDescriptor.layouts[VertexBuffer.index] = MDLVertexBufferLayout(stride: offset)
        
        /*vertexDescriptor.attributes[UV.index] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: UVBuffer.index)
        vertexDescriptor.layouts[UVBuffer.index] = MDLVertexBufferLayout(stride: MemoryLayout<float2>.stride)*/
        
        // Create submesh
        let submesh = MDLSubmesh(
            indexBuffer: indexBuffer,
            indexCount: indices.count,
            indexType: .uint16,
            geometryType: .triangles,
            material: MDLMaterial()
        )

        // Create MDL Mesh
        let mdlMesh = MDLMesh(
            vertexBuffer: vertexBuffer,
            vertexCount: vertices.count,
            descriptor: vertexDescriptor,
            submeshes: [submesh]
        )
        
        // Convert to MTK Mesh
        do {
            let mtkMesh = try MTKMesh(
                mesh: mdlMesh,
                device: Renderer.device
            )
            
            // Create Mesh from MDL and MTK Meshes
            meshes = [Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)]
        } catch {
            fatalError("Failed to create MTKMesh: \(error)")
        }
    }
    
}

extension Model {
    func setTexture(name: String, type: TextureIndices) {
        if let texture = TextureController.loadTexture(name: name) {
            switch type {
            case BaseColor:
                meshes[0].submeshes[0].textures.baseColor = texture
            default: break
            }
        }
    }
}
// swiftlint:enable force_try
