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
    
    private func setupTabBarController() {
        var tabBarViewControllers: [UIViewController] = []
        childCoordinators.forEach {
            $0.start()
            tabBarViewControllers.append($0.navigationController)
        }
        
        let playerViewController = PlayerViewController()
        let playerTabBarIcon = UIImage(named: "Music")
        let playerTabBarItem = UITabBarItem(title: "Player", image: playerTabBarIcon, selectedImage: nil)
        playerViewController.tabBarItem = playerTabBarItem
        
        tabBarViewControllers.append(playerViewController)
        
        let videoViewController = VideoPlayerViewController()
        let videoTabBarIcon = UIImage(named: "YouTube")
        let videoTabBarItem = UITabBarItem(title: "Video", image: videoTabBarIcon, selectedImage: nil)
        videoViewController.tabBarItem = videoTabBarItem
        tabBarViewControllers.append(videoViewController)
        
        let recorderViewController = RecorderViewController()
        let recorderTabBarIcon = UIImage(named: "Microphone")
        let recorderTabBarItem = UITabBarItem(title: "Recorder", image: recorderTabBarIcon, selectedImage: nil)
        recorderViewController.tabBarItem = recorderTabBarItem
        tabBarViewControllers.append(recorderViewController)
        
        tabBarController.viewControllers = tabBarViewControllers
    }
    
}
