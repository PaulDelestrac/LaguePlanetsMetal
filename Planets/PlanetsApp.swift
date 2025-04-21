//
//  PlanetsApp.swift
//  Planets
//
//  Created by Paul Delestrac on 06/12/2024.
//

import SwiftUI

@main
struct PlanetsApp: App {
    //@State var optionsList: [Options] = []
    @State private var navigationContext = NavigationContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationContext)
        }
        .modelContainer(for: [Options.self])
    }
}
