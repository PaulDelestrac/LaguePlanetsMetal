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

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query var optionsList: [Options]
    @Environment(\.modelContext) private var context
    @Environment(NavigationContext.self) private var navigationContext

    @State private var selectedOptions: Options?
    @State private var selectedOptionsID: UUID?
    @State public var isEditing = false
    @State public var isScrolling = false
    @State var isPresented = true

    @State var temporaryText = ""
    @FocusState var isFocused: Bool
    @Binding var refreshMiniatures: Bool

    var body: some View {
        @Bindable var navigationContext = navigationContext

        NavigationSplitView {
            PlanetsListView(
                selectedOptionsID: $selectedOptionsID,
                selectedOptions: $selectedOptions,
            )
            Spacer()
            HStack {
                Button {
                    let shapeSettings = ShapeSettings()
                    let option = Options(name: "New Planet", shapeSettings: shapeSettings)
                    context.insert(option)
                } label: {
                    Label {
                        Text("Add Planet")
                    } icon: {
                        Image("custom.globe.americas.fill.badge.plus")
                    }
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(10)
        } detail: {
            VStack {
                if navigationContext.selectedOptions != nil {
                    MetalView(isEditing: $isEditing, isScrolling: $isScrolling)
                        .environment(
                            \.options,
                            navigationContext.selectedOptions!
                        )
                } else {
                    Text("Choose a planet or create a new one!")
                }
            }
        }
        /*
        .toolbar {
            if selectedOptionsID != nil {
                Button {
                    let index = optionsList.firstIndex(where: { $0.id == selectedOptionsID })
                    if let index = index {
                        deleteOptions(offsets: IndexSet([index]))
                    }
                    //selectedOptions = nil
                    //selectedOptionsID = nil
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
        .toolbarRole(.editor)*/
        .navigationTitle(
            Text("\(selectedOptions?.name ?? "")")
        )
        .inspector(isPresented: $isPresented) {
            Inspector(
                navigationContext: navigationContext,
                isScrolling: $isScrolling,
            )
            .toolbar {
                RightToolbarItems(isPresented: $isPresented)
            }
        }
    }

    struct Inspector: View {
        @Bindable var navigationContext: NavigationContext
        @Binding var isScrolling: Bool
        var body: some View {
            if $navigationContext.selectedOptions.wrappedValue != nil {
                SettingsView(
                    isScrolling: $isScrolling
                )
                .environment(\.options, navigationContext.selectedOptions!)
                .frame(
                    width: 250)
            } else {
                VStack {
                    // Image("custom.globe.europe.africa.badge.questionmark")
                    //     .resizable()
                    //     .scaledToFit()
                    //     .frame(width: 32, height: 32)
                    // Text("No planet selected!")
                    Text(
                        "TODO - change the planet selection to be a grid of miniatures like in freeform app"
                    )
                }
            }
        }
    }

    struct RightToolbarItems: ToolbarContent {
        @Binding var isPresented: Bool
        var body: some ToolbarContent {
            ToolbarItem(content: { Spacer() })
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "sidebar.right")
                }
            }
        }
    }

}

extension ContentView {
    func deleteOptions(offsets: IndexSet) {
        for index in offsets {
            context.delete(optionsList[index])
        }
    }
}

extension EnvironmentValues {
    @Entry var options = Options()
}

#Preview {
    @Previewable @State var settings = [ShapeSettings()]
    @Previewable @State var options = Options()
    @Previewable @State var refresh: Bool = false
    ContentView(refreshMiniatures: $refresh)
}
