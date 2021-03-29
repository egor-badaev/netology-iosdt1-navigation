//
//  NetworkError.swift
//  Navigation
//
//  Created by Egor Badaev on 29.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case badResponse
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Данный URL не является валидным"
        case .badResponse:
            return "Не получен валидный ответ от сервера"
        case .invalidData:
            return "Не удалось распознать ответ от сервера"
        }
    }
}
