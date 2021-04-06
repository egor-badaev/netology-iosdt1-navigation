//
//  LogInViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 17.11.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit
import Firebase

class LogInViewController: ExtendedViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let logoSize: CGFloat = 100.0
        static let logoMargin: CGFloat = 120.0
        static let fieldHeight: CGFloat = 50.0
        static let cornerRadius: CGFloat = 10.0
    }
    
    // MARK: - Properties
    
    weak var coordinator: ProfileCoordinator?
    
    // MARK: - Flags
    private var viewIsSet: Bool = false
    private var shouldWaitForUserValidation = true
    private var shouldLogin = false

    // MARK: - Subviews
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        scrollView.toAutoLayout()
        scrollView.backgroundColor = .white
        scrollView.contentInset.bottom = .zero

        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let contentView = UIView()
        
        contentView.toAutoLayout()
        
        return contentView
    }()
    
    private lazy var logoImageView: UIImageView = {
        let logoImageView = UIImageView()
        
        logoImageView.toAutoLayout()
        logoImageView.image = #imageLiteral(resourceName: "logo")
        
        return logoImageView
    }()
    
    private lazy var emailTextField: UITextField = {
       let emailTextField = InputTextField()
        
        emailTextField.setupCommonProperties()
        emailTextField.placeholder = "Email or phone"
                
        emailTextField.addTarget(self, action: #selector(loginFieldDidChangeEditing(_:)), for: .editingChanged)
        
        return emailTextField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let passwordTextField = InputTextField()
        
        passwordTextField.setupCommonProperties()
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        
        passwordTextField.addTarget(self, action: #selector(passwordFieldDidChangeEditing(_:)), for: .editingChanged)
        
        return passwordTextField
    }()
    
    private lazy var inputStackView: UIStackView = {
        let stackView = UIStackView()
        
        stackView.toAutoLayout()
        
        stackView.spacing = -1.0
        stackView.axis = .vertical
        
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        
        stackView.layer.masksToBounds = true
        stackView.layer.borderColor = UIColor.lightGray.cgColor
        stackView.layer.borderWidth = 1.0
        stackView.layer.cornerRadius = Constants.cornerRadius
        
        return stackView
    }()
    
    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .white)
        loader.toAutoLayout()
        loader.isHidden = true
        return loader
    }()
    
    private lazy var loginButton: UIButton = {
        let loginButton = UIButton()
        
        loginButton.toAutoLayout()

        loginButton.setTitle("Log in", for: .normal)

        loginButton.setTitleColor(.white, for: .normal)
        loginButton.setTitleColor(UIColor(white: 1, alpha: 0), for: .disabled)
        loginButton.setTitleColor(UIColor(white: 1, alpha: 0.8), for: .highlighted)
        loginButton.setTitleColor(UIColor(white: 1, alpha: 0.8), for: .focused)
        loginButton.setTitleColor(UIColor(white: 1, alpha: 0.8), for: .selected)

        loginButton.setBackgroundImage(#imageLiteral(resourceName: "blue_pixel"), for: .normal)
        loginButton.setBackgroundImage(#imageLiteral(resourceName: "blue_pixel").alpha(0.8), for: .disabled)
        loginButton.setBackgroundImage(#imageLiteral(resourceName: "blue_pixel").alpha(0.8), for: .highlighted)
        loginButton.setBackgroundImage(#imageLiteral(resourceName: "blue_pixel").alpha(0.8), for: .focused)
        loginButton.setBackgroundImage(#imageLiteral(resourceName: "blue_pixel").alpha(0.8), for: .selected)
        
        loginButton.layer.masksToBounds = true
        loginButton.layer.cornerRadius = Constants.cornerRadius
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped(_:)), for: .touchUpInside)
        
        loginButton.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])

        return loginButton
    }()
    
    private let initialLoader = ActivityIndicatorFactory.makeDefaultLoader()
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBaseUI()
        
        AuthenticationManager.shared.validateUser { [weak self] isValidUser in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.shouldWaitForUserValidation = false
                if isValidUser {
                    if self.viewHasAppeared {
                        self.login()
                    } else {
                        /// View hasn't appeared yet, so it's too early to push
                        /// view controller - transition animation won't work
                        self.shouldLogin = true
                    }
                } else {
                    self.setupFullUI(animated: true)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFullUI()
        
        guard !shouldWaitForUserValidation else {
            return
        }
        
        passwordTextField.text = nil

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldLogin {
            login()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    
    // MARK: - Keyboard life cycle
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let insetAdjustment = keyboardSize.height - view.safeAreaInsets.bottom + AppConstants.margin
            scrollView.contentInset.bottom = insetAdjustment
            scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: insetAdjustment, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }

    // MARK: - Actions
    
    @objc private func loginButtonTapped(_ sender: Any) {

        toggleActivity(loading: true)
        AuthenticationManager.shared.validateCredentials { [weak self] result in
            guard let self = self else { return }
            
            self.toggleActivity(loading: false)
            switch result {
            case .failure(let error):
                self.coordinator?.showAlert(presentedOn: self, title: "Ошибка", message: error.localizedDescription)
                return
            case .success(let allowedLogin):
                if allowedLogin {
                    self.coordinator?.login()
                } else {
                    self.coordinator?.showAlert(
                        presentedOn: self,
                        title: "Указанная комбинация логина и пароля не найдена",
                        message: "Хотите зарегистрировать нового пользователя с указанными email и паролем?",
                        actions: [
                            UIAlertAction(
                                title: "Зарегистрироваться",
                                style: .default,
                                handler: { action in
                                    self.toggleActivity(loading: true)
                                    AuthenticationManager.shared.createUser(withCompletion: { registerResult in
                                        self.toggleActivity(loading: false)
                                        switch registerResult {
                                        case .failure(let registerError):
                                            self.coordinator?.showAlert(presentedOn: self, title: "Ошибка", message: registerError.localizedDescription)
                                            return
                                        case .success(_):
                                            self.coordinator?.login()
                                        }
                                    })
                                }),
                            UIAlertAction(
                                title: "Попробовать ещё раз",
                                style: .cancel,
                                handler: nil)],
                        completion: nil)
                }
                return
            }
        }
    }
    
    @objc private func loginFieldDidChangeEditing(_ sender: UITextField) {
        if let login = sender.text {
            AuthenticationManager.shared.submitLogin(login)
        }
    }
    
    @objc private func passwordFieldDidChangeEditing(_ sender: UITextField) {
        if let password = sender.text {
            AuthenticationManager.shared.submitPassword(password)
        }
    }
    
    // MARK: - Private methods
    
    private func setupBaseUI() {
        navigationController?.navigationBar.isHidden = true
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        view.addSubview(initialLoader)
        NSLayoutConstraint.activate([
            initialLoader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            initialLoader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        initialLoader.startAnimating()
        
        shouldWaitForUserValidation = true
    }
    
    private func setupFullUI(animated: Bool = false) {
        guard !viewIsSet else {
            /// Aborting setting up main UI because it's already been set
            return
        }
        
        guard !shouldWaitForUserValidation else {
            /// Aborting setting up main UI because we don't know if
            /// it is needed at the time
            return
        }
        
        initialLoader.stopAnimating()
        initialLoader.isHidden = true
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(logoImageView)
        contentView.addSubview(inputStackView)
        contentView.addSubview(loginButton)
        
        let constraints = [
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.logoMargin),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: Constants.logoSize),
            logoImageView.heightAnchor.constraint(equalToConstant: Constants.logoSize),
            
            inputStackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: Constants.logoMargin),
            inputStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppConstants.margin),
            inputStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppConstants.margin),
            emailTextField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),
            passwordTextField.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),
            
            loginButton.topAnchor.constraint(equalTo: inputStackView.bottomAnchor, constant: AppConstants.margin),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppConstants.margin),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppConstants.margin),
            loginButton.heightAnchor.constraint(equalToConstant: Constants.fieldHeight),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)

        viewIsSet = true
        
        if animated {
            scrollView.contentOffset =  CGPoint(x: 0, y: -view.frame.height)
            UIView.animate(withDuration: AppConstants.animationDuration, delay: .zero, options: .curveEaseOut, animations: {
                self.scrollView.contentOffset = .zero
            }, completion: nil)
        }
    }
    
    private func toggleActivity(loading: Bool) {
        DispatchQueue.main.async {
            self.loginButton.isEnabled = !loading
            self.loader.isHidden = !loading
            loading ? self.loader.startAnimating() : self.loader.stopAnimating()
        }
    }
    
    private func login() {
        initialLoader.stopAnimating()
        coordinator?.login()
        shouldLogin = false
    }

}

extension UITextField {
    func setupCommonProperties() {
        self.toAutoLayout()
        if #available(iOS 13.0, *) {
            self.backgroundColor = UIColor.systemGray6
        } else {
            // Fallback on earlier versions
            self.backgroundColor = UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0)
        }
        self.textColor = .black
        self.tintColor = UIColor(named: AppConstants.accentColor)
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        self.font = UIFont.systemFont(ofSize: 16)
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.lightGray.cgColor
    }
}
