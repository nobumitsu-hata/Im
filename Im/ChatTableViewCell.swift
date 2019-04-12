//
//  ChatTableViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/03/18.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userMessage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
