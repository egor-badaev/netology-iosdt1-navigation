//
//  FeedCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 08.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class FeedCoordinator: Coordinator {
    var childCoordinators: [Coordinator]    
    var navigationController: UINavigationController
    var selectedPostIndex: Int?
    
    init(navigationController: UINavigationController) {
        childCoordinators = []
        self.navigationController = navigationController
    }
    
    func start() {
        let feedTabBarItem = UITabBarItem(title: AppConstants.feedViewControllerTitle, image: UIImage(named: "Home"), selectedImage: nil)
        navigationController.tabBarItem = feedTabBarItem
    }
        
    func showPost(number index: Int) {

        let postViewController = PostViewController()
        postViewController.coordinator = self
        
        let post = FeedModel.shared.posts[index]
        postViewController.title = post.title
        selectedPostIndex = index

        navigationController.pushViewController(postViewController, animated: true)
    }
    
    func showPostInfo() {
        guard let selectedPostIndex = selectedPostIndex else {
            guard let topViewController = navigationController.topViewController else {
                return
            }
            showAlert(presentedOn: topViewController, title: "Ошибка", message: "Невозможно отобразить пост")
            return
        }
        let toDoUrl = FeedModel.shared.posts[selectedPostIndex].toDoUrl
        let planetUrl = FeedModel.shared.posts[selectedPostIndex].planetUrl
        let infoViewController = InfoViewController(toDoUrl: toDoUrl, planetUrl: planetUrl)
        infoViewController.coordinator = self
        navigationController.present(infoViewController, animated: true, completion: nil)
    }
    
    func showDeletePostAlert(presentedOn viewController: UIViewController) {
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { _ in
            print("Отмена")
        }
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { _ in
            print("Удалить")
        }
        self.showAlert(presentedOn: viewController, title: "Удалить пост?", message: "Пост нельзя будет восстановить", actions: [cancelAction, deleteAction])
    }
}
