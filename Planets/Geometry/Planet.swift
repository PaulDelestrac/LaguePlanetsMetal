//
//  Planet.swift
//  Planet
//
//  Created by Paul Delestrac on 06/12/2024.
//

import Foundation
import MetalKit

class Planet : Transformable {
    var transform = Transform()
    var terrainFaces: [TerrainFace]
    var rawMesh: RawMesh
    //var meshes: [Mesh]
    let resolution: Int = 100
    var tiling: UInt32 = 1
    
    //let vertexBuffer: MDLMeshBuffer
    //let indexBuffer: MDLMeshBuffer
    
    let directions: [SIMD3<Float>] = [
        SIMD3<Float>(1, 0, 0),  // Right
        SIMD3<Float>(0, 1, 0),  // Up
        SIMD3<Float>(0, 0, 1),  // Forward
        SIMD3<Float>(-1, 0, 0), // Left
        SIMD3<Float>(0, -1, 0), // Down
        SIMD3<Float>(0, 0, -1)  // Back
    ]
    
    init(/*device: MTLDevice, */scale: Float = 1) {
        self.terrainFaces = []
        
        // Create the terrain faces
        for i in 0..<directions.count {
            self.terrainFaces.append(TerrainFace(resolution: self.resolution, localUp: directions[i]))
        }
        
        // Generate the mesh for each face
        self.rawMesh = RawMesh(vertices: [], indices: [])
        for terrainFace in self.terrainFaces {
            terrainFace.construct_mesh()
            let numberOfIndices = self.rawMesh.vertices.count
            let shiftedIndices = terrainFace.mesh.indices.map { UInt16(numberOfIndices) + $0 }
            self.rawMesh.indices.append(contentsOf: shiftedIndices)
            self.rawMesh.vertices.append(contentsOf: terrainFace.mesh.vertices)
        }
        
        //let allocator = MTKMeshBufferAllocator(device: device)
        
        // Scale the meshes
        self.rawMesh.vertices = self.rawMesh.vertices.map {
            float3(x: $0.x * scale, y: $0.y * scale, z: $0.z * scale)
        }
        
        // Vertex buffer
        //let data = Data.init(bytes: &self.rawMesh.vertices, count: self.rawMesh.vertices.count * MemoryLayout<Vertex>.stride)
        //let vertexBuffer = allocator.newBuffer(with: data, type: .vertex)
        //let vertexBuffer = device.makeBuffer(bytes: &self.rawMesh.vertices, length: self.rawMesh.vertices.count * MemoryLayout<Vertex>.stride, options: [])!

        // Index buffer
        //let indexData = Data.init(bytes: &self.rawMesh.indices, count: self.rawMesh.indices.count * MemoryLayout<UInt16>.stride)
        //let indexBuffer = allocator.newBuffer(with: indexData, type: .index)
        //let indexBuffer = device.makeBuffer(bytes: &self.rawMesh.indices, length: self.rawMesh.indices.count * MemoryLayout<UInt16>.stride, options: [])!
        
        //self.vertexBuffer = vertexBuffer
        //self.indexBuffer = indexBuffer
        
        /*let submesh = MDLSubmesh(
            indexBuffer: indexBuffer,
            indexCount: self.rawMesh.indices.count,
            indexType: .uint16,
            geometryType: .triangles,
            material: nil)*/
        
        /*let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[Position.index] = MDLVertexAttribute(
            name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: VertexBuffer.index
            )*/

        /*let mdlMesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: self.rawMesh.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
        
        let mtkMesh = try! MTKMesh(mesh: mdlMesh, device: device)
        
        self.meshes = [Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)]*/
    }
}
/*
// Rendering
extension Planet {
    func render(
        encoder: MTLRenderCommandEncoder,
        uniforms vertex: Uniforms,
        params fragment: Params
    ) {
        // make the structures mutable
        var uniforms = vertex
        var params = fragment
        params.tiling = tiling
        uniforms.modelMatrix = transform.modelMatrix
        uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
        
        encoder.setVertexBytes(
            &uniforms,
            length: MemoryLayout<Uniforms>.stride,
            index: UniformsBuffer.index)
        
        encoder.setFragmentBytes(
            &params,
            length: MemoryLayout<Params>.stride,
            index: ParamsBuffer.index)
        
        for mesh in meshes {
            for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(
                    vertexBuffer,
                    offset: 0,
                    index: index)
            }
            
            for submesh in mesh.submeshes {
                
                // set the fragment texture here
                
                encoder.setFragmentTexture(
                    submesh.textures.baseColor,
                    index: BaseColor.index)
                
                //encoder.setTriangleFillMode(.lines) // Show wireframe
                
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer,
                    indexBufferOffset: submesh.indexBufferOffset
                )
            }
        }
    }
}*/
