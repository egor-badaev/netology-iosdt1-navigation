//
//  AppConfiguration.swift
//  Navigation
//
//  Created by Egor Badaev on 29.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

enum AppConfiguration: String {
    
    static let baseUrl = "http://swapi.dev/api"
    
    case films = "/films/3/"
    case vehicles = "/vehicles/14/"
    case starships = "/starships/5/"
    
    static func randomize() -> AppConfiguration {
        var appConfiguration: AppConfiguration
        
        let randomSeed = Int.random(in: 0...2)
        switch randomSeed {
        case 0:
            appConfiguration = .films
        case 1:
            appConfiguration = .vehicles
        default:
            appConfiguration = .starships
        }

        return appConfiguration
    }
}
