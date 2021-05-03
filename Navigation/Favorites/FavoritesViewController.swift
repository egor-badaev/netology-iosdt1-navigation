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
    func favoritePost(with identifier: Int) -> FavoritePost?
    func index(for identifier: Int) -> Int?
    func reloadData()
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
        configureTableView(dataSource: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadData()
        postsTableView.reloadData()
    }

    @objc private func removeFavorite(_ sender: Any) {
        guard let recognizer = sender as? UITapGestureRecognizer,
              let cell = recognizer.view as? PostTableViewCell,
              let identifier = cell.representedIdentifier,
              let favoritePost = viewModel.favoritePost(with: identifier),
              let index = viewModel.index(for: identifier) else {
            return
        }
        FavoritesManager.shared.delete(object: favoritePost)
        viewModel.reloadData()
        let indexPath = IndexPath(row: index, section: 0)
        cell.visualize(action: .deleteFromFavorites) { [weak self] in
            self?.postsTableView.deleteRows(at: [indexPath], with: .top)
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

        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeFavorite(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        cell.addGestureRecognizer(doubleTapGestureRecognizer)

        return cell
    }
}
