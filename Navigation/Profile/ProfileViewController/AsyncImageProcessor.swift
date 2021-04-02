//
//  AsyncImageProcessor.swift
//  Navigation
//
//  Created by Egor Badaev on 02.04.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit
import iOSIntPackage

enum ImageProcessorError: LocalizedError {
    case failedToProcessImage
    
    var errorDescription: String? {
        switch self {
        case .failedToProcessImage:
            return "Не удалось обработать изображение"
        }
    }
}


class AsyncImageProcessor {
    
    private var processedImages: [Int: UIImage] = [:]
    
    func process(image: UIImage, filter: ColorFilter, forIdentifier identifier: Int, completion: @escaping ((Result<UIImage, Error>) -> Void)) {
        
        ImageProcessor().processImageAsync(sourceImage: image, filter: filter) { processedImage in
            guard let processedImage = processedImage else {
                completion(.failure(ImageProcessorError.failedToProcessImage))
                return
            }
            let image = UIImage(cgImage: processedImage)
            completion(.success(image))
            self.processedImages[identifier] = image
        }
    }
    
    func processedImage(forIdentifier identifier: Int) -> UIImage? {
        return processedImages[identifier]
    }
}
