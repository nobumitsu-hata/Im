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
//import FirebaseUI
import CoreLocation

class MyTapGestureRecognizer: UITapGestureRecognizer {
    var targetString: String?
}

class ScrollViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var storage: Storage!
    private let db = Firestore.firestore()
    
    var communityKey:[String] = []
    var communityVal:[[String:Any]] = []
    
    var scrollScreenHeight:CGFloat!// ScrollScreenの高さ
    var scrollScreenWidth:CGFloat!// ScrollScreenの幅
    var screenSize:CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenSize = UIScreen.main.bounds
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
        
        db.collection("locations").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                return
            }
            guard querySnapshot!.documents.count > 0 else {
                return
            }
            
            for document in querySnapshot!.documents {
                print("\(document.documentID) => \(document.data())")
                let communityView = communityXib.instantiate(withOwner: self, options: nil).first as! UIView
                communityView.isUserInteractionEnabled = true
                
                let data = document.data()
                let documentId = document.documentID
                let latitude = data["latitude"] as! String
                let longitude = data["longitude"] as! String
                
                let baseLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                let targetLocation: CLLocation = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
                let distanceLocation = baseLocation.distance(from: targetLocation)
                print("距離は \(distanceLocation)")
                
                let radius = data["radius"] as! Double
                
                guard radius >= distanceLocation else {
                    return
                }
                
                self.db.collection("communities").document(documentId).getDocument { (document, error) in
                    if let community = document.flatMap({
                        $0.data().flatMap({ (data) in
                            return data
                        })
                    }) {
                        print("community: \(community)")
                        
                        // コミュニティー名設定
                        let titleLabel = communityView.viewWithTag(1) as! UILabel
                        let title = community["name"] as! String
                        titleLabel.textColor = UIColor.white
                        titleLabel.text = String(describing: title)
                        // コミュニティー画像設定
                        let img  = communityView.viewWithTag(2) as! UIImageView
                        let storageRef = self.storage.reference()
                        let imgData = storageRef.child("communities").child(community["img"] as! String)
                        img.sd_setImage(with: imgData)
                        img.isUserInteractionEnabled = true
                        
                        let gesture = MyTapGestureRecognizer(target: self, action: #selector(ScrollViewController.btnClick(_:)))
                        gesture.targetString = documentId
                        communityView.addGestureRecognizer(gesture)
                        self.scrollView.addSubview(communityView)
                        
                        // 描画開始設定
                        var viewFrame:CGRect = communityView.frame
                        viewFrame.size.width = self.scrollScreenWidth
                        viewFrame.size.height = self.scrollScreenHeight
                        viewFrame.origin = CGPoint(x: px, y: py)
                        communityView.frame = viewFrame
                        // 次の描画位置設定
                        py += (self.screenSize.height)
                        counter += 1
                        // スクロール範囲の設定
                        let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(counter)
                        self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
                    } else {
                        print("Document does not exist")
                    }
                }
                
            }
            
        }
        
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
        }
    }
    
    @objc func btnClick(_ sender:MyTapGestureRecognizer) {
        tabBarController?.tabBar.isHidden = true
        performSegue(withIdentifier: "toChatViewController", sender: sender.targetString)
    }
    
}
