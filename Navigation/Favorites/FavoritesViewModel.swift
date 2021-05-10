//
//  FavoritesViewModel.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit
import CoreData

final class FavoritesViewModel: NSObject, FavoritesViewControllerOutput {

    weak var input: FavoritesViewControllerInput?

    var numberOfRows: Int {
        resultsController.fetchedObjects?.count ?? 0
    }

    private var filter: String?

    private var resultsController: NSFetchedResultsController<FavoritePost> = {

        let sortDescriptor = NSSortDescriptor(key: #keyPath(FavoritePost.identifier), ascending: true)

        guard let resultsController: NSFetchedResultsController<FavoritePost> = FavoritesManager.shared.makeFetchedResultsController(for: FavoritePost.self, in: .background, sortingBy: sortDescriptor, with: nil) as? NSFetchedResultsController<FavoritePost> else {
            fatalError("Cannot build result controller")
        }

        return resultsController
    }()

    override init() {
        super.init()
        resultsController.delegate = self
    }

    func post(for indexPath: IndexPath) -> Post {

        let favoritePost = resultsController.object(at: indexPath)

        let post = Post(identifier: Int(favoritePost.identifier),
                        author: favoritePost.author ?? "",
                        description: favoritePost.postDescription ?? "",
                        image: "",
                        likes: Int(favoritePost.likes),
                        views: Int(favoritePost.views))
        return post
    }

    func loadImage(for indexPath: IndexPath, completion: @escaping (UIImage?) -> Void) {

        let favoritePost = resultsController.object(at: indexPath)

        DispatchQueue.global().async {
            guard let cacheFilename = favoritePost.image,
                  let image = ImageCacheService.shared.image(filename: cacheFilename) else {
                completion(nil)
                return
            }
            completion(image)
        }
    }

    func favoritePost(for indexPath: IndexPath) -> FavoritePost {
        resultsController.object(at: indexPath)
    }

    func reloadData(completion: ((Bool, Error?) -> Void)?) {
        let predicate: NSPredicate?

        if let filter = filter,
           let normalizedFilter = filter.applyingTransform(StringTransform(AppConstants.stringTransformer), reverse: false) {
            let name = "normalizedAuthor"
            let value = "\(normalizedFilter)*"
            predicate = NSPredicate(format: "%K like %@", name, value)
        } else {
            predicate = nil
        }

        resultsController.fetchRequest.predicate = predicate

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                try self.resultsController.performFetch()
                completion?(true, nil)
            } catch {
                guard let completion = completion else {
                    print(error.localizedDescription)
                    return
                }
                completion(false, error)
            }
        }
    }

    func setFilter(_ filter: String, completion: @escaping UpdatesHandler) {
        filterData(using: filter, completion: completion)
    }

    func clearFilter(completion: @escaping UpdatesHandler) {
        filterData(using: nil, completion: completion)
    }

    private func filterData(using filter: String?, completion: @escaping UpdatesHandler) {
        let initialData = resultsController.fetchedObjects ?? []
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

            let newData = self.resultsController.fetchedObjects ?? []

            let (addedIndexes, deletedIndexes) = Array<FavoritePost>.getChangedIndexes(initial: initialData, updated: newData)

            let changes = Changeset(added: addedIndexes, deleted: deletedIndexes)

            completion(changes, nil)

        }
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension FavoritesViewModel: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        input?.willUpdate()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        guard let indexPath = indexPath else { return }

        switch type {
        case .delete:
            input?.updateRow(at: indexPath, action: .delete)
        case .insert:
            input?.updateRow(at: indexPath, action: .add)
        case .move:
            guard let newIndexPath = newIndexPath else { return }
            input?.updateRow(at: indexPath, action: .move(newIndexPath))
        case .update:
            input?.updateRow(at: indexPath, action: .redraw)
        @unknown default:
            print("Unknown action type: \(type)")
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        input?.didUpdate()
    }
}
