//
//  PlanetContentView.swift
//  Planets
//
//  Created by Paul Delestrac on 01/05/2025.
//

import SwiftUI
//
//  PlanetContentView.swift
//  Planets
//
//  Created by Paul Delestrac on 01/05/2025.
//

import MetalKit
import SwiftData
import SwiftUI
import Glur

struct PlanetContentView: View {
    @Environment(\.options) private var options: Options
    @State private var isEditing: Bool = false
    @State private var isScrolling: Bool = false
    @State private var isPresented = true

    var body: some View {
        MetalView(isEditing: $isEditing, isScrolling: $isScrolling)
            .environment(\.options, options)
            .inspector(isPresented: $isPresented) {
                SettingsView(isScrolling: $isScrolling)
                    .environment(\.options, options)
            }
    }
}

#Preview {
    PlanetContentView()
}
