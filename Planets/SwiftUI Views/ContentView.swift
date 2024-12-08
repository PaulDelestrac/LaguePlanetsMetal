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

import SwiftUI

struct ContentView: View {
    @State var options = Options()
    @State public var isEditing = false
    var body: some View {
        VStack {
            MetalView(options: options, isEditing: $isEditing)
                .border(Color.black, width: 2)
            VStack {
                HStack {
                    Slider(
                        value: $options.color.x,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.red)
                    Slider(
                        value: $options.color.y,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.green)
                    Slider(
                        value: $options.color.z,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
                    .tint(Color.blue)
                }
                Slider(
                    value: $options.shapeSettings.planetRadius,
                    in: 0.1...10,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .tint(Color.black)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
