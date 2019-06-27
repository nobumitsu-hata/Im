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
import FirebaseFirestore
import CoreLocation
import KRProgressHUD

class MyTapGestureRecognizer: UITapGestureRecognizer {
    var targetString: String?
}

class ScrollViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var storage: Storage!
    private let db = Firestore.firestore()
    var appGuideView:UIView!
//    var locationManager: CLLocationManager!
    fileprivate let refreshCtl = UIRefreshControl()
    
    var communityKey:[String] = []
    var communityVal:[[String:Any]] = []
    
    var locationFlg = true
    var scrollScreenHeight:CGFloat!// ScrollScreenの高さ
    var scrollScreenWidth:CGFloat!// ScrollScreenの幅
    var screenSize:CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        locationManager = CLLocationManager()
//        locationManager.delegate = self
//
        scrollView.delegate = self
        
        refreshCtl.tintColor  = .white
        refreshCtl.addTarget(self, action: #selector(ScrollViewController.refresh(sender:)), for: .valueChanged)
        scrollView.refreshControl = refreshCtl
        
        storage = Storage.storage()
        
        // ローディング開始
        let appearance = KRProgressHUD.appearance()
        appearance.activityIndicatorColors = [UIColor]([
            UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
            ])
        KRProgressHUD.show()
        
        // iOS11かどうかで分岐する
        let safeAreaInsets: UIEdgeInsets
        if #available(iOS 11, *) {
            safeAreaInsets = view.safeAreaInsets
            print(UIScreen.main.nativeBounds.height)
            
            // 新機種 レスポンシブ
            if UIScreen.main.nativeBounds.height == 2436 || UIScreen.main.nativeBounds.height == 2688 || UIScreen.main.nativeBounds.height == 1792 {
                bottomConstraint.constant = 83
            }
        } else {
            safeAreaInsets = .zero
        }
        print(safeAreaInsets)
        // ページスクロールとするためにページ幅を合わせる
        screenSize = UIScreen.main.bounds
        scrollScreenWidth = screenSize.width
        scrollScreenHeight = screenSize.height
        self.view.setGradientLayer()
        setAppGuide()
        setupFirebase()
    }
    
    
    
    func setAppGuide() {
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: Bundle(for: type(of: self)))
        appGuideView = communityXib.instantiate(withOwner: self, options: nil).first as? UIView
        appGuideView.isUserInteractionEnabled = true
        // 描画開始の x,y 位置
        let px:CGFloat = 0.0
        let py:CGFloat = 0.0
        
        // コミュニティー画像設定
        let imgView  = appGuideView.viewWithTag(2) as! UIImageView
        imgView.image = UIImage(named: "AppGuide")
        imgView.isUserInteractionEnabled = true
        
        // 描画開始設定
        var viewFrame:CGRect = appGuideView.frame
        viewFrame.size.width = self.scrollScreenWidth
        viewFrame.size.height = self.scrollScreenHeight
        viewFrame.origin = CGPoint(x: px, y: py)
        appGuideView.frame = viewFrame
        
        self.scrollView.addSubview(appGuideView)
        
        // スクロール範囲の設定
        let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(1)
        self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
    }
    
    func setupFirebase() {
        
        let communityXib = UINib(nibName: "CommunityTableViewCell", bundle: Bundle(for: type(of: self)))
        
        // 描画開始の x,y 位置
        let px:CGFloat = 0.0
        var py:CGFloat = 0.0
        
        var counter = 1
        
        guard RootTabBarController.locationFlg else {
            KRProgressHUD.dismiss()// ローディング終了
            return
        }
        
        db.collection("communities").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                KRProgressHUD.dismiss()// ローディング終了
                return
            }
            guard querySnapshot!.documents.count > 0 else {
                KRProgressHUD.dismiss()// ローディング終了
                return
            }
            
            for document in querySnapshot!.documents {
                print("\(document.documentID) => \(document.data())")
                let communityView = communityXib.instantiate(withOwner: self, options: nil).first as! UIView
                communityView.isUserInteractionEnabled = true
                
                let community = document.data()
                let documentId = document.documentID
                let latitude = community["latitude"] as! Double
                let longitude = community["longitude"] as! Double
                
                let baseLocation: CLLocation = CLLocation(latitude: RootTabBarController.latitude, longitude: RootTabBarController.longitude)
                let targetLocation: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distanceLocation = baseLocation.distance(from: targetLocation)
                print("距離は \(distanceLocation)")
                
                let radius = community["radius"] as! Double
                
                if radius < distanceLocation  {
                    print("県外")
                    continue
                }
                
                print("community: \(community)")
                
                // コミュニティー名設定
                let titleLabel = communityView.viewWithTag(1) as! UILabel
                let title = community["name"] as! String
                titleLabel.textColor = UIColor.white
                titleLabel.text = String(describing: title)
                // コミュニティー画像設定
                let img  = communityView.viewWithTag(2) as! UIImageView
                
                
                let storageRef = self.storage.reference()
                let imgRef: StorageReference!
                // 新機種 レスポンシブ
                if UIScreen.main.nativeBounds.height == 2436 || UIScreen.main.nativeBounds.height == 2688 || UIScreen.main.nativeBounds.height == 1792 {
                    imgRef = storageRef.child("communities").child(community["imgX"] as! String)
                }  else {
                    imgRef = storageRef.child("communities").child(community["img8"] as! String)
                }
                img.sd_setImage(with: imgRef)
                img.isUserInteractionEnabled = true
                img.frame.size.height = UIScreen.main.bounds.height
                
                let gesture = MyTapGestureRecognizer(target: self, action: #selector(ScrollViewController.btnClick(_:)))
                gesture.targetString = documentId
                communityView.addGestureRecognizer(gesture)
                communityView.tag = 1
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
                
                var appGuideViewFrame:CGRect = self.appGuideView.frame
                appGuideViewFrame.size.width = self.scrollScreenWidth
                appGuideViewFrame.size.height = self.scrollScreenHeight
                appGuideViewFrame.origin = CGPoint(x: px, y: py)
                self.appGuideView.frame = appGuideViewFrame
                
                // スクロール範囲の設定
                let nHeight:CGFloat = self.scrollScreenHeight * CGFloat(counter)
                self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: nHeight)
            
            }
            KRProgressHUD.dismiss()// ローディング終了
            
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
        
        //  ログイン済み
        if RootTabBarController.AuthCheck {
            // 仮登録状態の場合
            if RootTabBarController.UserInfo["status"] as? Int  == 0 {
                let modalViewController = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
                present(modalViewController, animated: true, completion: {
                    modalViewController.fromWhere = "RootTabBarController"
                })
                
            } else {
                tabBarController?.tabBar.isHidden = true
                performSegue(withIdentifier: "toChatViewController", sender: sender.targetString)
            }
        } else {
            
            let modalViewController = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            modalViewController.modalPresentationStyle = .custom
            modalViewController.transitioningDelegate = self
            present(modalViewController, animated: true, completion: nil)
        }
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        let subviews =  self.scrollView.subviews
        for view in subviews {
            if view.tag == 1 {
                view.removeFromSuperview()
            }
        }
        
        var appGuideViewFrame:CGRect = self.appGuideView.frame
        appGuideViewFrame.origin = CGPoint(x: 0, y: 0)
        self.appGuideView.frame = appGuideViewFrame
        self.scrollView.contentSize = CGSize(width: self.scrollScreenWidth, height: self.scrollScreenHeight)
        // ここが引っ張られるたびに呼び出される
        DispatchQueue.global().async {
            self.setupFirebase()
            Thread.sleep(forTimeInterval: 1.0)
            
            DispatchQueue.main.async {
                // 通信終了後、endRefreshingを実行することでロードインジケーター（くるくる）が終了
                sender.endRefreshing()
            }
        }
        
    }
    
}

extension ScrollViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return LoginPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
