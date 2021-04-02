//
//  CredentialsVerificator.swift
//  Navigation
//
//  Created by Egor Badaev on 02.02.2021.
//  Copyright © 2021 Artem Novichkov. All rights reserved.
//

import Foundation
import Firebase

enum CredentialsError: LocalizedError {
    case emptyLogin
    case emptyPassword
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .emptyLogin:
            return "Логин не может быть пустым"
        case .emptyPassword:
            return "Пароль не может быть пустым"
        case .unknown:
            return "Произошла неизвестная ошибка"
        }
    }
}

typealias CredentialsVerificationCompletionBlock = (Result<Bool, Error>) -> Void


class CredentialsVerificator: LoginViewControllerDelegate {
    
    private var login: String?
    private var password: String?
    
    /**
     Stores provided login for subsequent verification
     
     - parameters:
        - loginController: a source controller which provides data
        - login: login provided for verifications
     
     */
    func loginController(_ loginController: LogInViewController, didSubmitLogin login: String) {
        self.login = login
    }
    
    /**
     Stores provided password for subsequent verification
     
     - parameters:
        - loginController: a source controller which provides data
        - password: password provided for verifications
     
     */
    func loginController(_ loginController: LogInViewController, didSubmitPassword password: String) {
        self.password = password
    }
    
    /**
     Verifies credentials stored previously
     
     - parameters:
        - loginController: a source controller which provides data
        - completion: returns `failure(error)` if con't allow login, `success(true)` if should allow login and `success(false)` if can register a new user
     
     - important: This function will issue an alert to user if there is an error.
     
     */
    func loginControllerDidValidateCredentials(_ loginController: LogInViewController, completion: @escaping CredentialsVerificationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(CredentialsError.emptyLogin))
            return
        }
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(CredentialsError.emptyPassword))
            return
        }

        Auth.auth().signIn(withEmail: login, password: password) { (result, error) in
            
            if let error = error as NSError?,
               let code = AuthErrorCode(rawValue: error.code) {
                switch code {
                case .userNotFound:
                    completion(.success(false))
                    return
                default:
                    completion(.failure(error))
                }
                return
            }
            
            completion(.success(true))
        }
    }
    
    /**
     Registers a new user
     
     - parameters:
        - loginController: a source controller which provides data
        - completion: returns `failure(error)` if con't allow login, `success(true)` if should allow login and `success(false)` if can register a new user
     
     - important: This function will issue an alert to user if there is an error.
     
     */
    func loginControllerDidRegisterUser(_ loginController: LogInViewController, completion: @escaping CredentialsVerificationCompletionBlock) {
        guard let login = self.login,
              !login.isEmpty else {
            completion(.failure(CredentialsError.emptyLogin))
            return
        }
        
        guard let password = self.password,
              !password.isEmpty else {
            completion(.failure(CredentialsError.emptyPassword))
            return
        }
        
        Auth.auth().createUser(withEmail: login, password: password) { (result, error) in
            if let error = error as NSError?,
               let code = AuthErrorCode(rawValue: error.code) {
                print(error)
                completion(.failure(error))
                return
            }
            completion(.success(true))
        }
    }
    
}
