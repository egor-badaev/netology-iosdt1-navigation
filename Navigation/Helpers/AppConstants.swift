//
//  AppConstants.swift
//  Navigation
//
//  Created by Egor Badaev on 17.11.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit

enum AppConstants {

    enum AuthenticationProvider {
        case firebase
    }

    static let accentColor = "AccentColor"
    static let margin: CGFloat = 16.0
    static let feedViewControllerTitle = "Feed"
    static let animationDuration: TimeInterval = 0.3
    static let authenticationProvider: AuthenticationProvider = .firebase
}
