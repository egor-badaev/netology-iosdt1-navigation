//
//  NetworkService.swift
//  Navigation
//
//  Created by Egor Badaev on 29.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation
import EBFoundation

struct NetworkService {
    static func makeDataTask(with url: URL, completion: ((Result<(HTTPURLResponse, Data), Error>) -> Void)? = nil) -> URLSessionDataTask {
        return URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion?(.failure(error))
                return
            }
            guard let httpURLResponse = response as? HTTPURLResponse,
                  httpURLResponse.statusCode == 200,
                  let mimeType = response?.mimeType,
                  mimeType.hasSuffix("json"),
                  let data = data else {
                completion?(.failure(NetworkError.badResponse))
                return
            }
            
            completion?(.success((httpURLResponse, data)))
            
        }
    }
    
    static func startDataTask(with url: URL, completion: ((Result<(HTTPURLResponse, Data), Error>) -> Void)? = nil) {
        let dataTask = NetworkService.makeDataTask(with: url, completion: completion)
        dataTask.resume()
    }
}
