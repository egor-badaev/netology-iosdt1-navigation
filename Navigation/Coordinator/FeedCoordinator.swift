//
//  FeedCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 08.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class FeedCoordinator: BaseCoordinator {
    var selectedPostIndex: Int?
    
    override func start() {
        let feedTabBarIcon = UIImage(named: "Home")
        let feedTabBarItem = UITabBarItem(title: AppConstants.feedViewControllerTitle, image: feedTabBarIcon, selectedImage: nil)
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
            showAlert(title: "Ошибка", message: "Невозможно отобразить пост")
            return
        }
        let infoViewModel = InfoViewModel(forPostWithIndex: selectedPostIndex)
        let infoViewController = InfoViewController(viewModel: infoViewModel)
        infoViewModel.viewInput = infoViewController
        infoViewController.coordinator = self
        navigationController.present(infoViewController, animated: true, completion: nil)
    }
    
    func showDeletePostAlert() {
        let cancelAction = UIAlertAction(title: "Отмена", style: .default) { _ in
            print("Отмена")
        }
        let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { _ in
            print("Удалить")
        }
        showAlert(title: "Удалить пост?", message: "Пост нельзя будет восстановить", actions: [cancelAction, deleteAction])
    }
}
