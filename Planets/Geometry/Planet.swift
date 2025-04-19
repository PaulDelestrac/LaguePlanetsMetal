//
//  Planet.swift
//  Planet
//
//  Created by Paul Delestrac on 06/12/2024.
//

import Foundation
import MetalKit

class Planet: Transformable {
    let device: MTLDevice
    var transform = Transform()

    var terrainFaces: [TerrainFace] = []
    var rawMesh: RawMesh = RawMesh(vertices: [], indices: [])
    var tiling: UInt32 = 1

    var shapeSettings: ShapeSettings
    var shapeGenerator: ShapeGenerator

    var colors: [SIMD4<Float>] = []
    var normals: [SIMD3<Float>] = []

    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var colorBuffer: MTLBuffer!
    var normalBuffer: MTLBuffer!

    let directions: [SIMD3<Float>] = [
        SIMD3<Float>(0, 1, 0),  // Top
        SIMD3<Float>(0, -1, 0),  // Bottom
        SIMD3<Float>(-1, 0, 0),  // Left
        SIMD3<Float>(1, 0, 0),  // Right
        SIMD3<Float>(0, 0, 1),  // Front
        SIMD3<Float>(0, 0, -1),  // Back
    ]

    enum FaceRenderMask: Int, Codable, Hashable {
        case All, Top, Bottom, Left, Right, Front, Back
    }

    init(device: MTLDevice, shapeSettings: ShapeSettings, color: float3 = float3(0, 0, 0)) {
        self.device = device
        self.shapeSettings = shapeSettings
        self.shapeGenerator = ShapeGenerator(settings: self.shapeSettings)
        self.generateMesh()

        // Initialize random colors
        for _ in self.rawMesh.vertices {
            // if no color is provided, set random colors
            if color == float3(0, 0, 0) {
                self.colors.append(
                    SIMD4<Float>(
                        Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1
                    ))
            } else {
                self.colors.append(SIMD4<Float>(color, 1))
            }
        }

        // Vertex buffer
        guard
            let vertexBuffer = device.makeBuffer(
                bytes: &self.rawMesh.vertices,
                length: MemoryLayout<SIMD3<Float>>.stride * self.rawMesh.vertices.count, options: []
            )
        else {
            fatalError("Unable to create planet vertex buffer")
        }
        self.vertexBuffer = vertexBuffer

        // Index buffer
        guard
            let indexBuffer = device.makeBuffer(
                bytes: &self.rawMesh.indices,
                length: MemoryLayout<UInt32>.stride * self.rawMesh.indices.count, options: [])
        else {
            fatalError("Unable to create planet index buffer")
        }
        self.indexBuffer = indexBuffer

        // Color buffer
        guard
            let colorBuffer = device.makeBuffer(
                bytes: &self.colors, length: MemoryLayout<SIMD4<Float>>.stride * self.colors.count,
                options: [])
        else {
            fatalError("Unable to create planet color buffer")
        }
        self.colorBuffer = colorBuffer

        // Normal buffer
        guard
            let normalBuffer = device.makeBuffer(
                bytes: &self.normals,
                length: MemoryLayout<SIMD3<Float>>.stride * self.normals.count, options: [])
        else {
            fatalError("Unable to create planet normal buffer")
        }
        self.normalBuffer = normalBuffer
    }

    func generateMesh() {
        self.terrainFaces = []

        // Create the terrain faces
        for i in 0..<directions.count {
            let renderFace: Bool =
                (shapeSettings.faceRenderMask == FaceRenderMask.All)
                || (shapeSettings.faceRenderMask.rawValue - 1 == i)
            if renderFace {
                self.terrainFaces.append(
                    TerrainFace(
                        shapeGenerator: self.shapeGenerator,
                        resolution: self.shapeSettings.resolution,
                        localUp: directions[i]))
            }
        }

        // Generate the mesh for each face
        self.rawMesh = RawMesh(vertices: [], indices: [], normals: [])
        for terrainFace in self.terrainFaces {
            terrainFace.construct_mesh()
            let numberOfIndices = self.rawMesh.vertices.count
            let shiftedIndices = terrainFace.mesh.indices.map { UInt32(numberOfIndices) + $0 }
            self.rawMesh.indices.append(contentsOf: shiftedIndices)
            self.rawMesh.vertices.append(contentsOf: terrainFace.mesh.vertices)
            self.rawMesh.normals.append(contentsOf: terrainFace.mesh.normals)
        }

        // Calculate normals

        mergeVerticesAndRecalculateNormals()
    }

