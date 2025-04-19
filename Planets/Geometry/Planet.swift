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
            terrainFace.construct_mesh(device: self.device)
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
        let precision: Int = Int(1.0 / epsilon)

        var uniqueVertices: [SIMD3<Float>] = []
        var newIndices: [UInt32] = []
        var vertexKeyMap: [String: Int] = [:]
        var vertexMapping: [Int: Int] = [:]

        for (index, vertex) in self.rawMesh.vertices.enumerated() {
            let vertexKey =
                "\(Int(vertex.x * Float(precision)))/\(Int(vertex.y * Float(precision)))/\(Int(vertex.z * Float(precision)))"

            if let existingIndex = vertexKeyMap[vertexKey] {
                vertexMapping[index] = existingIndex
            } else {
                let newIndex = uniqueVertices.count
                vertexKeyMap[vertexKey] = newIndex
                vertexMapping[index] = newIndex
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

        self.normals = calculateVertexNormalsGPU(
            device: self.device,
            vertices: self.rawMesh.vertices,
            indices: self.rawMesh.indices
        )

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
    var vertexNormals = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: vertices.count)

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

func calculateVertexNormalsGPU(device: MTLDevice, vertices: [SIMD3<Float>], indices: [UInt32])
    -> [SIMD3<Float>]
{
    let vertexCount = vertices.count
    let triangleCount = indices.count / 3

    var normals = [SIMD3<Float>](repeating: SIMD3<Float>(0, 0, 0), count: vertexCount)

    if vertexCount == 0 || triangleCount == 0 {
        print("No vertices or triangles to calculate normals")
        return normals
    }

    // Create buffers
    guard
        let vertexBuffer = device.makeBuffer(
            bytes: vertices, length: MemoryLayout<SIMD3<Float>>.stride * vertexCount),
        let indexBuffer = device.makeBuffer(
            bytes: indices, length: MemoryLayout<UInt32>.stride * indices.count),
        let faceNormalBuffer = device.makeBuffer(
            length: MemoryLayout<SIMD3<Float>>.stride * triangleCount),
        let vertexNormalBuffer = device.makeBuffer(
            length: MemoryLayout<SIMD3<Float>>.stride * vertexCount)
    else {
        print("Unable to create vertex buffer, falling back to CPU calculation")
        return calculateVertexNormals(vertices: vertices, indices: indices)
    }

    // Create a compute pipeline
    guard let library = device.makeDefaultLibrary(),
        let faceNormalKernel = library.makeFunction(name: "computeFaceNormals"),
        let vertexNormalKernel = library.makeFunction(name: "computeVertexNormals"),
        let facePipelineState = try? device.makeComputePipelineState(function: faceNormalKernel),
        let vertexPipelineState = try? device.makeComputePipelineState(function: vertexNormalKernel)
    else {
        print("Unable to create compute pipeline state, falling back to CPU calculation")
        return calculateVertexNormals(vertices: vertices, indices: indices)
    }

    // Create a command queue
    let commandQueue = device.makeCommandQueue()!
    let commandBuffer = commandQueue.makeCommandBuffer()!

    let faceEncoder: any MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
    faceEncoder.setComputePipelineState(facePipelineState)
    faceEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
    faceEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
    faceEncoder.setBuffer(faceNormalBuffer, offset: 0, index: 2)

    var triangleCountUInt = UInt32(triangleCount)
    faceEncoder.setBytes(
        &triangleCountUInt, length: MemoryLayout<UInt32>.size, index: 3)

    let faceThreadGroupSize = MTLSize(width: 64, height: 1, depth: 1)
    let faceThreadGroups = MTLSize(
        width: (triangleCount + faceThreadGroupSize.width - 1) / faceThreadGroupSize.width,
        height: 1, depth: 1)
    faceEncoder.dispatchThreadgroups(
        faceThreadGroups, threadsPerThreadgroup: faceThreadGroupSize)
    faceEncoder.endEncoding()

    let vertexEncoder: any MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
    vertexEncoder.setComputePipelineState(vertexPipelineState)
    vertexEncoder.setBuffer(indexBuffer, offset: 0, index: 0)
    vertexEncoder.setBuffer(faceNormalBuffer, offset: 0, index: 1)
    vertexEncoder.setBuffer(vertexNormalBuffer, offset: 0, index: 2)

    vertexEncoder.setBytes(&triangleCountUInt, length: MemoryLayout<UInt32>.size, index: 3)
    var vertexCountUInt = UInt32(vertexCount)
    vertexEncoder.setBytes(
        &vertexCountUInt, length: MemoryLayout<UInt32>.size, index: 4)

    let vertexThreadGroupSize = MTLSize(width: 64, height: 1, depth: 1)
    let vertexThreadGroups = MTLSize(
        width: (vertexCount + vertexThreadGroupSize.width - 1) / vertexThreadGroupSize.width,
        height: 1, depth: 1)
    vertexEncoder.dispatchThreadgroups(
        vertexThreadGroups, threadsPerThreadgroup: vertexThreadGroupSize)
    vertexEncoder.endEncoding()

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    // Copy the results back to the host
    // normalBuffer.contents().copyMemory(
    //     to: &normals, byteCount: MemoryLayout<SIMD3<Float>>.stride * vertexCount)
    memcpy(&normals, vertexNormalBuffer.contents(), MemoryLayout<SIMD3<Float>>.stride * vertexCount)
    return normals
}
