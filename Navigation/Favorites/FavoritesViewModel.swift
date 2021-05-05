//
//  FavoritesViewModel.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class FavoritesViewModel: FavoritesViewControllerOutput {

    var numberOfRows: Int {
        posts.count
    }

    private var posts = [FavoritePost]()

    func post(for index: Int) -> Post {
        let favoritePost = posts[index]

        let post = Post(identifier: Int(favoritePost.identifier),
                        author: favoritePost.author ?? "",
                        description: favoritePost.postDescription ?? "",
                        image: "",
                        likes: Int(favoritePost.likes),
                        views: Int(favoritePost.views))
        return post
    }

    func image(for index: Int) -> UIImage {
        let favoritePost = posts[index]
        guard let data = favoritePost.image,
              let image = UIImage(data: data) else {
            return UIImage()
        }
        return image
    }

    func favoritePost(for index: Int) -> FavoritePost? {
        guard posts.indices.contains(index) else {
            return nil
        }
        return posts[index]
    }

    func reloadData(completion: ((Bool, Error?) -> Void)?) {
        FavoritesManager.shared.fetchDataAsync(for: FavoritePost.self) { [weak self] results, error in
            guard let self = self else { return }
            if let error = error {
                completion?(false, error)
                return
            }
            self.posts = results
            completion?(true, nil)
        }
    }
}