    func updateColor(_ color: SIMD3<Float>) {
        if colors.count != self.rawMesh.vertices.count {
            let newColors = Array(repeating: SIMD4<Float>(), count: self.rawMesh.vertices.count)
            self.colors = newColors
        }
        for colorIndex in 0..<colors.count {
            self.colors[colorIndex].x = color.x
            self.colors[colorIndex].y = color.y
            self.colors[colorIndex].z = color.z
        }

        self.colorBuffer = self.device.makeBuffer(
            bytes: &self.colors, length: MemoryLayout<SIMD4<Float>>.stride * self.colors.count,
            options: [])!
    }

    func updateShape(settings: ShapeSettings) {
        self.shapeSettings = settings
        self.shapeGenerator = ShapeGenerator(settings: settings)
        self.generateMesh()
        self.vertexBuffer = self.device.makeBuffer(
            bytes: &self.rawMesh.vertices,
            length: MemoryLayout<SIMD3<Float>>.stride * self.rawMesh.vertices.count, options: [])!
        self.indexBuffer = device.makeBuffer(
            bytes: &self.rawMesh.indices,
            length: MemoryLayout<UInt32>.stride * self.rawMesh.indices.count, options: [])!
        self.normalBuffer = device.makeBuffer(
            bytes: &self.normals, length: MemoryLayout<SIMD3<Float>>.stride * self.normals.count,
            options: [])!

        self.updateColor(self.colors[0].xyz)
    }

    func update(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: Position.index)
        encoder.setVertexBuffer(self.colorBuffer, offset: 0, index: Color.index)
        encoder.setVertexBuffer(self.normalBuffer, offset: 0, index: Normal.index)
    }

    func mergeVerticesAndRecalculateNormals() {
        let epsilon: Float = 0.00001

        var uniqueVertices: [SIMD3<Float>] = []
        var newIndices: [UInt32] = []
        var vertexMapping: [Int: Int] = [:]

        for (index, vertex) in self.rawMesh.vertices.enumerated() {
            var found = false
            for (uniqueIndex, uniqueVertex) in uniqueVertices.enumerated() {
                if distance(vertex, uniqueVertex) < epsilon {
                    vertexMapping[index] = uniqueIndex
                    found = true
                    break
                }
            }

            if !found {
                vertexMapping[index] = uniqueVertices.count
                uniqueVertices.append(vertex)
            }
        }

        for oldIndex in self.rawMesh.indices {
            if let newIndex = vertexMapping[Int(oldIndex)] {
                newIndices.append(UInt32(newIndex))
            }
        }

        self.rawMesh.vertices = uniqueVertices
        self.rawMesh.indices = newIndices

        self.normals = calculateVertexNormals(
            vertices: self.rawMesh.vertices, indices: self.rawMesh.indices)
        self.rawMesh.normals = self.normals
    }
}

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

        self.update(encoder: encoder)

        encoder.drawIndexedPrimitives(
            type: .triangle, indexCount: self.rawMesh.indices.count, indexType: .uint32,
            indexBuffer: self.indexBuffer, indexBufferOffset: 0
        )
    }
}

// Calculate vertex normals for a list of vertices assuming triangular mesh
func calculateVertexNormals(vertices: [SIMD3<Float>], indices: [UInt32]) -> [SIMD3<Float>] {
    // Initialize normal vectors with zero
    var vertexNormals = [SIMD3<Float>](repeating: float3(0, 0, 0), count: vertices.count)

    // Calculate face normals and accumulate for each vertex
    for i in stride(from: 0, to: indices.count, by: 3) {
        guard i + 2 < indices.count else { break }

        let index0 = Int(indices[i])
        let index1 = Int(indices[i + 1])
        let index2 = Int(indices[i + 2])

        let A = vertices[index0]
        let B = vertices[index1]
        let C = vertices[index2]

        // Calculate face normal using cross product
        let faceNormal = cross(B - A, C - A)

        // Accumulate normal for each vertex of the triangle
        vertexNormals[index0] += faceNormal
        vertexNormals[index1] += faceNormal
        vertexNormals[index2] += faceNormal
    }

    // Normalize the accumulated normals
    return vertexNormals.map { vertex in
        return normalize(vertex)
    }
}
