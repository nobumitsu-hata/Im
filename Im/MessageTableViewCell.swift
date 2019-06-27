//
//  MessageTableViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/04/29.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var lastMsg: UILabel!
    @IBOutlet weak var unreadMark: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lastMsg.textColor = UIColor.white
        unreadMark.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
