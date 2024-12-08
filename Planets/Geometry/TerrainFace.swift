//
//  TerrainFace.swift
//  Planets
//
//  Created by Paul Delestrac on 06/12/2024.
//

import Foundation
import MetalKit
import simd

struct Vertex {
    var x: Float
    var y: Float
    var z: Float
};

extension Vertex {
    init (_ position: SIMD3<Float>) {
        self.x = position.x
        self.y = position.y
        self.z = position.z
    }
}

struct RawMesh {
    var vertices: [SIMD3<Float>]
    var indices: [UInt16]
    var normals: [SIMD3<Float>] = []
}

class TerrainFace {
    var mesh = RawMesh(vertices: [], indices: [])
    
    let shapeGenerator: ShapeGenerator
    
    let resolution: Int
    let localUp: SIMD3<Float>
    var axisA: SIMD3<Float>
    var axisB: SIMD3<Float>
    
    init(shapeGenerator: ShapeGenerator, resolution: Int, localUp: SIMD3<Float>) {
        self.shapeGenerator = shapeGenerator
        self.resolution = resolution
        self.localUp = localUp
        
        self.axisA = SIMD3(x: localUp.y, y: localUp.z, z: localUp.x)
        self.axisB = SIMD3(x: localUp.z, y: localUp.x, z: localUp.y)
    }
    
    func construct_mesh() {
        var vertices: [SIMD3<Float>] = []
        var triangles: [UInt16] = []
        
        for y in 0..<self.resolution {
            for x in 0..<self.resolution {
                let index = y * self.resolution + x
                let percent = SIMD2<Float>(x: Float(x), y: Float(y)) / Float(self.resolution - 1)
                let pointOnUnitCube = localUp + (Float(percent.x) - 0.5) * 2 * self.axisA + (Float(percent.y) - 0.5) * 2 * self.axisB
                let pointOnUnitSphere = normalize(pointOnUnitCube)
                //vertices.append(Vertex(pointOnUnitCube))
                vertices.append(shapeGenerator.calculatePointOnPlanet(pointOnUnitSphere: pointOnUnitSphere))
                
                if (x != self.resolution - 1) && (y != self.resolution - 1) {
                    triangles.append(UInt16(index))
                    triangles.append(UInt16(index + self.resolution))
                    triangles.append(UInt16(index + self.resolution + 1))
                    
                    triangles.append(UInt16(index))
                    triangles.append(UInt16(index + self.resolution + 1))
                    triangles.append(UInt16(index + 1))
                }
            }
        }

        self.mesh.vertices = vertices
        self.mesh.indices = triangles
        self.mesh.normals = calculateVertexNormals(vertices: vertices, indices: triangles)
        if localUp.x < 0 || localUp.y < 0 || localUp.z < 0 {
            self.mesh.normals = self.mesh.normals.map { normal in
                return -normal
            }
        }
    }
}
