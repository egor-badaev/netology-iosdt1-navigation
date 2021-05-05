//
//  FavoritesViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 02.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

protocol FavoritesViewControllerOutput {
    var numberOfRows: Int { get }
    func post(for index: Int) -> Post
    func image(for index: Int) -> UIImage
    func favoritePost(for index: Int) -> FavoritePost?
    func reloadData(completion: ((Bool, Error?) -> Void)?)
}

class FavoritesViewController: BasePostsViewController {

    weak var coordinator: FavoritesCoordinator?
    private let viewModel: FavoritesViewControllerOutput

    // MARK: - Life cycle

    init(viewModel: FavoritesViewControllerOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        configureTableView(dataSource: self, delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadData { [weak self] success, error in
            guard let self = self else { return }

            if let error = error {
                print(error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                self.postsTableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier) as? PostTableViewCell else {
            return UITableViewCell()
        }

        let post = viewModel.post(for: indexPath.row)
        let image = viewModel.image(for: indexPath.row)
        cell.configure(with: post, image: image)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove from favorites") { [weak self] _, _, _ in
            guard let self = self,
                  let favoritePost = self.viewModel.favoritePost(for: indexPath.row) else { return }
            FavoritesManager.shared.deleteAsync(object: favoritePost) { [weak self] success, error in
                guard let self = self else { return }

                guard success else {
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    return
                }

                self.viewModel.reloadData { [weak self] success, error in
                    guard let self = self else { return }

                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }

                    DispatchQueue.main.async {
                        self.postsTableView.deleteRows(at: [indexPath], with: .top)
                    }
                }
            }
        }
        deleteAction.image = UIImage(named: "xmark.bin.circle")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
}
