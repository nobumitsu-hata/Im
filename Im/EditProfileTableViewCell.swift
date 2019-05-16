//
//  EditProfileTableViewCell.swift
//  Im
//
//  Created by nobumitsu on 2019/05/15.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class EditProfileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var valField: PickerKeyboard!
    @IBOutlet weak var keyLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        valField.textColor = UIColor.white
        keyLbl.textColor = UIColor.white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
