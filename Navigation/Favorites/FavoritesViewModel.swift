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
    private var filter: String?

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
        let predicate: NSPredicate?

        if let filter = filter {
            let name = "author"
            let value = "\(filter)*"
            predicate = NSPredicate(format: "%K like %@", name, value)
        } else {
            predicate = nil
        }

        FavoritesManager.shared.fetchDataAsync(for: FavoritePost.self, with: predicate) { [weak self] results, error in
            guard let self = self else { return }
            if let error = error {
                completion?(false, error)
                return
            }
            self.posts = results
            completion?(true, nil)
        }
    }

    func setFilter(_ filter: String, completion: @escaping FilterHandler) {
        filterData(using: filter, completion: completion)
    }

    func clearFilter(completion: @escaping FilterHandler) {
        filterData(using: nil, completion: completion)
    }

    private func filterData(using filter: String?, completion: @escaping FilterHandler) {
        let initialData = posts
        self.filter = filter
        self.reloadData { [weak self] success, error in
            guard let self = self else {
                completion(nil, nil)
                return
            }
            guard success else {
                if let error = error {
                    print(error.localizedDescription)
                }
                completion(nil, error)
                return
            }

            let newData = self.posts

            let (addedIndexes, deletedIndexes) = Array<FavoritePost>.getChangedIndexes(initial: initialData, updated: newData)

            let changes = FilterChanges(added: addedIndexes, deleted: deletedIndexes)

            completion(changes, nil)

        }
    }

}
