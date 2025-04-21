//
//  NavigationContext.swift
//  Planets
//
//  Created by Paul Delestrac on 21/04/2025.
//

import SwiftUI

@Observable
class NavigationContext {
    var selectedOptions: Options?
    var columnVisibility: NavigationSplitViewVisibility

    var sideBarTitle: String = "Planets"

    var contentListTitle: String = "Planets"

    init(
        selectedOptions: Options? = nil,
        columnVisibility: NavigationSplitViewVisibility = .automatic,
    ) {
        self.selectedOptions = selectedOptions
        self.columnVisibility = columnVisibility
    }
}
