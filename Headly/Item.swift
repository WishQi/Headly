//
//  Item.swift
//  Headly
//
//  Created by Maoqi on 2026/5/13.
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
