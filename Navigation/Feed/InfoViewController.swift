//
//  InfoViewController.swift
//  Navigation
//
//  Created by Artem Novichkov on 12.09.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

// MARK: - Protocols
protocol InfoViewControllerOutput {
    // MARK: Header
    var titleLabelText: String? { get }
    var periodLabelText: String? { get }
    var planetNameText: String { get }
    var shouldDisplayUI: Bool { get }
    func fetchData()

    // MARK: Residents table
    var numberOfRows: Int { get }
    var shouldDisplayTable: Bool { get }
    func textLabelForRow(index: Int) -> String
}

protocol InfoViewControllerInput: AnyObject {
    func displayUI()
    func showResidentsTableIfReady()
    func showNoResidentsLabel()
    func closeController(for error: Error?)
}

// MARK: - Implementation
class InfoViewController: UIViewController {

    // MARK: - Properties
    
    weak var coordinator: FeedCoordinator?
    private let viewModel: InfoViewControllerOutput
    
    // MARK: - Views
    
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
        alertButton.addTarget(self, action: #selector(showAlertButtonTapped(_:)), for: .touchUpInside)
        
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

    // MARK: - Life cycle
    
    init(viewModel: InfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        viewModel.fetchData()
    }
    
    // MARK: - UI methods
    
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
            residentsTableView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            residentsTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -AppConstants.margin),
            
            tableLoader.centerXAnchor.constraint(equalTo: residentsTableView.centerXAnchor),
            tableLoader.centerYAnchor.constraint(equalTo: residentsTableView.centerYAnchor),
            
            noResidentsLabel.centerYAnchor.constraint(equalTo: residentsTableView.centerYAnchor),
            noResidentsLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: AppConstants.margin),
            noResidentsLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -AppConstants.margin)
        ]
        
        NSLayoutConstraint.activate(constraints)
    
        loader.startAnimating()
        tableLoader.startAnimating()
        
    }


    // MARK: - Actions
    
    @objc private func showAlertButtonTapped(_ sender: Any) {
        coordinator?.showDeletePostAlert()
    }
}

// MARK: - InfoViewControllerInput

extension InfoViewController: InfoViewControllerInput {
    func displayUI() {

        guard viewModel.shouldDisplayUI else {
            print("Some tasks still running")
            return
        }

        DispatchQueue.main.async {
            self.postTitleLabel.text = self.viewModel.titleLabelText
            self.planetOrbitalPeriodLabel.text = self.viewModel.periodLabelText
            self.show(view: self.containerView, andHide: self.loader)
        }
    }

    func showResidentsTableIfReady() {
        guard viewModel.shouldDisplayTable else { return }
        print("Reloading TableView")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.residentsTableView.reloadData()
            self.show(view: self.residentsTableView, andHide: self.tableLoader)
        }
    }

    func showNoResidentsLabel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.show(view: self.noResidentsLabel, andHide: self.tableLoader)
        }
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

    func closeController(for error: Error?) {
        coordinator?.showAlertAndClose(message: error?.localizedDescription)
    }

}

// MARK: - UITableViewDataSource

extension InfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self)) else {
            return UITableViewCell()
        }

        cell.textLabel?.text = viewModel.textLabelForRow(index: indexPath.row)
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return .zero }
        return 44.0
    }
}

// MARK: - UITableViewDelegate
extension InfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        let headerView = UITableViewHeaderFooterView()
        headerView.contentView.backgroundColor = .systemYellow
        headerView.textLabel?.text = "Резиденты \(viewModel.planetNameText)"
        return headerView
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView,
              let textLabel = headerView.textLabel else { return }
        textLabel.textColor = .black
        textLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    }
}
