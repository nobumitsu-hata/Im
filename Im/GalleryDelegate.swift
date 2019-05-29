//
//  GalleryDelegate.swift
//  Im
//
//  Created by nobumitsu on 2019/05/27.
//  Copyright © 2019 im. All rights reserved.
//

import Foundation
import Nuke
import ImageViewer
class GalleryDelegate: GalleryItemsDataSource {
    private let items: [GalleryItem]
    // 一応ギャラリーとしても使えるように複数のURL読み込みに対応してます。
    init(imageUrls: [String]) {
        
        items = imageUrls.map { URL(string: $0) }.compactMap { $0 }.map { imageUrl in
            
            GalleryItem.image { imageCompletion in
                // Nukeのモジュールで非同期に画像を読み込んでます。
                ImagePipeline.shared.loadImage(with: imageUrl, progress: nil, completion: { (response, error) in
                    imageCompletion(response?.image) // 読み込んだ画像をImageViewerに渡してます
                })
            }
        }
    }
    // 何個表示するか
    func itemCount() -> Int {
        return 1
    }
    // 実際に表示する画像を指定
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return items[0]
    }
}
