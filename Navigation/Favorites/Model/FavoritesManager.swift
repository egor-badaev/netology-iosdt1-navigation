//
//  FavoritesManager.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import CoreData

final class FavoritesManager: CoreDataManager {

    static let shared: FavoritesManager = {
        let instance = FavoritesManager(model: "Favorites")
        return instance
    }()

    private override init(model: String) {
        super.init(model: model)
        persistentStoreContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
