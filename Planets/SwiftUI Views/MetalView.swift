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
import SwiftUI

struct MetalView: View {
    @Environment(\.options) private var options: Options
    @Binding public var isEditing: Bool
    @Binding public var isScrolling: Bool
    @State private var metalView = MTKView()
    @State private var gameController: GameController?
    @State private var previousTranslation = CGSize.zero
    @State private var previousScroll: CGFloat = 1

    var body: some View {
        MetalViewRepresentable(
            gameController: gameController,
            metalView: $metalView,
            options: options,
            isEditing: $isEditing,
            isScrolling: $isScrolling
        )
        .onAppear {
            gameController = GameController(
                metalView: metalView, options: options, isEditing: isEditing,
                isScrolling: isScrolling)
        }
        /*.gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in
                InputController.shared.touchLocation = value.location
                InputController.shared.touchDelta = CGSize(
                    width: value.translation.width - previousTranslation.width,
                    height: value.translation.height - previousTranslation.height)
                previousTranslation = value.translation
                // if the user drags, cancel the tap touch
                if abs(value.translation.width) > 1 ||
                    abs(value.translation.height) > 1 {
                    InputController.shared.touchLocation = nil
                }
            }
            .onEnded {_ in
                previousTranslation = .zero
            })
        .gesture(MagnificationGesture()
            .onChanged { value in
                let scroll = value - previousScroll
                InputController.shared.mouseScroll.x = Float(scroll)
                * Settings.touchZoomSensitivity
                previousScroll = value
            }
            .onEnded {_ in
                previousScroll = 1
            })*/
    }
}

#if os(macOS)
    typealias ViewRepresentable = NSViewRepresentable
#elseif os(iOS)
    typealias ViewRepresentable = UIViewRepresentable
#endif

struct MetalViewRepresentable: ViewRepresentable {
    let gameController: GameController?
    @Binding var metalView: MTKView
    let options: Options
    @Binding var isEditing: Bool
    @Binding var isScrolling: Bool

    #if os(macOS)
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        class Coordinator: NSObject, NSWindowDelegate {
            var parent: MetalViewRepresentable
            var dragDebounceTimer: Timer?
            var mouseMonitor: Any?
            var isDragging: Bool = false

            init(_ parent: MetalViewRepresentable) {
                self.parent = parent
                super.init()

                // Add global mouse event monitor to detect mouse up
                mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
                    .leftMouseUp, .leftMouseDragged,
                ]) { [weak self] event in
                    if event.type == .leftMouseUp && self?.isDragging == true {
                        // Mouse up detected, actually end the drag
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("windowDidDrag"), object: nil)
                            self?.isDragging = false
                        }
                    }
                }
            }

            deinit {
                if let mouseMonitor = mouseMonitor {
                    NSEvent.removeMonitor(mouseMonitor)
                }
            }

            func windowWillMove(_ notification: Notification) {
                dragDebounceTimer?.invalidate()
                isDragging = true
                NotificationCenter.default.post(
                    name: NSNotification.Name("windowWillDrag"), object: nil)
            }
            func windowDidMove(_ notification: Notification) {}
        }
        func makeNSView(context: Context) -> some NSView {
            DispatchQueue.main.async {
                metalView.window?.delegate = context.coordinator
            }
            return metalView
        }
        func updateNSView(_ uiView: NSViewType, context: Context) {
            updateMetalView()
        }
    #elseif os(iOS)
        func makeUIView(context: Context) -> MTKView {
            metalView
        }

        func updateUIView(_ uiView: MTKView, context: Context) {
            updateMetalView()
        }
    #endif

    func updateMetalView() {
        gameController?.options = options
        gameController?.isEditing = isEditing
        gameController?.isScrolling = isScrolling
    }
}

#Preview {
    @Previewable @State var testBool: Bool = false
    @Previewable @State var options = Options()
    @Previewable @State var isScrolling: Bool = false
    VStack {
        MetalView(isEditing: $testBool, isScrolling: $isScrolling)
        Text("Metal View")
    }
}
