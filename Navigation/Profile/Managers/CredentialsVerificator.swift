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
    case invalidLogin
    case userDisabled
    case loginInUse
    case emptyPassword
    case weakPassword(String)
    case networkError
    case tooManyRequests
    case configError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .emptyLogin:
            return "Логин не может быть пустым"
        case .invalidLogin:
            return "Пожалуйста, используйте действительный email-адрес в качестве логина"
        case .userDisabled:
            return "Ваш аккаунт был отключён. Свяжитесь с администратором приложения для восстановления доступа"
        case .loginInUse:
            return "Пользователь с таким адресом уже зарегистрирован, пожалуйста, выберете другой адрес"
        case .emptyPassword:
            return "Пароль не может быть пустым"
        case .weakPassword(let reason):
            return "Вы ввели слишком ненадёжный пароль. \(reason)"
        case .tooManyRequests:
            return "С вашего устройства поступило слишком много запросов аутентификации. Пожалуйста, повторите попытку через 10 минут"
        case .networkError:
            return "Ошибка связи с сервером актентификации. Попробуйте ещё раз"
        case .configError:
            return "Возникла внутренняя ошибка в приложении. Пожалуйста, сообщите о баге разработчикам"
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
        - completion: returns `failure(error)` if can't allow login, `success(true)` if should allow login and `success(false)` if can register a new user
     
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
        - loginController: a source controller which provides data
        - completion: returns `failure(error)` if can't allow login and `success(true)` if should allow login
     
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
                self.handleCommonError(code: code, error: error, completion: completion)
                return
            }
            completion(.success(true))
        }
    }
    
    func loginControllerShouldLoginAutomatically() -> Bool {
        if Auth.auth().currentUser != nil {
            return true
        }
        return false
    }
    
    // MARK: - Helpers
    private func handleCommonError(code: AuthErrorCode, error: NSError, completion: @escaping CredentialsVerificationCompletionBlock) {
        switch code {
        case .invalidEmail:
            completion(.failure(CredentialsError.invalidLogin))
        case .userDisabled:
            completion(.failure(CredentialsError.userDisabled))
        case .emailAlreadyInUse:
            completion(.failure(CredentialsError.loginInUse))
        case .weakPassword:
            if let reason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                completion(.failure(CredentialsError.weakPassword(reason)))
            } else {
                print(error.userInfo)
                completion(.failure(CredentialsError.unknown))
            }
        case .networkError:
            completion(.failure(CredentialsError.networkError))
        case .tooManyRequests:
            completion(.failure(CredentialsError.tooManyRequests))
        case .invalidAPIKey,
             .appNotAuthorized,
             .operationNotAllowed:
            completion(.failure(CredentialsError.configError))
        default:
            completion(.failure(CredentialsError.unknown))
        }
    }
    
}
