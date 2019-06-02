//
//  ChatTableViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/03/18.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var message: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear
        // 角丸にする
        img.layer.cornerRadius = img.frame.size.width * 0.5
        img.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
