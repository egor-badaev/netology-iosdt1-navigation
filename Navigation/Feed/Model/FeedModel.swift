//
//  FeedModel.swift
//  Navigation
//
//  Created by Egor Badaev on 09.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

struct FeedModel {
    
    static let shared: FeedModel = {
        let instance = FeedModel()
        return instance
    }()
    
    let posts: [PostDummy]

    private init() {
        var posts = [PostDummy]()
        for index in 1...Int.random(in: 2...10) {
            posts.append(PostDummy(title: "Пост \(index)",
                                   toDoUrl: "https://jsonplaceholder.typicode.com/todos/\(index)",
                                   planetUrl: "https://swapi.dev/api/planets/\(index)/"))
        }
        self.posts = posts
    }
}
