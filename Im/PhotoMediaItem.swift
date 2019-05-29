//
//  PhotoMediaItem.swift
//  Im
//
//  Created by nobumitsu on 2019/05/27.
//  Copyright © 2019 im. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class PhotoMediaItem: JSQPhotoMediaItem {
    var thumbSize: CGSize!
    override func mediaViewDisplaySize() -> CGSize {
        
        if self.image != nil && self.image.size.width > 0 && self.image.size.height > 0 {
            let aspect: CGFloat = self.image.size.height / self.image.size.width
            thumbSize = CGSize(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.width / 2 * aspect)
        } else {
            thumbSize = CGSize(width: UIScreen.main.bounds.width / 2, height: 256)
        }
        return thumbSize
    }
}
