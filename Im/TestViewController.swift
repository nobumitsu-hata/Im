//
//  TestViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class TestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    var storage: StorageReference!
    @IBOutlet weak var tableView: UITableView!
    
    
    let testArr = ["s;klfjsal;fjasl;kfjas;lfjasl;kfjsal;kfjsal;dfjlsadfjsdal;fdkjsa;lkfjaaaaab","sdlafj", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "lskfjas;lfkjsal;fkjsa;lkfjas;lkfjsl;kfjas;lfjsa;lkfjsal;jdfals;fjl;askdfjsa;lkaaaaaaaaaaaaaaaac"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        storage = Storage.storage().reference()
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60
        
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "CommunityTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "chatCell")

//        self.tableView.reloadData()
//        let test = self.tableView.contentSize.height - self.tableView.frame.size.height
//        self.tableView.contentOffset = CGPoint(x: 0, y: test)

    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! CommunityTableViewCell
                let imgView = cell.viewWithTag(2) as! UIImageView
        //        let name = cell.viewWithTag(2) as! UILabel
        //        let text = cell.viewWithTag(3) as! UITextView
        
        
//        let imgView = cell.userImg as! UIImageView
//        let name = cell.userName as! UILabel
//        let text = cell.userMessage as! UILabel
        
        let getImg = storage.child("communities").child("-LcLgw1SEtq1xtq-6Hqy.jpeg")
        
        //        text.isEditable = false
        //        text.delegate = self
        // 画像設定
        imgView.sd_setImage(with: getImg)
//        let img = UIImage(named: "User")
//        imgView.image = img
        // 配色
//        cell.backgroundColor = UIColor.clear
//        name.backgroundColor = UIColor.clear
//        text.backgroundColor = UIColor.clear
        // paddingを消す
//                text.textContainerInset = UIEdgeInsets.zero
        //        text.textContainer.lineFragmentPadding = 0
//        text.text = testArr[indexPath.row]
//        text.sizeToFit()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
}
