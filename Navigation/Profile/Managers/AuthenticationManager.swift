//
//  AuthenticationManager.swift
//  Navigation
//
//  Created by Egor Badaev on 16.04.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import Firebase

class AuthenticationManager {

    static let shared: AuthenticationProviderProtocol = {
        var instance: AuthenticationProviderProtocol

        switch AppConstants.authenticationProvider {
        case .keychain:
            instance = KeychainAuthenticationManager()
        case .firebase:
            instance = FirebaseAuthenticationManager()
        case .realm:
            instance = RealmAuthenticationManager()
        }

        return instance
    }()
}

private class KeychainAuthenticationManager: AuthenticationProviderProtocol {

    private var login: String?
    private var password: String?

    /**
     Stores provided login for subsequent verification

     - parameters:
        - loginController: a source controller which provides data
        - login: login provided for verifications

     */
    func submitLogin(_ login: String) {
        self.login = login
    }

    /**
     Stores provided password for subsequent verification

     - parameters:
        - loginController: a source controller which provides data
        - password: password provided for verifications

     */
    func submitPassword(_ password: String) {
        self.password = password
    }

    /**
     Verifies credentials stored previously

     - returns: `true` if both stored credentials are correct, `false` otherwise

     - parameters:
        - loginController: a source controller which provides data

     - important: This function will issue an alert to user if there is an error.

     */
    func validateCredentials(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        CredentialsStore.shared.signIn(withLogin: login, password: password) { success in
            completion(.success(success))
        }
    }

    /**
     Registers a new user

     - parameters:
        - completion: returns `failure(error)` if can't allow login and `success(true)` if should allow login

     - important: This function will issue an alert to user if there is an error.

     */
    func createUser(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        CredentialsStore.shared.createUser(withLogin: login, password: password) { (success, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            completion(.success(success))
        }
    }

    /**
     Checks if user is currently logged in

     - parameters:
        - completion: returns `true` if user is valid and signed in and `false` otherwise

     */
    func validateUser(withCompletion completion: @escaping ((Bool) -> Void)) {
        if CredentialsStore.shared.activeUser != nil {
            completion(true)
            return
        }
        completion(false)
    }

    /**
     Logs out current user

     - parameters:
        - completion: returns `failure(error)` if can't sign out and `success(true)` if signed out successfully

     */
    func logout(withCompletion completion: (Result<Bool, Error>) -> Void) {
        CredentialsStore.shared.signOut()
        completion(.success(true))
    }

}

private class FirebaseAuthenticationManager: AuthenticationProviderProtocol {

    private var login: String?
    private var password: String?

    /**
     Stores provided login for subsequent verification

     - parameters:
        - login: login provided for verifications

     */
    func submitLogin(_ login: String) {
        self.login = login
    }

    /**
     Stores provided password for subsequent verification

     - parameters:
        - password: password provided for verifications

     */
    func submitPassword(_ password: String) {
        self.password = password
    }

    /**
     Verifies credentials stored previously

     - parameters:
        - completion: returns `failure(error)` if can't allow login, `success(true)` if should allow login and `success(false)` if can register a new user

     - important: This function will issue an alert to user if there is an error.

     */
    func validateCredentials(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        Auth.auth().signIn(withEmail: login, password: password) { (result, error) in

            if let error = error as NSError?,
               let code = AuthErrorCode(rawValue: error.code) {
                switch code {
                case .userNotFound,
                     .wrongPassword:
                    completion(.success(false))
                    return
                default:
                    self.handleCommonError(code: code, error: error, completion: completion)
                }
                return
            }

            completion(.success(true))
        }
    }

    /**
     Registers a new user

     - parameters:
        - completion: returns `failure(error)` if can't allow login and `success(true)` if should allow login

     - important: This function will issue an alert to user if there is an error.

     */
    func createUser(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }

        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        Auth.auth().createUser(withEmail: login, password: password) { (result, error) in
            if let error = error as NSError?,
               let code = AuthErrorCode(rawValue: error.code) {
                self.handleCommonError(code: code, error: error, completion: completion)
                return
            }
            completion(.success(true))
        }
    }

