//
//  ProfileViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 05.11.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

class ProfileViewController: BasePostsViewController {

    weak var coordinator: ProfileCoordinator?

    //MARK: - Subviews

    private let headerView = ProfileHeaderView()

    private lazy var tintView: UIView = {
        let tintView = UIView()
        tintView.backgroundColor = .black
        tintView.layer.opacity = 0

        return tintView
    }()
    
    private lazy var closeView: UIButton = {
        let closeView = UIButton()

        closeView.frame.size.width = 28
        closeView.frame.size.height = 28
        closeView.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .selected)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .highlighted)
        closeView.setImage(#imageLiteral(resourceName: "close").alpha(0.7), for: .focused)

        closeView.addTarget(self, action: #selector(closeTapped(_:)), for: .touchUpInside)
        
        return closeView
    }()

    // MARK: - Properties

    private var zoomedSize: CGFloat {
        min(view.bounds.height, view.bounds.width)
    }
    private var zoomedAbsoluteFrame: CGRect {
        CGRect(
            x: self.view.bounds.width / 2 - self.zoomedSize / 2,
            y: self.view.bounds.height / 2 - self.zoomedSize / 2,
            width: self.zoomedSize,
            height: self.zoomedSize
        )
    }
    private var isZoomed: Bool = false
    private var originalAbsoluteFrame: CGRect {
        let absoluteOriginX = postsTableView.frame.origin.x + headerView.frame.origin.x + headerView.avatarContainerView.frame.origin.x
        let absoluteOriginY = postsTableView.frame.origin.y - postsTableView.contentOffset.y + headerView.frame.origin.y + headerView.avatarContainerView.frame.origin.y

        return CGRect(x: absoluteOriginX, y: absoluteOriginY, width: headerView.avatarContainerView.bounds.width, height: headerView.avatarContainerView.bounds.height)

    }
    
    private let imageProcessor = AsyncImageProcessor()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
        configureTableView(dataSource: self, delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tintView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)

        closeView.frame = CGRect(
            x: view.bounds.width - view.safeAreaInsets.right - AppConstants.margin - closeView.bounds.width,
            y: view.safeAreaInsets.top + AppConstants.margin,
            width: closeView.bounds.width,
            height: closeView.bounds.height
        )
        
        if isZoomed {
            headerView.avatarImageView.frame = zoomedAbsoluteFrame
        }
    }

    // MARK: - Private methods

    private func configureViews() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
        headerView.avatarImageView.isUserInteractionEnabled = true
        headerView.avatarImageView.addGestureRecognizer(tapGestureRecognizer)
        headerView.logoutCompletion = { [weak self] in
            guard let self = self,
                  let coordinator = self.coordinator else { return }
            coordinator.logout()
        }
    }

    @objc private func avatarTapped(_ sender: Any) {
        
        guard !isZoomed, let window = view.window else { return }
        
        window.addSubview(tintView)

        NSLayoutConstraint.deactivate(headerView.avatarConstraints)
        headerView.avatarImageView.removeFromSuperview()
        headerView.avatarImageView.translatesAutoresizingMaskIntoConstraints = true
        headerView.avatarImageView.frame = originalAbsoluteFrame
        headerView.avatarImageView.isUserInteractionEnabled = false
        window.addSubview(headerView.avatarImageView)
        
        closeView.layer.opacity = 0
        window.addSubview(closeView)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.headerView.avatarImageView.frame = self.zoomedAbsoluteFrame
            self.headerView.avatarImageView.layer.cornerRadius = 0
            self.tintView.layer.opacity = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.closeView.layer.opacity = 1.0
            } completion: { _ in
                self.isZoomed = true
            }
        }
    }
    
    @objc private func closeTapped(_ sender: Any) {

        guard isZoomed else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.closeView.layer.opacity = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.5) {
                self.headerView.avatarImageView.frame = self.originalAbsoluteFrame
                self.headerView.avatarImageView.layer.cornerRadius = self.originalAbsoluteFrame.width / 2
                self.tintView.layer.opacity = 0
            } completion: { _ in
                self.headerView.avatarImageView.removeFromSuperview()
                self.headerView.avatarImageView.toAutoLayout()
                self.headerView.avatarImageView.isUserInteractionEnabled = true
                self.headerView.avatarContainerView.addSubview(self.headerView.avatarImageView)
                NSLayoutConstraint.activate(self.headerView.avatarConstraints)
                
                self.closeView.removeFromSuperview()
                self.tintView.removeFromSuperview()
                self.isZoomed = false
            }
        }
    }

    @objc private func saveFavoritePost(_ sender: Any) {
        print(type(of: self), #function, sender)
        guard let gestureRecognizer = sender as? UITapGestureRecognizer,
              let cell = gestureRecognizer.view as? PostTableViewCell,
              let postIdentifier = cell.representedIdentifier,
              let post = Post.samplePosts.first(where: { $0.identifier == postIdentifier }) else {
            return
        }

        let processedImage = imageProcessor.processedImage(forIdentifier: postIdentifier)
        let favoritePost = FavoritesManager.shared.create(from: FavoritePost.self)
        favoritePost.configure(with: post, image: processedImage)

        FavoritesManager.shared.save()
        cell.visualize(action: .addToFavorites)
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

            let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(saveFavoritePost(_:)))
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            cell.addGestureRecognizer(doubleTapGestureRecognizer)

            let identifier = post.identifier
            cell.representedIdentifier = identifier
            
            if let processedImage = imageProcessor.processedImage(forIdentifier: identifier) {
                cell.configure(with: post, image: processedImage)
            } else {
                cell.resetData()
                cell.configure(with: post, image: nil)

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
