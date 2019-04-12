//
//  TestViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

class TestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    
    let testArr = ["s;klfjsal;fjasl;kfjas;lfjasl;kfjsal;kfjsal;dfjlsadfjsdal;fdkjsa;lkfjaaaaab","sdlafj", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "fdsaf", "lskfjas;lfkjsal;fkjsa;lkfjas;lkfjsl;kfjas;lfjsa;lkfjsal;jdfals;fjl;askdfjsa;lkaaaaaaaaaaaaaaaac"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 100000
        
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "ChatTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "chatCell")
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        //        let imgView = cell.viewWithTag(1) as! UIImageView
        //        let name = cell.viewWithTag(2) as! UILabel
        //        let text = cell.viewWithTag(3) as! UITextView
        
        let imgView = cell.userImg as! UIImageView
        let name = cell.userName as! UILabel
        let text = cell.userMessage as! UILabel
        
        //        text.isEditable = false
        //        text.delegate = self
        // 画像設定
        let img = UIImage(named: "User")
        imgView.image = img
        // 配色
        cell.backgroundColor = UIColor.clear
        name.backgroundColor = UIColor.clear
        text.backgroundColor = UIColor.clear
        // paddingを消す
//                text.textContainerInset = UIEdgeInsets.zero
        //        text.textContainer.lineFragmentPadding = 0
        text.text = testArr[indexPath.row]
        text.sizeToFit()
        
//        let height = text.sizeThatFits(CGSize(width: text.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
//        text.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testArr.count
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
