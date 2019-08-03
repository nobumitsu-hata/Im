//
//  ReportUserViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/07/25.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore


class ReportUserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let db = Firestore.firestore()
    let typeArr = ["不適切なコンテンツを送っている", "スパムを送っている", "このプロフィールは他の人になりすましている"]
    var targetId = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        view.setGradientLayer()
        tableView.backgroundColor = .clear
        
        
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typeArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportTypeCell", for: indexPath)
        cell.backgroundColor = .clear
        
        if let label = cell.viewWithTag(1) as? UILabel {
            label.text = typeArr[indexPath.row]
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
        
        if indexPath.row == 1 {
            let timestamp = Date().timeIntervalSince1970
            db.collection("reports").addDocument(data: ["senderId" : RootTabBarController.UserId, "type": typeArr[indexPath.row], "targetId": targetId, "createTime": timestamp]) { (error) in
                if let error = error {
                    print("Error adding document: \(error)")
                    self.showMessagePrompt(message: "もう一度やり直してください")
                } else {
                    let alertController = UIAlertController(title: "報告が完了しました", message: nil, preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel) { action in
                        self.dismiss(animated: true, completion: nil)
                    }
                    alertController.addAction(cancelAction)
                    (self.navigationController ?? self)?.present(alertController, animated: true, completion: nil)
                }
            }
            return
        }
        performSegue(withIdentifier: "toReportItemsViewController", sender: indexPath.row)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toReportItemsViewController" {
            let reportItemsViewController = segue.destination as! ReportItemsViewController
            var type = sender as? Int
            if type == 2 {
                type = 1
            }
            reportItemsViewController.targetId = targetId
            reportItemsViewController.itemType = type ?? 0
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
