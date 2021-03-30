//
//  InfoViewController.swift
//  Navigation
//
//  Created by Artem Novichkov on 12.09.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    // MARK: - Properties
    
    var infoUrlSting: String
    weak var coordinator: FeedCoordinator?
    
    private var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .gray)
        loader.toAutoLayout()
        return loader
    }()
    
    private var postTitleLabel: UILabel = {
        let title = UILabel()
        
        title.toAutoLayout()
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.numberOfLines = 0
        title.textAlignment = .center
        
        return title
    }()
    
    private lazy var alertButton: UIButton = {
        let alertButton = UIButton(type: .system)
        
        alertButton.toAutoLayout()
        alertButton.setTitle("Show alert", for: .normal)
        alertButton.addTarget(self, action: #selector(showAlert(_:)), for: .touchUpInside)
        
        return alertButton
    }()
    
    private lazy var containerView: UIStackView = {
        let containerView = UIStackView()
        
        containerView.toAutoLayout()
        containerView.axis = .vertical
        containerView.spacing = AppConstants.margin
        
        containerView.addArrangedSubview(postTitleLabel)
        containerView.addArrangedSubview(alertButton)
        
        containerView.alpha = 0.0
        
        return containerView
    }()
    
    // MARK: - Life cycle
    
    init(url: String) {
        infoUrlSting = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        guard let url = URL(string: infoUrlSting) else {
            print("Can't create URL from the string provided")
            coordinator?.showAlertAndClose(self)
            return
        }
        
        NetworkService.startDataTast(with: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("NetworkService failure: \(error.localizedDescription)")
                self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: error.localizedDescription)
            case .success(let (_, data)):
                do {
                    if let dictionary = try data.toObject(),
                       let toDo = ToDo(from: dictionary) {
                        DispatchQueue.main.async {
                            self.postTitleLabel.text = toDo.title
                            self.displayUI()
                        }
                    } else {
                        print("JSON data has unknown format")
                        self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: "Данные неверного формата!")
                    }
                } catch {
                    print("Data parsing failed")
                    self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: "Невозможно обработать данные!")
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        view.backgroundColor = .systemYellow
        
        view.addSubview(containerView)
        view.addSubview(loader)
        
        let constraints = [
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppConstants.margin),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppConstants.margin),
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: AppConstants.margin),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AppConstants.margin),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    
        loader.startAnimating()
    }

    private func displayUI() {
        UIView.animate(withDuration: AppConstants.animationDuration) {
            self.loader.alpha = 0.0
        } completion: { success in
            if success {
                self.loader.stopAnimating()
                UIView.animate(withDuration: AppConstants.animationDuration) {
                    self.containerView.alpha = 1.0
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func showAlert(_ sender: Any) {
        coordinator?.showDeletePostAlert(presentedOn: self)
    }
}
