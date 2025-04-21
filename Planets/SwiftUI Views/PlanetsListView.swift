import SwiftData
//
//  PlanetsListView.swift
//  Planets
//
//  Created by Paul Delestrac on 19/04/2025.
//
import SwiftUI

struct PlanetsListView: View {
    @Query var optionsList: [Options]
    @Environment(\.modelContext) private var context
    @Environment(NavigationContext.self) private var navigationContext
    @Binding var selectedOptionsID: UUID?
    @Binding var selectedOptions: Options?
    @FocusState var isFocused: Bool

    private func nameBinding(for options: Options) -> Binding<String> {
        Binding(
            get: { options.name },
            set: { newValue in
                if let index = optionsList.firstIndex(where: { $0.id == options.id }) {
                    optionsList[index].name = newValue
                    if selectedOptionsID == options.id {
                        selectedOptions = optionsList[index]
                    }
                }
            }
        )
    }

    var body: some View {
        @Bindable var navigationContext = navigationContext
        List(selection: $navigationContext.selectedOptions) {
            ForEach(optionsList) { options in
                NavigationLink(options.id.uuidString, value: options)
                    .swipeActions {
                        Button(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            navigationContext.selectedOptions = nil
                            context.delete(options)                        }
                    }
                /*NavigationLink(value: options.id) {
                    TextField(
                        "Planet Name",
                        text: nameBinding(for: options)
                    )
                    .focused($isFocused)
                    .textContentType(.name)
                    .contextMenu {
                        Button("Delete", systemImage: "trash") {
                            if let index = optionsList.firstIndex(where: { $0.id == options.id}) {
                                deleteItems(at: IndexSet([index]))
                            }
                            if selectedOptionsID == options.id {
                                selectedOptions = nil
                                selectedOptionsID = nil
                            }
                        }
                        RenameButton()
                    }
                    .renameAction {
                        isFocused = true
                    }
                }*/
            }
            .onDelete(perform: deleteItems)
            .renameAction {
                isFocused = true
            }
        }
        .navigationTitle(navigationContext.sideBarTitle)
        /*.onChange(of: selectedOptionsID) { _, newSelectedOptionsID in
            handleSelectedOptionsChange(newSelectedOptionsID)
        }*/
    }

    func deleteItems(at offsets: IndexSet) {
        offsets.forEach { index in
            context.delete(optionsList[index])
        }
    }

    /*private func handleSelectedOptionsChange(_ newSelectedOptionsID: UUID?) {
        if let foundOptions = optionsList.first(where: { $0.id == newSelectedOptionsID }) {
            selectedOptions = foundOptions
            selectedOptions?.shapeSettings.needsUpdate = true
        }
    }*/
}
