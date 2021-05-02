//
//  FavoritesCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 02.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

final class FavoritesCoordinator: BaseCoordinator {

    override func start() {
        let favTabBarIcon = UIImage(named: "Favorites")
        let favTabBarItem = UITabBarItem(title: "Favorites", image: favTabBarIcon, selectedImage: nil)
        navigationController.tabBarItem = favTabBarItem
    }

}
