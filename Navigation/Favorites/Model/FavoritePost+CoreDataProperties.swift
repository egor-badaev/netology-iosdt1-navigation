//
//  FavoritePost+CoreDataProperties.swift
//  
//
//  Created by Egor Badaev on 06.05.2021.
//
//

import Foundation
import CoreData


extension FavoritePost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoritePost> {
        return NSFetchRequest<FavoritePost>(entityName: "FavoritePost")
    }

    @NSManaged public var author: String?
    @NSManaged public var identifier: Int32
    @NSManaged public var image: String?
    @NSManaged public var likes: Int16
    @NSManaged public var postDescription: String?
    @NSManaged public var savedOn: Date?
    @NSManaged public var views: Int16
    @NSManaged public var normalizedAuthor: String?

}
