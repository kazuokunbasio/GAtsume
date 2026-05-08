//
//  Item.swift
//  GAtsume
//
//  Created by ISHIBASHI KAZUHIRO on 2026/05/08.
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
