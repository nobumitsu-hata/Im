//
//  MessageViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/13.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class MessageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var ref: DatabaseReference!
    var storage: StorageReference!
    private let storageRef = Storage.storage().reference()
    private let db = Firestore.firestore()
    var dmKeyArr:[String] = []
    var dmValArr:[String] = []
    var receiverArr:[[String:String]] = []
    @IBOutlet weak var tableView: UITableView!
    var chatListArr:[[String:Any]] = []
    
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // 自作セルをテーブルビューに登録する
        let chatXib = UINib(nibName: "MessageTableViewCell", bundle: nil)
        tableView.register(chatXib, forCellReuseIdentifier: "messageCell")
        
        setupFirebase()
        
        // ナビゲーションを透明にする処理
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.navigationBar.tintColor = .white
        // ナビゲーションバーのテキストを変更する
        navigationController?.navigationBar.titleTextAttributes = [
            // 文字の色
            .foregroundColor: UIColor.white
        ]
        
        
        //グラデーションの開始色
        let topColor = UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0)
        //グラデーションの開始色
        let bottomColor = UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        
        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [topColor.cgColor, bottomColor.cgColor]
        
        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        
        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        // 上から下へグラデーション向きの設定
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 1)
        //グラデーションレイヤーをビューの一番下に配置
        self.view.layer.insertSublayer(gradientLayer, at:0)
        tableView.backgroundColor = UIColor.clear
        
    }
    
    func setupFirebase() {
        storage = Storage.storage().reference()
        ref = Database.database().reference()
        print("通過11113")
        db.collection("users").document(RootTabBarController.UserId).collection("privateChatPartners").addSnapshotListener{ querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            guard documents.count > 0 else { return }
        print(documents.count)
            guard let snapshot = querySnapshot else {
                print("Error fetching documents: \(error!)")
                return
            }
            print("通過3")
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    print("通過34")
                    var dic:[String:Any] = [:]
                    let data = diff.document.data()
                    print(data)
                    let privateChatRef = data["privateChatRef"] as! DocumentReference
                    let partnerRef = data["partnerRef"] as! DocumentReference
                    
                    partnerRef.addSnapshotListener{ documentSnapshot, error in
                        guard let document = documentSnapshot else {
                            print("Error fetching document: \(error!)")
                            return
                        }
                        print("通過377")
                        let partnerDoc = document.data()
                        print(partnerDoc)
                        privateChatRef.addSnapshotListener{ documentSnapshot, error in
                            guard let document = documentSnapshot else {
                                print("Error fetching document: \(error!)")
                                return
                            }
                            print("通過312")
                            let privateChatDoc = document.data()
                            print(privateChatDoc)
                            if let firstIndex = self.chatListArr.index(where: {$0["partnerId"] as! String == diff.document.documentID}) {
                                print("インデックス番号: \(firstIndex)")
                                self.chatListArr[firstIndex]["updateTime"] = privateChatDoc?["updateTime"] as! TimeInterval
                                self.chatListArr[firstIndex]["lastMessage"] = privateChatDoc?["lastMessage"] as! String
                                self.chatListArr[firstIndex]["name"] = partnerDoc?["name"] as! String
                                self.chatListArr[firstIndex]["img"] = partnerDoc?["img"] as! String
                                self.chatListArr = self.chatListArr.sorted{ ($0["updateTime"] as! TimeInterval) > ($1["updateTime"] as! TimeInterval) }
                            } else {
                                dic["updateTime"] = privateChatDoc?["updateTime"] as! TimeInterval
                                dic["lastMessage"] = privateChatDoc?["lastMessage"] as! String
                                dic["name"] = partnerDoc?["name"] as! String
                                dic["img"] = partnerDoc?["img"] as! String
                                dic["partnerId"] = diff.document.documentID
                                self.chatListArr.append(dic)
                                self.chatListArr = self.chatListArr.sorted{ ($0["updateTime"] as! TimeInterval) > ($1["updateTime"] as! TimeInterval) }
                                print(self.chatListArr)
                            }
                            
                            self.tableView.reloadData()
                        }
                    }
                default:
                    break
                }
            }
            
        }
        
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セル生成
        let cell = table.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        cell.backgroundColor = UIColor.clear
        print(chatListArr[indexPath.row]["name"] as? String)
        cell.name.text = chatListArr[indexPath.row]["name"] as? String
        
        if chatListArr[indexPath.row]["img"] as! String != "" {
            let getImg = self.storage.child("users").child(chatListArr[indexPath.row]["img"] as! String)
            DispatchQueue.main.async {
                print("画像")
                cell.imgView.sd_setImage(with: getImg)
                cell.imgView.setNeedsLayout()
            }
        } else {
            cell.imgView.image = UIImage(named: "UserImg")
        }
        
        cell.imgView.layer.cornerRadius = cell.imgView.frame.size.width * 0.5
        cell.imgView.clipsToBounds = true
        
        cell.lastMsg.text = chatListArr[indexPath.row]["lastMessage"] as? String
        
        // 選択された背景色を白に設定
        let cellSelectedBgView = UIView()
        cellSelectedBgView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = cellSelectedBgView
        
        return cell
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatListArr.count
    }
    
    // Cell が選択された場合
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        // DMViewController へ遷移するために Segue を呼び出す
        tabBarController?.tabBar.isHidden = true
        performSegue(withIdentifier: "fromListToDMViewController",sender: indexPath.row)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromListToDMViewController" {
            let dmViewController = segue.destination as! DMViewController
            dmViewController.partnerId = chatListArr[sender as! Int]["partnerId"] as! String
            dmViewController.partnerData = chatListArr[sender as! Int]
        }
    }

}
