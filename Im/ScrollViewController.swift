//
//  ScrollViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/30.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI
import CoreLocation

class MyTapGestureRecognizer: UITapGestureRecognizer {
    var targetString: String?
}

class ScrollViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var ref: DatabaseReference!
    var storage: Storage!
    
    var communityKey:[String] = []
    var communityVal:[[String:Any]] = []
    // ScrollScreenの高さ
    var scrollScreenHeight:CGFloat!
    // ScrollScreenの幅
    var scrollScreenWidth:CGFloat!
    
    var screenSize:CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenSize = UIScreen.main.bounds
        print("こんちは")
        // ページスクロールとするためにページ幅を合わせる
        scrollScreenWidth = screenSize.width
        scrollScreenHeight = screenSize.height
        self.view.setGradientLayer()
        setupFirebase()
        
    }
    
    func setupFirebase() {
        storage = Storage.storage()
        
        // 自作セルをテーブルビューに登録する
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: Bundle(for: type(of: self)))
        
        // 描画開始の x,y 位置
        let px:CGFloat = 0.0
        var py:CGFloat = 0.0
        
        var counter = 0
        
        ref = Database.database().reference()
        ref.child("locations").observe(DataEventType.childAdded, with: { (snapshot) in
            let communityView = communityXib.instantiate(withOwner: self, options: nil).first as! UIView
            communityView.isUserInteractionEnabled = true
//            communityView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("btnClick:")))
            
            let snapshotVal = snapshot.value as! [String:Any]
            let latitude = snapshotVal["latitude"] as! String
            let longitude = snapshotVal["longitude"] as! String

            let baseLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
            let targetLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
            let distanceLocation = baseLocation.distance(from: targetLocation)
            print("距離は \(distanceLocation)")

            let radius = snapshotVal["radius"] as! Double
            // 現在地が目的地の許容範囲内かどうか
            if radius >= distanceLocation {
                self.ref.child("communities").child(snapshot.key).observeSingleEvent(of: .value, with: { (snapshot) in
                    guard counter < 3 else {return}
                    let val = snapshot.value as! [String:Any]
                    self.communityVal.append(val)
                    self.communityKey.append(snapshot.key)
                    // コミュニティー名設定
                    let titleLabel = communityView.viewWithTag(1) as! UILabel
                    let title = val["name"] as! String
                    titleLabel.textColor = UIColor.white
                    titleLabel.text = String(describing: title)
                    // コミュニティー画像設定
                    let img  = communityView.viewWithTag(2) as! UIImageView
                    let storageRef = self.storage.reference()
                    let imgData = storageRef.child("communities").child(val["img"] as! String)
                    img.sd_setImage(with: imgData)
                    img.isUserInteractionEnabled = true
                    
                    let gesture = MyTapGestureRecognizer(target: self, action: #selector(ScrollViewController.btnClick(_:)))
                    gesture.targetString = snapshot.key
                    communityView.addGestureRecognizer(gesture)
                    self.scrollView.addSubview(communityView)
                    
                    // 描画開始設定
                    var viewFrame:CGRect = communityView.frame
                    viewFrame.size.width = self.scrollScreenWidth
                    viewFrame.size.height = self.scrollScreenHeight
                    viewFrame.origin = CGPoint(x: px, y: py)
                    communityView.frame = viewFrame
//                    communityView.setGradientLayer()
                    // 次の描画位置設定
                    py += (self.screenSize.height)
//                    communityView.addTarget(self, action: #selector(self.btnClick(btn: )), for: .touchUpInside)
                    counter += 1
                    // スクロール範囲の設定
                    let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(counter)
                    print("コンテントサイズ")
                    print(nHeight)
                    self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
            
        })
        
    }
    
    override var prefersStatusBarHidden:Bool {
        // trueの場合はステータスバー非表示
        return true;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatViewController" {
            let nav = segue.destination as! UINavigationController
            let chatViewController = nav.topViewController as! ChatViewController
            chatViewController.communityId = (sender as! String)
            print("テスト")
        }
    }
    
    @objc func btnClick(_ sender:MyTapGestureRecognizer) {
        tabBarController?.tabBar.isHidden = true
        performSegue(withIdentifier: "toChatViewController", sender: sender.targetString)
    }
    
}
