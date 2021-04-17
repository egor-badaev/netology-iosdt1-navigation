//
//  AuthenticationProviderProtocol.swift
//  Navigation
//
//  Created by Egor Badaev on 02.02.2021.
//  Copyright © 2021 Artem Novichkov. All rights reserved.
//

import Foundation

enum AuthenticationError: LocalizedError {
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

typealias AuthenticationCompletionBlock = (Result<Bool, Error>) -> Void


protocol AuthenticationProviderProtocol {
    
    /**
     Stores provided login for subsequent verification
     
     - parameters:
        - login: login provided for verifications
     
     */
    func submitLogin(_ login: String)

    /**
     Stores provided password for subsequent verification
     
     - parameters:
        - password: password provided for verifications
     
     */
    func submitPassword(_ password: String)
    
    /**
     Verifies credentials stored previously
     
     - parameters:
        - completion: returns `failure(error)` if can't allow login, `success(true)` if should allow login and `success(false)` if can register a new user
     
     - important: This function will issue an alert to user if there is an error.
     
     */
    func validateCredentials(withCompletion completion: @escaping AuthenticationCompletionBlock)
    
    /**
     Registers a new user
     
     - parameters:
        - completion: returns `failure(error)` if can't allow login and `success(true)` if should allow login
     
     - important: This function will issue an alert to user if there is an error.
     
     */
    func createUser(withCompletion completion: @escaping AuthenticationCompletionBlock)
    
    /**
     Checks if user is currently logged in
     
     - parameters:
        - completion: returns `true` if user is valid and signed in and `false` otherwise
     
     */
    func validateUser(withCompletion completion: @escaping ((Bool) -> Void))
    
    /**
     Logs out current user
     
     - parameters:
        - completion: returns `failure(error)` if can't sign out and `success(true)` if signed out successfully
     
     */
    func logout(withCompletion completion: AuthenticationCompletionBlock)

}
