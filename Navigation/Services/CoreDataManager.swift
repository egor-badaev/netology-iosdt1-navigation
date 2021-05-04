//
//  CoreDataManager.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import CoreData

enum CoreDataManagerError: LocalizedError {
    case fetchRequestError

    var errorDescription: String? {
        switch self {
        case .fetchRequestError:
            return "❗️ Cannot build NSFetchRequest"
        }
    }
}

class CoreDataManager {

    typealias CompletioHandler = (Bool, Error?) -> Void

    enum ContextType {
        case main
        case background
    }

    private let model: String

    init(model: String) {
        self.model = model

        defer {
            /// Initialize container
            let _ = persistentStoreContainer
        }
    }

    lazy var persistentStoreContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: model)
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                // TODO: Show error to user, do not crash app
                fatalError()
            }
        }
        return container
    }()

    lazy var context: NSManagedObjectContext = {
        return persistentStoreContainer.viewContext
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentStoreContainer.newBackgroundContext()
        return context
    }()

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO: Notify user
                print("Error saving context! ", error.localizedDescription)
            }
        }
    }

    func saveAsync(completion: CompletioHandler?) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                try self.backgroundContext.save()
                completion?(true, nil)
            } catch {
                print("Error saving background context! ", error.localizedDescription)
                completion?(false, error)
            }
        }
    }

    func create<T: NSManagedObject> (from entity: T.Type, in contextType: ContextType = .main) -> T {
        var context: NSManagedObjectContext
        switch contextType {
        case .main:
            context = self.context
        case .background:
            context = backgroundContext
        }
        let object = NSEntityDescription.insertNewObject(forEntityName: String(describing: entity), into: context) as! T
        return object
    }

    func delete(object: NSManagedObject) {
        context.delete(object)
        save()
    }

    func deleteAsync(object: NSManagedObject, with completion: CompletioHandler?) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            self.backgroundContext.delete(object)
            self.saveAsync(completion: completion)
        }
    }

    func fetchData<T: NSManagedObject> (for entity: T.Type) -> [T] {
        guard let request = entity.fetchRequest() as? NSFetchRequest<T> else {
            print("❗️ Cannot build NSFetchRequest")
            return []
        }

        do {
            return try context.fetch(request)
        } catch {
            print("❗️", error.localizedDescription)
            return []
        }
    }

    func fetchDataAsync<T: NSManagedObject> (for entity: T.Type, with completion: @escaping ([T], Error?) -> Void) {
        guard let request = entity.fetchRequest() as? NSFetchRequest<T> else {
            completion([], CoreDataManagerError.fetchRequestError)
            return
        }

        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            do {
                let results = try self.backgroundContext.fetch(request)
                completion(results, nil)
            } catch {
                completion([], error)
            }
        }

    }
}