    /**
     Checks if user is currently logged in

     - parameters:
        - completion: returns `true` if user is valid and signed in and `false` otherwise

     */
    func validateUser(withCompletion completion: @escaping ((Bool) -> Void)) {
        if Auth.auth().currentUser != nil {
            completion(true)
            return
        }
        completion(false)
    }

    /**
     Logs out current user

     - parameters:
        - completion: returns `failure(error)` if can't sign out and `success(true)` if signed out successfully

     */
    func logout(withCompletion completion: AuthenticationCompletionBlock) {
        do {
            try Auth.auth().signOut()
            completion(.success(true))
        } catch let error as NSError {
            completion(.failure(error))
        }
    }

    // MARK: - Helpers
    private func handleCommonError(code: AuthErrorCode, error: NSError, completion: @escaping AuthenticationCompletionBlock) {
        switch code {
        case .invalidEmail:
            completion(.failure(AuthenticationError.invalidLogin))
        case .userDisabled:
            completion(.failure(AuthenticationError.userDisabled))
        case .emailAlreadyInUse:
            completion(.failure(AuthenticationError.loginInUse))
        case .weakPassword:
            if let reason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                completion(.failure(AuthenticationError.weakPassword(reason)))
            } else {
                print(error.userInfo)
                completion(.failure(AuthenticationError.unknown))
            }
        case .networkError:
            completion(.failure(AuthenticationError.networkError))
        case .tooManyRequests:
            completion(.failure(AuthenticationError.tooManyRequests))
        case .invalidAPIKey,
             .appNotAuthorized,
             .operationNotAllowed:
            completion(.failure(AuthenticationError.configError))
        default:
            completion(.failure(AuthenticationError.unknown))
        }
    }

}

private class RealmAuthenticationManager: AuthenticationProviderProtocol {

    private var login: String?
    private var password: String?

    /**
     Stores provided login for subsequent verification

     - parameters:
        - login: login provided for verifications

     */
    func submitLogin(_ login: String) {
        self.login = login
    }

    /**
     Stores provided password for subsequent verification

     - parameters:
        - password: password provided for verifications

     */
    func submitPassword(_ password: String) {
        self.password = password
    }

    /**
     Verifies credentials stored previously

     - parameters:
        - completion: returns `failure(error)` if can't allow login, `success(true)` if should allow login and `success(false)` if can register a new user

     - important: This function will issue an alert to user if there is an error.

     */
    func validateCredentials(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        do {
            try RealmAuthenticationAdapter.shared.signIn(withLogin: login, password: password)
            completion(.success(true))
        } catch RealmAuthenticationError.userNotFound {
            completion(.success(false))
        } catch RealmAuthenticationError.wrongPassword {
            completion(.success(false))
        } catch let error {
            completion(.failure(error))
        }

    }

    /**
     Registers a new user

     - parameters:
        - completion: returns `failure(error)` if can't allow login and `success(true)` if should allow login

     - important: This function will issue an alert to user if there is an error.

     */
    func createUser(withCompletion completion: @escaping AuthenticationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(AuthenticationError.emptyLogin))
            return
        }

        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(AuthenticationError.emptyPassword))
            return
        }

        do {
            try RealmAuthenticationAdapter.shared.createUser(withLogin: login, password: password)
            completion(.success(true))
        } catch RealmAuthenticationError.loginTaken {
            completion(.failure(AuthenticationError.loginInUse))
        } catch RealmAuthenticationError.weakPassword {
            completion(.failure(AuthenticationError.weakPassword("Пароль должен быть не менее 6 символов")))
        } catch {
            completion(.failure(error))
        }

    }

    /**
     Checks if user is currently logged in

     - parameters:
        - completion: returns `true` if user is valid and signed in and `false` otherwise

     */
    func validateUser(withCompletion completion: @escaping ((Bool) -> Void)) {
        if RealmAuthenticationAdapter.shared.currentUser != nil {
            completion(true)
            return
        }
        completion(false)
    }

    /**
     Logs out current user

     - parameters:
        - completion: returns `failure(error)` if can't sign out and `success(true)` if signed out successfully

     */
    func logout(withCompletion completion: AuthenticationCompletionBlock) {
        do {
            try RealmAuthenticationAdapter.shared.signOut()
            completion(.success(true))
        } catch let error {
            completion(.failure(error))
        }
    }
}
