//
//  CommunityChatCollectionViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/05/31.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class CommunityChatCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var message: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // 角丸にする
        img.layer.cornerRadius = img.frame.size.width * 0.5
        img.clipsToBounds = true
    }

}
