//
//  ExtendedViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 07.04.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class ExtendedViewController: UIViewController {
    
    var viewHasAppeared = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewHasAppeared = false
    }
}
