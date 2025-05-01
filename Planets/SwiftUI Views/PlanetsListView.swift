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

    var body: some View {
        @Bindable var navigationContext = navigationContext
        List(selection: $navigationContext.selectedOptions) {
            ForEach(optionsList) { options in
                NavigationLink(options.name, value: options) //{
                    .swipeActions {
                        Button(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            if options.id == navigationContext.selectedOptions?.id {
                                navigationContext.selectedOptions = nil
                            }
                            context.delete(options)
                        }
                    }

            }
            .onDelete {
                $0.forEach { index in
                    if navigationContext.selectedOptions?.id == optionsList[index].id {
                        navigationContext.selectedOptions = nil
                    }
                }
                deleteItems(at: $0)
            }
            .renameAction {
                isFocused = true
            }
        }
        //.navigationTitle(navigationContext.sideBarTitle)
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
