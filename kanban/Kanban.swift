//
//  Kanban.swift
//  kanban
//
//  Created by Stevanus Prasetyo Soemadi on 23/11/21.
//

import Foundation

class Kanban: Codable {
    
    var title: String
    var items: [String]
    
    init(title: String, items: [String]) {
        self.title = title
        self.items = items
    }
}

