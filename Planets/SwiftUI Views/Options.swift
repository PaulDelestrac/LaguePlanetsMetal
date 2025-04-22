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

import Observation
import SwiftData
import SwiftUI

@Model
class Options: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String = "New Planet"

    // Replace float3 with individual components
    var colorX: Float = 0
    var colorY: Float = 0
    var colorZ: Float = 0

    var shapeSettings = ShapeSettings()

    var isColorChanging = false
    var colorNeedsUpdate: Bool = false

    // Computed property to provide the float3 interface
    var color: float3 {
        get {
            return float3(colorX, colorY, colorZ)
        }
        set {
            colorX = newValue.x
            colorY = newValue.y
            colorZ = newValue.z
        }
    }

    init() {
        self.id = UUID()
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
    }

    init(color: float3) {
        self.id = UUID()
        self.colorX = color.x
        self.colorY = color.y
        self.colorZ = color.z
    }

    init(name: String, shapeSettings: ShapeSettings) {
        self.id = UUID()
        self.name = name
        self.shapeSettings = shapeSettings
    }

    init(color: float3, shapeSettings: ShapeSettings) {
        self.id = UUID()
        self.colorX = color.x
        self.colorY = color.y
        self.colorZ = color.z
        self.shapeSettings = shapeSettings
    }

    func setShapeSettings(_ shapeSettings: ShapeSettings) {
        self.shapeSettings = shapeSettings
    }
}
