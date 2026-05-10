//
//  Item.swift
//  KeymapOverlay
//
//  Created by Lenny Phelan on 5/10/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
