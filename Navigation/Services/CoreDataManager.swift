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
        print(type(of: self), #function, model)
        self.model = model

        defer {
            /// Initialize container
            let _ = persistentStoreContainer
        }
    }

    lazy var persistentStoreContainer: NSPersistentContainer = {
        print(type(of: self), #function, model)
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
        print(type(of: self), #function, model)
        return persistentStoreContainer.viewContext
    }()

    func save() {
        print(type(of: self), #function, model)
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
        print(type(of: self), #function, model)
        let object = NSEntityDescription.insertNewObject(forEntityName: String(describing: entity), into: context) as! T
        return object
    }

    func delete(object: NSManagedObject) {
        print(type(of: self), #function, model)
        context.delete(object)
        save()
    }

    func find<T: NSManagedObject> (entity: T.Type, with predicate: NSPredicate) -> T? {
        
        return nil
    }

    func fetchData<T: NSManagedObject> (for entity: T.Type) -> [T] {
        print(type(of: self), #function, model)
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
