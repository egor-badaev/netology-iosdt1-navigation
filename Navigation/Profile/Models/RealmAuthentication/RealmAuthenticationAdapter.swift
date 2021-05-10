//
//  RealmAuthenticationAdapter.swift
//  Navigation
//
//  Created by Egor Badaev on 17.04.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - Errors
enum RealmAuthenticationError: LocalizedError {
    case userNotLoggedIn
    case loginTaken
    case weakPassword
    case userNotFound
    case wrongPassword
}

// MARK: - Object model
@objcMembers class RealmUser: Object {
    dynamic var login: String?
    dynamic var password: String?
    dynamic var loggedIn: Date?

    override class func primaryKey() -> String? {
        return "login"
    }

}

// MARK: - Object manager
class RealmAuthenticationAdapter {

    // MARK: - Public properties
    static let shared: RealmAuthenticationAdapter = {
        let instance = RealmAuthenticationAdapter()
        return instance
    }()

    var currentUser: String? {
        guard let user = realm?.objects(RealmUser.self).first(where: { $0.loggedIn != nil }) else {
            return nil
        }
        return user.login
    }

    // MARK: - Private properties
    private var realm: Realm?

    // MARK: - Initializer
    private init() {
        let key = RealmEncryption.manager.encryptionKey
        let config = Realm.Configuration(encryptionKey: key)
        realm = try? Realm(configuration: config)
    }

    // MARK: - Public methods
    func signIn(withLogin login: String, password: String) throws {

        guard let user = realm?.object(ofType: RealmUser.self, forPrimaryKey: login.lowercased()) else {
            throw RealmAuthenticationError.userNotFound
        }

        guard user.password == password else {
            throw RealmAuthenticationError.wrongPassword
        }

        try realm?.write({
            user.loggedIn = Date.init(timeIntervalSinceNow: 0)
        })
    }

    func createUser(withLogin login: String, password: String) throws {

        if let _ = realm?.object(ofType: RealmUser.self, forPrimaryKey: login.lowercased()) {
            throw RealmAuthenticationError.loginTaken
        }

        guard password.count >= 6 else {
            throw RealmAuthenticationError.weakPassword
        }

        let user = RealmUser()
        user.login = login.lowercased()
        user.password = password

        try realm?.write({
            realm?.add(user)
        })

        try signIn(withLogin: login, password: password)

    }

    func signOut() throws {
        guard let userLogin = currentUser else {
            throw RealmAuthenticationError.userNotLoggedIn
        }

        guard let user = realm?.object(ofType: RealmUser.self, forPrimaryKey: userLogin) else {
            throw RealmAuthenticationError.userNotFound
        }

        try realm?.write({
            user.loggedIn = nil
        })
    }
}
