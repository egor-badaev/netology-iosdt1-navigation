//
//  FavoritePost+CoreDataProperties.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//
//

import Foundation
import CoreData


extension FavoritePost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoritePost> {
        return NSFetchRequest<FavoritePost>(entityName: "FavoritePost")
    }

    @NSManaged public var identifier: Int32
    @NSManaged public var normalizedAuthor: String?
    @NSManaged public var author: String?
    @NSManaged public var postDescription: String?
    @NSManaged public var image: Data?
    @NSManaged public var likes: Int16
    @NSManaged public var views: Int16
    @NSManaged public var savedOn: Date?

}
