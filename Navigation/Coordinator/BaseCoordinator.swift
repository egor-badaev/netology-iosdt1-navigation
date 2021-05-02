//
//  BaseCoordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 02.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class BaseCoordinator: Coordinator {
    var childCoordinators: [Coordinator]

    var navigationController: UINavigationController

    func start() { }

    /// default initializer
    init(navigationController: UINavigationController) {
        childCoordinators = []
        self.navigationController = navigationController
    }

}
