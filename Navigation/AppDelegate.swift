//
//  AppDelegate.swift
//  Navigation
//
//  Created by Artem Novichkov on 12.09.2020.
//  Copyright © 2020 Artem Novichkov. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var coordinator: MainCoordinator?
    var appConfiguration: AppConfiguration?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        coordinator = MainCoordinator(rootWindow: window)
        coordinator?.start()
        
        appConfiguration = AppConfiguration.randomize()
        fetchData()
        
        FirebaseApp.configure()

        return true
    }

    private func fetchData() {
        guard let appConfiguration = appConfiguration,
              let baseUrl = URL(string: AppConfiguration.baseUrl) else {
            return
        }
        
        let apiUrl = baseUrl.appendingPathComponent(appConfiguration.rawValue)
        print("🟢 Fetching data from \(apiUrl)")
                
        NetworkService.startDataTask(with: apiUrl) { result in

            switch result {
            case .failure(let error):
                // In case of no Internet
                // Code=-1009 "The Internet connection appears to be offline."
                print(error.localizedDescription)

            case .success(let (response, data)):
                print("Received data:")
                if let humanReadable = data.prettyJson { print(humanReadable) }
                print("Status code: \(response.statusCode)")
                print("All header fields:")
                response.allHeaderFields.forEach { print("    \($0): \($1)") }
            }
        }
    }

}

