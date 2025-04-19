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
    @Environment(\.modelContext) private var context
    @State private var selectedOptions: Options?
    @State private var selectedOptionsID: UUID?
    @State var optionsList: [Options]
    @State public var isEditing = false
    @State public var isScrolling = false
    @State var isPresented = true

    @State var temporaryText = ""
    @FocusState var isFocused: Bool

    var body: some View {
        NavigationSplitView {
            PlanetsListView(
                selectedOptionsID: $selectedOptionsID,
                selectedOptions: $selectedOptions,
                optionsList: $optionsList
            )
            Spacer()
            HStack {
                Button {
                    let shapeSettings = ShapeSettings(name: "New Planet")
                    optionsList.append(Options(shapeSettings: shapeSettings))
                } label: {
                    Label {
                        //Text("Add Planet")
                    } icon: {
                        Image("custom.globe.americas.fill.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(10)
        } detail: {
            VStack {
                if selectedOptions != nil {
                    MetalView(isEditing: $isEditing, isScrolling: $isScrolling)
                        .border(Color.black, width: 2)
                        .environment(\.options, selectedOptions!)
                } else {
                    Text("Choose a planet or create a new one!")
                }
            }
        }
        .toolbar {
            if selectedOptionsID != nil {
                Button {
                    optionsList.removeAll(where: { $0.id == selectedOptionsID })
                    selectedOptions = nil
                    selectedOptionsID = nil
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
        .toolbarRole(.editor)
        .navigationTitle(
            Text("\(selectedOptions?.shapeSettings.name ?? "")")
        )
        .inspector(isPresented: $isPresented) {
            if selectedOptions != nil {
                SettingsView(isScrolling: $isScrolling)
                    .frame(width: 250)
                    .environment(\.options, selectedOptions!)
                    .toolbar {
                        ToolbarItemGroup {
                            Spacer()
                            Button {
                                isPresented.toggle()
                            } label: {
                                Image(systemName: "sidebar.right")
                            }
                        }
                    }
            } else {
                Text("No planet selected!")
                    .toolbar {
                        ToolbarItemGroup {
                            Spacer()
                            Button {
                                isPresented.toggle()
                            } label: {
                                Image(systemName: "sidebar.right")
                            }
                        }
                    }
            }
        }
    }
}

extension ContentView {
    private func deleteOptions(offsets: IndexSet) {
        optionsList.remove(atOffsets: offsets)
    }
}

extension EnvironmentValues {
    var options: Options {
        get { self[OptionsEnvironmentKey.self] }
        set { self[OptionsEnvironmentKey.self] = newValue }
    }
}

private struct OptionsEnvironmentKey: EnvironmentKey {
    static let defaultValue: Options = Options()
}

#Preview {
    @Previewable @State var settings = [ShapeSettings(name: "")]
    @Previewable @State var options = Options()
    ContentView(optionsList: [])
}
