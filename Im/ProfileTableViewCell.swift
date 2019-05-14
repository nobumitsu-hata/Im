//
//  ProfileTableViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/05/13.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var valLbl: UILabel!
    @IBOutlet weak var keyLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
