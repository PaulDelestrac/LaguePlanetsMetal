//
//  ColorSettingsView.swift
//  Planets
//
//  Created by Paul Delestrac on 10/12/2024.
//

import SwiftUI

struct ColorSettingsView: View {
    @Environment(\.options) private var options: Options
    @Binding var isEditing: Bool
    var body: some View {
        @Bindable var options = options
        VStack {
            Text("Color (RGB)")
            Slider(
                value: $options.color.x,
                in: 0...1,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.isColorChanging = editing
                }
            )
            .tint(Color.red)
            Slider(
                value: $options.color.y,
                in: 0...1,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.isColorChanging = editing
                }
            )
            .tint(Color.green)
            Slider(
                value: $options.color.z,
                in: 0...1,
                onEditingChanged: { editing in
                    isEditing = editing
                    options.isColorChanging = editing
                }
            )
            .tint(Color.blue)
        }
    }
}

#Preview {
    @Previewable @State var isEditing: Bool = false
    ColorSettingsView(isEditing: $isEditing)
}
