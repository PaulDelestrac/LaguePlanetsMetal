//
//  SettingsStore.swift
//  Planets
//
//  Created by Paul Delestrac on 02/02/2025.
//

import Foundation
import SwiftData

@Model final public class OptionsStore: Identifiable {
    var creationDate: Date = Date()
    var name: String = "New Planet"
    
    public var id: UUID = UUID()
    
    init() {}
    
    init(creationDate: Date, name: String, id: UUID) {
        self.creationDate = creationDate
        self.name = name
        self.id = id
    }
}
