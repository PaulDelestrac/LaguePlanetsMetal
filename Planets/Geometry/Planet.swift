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

    enum FaceRenderMask: Int, Codable, Hashable, Equatable {
        case All, Top, Bottom, Left, Right, Front, Back
    }

    init(device: MTLDevice, shapeSettings: ShapeSettings, color: float3 = float3(0, 0, 0)) {
        self.device = device
        self.shapeSettings = shapeSettings
        self.shapeGenerator = ShapeGenerator(settings: self.shapeSettings)
        self.generateUnifiedMesh()

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

    func generateUnifiedMesh() {
        // Create empty data structures
        var allVertices: [SIMD3<Float>] = []
        var allIndices: [UInt32] = []
        var allNormals: [SIMD3<Float>] = []

        // Create maps for edge sharing
        var vertexMap: [SIMD3<Int>: UInt32] = [:]
        let epsilon: Float = 0.00001
        let scale: Int = Int(1.0 / epsilon)

        // Track the global vertex count
        var globalVertexCount: UInt32 = 0

        // Generate faces one by one
        for (faceIndex, localUp) in directions.enumerated() {
            let renderFace =
                (shapeSettings.faceRenderMask == FaceRenderMask.All)
                || (shapeSettings.faceRenderMask.rawValue - 1 == faceIndex)

            if !renderFace { continue }

            // Generate the axes the same way TerrainFace does
            var axisA = SIMD3<Float>(x: 0, y: 1, z: 0)
            if abs(dot(localUp, axisA)) > 0.9 {
                axisA = SIMD3<Float>(x: 1, y: 0, z: 0)
            }
            let axisB = normalize(cross(localUp, axisA))
            axisA = normalize(cross(axisB, localUp))

            let resolution = shapeSettings.resolution

            // Create local arrays for this face
            var faceVertices: [SIMD3<Float>] = []
            var faceIndices: [UInt32] = []
            var localToGlobalIndexMap: [Int: UInt32] = [:]

            // Generate vertices
            for y in 0..<resolution {
                for x in 0..<resolution {
                    let localIndex = y * resolution + x
                    let percent = SIMD2<Float>(x: Float(x), y: Float(y)) / Float(resolution - 1)

                    // Calculate position the same way TerrainFace does
                    let pointOnUnitCube =
                        localUp + (Float(percent.x) - 0.5) * 2 * axisA + (Float(percent.y) - 0.5)
                        * 2 * axisB
                    let pointOnUnitSphere = normalize(pointOnUnitCube)
                    let vertexPosition = shapeGenerator.calculatePointOnPlanet(
                        pointOnUnitSphere: pointOnUnitSphere)

                    // Check if this vertex already exists (shared between faces)
                    let key = SIMD3<Int>(
                        x: Int(vertexPosition.x * Float(scale)),
                        y: Int(vertexPosition.y * Float(scale)),
                        z: Int(vertexPosition.z * Float(scale))
                    )

                    if let existingGlobalIndex = vertexMap[key] {
                        // Reuse existing vertex in another face
                        localToGlobalIndexMap[localIndex] = existingGlobalIndex
                    } else {
                        // Add new vertex
                        let globalIndex = globalVertexCount
                        vertexMap[key] = globalIndex
                        localToGlobalIndexMap[localIndex] = globalIndex
                        faceVertices.append(vertexPosition)
                        globalVertexCount += 1
                    }
                }
            }

            // Create triangles using CONSISTENT winding order
            for y in 0..<(resolution - 1) {
                for x in 0..<(resolution - 1) {
                    if let i00 = localToGlobalIndexMap[y * resolution + x],
                        let i10 = localToGlobalIndexMap[y * resolution + (x + 1)],
                        let i01 = localToGlobalIndexMap[(y + 1) * resolution + x],
                        let i11 = localToGlobalIndexMap[(y + 1) * resolution + (x + 1)]
                    {

                        // Use single consistent winding order for ALL faces
                        faceIndices.append(i00)
                        faceIndices.append(i10)
                        faceIndices.append(i11)

                        faceIndices.append(i00)
                        faceIndices.append(i11)
                        faceIndices.append(i01)
                    } else {
                        print("Missing vertex at face \(faceIndex), position (\(x), \(y))")
                    }
                }
            }

            // Append face data to the unified arrays
            allVertices.append(contentsOf: faceVertices)
            allIndices.append(contentsOf: faceIndices)
        }

        // Calculate normals
        allNormals = calculateVertexNormalsGPU(
            device: self.device,
            vertices: allVertices,
            indices: allIndices
        )

        // Set the results
        self.rawMesh.vertices = allVertices
        self.rawMesh.indices = allIndices
        self.rawMesh.normals = allNormals
        self.normals = allNormals
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
        self.generateUnifiedMesh()
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
