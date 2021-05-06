//
//  FavoritePost+CoreDataClass.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//
//

import UIKit
import CoreData

@objc(FavoritePost)
public class FavoritePost: NSManagedObject {

    func configure(with post: Post, image: UIImage? = nil) {
        self.identifier = Int32(post.identifier)

        let author = post.author
        self.author = author
        let authorTransformer = StringTransform(AppConstants.stringTransformer)
        self.normalizedAuthor = author.applyingTransform(authorTransformer, reverse: false)

        self.postDescription = post.description
        self.likes = Int16(post.likes)
        self.views = Int16(post.views)
        self.savedOn = Date()

        var postImage = UIImage()
        if let image = image {
            postImage = image
        } else if let image = UIImage(named: post.image) {
            postImage = image
        }

        let imageURL = ImageCacheService.shared.cachedFilename(for: postImage)
        self.image = imageURL
    }

}
