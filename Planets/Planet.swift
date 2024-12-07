//
//  Planet.swift
//  Planet
//
//  Created by Paul Delestrac on 06/12/2024.
//

import Foundation
import MetalKit

class Planet {
    var terrainFaces: [TerrainFace]
    var mesh: Mesh
    let resolution: Int = 10
    
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    
    let directions: [SIMD3<Float>] = [
        SIMD3<Float>(1, 0, 0),  // Right
        SIMD3<Float>(0, 1, 0),  // Up
        SIMD3<Float>(0, 0, 1),  // Forward
        SIMD3<Float>(-1, 0, 0), // Left
        SIMD3<Float>(0, -1, 0), // Down
        SIMD3<Float>(0, 0, -1)  // Back
    ]
    
    init(device: MTLDevice, scale: Float = 1) {
        self.terrainFaces = []
        
        // Create the terrain faces
        for i in 0..<directions.count {
            self.terrainFaces.append(TerrainFace(resolution: self.resolution, localUp: directions[i]))
        }
        
        // Generate the mesh for each face
        self.mesh = Mesh(vertices: [], indices: [])
        for terrainFace in self.terrainFaces {
            terrainFace.construct_mesh()
            let numberOfIndices = self.mesh.vertices.count
            let shiftedIndices = terrainFace.mesh.indices.map { UInt16(numberOfIndices) + $0 }
            self.mesh.indices.append(contentsOf: shiftedIndices)
            self.mesh.vertices.append(contentsOf: terrainFace.mesh.vertices)
        }

        // Scale the meshes
        self.mesh.vertices = self.mesh.vertices.map {
            Vertex(x: $0.x * scale, y: $0.y * scale, z: $0.z * scale)
        }
        
        // Vertex buffer
        guard let vertexBuffer = device.makeBuffer(bytes: &self.mesh.vertices, length: self.mesh.vertices.count * MemoryLayout<Vertex>.stride, options: []) else { fatalError("Unable to create planet vertex buffer") }
        
        // Index buffer
        guard let indexBuffer = device.makeBuffer(bytes: &self.mesh.indices, length: self.mesh.indices.count * MemoryLayout<UInt16>.stride, options: []) else { fatalError("Unable to create planet index buffer") }
        
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
    }
    
    func generate() {
        for terrainFace in terrainFaces {
            terrainFace.construct_mesh()
        }
    }
}
