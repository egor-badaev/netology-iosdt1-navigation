//
//  KeychainPassword.swift
//  FileManager
//
//  Created by Egor Badaev on 13.04.2021.
//

import Foundation
import KeychainAccess

struct KeychainPassword {

    private let keychain = Keychain()

    func isSet(key: String) -> Bool {
        if let _ = keychain[key] {
            return true
        }
        return false
    }

    func isValid(_ password: String, for key: String) -> Bool {
        guard let token = keychain[key] else {
            return false
        }
        return password == token
    }

    func save(_ password: String, for key: String, completion: (Bool, Error?) -> Void) {
        do {
            try keychain.set(password, key: key)
            completion(true, nil)
        }
        catch let error {
            completion(false, error)
        }
    }

}
