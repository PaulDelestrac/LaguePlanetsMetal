//
//  PlanetsApp.swift
//  Planets
//
//  Created by Paul Delestrac on 06/12/2024.
//

import SwiftUI

@main
struct PlanetsApp: App {
    @State var optionsList: [Options] = []
    
    var body: some Scene {
        WindowGroup {
            ContentView(optionsList: [])
        }
    }
}
