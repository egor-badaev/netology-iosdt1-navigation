//
//  MainCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 08.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class MainCoordinator {
    var childCoordinators: [Coordinator] = []
    private var rootWindow: UIWindow?
    private var tabBarController: UITabBarController

    init(rootWindow: UIWindow?) {
        self.rootWindow = rootWindow
        tabBarController = UITabBarController()
    }
    
    func start() {
        setupFeedCoordinator()
        setupProfileCoordinator()
        setupFavoritesCoordinator()
        setupTabBarController()
        rootWindow?.rootViewController = self.tabBarController
        rootWindow?.makeKeyAndVisible()
    }
    
    private func setupFeedCoordinator() {
        let feedViewController = FeedViewController()
        let feedNavigationController = UINavigationController(rootViewController: feedViewController)
        let feedCoordinator = FeedCoordinator(navigationController: feedNavigationController)
        feedViewController.coordinator = feedCoordinator
        childCoordinators.append(feedCoordinator)
    }

    private func setupProfileCoordinator() {
        let loginViewController = LogInViewController()
        let profileNavigationController = UINavigationController(rootViewController: loginViewController)
        let profileCoordinator = ProfileCoordinator(navigationController: profileNavigationController)
        loginViewController.coordinator = profileCoordinator
        childCoordinators.append(profileCoordinator)
    }

    private func setupFavoritesCoordinator() {
        let favoritesViewModel = FavoritesViewModel()
        let favoritesController = FavoritesViewController(viewModel: favoritesViewModel)
        let favoritesNavigationController = UINavigationController(rootViewController: favoritesController)
        favoritesViewModel.input = favoritesController
        let favoritesCoordinator = FavoritesCoordinator(navigationController: favoritesNavigationController)
        favoritesController.coordinator = favoritesCoordinator
        childCoordinators.append(favoritesCoordinator)
    }

    private func setupTabBarController() {
        var tabBarViewControllers: [UIViewController] = []
        childCoordinators.forEach {
            $0.start()
            tabBarViewControllers.append($0.navigationController)
        }
        
        let mediaViewController = MediaViewController()
        let mediaTabBarIcon = UIImage(named: "Music")
        let mediaTabBarItem = UITabBarItem(title: "Media", image: mediaTabBarIcon, selectedImage: nil)
        mediaViewController.tabBarItem = mediaTabBarItem

        tabBarViewControllers.append(mediaViewController)

        tabBarController.viewControllers = tabBarViewControllers
    }
    
}
