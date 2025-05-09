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

class GameController: NSObject {
    var scene: GameScene
    var renderer: Renderer
    var options: Options
    var fps: Double = 0
    var deltaTime: Double = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
    var isEditing: Bool
    var isScrolling: Bool
    var isWindowDragging: Bool = false
    var isWindowResizing: Bool = false

    init(metalView: MTKView, options: Options, isEditing: Bool = false, isScrolling: Bool = false) {
        renderer = Renderer(metalView: metalView, options: options)
        scene = GameScene()
        self.options = options
        self.isEditing = isEditing
        self.isScrolling = isScrolling

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillDrag),
            name: NSNotification.Name("windowWillDrag"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidDrag),
            name: NSNotification.Name("windowDidDrag"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillResize),
            name: NSNotification.Name("windowWillResize"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSNotification.Name("windowDidResize"),
            object: nil
        )

        metalView.delegate = self
        fps = Double(metalView.preferredFramesPerSecond)
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func windowWillDrag() {
        self.isWindowDragging = true
    }
    @objc func windowDidDrag() {
        self.isWindowDragging = false
    }
    @objc func windowWillResize() {
        self.isWindowResizing = true
    }
    @objc func windowDidResize() {
        self.isWindowResizing = false
    }
}

extension GameController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if !options.shapeSettings.isChanging && !self.isScrolling
            && !options.isColorChanging && !self.isWindowDragging
        {
            scene.update(size: size)
        }
        renderer.mtkView(view, drawableSizeWillChange: size)
    }

    func draw(in view: MTKView) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = (currentTime - lastTime)
        lastTime = currentTime

        if !options.shapeSettings.isChanging && !options.isColorChanging
            && !self.isWindowDragging && !self.isWindowResizing
        {
            scene.update(deltaTime: Float(deltaTime), isScrolling: self.isScrolling)
        }
        renderer.draw(scene: scene, in: view, options: options)
    }
}
