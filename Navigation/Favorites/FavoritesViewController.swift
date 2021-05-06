//
//  FavoritesViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 02.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

protocol FavoritesViewControllerOutput {
    typealias FilterChanges = (added: Set<Int>, deleted: Set<Int>)
    typealias FilterHandler = (FilterChanges?, Error?) -> Void

    var numberOfRows: Int { get }
    func post(for index: Int) -> Post
    func image(for index: Int) -> UIImage
    func favoritePost(for index: Int) -> FavoritePost?
    func reloadData(completion: ((Bool, Error?) -> Void)?)
    func setFilter(_ filter: String, completion: @escaping FilterHandler)
    func clearFilter(completion: @escaping FilterHandler)
}

class FavoritesViewController: BasePostsViewController {

    weak var coordinator: FavoritesCoordinator?
    private let viewModel: FavoritesViewControllerOutput
    private var filterText: String?

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Clear filter", style: .plain, target: self, action: #selector(clearFiltersTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter author", style: .plain, target: self, action: #selector(addFilterTapped(_:)))

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

    // MARK: - Actions

    @objc func addFilterTapped(_ sender: UIBarButtonItem) {

        let alert = UIAlertController(title: "Add filter by author", message: "Display only posts made by certain author", preferredStyle: .alert)
        alert.addTextField { textfield in
            textfield.addTarget(self, action: #selector(self.filterTextEntered(_:)), for: .editingChanged)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self,
                  let filterText = self.filterText,
                  filterText.count > 0 else {
                return
            }
            self.viewModel.setFilter(filterText) { [weak self] changes, error in
                guard let self = self else { return }
                self.updateTable(changes: changes, error: error)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        [okAction, cancelAction].forEach { alert.addAction($0) }

        coordinator?.navigationController.present(alert, animated: true, completion: nil)
    }

    @objc func filterTextEntered(_ sender: UITextField) {
        filterText = sender.text
    }

    @objc func clearFiltersTapped(_ sender: UIBarButtonItem) {
        viewModel.clearFilter { [weak self] changes, error in
            guard let self = self else { return }
            self.updateTable(changes: changes, error: error)
        }
    }

    // MARK: - Helpers
    private func updateTable(changes: FavoritesViewControllerOutput.FilterChanges?, error: Error?) {

        guard let changes = changes else {
            if let error = error {
                print(error.localizedDescription)
            }
            return
        }

        DispatchQueue.main.async {
            self.postsTableView.performBatchUpdates {
                if changes.deleted.count > 0 {
                    let deleteIndexes = changes.deleted.map { IndexPath(row: $0, section: 0) }
                    self.postsTableView.deleteRows(at: deleteIndexes, with: .automatic)
                }
                if changes.added.count > 0 {
                    let insertIndexes = changes.added.map { IndexPath(row: $0, section: 0) }
                    self.postsTableView.insertRows(at: insertIndexes, with: .automatic)
                }
            } completion: { _ in
                print("Updates complete")
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
