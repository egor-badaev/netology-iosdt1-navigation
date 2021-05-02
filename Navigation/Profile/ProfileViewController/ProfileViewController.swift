//
//  ProfileViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 05.11.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    weak var coordinator: ProfileCoordinator?
    
    //MARK: - Subviews
    
    private lazy var postsTableView: UITableView = {
        let tableView = UITableView()
        
        tableView.toAutoLayout()
        
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.reuseIdentifier)
        tableView.register(PhotosTableViewCell.self, forCellReuseIdentifier: PhotosTableViewCell.reuseIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        return tableView
    }()
    
    private let headerView = ProfileHeaderView()

    private lazy var tintView: UIView = {
        let tintView = UIView()
        tintView.backgroundColor = .black
        tintView.alpha = 0
        tintView.toAutoLayout()

        return tintView
    }()
    
    private lazy var closeView: UIButton = {
        let closeView = UIButton()

        closeView.toAutoLayout()
        closeView.alpha = 0
        closeView.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .selected)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .highlighted)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .focused)

        closeView.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
        
        return closeView
    }()

    // MARK: - Properties

    private var expandedConstraints = [NSLayoutConstraint]()
    private var isZoomed: Bool = false

    private var avatarOriginXAdjustment: CGFloat {
        postsTableView.frame.origin.x + headerView.frame.origin.x + headerView.avatarContainerView.frame.origin.x
    }
    private var avatarOriginYAdjustment: CGFloat {
        postsTableView.frame.origin.y - postsTableView.contentOffset.y + headerView.frame.origin.y + headerView.avatarContainerView.frame.origin.y
    }


    private let imageProcessor = AsyncImageProcessor()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - Private methods

    private func setupUI() {
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            view.backgroundColor = .white
        }
        
        view.addSubview(postsTableView)
        
        let constraints = [
            postsTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            postsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            postsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            postsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
        headerView.avatarImageView.isUserInteractionEnabled = true
        headerView.avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        headerView.logoutCompletion = { [weak self] in
            guard let self = self,
                  let coordinator = self.coordinator else { return }
            coordinator.logout()
        }
    }

    override func viewDidAppear(_ animated: Bool) {

        guard expandedConstraints.isEmpty,
              let window = view.window else { return }

        window.addSubview(tintView)
        window.addSubview(closeView)

        let animationConstraints = [
            tintView.topAnchor.constraint(equalTo: window.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: window.trailingAnchor),

            closeView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: AppConstants.margin),
            closeView.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -AppConstants.margin),
            closeView.widthAnchor.constraint(equalToConstant: 28),
            closeView.heightAnchor.constraint(equalToConstant: 28)
        ]

        NSLayoutConstraint.activate(animationConstraints)

        expandedConstraints = [
            headerView.avatarImageView.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor),
            headerView.avatarImageView.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor),
            headerView.avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: window.topAnchor),
            headerView.avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: window.bottomAnchor),
            headerView.avatarImageView.heightAnchor.constraint(equalTo: headerView.avatarImageView.widthAnchor),
            headerView.avatarImageView.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            headerView.avatarImageView.centerXAnchor.constraint(equalTo: window.centerXAnchor)
        ]
    }

    @objc private func avatarTapped(_ sender: Any) {
        
        guard !isZoomed, let window = view.window else { return }

        window.addSubview(headerView.avatarImageView)

        /// After changing superview, the frame stays the same
        /// So, if the superview's origins differ, the view will jump from its position
        /// To avoid this, we need manual origin correction
        headerView.avatarImageView.frame.origin.x += avatarOriginXAdjustment
        headerView.avatarImageView.frame.origin.y += avatarOriginYAdjustment

        NSLayoutConstraint.deactivate(headerView.avatarConstraints)
        NSLayoutConstraint.activate(expandedConstraints)

        UIView.animate(withDuration: 0.5, animations: {
            window.layoutIfNeeded()
            self.headerView.avatarImageView.layer.cornerRadius = 0
            self.tintView.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.closeView.alpha = 1.0
            } completion: { _ in
                self.isZoomed = true
            }
        }
    }
    
    @objc private func closeTapped(_ sender: Any) {

        guard isZoomed else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.closeView.alpha = 0
            self.tintView.alpha = 0
        } completion: { _ in
            NSLayoutConstraint.deactivate(self.expandedConstraints)

            self.headerView.avatarContainerView.addSubview(self.headerView.avatarImageView)

            /// After changing superview, the frame stays the same
            /// So, if the superview's origins differ, the view will jump from its position
            /// To avoid this, we need manual origin correction
            self.headerView.avatarImageView.frame.origin.x -= self.avatarOriginXAdjustment
            self.headerView.avatarImageView.frame.origin.y -= self.avatarOriginYAdjustment

            self.headerView.bringSubviewToFront(self.headerView.avatarContainerView)
            NSLayoutConstraint.activate(self.headerView.avatarConstraints)
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.headerView.avatarImageView.layer.cornerRadius = ProfileHeaderView.Config.avatarSize / 2
            } completion: { _ in
                self.isZoomed = false
            }
        }
    }
    
}

// MARK: - Table View Data Source

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return Post.samplePosts.count
        default:
            return .zero
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PhotosTableViewCell.reuseIdentifier, for: indexPath) as? PhotosTableViewCell else {
                return UITableViewCell()
            }
            return cell
            
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier, for: indexPath) as? PostTableViewCell else {
                return UITableViewCell()
            }
            let post = Post.samplePosts[indexPath.row]
            let identifier = post.identifier
            cell.representedIdentifier = identifier
            
            if let processedImage = imageProcessor.processedImage(forIdentifier: identifier) {
                cell.configure(with: post, image: processedImage)
            } else {
                cell.resetData()
                
                guard let sourceImage = UIImage(named: post.image) else {
                    return UITableViewCell()
                }
                
                imageProcessor.process(image: sourceImage, filter: .sepia(intensity: 0.5), forIdentifier: identifier) { result in
                    
                    guard cell.representedIdentifier == identifier else { return }
                    
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                        return
                    case .success(let image):
                        DispatchQueue.main.async {
                            cell.configure(with: post, image: image)
                        }
                        
                    }
                }
            }
            return cell

        default:
            return UITableViewCell()
        }
    }

}

// MARK: - Table View Delegate

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return .zero }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section <= 1 else { return .zero }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 && indexPath.row == 0 else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        coordinator?.showPhotos()
    }
}
