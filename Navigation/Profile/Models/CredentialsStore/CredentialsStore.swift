//
//  CredentialsStore.swift
//  Navigation
//
//  Created by Egor Badaev on 02.02.2021.
//  Copyright © 2021 Artem Novichkov. All rights reserved.
//

import Foundation

class CredentialsStore {

    static let shared: CredentialsStore = {
        let manager = KeychainPassword()

        let instance = CredentialsStore(manager: manager)

        return instance
    }()
    
    private let passwordManager: KeychainPassword
    private let activeUserKey = "CredentialsStoreActiveUser"
    private(set) var activeUser: String? {
        get {
            return UserDefaults.standard.string(forKey: activeUserKey)
        }

        set {
            UserDefaults.standard.setValue(newValue, forKey: activeUserKey)
        }
    }

    private init(manager: KeychainPassword) {
        self.passwordManager = manager
    }

    /**
     Verifies provided credentials
     
     - parameters:
        - login: login provided by user
        - password: password provided by user
        - completion: provides `true` if all provided credentials are correct, `false` otherwise
     
     */
    func signIn(withLogin login: String, password: String, completion: (Bool) -> Void) {
        guard self.passwordManager.isValid(password, for: login) else {
            completion(false)
            return
        }
        activeUser = login
        completion(true)
    }

    /**
     Creates a new user

     - parameters:
        - login: login provided by user
        - password: password provided by user
        - completion: `success` indicates  if finished successfully and optional `error` returns failure reason in `localizedDescription` in case if something goes wrong

     */
    func createUser(withLogin login: String, password: String, completion: (Bool, Error?) -> Void) {

        guard !self.passwordManager.isSet(key: login) else {
            completion(false, AuthenticationError.loginInUse)
            return
        }

        // pattern from https://stackoverflow.com/a/201378/4776676
        let regex = NSRegularExpression("(?:[a-z0-9!#$%&'*+\\/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+\\/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")

        guard regex.matches(login) else {
            completion(false, AuthenticationError.invalidLogin)
            return
        }

        guard password.count >= 6 else {
            completion(false, AuthenticationError.weakPassword("Пароль должен быть не короче 6 символов"))
            return
        }

        self.passwordManager.save(password, for: login) { (success, error) in
            guard success,
                  error == nil else {
                if let error = error {
                    completion(false, error)
                } else {
                    completion(false, AuthenticationError.unknown)
                }
                return
            }

            signIn(withLogin: login, password: password) { success in
                completion(success, nil)
            }
        }
    }

    func signOut() {
        activeUser = nil
    }
}
