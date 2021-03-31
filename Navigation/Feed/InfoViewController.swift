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
    
    var toDoUrlSting: String
    var planetUrlString: String
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
    
    private var planetOrbitalPeriodLabel: UILabel = {
        let label = UILabel()
        
        label.toAutoLayout()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        return label
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
        containerView.addArrangedSubview(planetOrbitalPeriodLabel)
        containerView.addArrangedSubview(alertButton)
        
        containerView.alpha = 0.0
        
        return containerView
    }()
    
    private var toDoDataTask: URLSessionDataTask?
    private var planetDataTask: URLSessionDataTask?
    
    // MARK: - Life cycle
    
    init(toDoUrl: String, planetUrl: String) {
        toDoUrlSting = toDoUrl
        planetUrlString = planetUrl
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        guard let toDoUrl = URL(string: toDoUrlSting),
              let planetUrl = URL(string: planetUrlString) else {
            print("Can't create URL from the string provided")
            coordinator?.showAlertAndClose(self)
            return
        }
        
        toDoDataTask = NetworkService.makeDataTask(with: toDoUrl) { [weak self] result in
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
        toDoDataTask?.resume()
        
        planetDataTask = NetworkService.makeDataTask(with: planetUrl, completion: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("NetworkService failure: \(error.localizedDescription)")
                self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: error.localizedDescription)
            case .success(let (_, data)):
                do {
                    let planet = try JSONDecoder().decode(Planet.self, from: data)
                    
                    var name, period: String
                    
                    if let planetName = planet.name {
                        name = "планеты \"\(planetName)\""
                    } else {
                        name = "неизвестной планеты"
                    }
                    
                    if let planetPeriod = planet.orbitalPeriod {
                        let days = planetPeriod.pluralForm(of: PluralizableString(one: "день", few: "дня", many: "дней"))
                        period = "составляет \(days)"
                    } else {
                        period = "неизвестен"
                    }
                                        
                    DispatchQueue.main.async {
                        self.planetOrbitalPeriodLabel.text = "Период обращения \(name) по своей орбите \(period)"
                        self.displayUI()
                    }
                } catch {
                    print("Decoding failed: \(error)")
                    self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: "Возникла ошибка при распознавании данных")
                }
            }
        })
        
        planetDataTask?.resume()
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
        
        guard toDoDataTask?.state != .running,
              planetDataTask?.state != .running else {
            print("Some tasks still running")
            return
        }

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
