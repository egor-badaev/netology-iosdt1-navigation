//
//  CoreDataManager.swift
//  Navigation
//
//  Created by Egor Badaev on 03.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
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

    func create<T: NSManagedObject> (from entity: T.Type) -> T {
        let object = NSEntityDescription.insertNewObject(forEntityName: String(describing: entity), into: context) as! T
        return object
    }

    func delete(object: NSManagedObject) {
        context.delete(object)
        save()
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
}
