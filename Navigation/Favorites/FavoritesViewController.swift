//
//  FavoritesViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 02.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class FavoritesViewController: BasePostsViewController {

    weak var coordinator: FavoritesCoordinator?

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        configureTableView(dataSource: self)
    }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier) as? PostTableViewCell else {
            return UITableViewCell()
        }
        return cell
    }
}
