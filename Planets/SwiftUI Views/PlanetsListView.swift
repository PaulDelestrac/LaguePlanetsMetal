//
//  PlanetsListView.swift
//  Planets
//
//  Created by Paul Delestrac on 19/04/2025.
//
import SwiftUI

struct PlanetsListView: View {
    @Binding var selectedOptionsID: UUID?
    @Binding var selectedOptions: Options?
    @Binding var optionsList: [Options]
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
        List(selection: $selectedOptionsID) {
            ForEach(optionsList, id: \.id) { options in
                NavigationLink(value: options.id) {
                    TextField(
                        "Planet Name",
                        text: nameBinding(for: options)
                    )
                    .focused($isFocused)
                    .textContentType(.name)
                    .contextMenu {
                        Button("Delete", systemImage: "trash") {
                            optionsList.removeAll(where: { $0.id == options.id })
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
                }
            }
        }
        .navigationTitle("Sidebar")
        .onChange(of: selectedOptionsID) { _, newSelectedOptionsID in
            handleSelectedOptionsChange(newSelectedOptionsID)
        }
    }

    private func handleSelectedOptionsChange(_ newSelectedOptionsID: UUID?) {
        if let foundOptions = optionsList.first(where: { $0.id == newSelectedOptionsID }) {
            selectedOptions = foundOptions
            selectedOptions?.shapeSettings.needsUpdate = true
        }
    }
}
