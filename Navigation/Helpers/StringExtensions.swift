//
//  StringExtensions.swift
//  Navigation
//
//  Created by Egor Badaev on 31.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

extension String {
    func toURL() throws -> URL {
        guard let url = URL(string: self) else {
            print("Cannot create URL from string")
            throw NetworkError.invalidURL
        }
        return url
    }
    
    func toISO8601Date(withFractionalSeconds: Bool = true) throws -> Date {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if withFractionalSeconds {
            dateFormatter.formatOptions.update(with: .withFractionalSeconds)
        }
        
        guard let date = dateFormatter.date(from: self) else {
            print("Cannot create date from string")
            throw NetworkError.invalidData
        }
            
        return date

    }
}
