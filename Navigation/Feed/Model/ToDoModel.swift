//
//  ToDoModel.swift
//  Navigation
//
//  Created by Egor Badaev on 30.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

struct ToDo {
    var id: Int
    var userId: Int
    var title: String
    var completed: Bool
    
    init(id: Int, userId: Int, title: String, completed: Bool) {
        self.id = id
        self.userId = userId
        self.title = title
        self.completed = completed
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
              let userId = dictionary["userId"] as? Int,
              let title = dictionary["title"] as? String,
              let completed = dictionary["completed"] as? Bool else {
            return nil
        }

        self.init(id: id, userId: userId, title: title, completed: completed)
    }
}
