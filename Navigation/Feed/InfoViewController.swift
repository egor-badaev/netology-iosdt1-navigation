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
        return ActivityIndicatorFactory.makeDefaultLoader()
    }()
    
    private var tableLoader: UIActivityIndicatorView = {
        return ActivityIndicatorFactory.makeDefaultLoader()
    }()
    
    private var postTitleLabel: UILabel = {
        let title = UILabel()
        
        title.toAutoLayout()
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.numberOfLines = 0
        title.textAlignment = .center
        title.textColor = .black
        
        return title
    }()
    
    private var planetOrbitalPeriodLabel: UILabel = {
        let label = UILabel()
        
        label.toAutoLayout()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        
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
    
    private lazy var residentsTableView: UITableView = {
        let tableView = UITableView()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        
        tableView.toAutoLayout()
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        
        tableView.alpha = 0.0
        
        tableView.dataSource = self
        tableView.delegate = self

        return tableView
        
    }()
    
    private var noResidentsLabel: UILabel = {
        let label = UILabel()
        
        label.toAutoLayout()
        label.textColor = UIColor.init(red: 0.4, green: 0.4, blue: 0.45, alpha: 0.6)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        label.text = "На этой планете не проживает ни одного персонажа"
        
        label.alpha = 0.0
        
        return label
    }()
    
    private var toDoDataTask: URLSessionDataTask?
    private var planetDataTask: URLSessionDataTask?
    private var residents: [Person] = []
    private var activeDataTasks = 0
    
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

                    self.fetchResidents(from: planet.residents)

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
        view.addSubview(residentsTableView)
        view.addSubview(tableLoader)
        view.addSubview(noResidentsLabel)
        
        let safeArea = view.safeAreaLayoutGuide
        
        let constraints = [
            containerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: AppConstants.margin),
            containerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -AppConstants.margin),
            containerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: AppConstants.margin),
            
            loader.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            residentsTableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: AppConstants.margin),
            residentsTableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -AppConstants.margin),
            residentsTableView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: AppConstants.margin),
            residentsTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            
            tableLoader.centerXAnchor.constraint(equalTo: residentsTableView.centerXAnchor),
            tableLoader.centerYAnchor.constraint(equalTo: residentsTableView.centerYAnchor),
            
            noResidentsLabel.centerYAnchor.constraint(equalTo: residentsTableView.centerYAnchor),
            noResidentsLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: AppConstants.margin),
            noResidentsLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -AppConstants.margin)
        ]
        
        NSLayoutConstraint.activate(constraints)
    
        loader.startAnimating()
        tableLoader.startAnimating()
        
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).font = .systemFont(ofSize: 14, weight: .semibold)

    }

    private func displayUI() {
        
        guard toDoDataTask?.state != .running,
              planetDataTask?.state != .running else {
            print("Some tasks still running")
            return
        }

        show(view: containerView, andHide: loader)
    }
    
    private func show(view: UIView, andHide loader: UIActivityIndicatorView) {
        UIView.animate(withDuration: AppConstants.animationDuration) {
            loader.alpha = 0.0
        } completion: { success in
            if success {
                loader.stopAnimating()
                UIView.animate(withDuration: AppConstants.animationDuration) {
                    view.alpha = 1.0
                }
            }
        }
    }
    
    private func fetchResidents(from urls: [URL]) {
        guard !urls.isEmpty else {
            print("No residents on the planet")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.show(view: self.noResidentsLabel, andHide: self.tableLoader)
            }
            return
        }
        
        urls.forEach { url in
            activeDataTasks += 1
            NetworkService.startDataTask(with: url) { [weak self] result in
                guard let self = self else { return }
                self.activeDataTasks -= 1
                
                switch result {
                case .failure(let error):
                    print("NetworkService failure: \(error.localizedDescription)")
                    self.coordinator?.showAlertAndClose(self, title: "Ошибка", message: error.localizedDescription)
                case .success(let (_, data)):
                    do {
                        let person = try JSONDecoder().decode(Person.self, from: data)
                        self.residents.append(person)
                        self.showResidentsTableIfReady()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    private func showResidentsTableIfReady() {
        guard activeDataTasks == 0 else { return }
        print("Reloading TableView")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.residentsTableView.reloadData()
            self.show(view: self.residentsTableView, andHide: self.tableLoader)
        }
    }
    
    // MARK: - Actions
    
    @objc private func showAlert(_ sender: Any) {
        coordinator?.showDeletePostAlert(presentedOn: self)
    }
}

// MARK: - UITableViewDataSource

extension InfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return residents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self)) else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = residents[indexPath.row].name
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return .zero }
        return 45.0
    }
}

// MARK: - UITableViewDelegate
extension InfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        let headerView = UITableViewHeaderFooterView()
        if #available(iOS 14.0, *) {
            headerView.backgroundConfiguration = .clear()
        } else {
            headerView.backgroundView?.backgroundColor = .clear
        }
        headerView.textLabel?.text = "Персонажи на планете"
        headerView.textLabel?.textColor = .black
        return headerView
    }
}
