//
//  Noise.swift
//  Planets
//
//  Created by Paul Delestrac on 08/12/2024.
//

import Foundation

class Noise {
    static let sources: [Int] = [
        151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142,
        8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203,
        117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165,
        71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41,
        55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89,
        18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250,
        124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189,
        28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
        129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34,
        242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31,
        181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114,
        67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
    ]
    
    static let randomSize: Int = 256
    static let Sqrt3: Double = 1.7320508075688772935
    static let Sqrt5: Double = 2.2360679774997896964
    var _random: [Int] = []
    
    /// Skewing and unskewing factors for 2D, 3D and 4D,
    /// some of them pre-multiplied.
    static let F2: Double = 0.5 * (Sqrt3 - 1.0)
    
    static let G2: Double = (3.0 - Sqrt3) / 6.0
    static let G22: Double = G2 * 2.0 - 1
    
    static let F3: Double = 1.0 / 3.0
    static let G3: Double = 1.0 / 6.0
    
    static let F4: Double = (Sqrt5 - 1.0) / 4.0
    static let G4: Double = (5.0 - Sqrt5) / 20.0
    static let G42: Double = G4 * 2.0
    static let G43: Double = G4 * 3.0
    static let G44: Double = G4 * 4.0 - 1.0
    
    /// <summary>
    /// Gradient vectors for 3D (pointing to mid points of all edges of a unit
    /// cube)
    /// </summary>
    static let Grad3: [[Int]] =
    [
        [1, 1, 0], [-1, 1, 0], [1, -1, 0],
        [-1, -1, 0], [1, 0, 1], [-1, 0, 1],
        [1, 0, -1], [-1, 0, -1], [0, 1, 1],
        [0, -1, 1], [0, 1, -1], [0, -1, -1]
    ]
    
    init()
    {
        Randomize(seed: 0)
    }
    
    init(seed: Int)
    {
        Randomize(seed: seed)
    }
    
