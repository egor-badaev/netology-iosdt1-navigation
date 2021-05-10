//
//  RealmEncryption.swift
//  Navigation
//
//  Created by Egor Badaev on 10.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import KeychainAccess

class RealmEncryption {

    // MARK: - Public properties

    static let manager: RealmEncryption = {
        let instance = RealmEncryption()
        return instance
    }()

    var encryptionKey: Data {
        if let storedEncryptionKey = self.previouslyStoredKey {
            return storedEncryptionKey
        }

        let encryptionKey = generateRandomKey()
        saveEncryptionKey(encryptionKey: encryptionKey)

        return encryptionKey
    }

    // MARK: - Private properties

    private let kKeychainTokenKey = "kNavigationRealmEncryptionKey"
    private let keychain = Keychain()

    private var previouslyStoredKey: Data? {
        try? keychain.getData(kKeychainTokenKey)
    }

    // MARK: - Initializer

    private init() { }

    // MARK: - Private methods

    private func generateRandomKey() -> Data {
        var key = Data(count: 64)

        key.withUnsafeMutableBytes({ pointer in
            guard let baseAddress = pointer.baseAddress else { return }
            _ = SecRandomCopyBytes(kSecRandomDefault, 64, baseAddress)
        })

        return key
    }

    private func saveEncryptionKey(encryptionKey: Data) {
        do {
            try keychain.set(encryptionKey, key: kKeychainTokenKey)
        }
        catch let error {
            fatalError("Cannot save Realm Encryption Key: \(error.localizedDescription)")
        }
    }
}
