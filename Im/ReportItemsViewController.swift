//
//  ReportItemsViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/08/02.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class ReportItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let db = Firestore.firestore()
    var targetId = ""
    let items = [
        ["嫌がらせやいじめ", "薬物の売買または宣伝", "暴力または暴力的脅威", "ヌードまたはわいせつコンテンツ", "ヘイトスピーチや差別的なシンボル", "自傷行為"],
        ["自分", "友人", "有名人、著名人"]
    ]
    let typeArr = ["不適切なコンテンツを送っている", "このプロフィールは他の人になりすましている"]
    var itemType = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        view.setGradientLayer()
        tableView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[itemType].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportItemCell", for: indexPath)
        cell.backgroundColor = .clear
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = items[itemType][indexPath.row]
        }
        
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator // ここで「>」ボタンを設定
        
        // 選択された背景色を透明に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }
    
    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let timestamp = Date().timeIntervalSince1970
        db.collection("reports").addDocument(data: ["sender" : RootTabBarController.UserId, "targetId": targetId, "type": typeArr[itemType], "item": items[itemType][indexPath.row], "createTime": timestamp]) { (error) in
            if let error = error {
                print("Error adding document: \(error)")
                self.showMessagePrompt(message: "もう一度やり直してください")
            } else {
                let alertController = UIAlertController(title: "報告が完了しました", message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(cancelAction)
                (self.navigationController ?? self)?.present(alertController, animated: true, completion: nil)
            }
        }
        
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    

}
