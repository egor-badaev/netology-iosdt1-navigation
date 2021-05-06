//
//  ImageCacheService.swift
//  Navigation
//
//  Created by Egor Badaev on 06.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class ImageCacheService {

    static let shared: ImageCacheService = {
        let instance = ImageCacheService()
        return instance
    }()

    private let documentsURL: URL

    private init() {
        let documentsUrls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        documentsURL = documentsUrls[0]
    }

    func cachedFilename(for image: UIImage) -> String {


        let uuid = UUID().uuidString
        let filename = "\(uuid).png"
        let fileUrl = documentsURL.appendingPathComponent(filename)

        FileManager.default.createFile(atPath: fileUrl.path, contents: image.pngData(), attributes: nil)

        return filename
    }

    func image(filename: String) -> UIImage? {

        let fileUrl = documentsURL.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: fileUrl) {
            let image = UIImage(data: data)
            return image
        }

        return nil
    }
}