    /// <summary>
    /// Generates value, typically in range [-1, 1]
    /// </summary>
    func Evaluate(point: float3) -> Float {
        let x: Double = Double(point.x)
        let y: Double = Double(point.y)
        let z: Double = Double(point.z)
        var n0: Double = 0
        var n1: Double = 0
        var n2: Double = 0
        var n3: Double = 0
        
        // Noise contributions from the four corners
        // Skew the input space to determine which simplex cell we're in
        let s: Double = (x + y + z) * Noise.F3
        
        // for 3D
        let i: Int = Noise.FastFloor(x: x + s)
        let j: Int = Noise.FastFloor(x: y + s)
        let k: Int = Noise.FastFloor(x: z + s)
        
        let t: Double = Double((i + j + k)) * Noise.G3
        
        // The x,y,z distances from the cell origin
        let x0: Double = x - (Double(i) - t)
        let y0: Double = y - (Double(j) - t)
        let z0: Double = z - (Double(k) - t)
        
        // For the 3D case, the simplex shape is a slightly irregular tetrahedron.
        // Determine which simplex we are in.
        // Offsets for second corner of simplex in (i,j,k)
        var i1: Int
        var j1: Int
        var k1: Int
        
        // coords
        // Offsets for third corner of simplex in (i,j,k) coords
        var i2: Int
        var j2: Int
        var k2: Int
        
        if (x0 >= y0) {
            if (y0 >= z0) {
                // X Y Z order
                i1 = 1
                j1 = 0
                k1 = 0
                i2 = 1
                j2 = 1
                k2 = 0
            } else if (x0 >= z0) {
                // X Z Y order
                i1 = 1
                j1 = 0
                k1 = 0
                i2 = 1
                j2 = 0
                k2 = 1
            } else {
                // Z X Y order
                i1 = 0
                j1 = 0
                k1 = 1
                i2 = 1
                j2 = 0
                k2 = 1
            }
        } else {
            // x0 < y0
            if (y0 < z0) {
                // Z Y X order
                i1 = 0
                j1 = 0
                k1 = 1
                i2 = 0
                j2 = 1
                k2 = 1
            } else if (x0 < z0) {
                // Y Z X order
                i1 = 0
                j1 = 1
                k1 = 0
                i2 = 0
                j2 = 1
                k2 = 1
            } else {
                // Y X Z order
                i1 = 0
                j1 = 1
                k1 = 0
                i2 = 1
                j2 = 1
                k2 = 0
            }
        }
        
        // A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
        // a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z),
        // and
        // a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z),
        // where c = 1/6.
        
        // Offsets for second corner in (x,y,z) coords
        let x1: Double = x0 - Double(i1) + Noise.G3
        let y1: Double = y0 - Double(j1) + Noise.G3
        let z1: Double = z0 - Double(k1) + Noise.G3
        
        // Offsets for third corner in (x,y,z)
        let x2: Double = x0 - Double(i2) + Noise.F3
        let y2: Double = y0 - Double(j2) + Noise.F3
        let z2: Double = z0 - Double(k2) + Noise.F3
        
        // Offsets for last corner in (x,y,z)
        let x3: Double = x0 - 0.5
        let y3: Double = y0 - 0.5
        let z3: Double = z0 - 0.5
        
        // Work out the hashed gradient indices of the four simplex corners
        let ii: Int = i & 0xff
        let jj: Int = j & 0xff
        let kk: Int = k & 0xff
        
        // Calculate the contribution from the four corners
        var t0: Double = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
        if (t0 > 0) {
            t0 *= t0
            let gi0: Int = _random[ii + _random[jj + _random[kk]]] % 12
            n0 = Double(t0 * t0 * Noise.Dot(g: Noise.Grad3[gi0], x: x0, y: y0, z: z0))
        }
        
        var t1: Double = 0.6 - x1*x1 - y1*y1 - z1*z1
        if (t1 > 0)
        {
            t1 *= t1;
            let gi1: Int = _random[ii + i1 + _random[jj + j1 + _random[kk + k1]]] % 12
            n1 = Double(t1 * t1 * Noise.Dot(g: Noise.Grad3[gi1], x: x1, y: y1, z: z1))
        }
        
        var t2: Double = 0.6 - x2*x2 - y2*y2 - z2*z2
        if (t2 > 0) {
            t2 *= t2;
            let gi2: Int = _random[ii + i2 + _random[jj + j2 + _random[kk + k2]]] % 12
            n2 = Double(t2 * t2 * Noise.Dot(g: Noise.Grad3[gi2], x: x2, y: y2, z: z2))
        }
        
        var t3: Double = 0.6 - x3*x3 - y3*y3 - z3*z3
        if (t3 > 0) {
            t3 *= t3;
            let gi3: Int = _random[ii + 1 + _random[jj + 1 + _random[kk + 1]]] % 12
            n3 = Double(t3 * t3 * Noise.Dot(g: Noise.Grad3[gi3], x: x3, y: y3, z: z3))
        }
        
        // Add contributions from each corner to get the final noise value.
        // The result is scaled to stay just inside [-1,1]
        return Float((n0 + n1 + n2 + n3) * 32)
    }
    
    
    func Randomize(seed: Int) {
        self._random =  [Int](repeating: 0, count: Noise.randomSize * 2);
        
        if (seed != 0) {
            // Shuffle the array using the given seed
            // Unpack the seed into 4 bytes then perform a bitwise XOR operation
            // with each byte
            var F = [UInt8](repeating: 0, count: 4)
            F = Noise.UnpackLittleUint32(value: seed, buffer: F)
            
            for i in 0..<Noise.sources.count {
                _random[i] = Noise.sources[i] ^ Int(F[0])
                _random[i] ^= Int(F[1])
                _random[i] ^= Int(F[2])
                _random[i] ^= Int(F[3])
                
                _random[i + Noise.randomSize] = _random[i];
            }
        } else {
            for i in 0..<Noise.randomSize {
                _random[i] = Noise.sources[i]
                _random[i + Noise.randomSize] = _random[i]
            }
        }
    }
    
    static func Dot(g: [Int], x: Double, y: Double, z: Double, t: Double) -> Double {
        let first = Double(g[0]) * x
        let second = Double(g[1]) * y
        let third = Double(g[2]) * z
        let fourth = Double(g[3]) * t
        return first + second + third + fourth
    }
    
    static func Dot(g: [Int], x: Double, y: Double, z: Double) -> Double {
        let first = Double(g[0]) * x
        let second = Double(g[1]) * y
        let third = Double(g[2]) * z
        return first + second + third
    }
    
    static func Dot(g: [Int], x: Double, y: Double) -> Double {
        return Double(g[0]) * x + Double(g[1]) * y
    }
    
    static func FastFloor(x: Double) -> Int {
        if (x >= 0) {
            return Int(x)
        } else {
            return Int(x - 1)
        }
    }
    
    /// <summary>
    /// Unpack the given integer (int32) to an array of 4 bytes  in little endian format.
    /// If the length of the buffer is too smal, it wil be resized.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <param name="buffer">The output buffer.</param>
    static func UnpackLittleUint32(value: Int, buffer: [UInt8]) -> [UInt8] {
        var temp = [UInt8]()
        if buffer.count < 4 {
            var i = 0
            while i < 4 {
                if i < buffer.count {
                    temp.append(buffer[i])
                } else {
                    temp.append(0)
                }
                i += 1
            }
        }
        
        temp[0] = UInt8(value & 0x00ff)
        temp[1] = UInt8((value & 0xff00) >> 8)
        temp[2] = UInt8((value & 0x00ff0000) >> 16)
        temp[3] = UInt8((value & 0xff000000) >> 24)
        
        return buffer;
    }
}
