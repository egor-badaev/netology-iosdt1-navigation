//
//  Coordinator.swift
//  Navigation
//
//  Created by Egor Badaev on 08.02.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

extension Coordinator {
    func showAlert(presentedOn viewController: UIViewController, title: String?, message: String?, actions: [UIAlertAction] = [], completion: (() -> Void)? = nil) {

        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if !actions.isEmpty {
                actions.forEach { alertController.addAction($0) }
            } else {
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            }
            viewController.present(alertController, animated: true, completion: completion)
        }
    }
    
    func closeCurrentController() {
        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController.popViewController(animated: true)
        }
    }

    func showAlertAndClose(_ viewController: UIViewController, title: String? = nil, message: String? = nil) {
        self.showAlert(presentedOn: viewController, title: title ?? "Ошибка", message: message, actions: [UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.closeCurrentController()
        })])
    }
}
