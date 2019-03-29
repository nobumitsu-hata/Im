//
//  CreateViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/23.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseDatabase

class CreateViewController: UIViewController {
    
    var locationManager: CLLocationManager!
    var selectedImage: UIImage!
    var selectedImageType: String!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    
    var latitude: String!
    var longitude: String!
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        // 初期化
        ref = Database.database().reference()
        setupLocationManager()
        
        let border = CALayer()
        let width = CGFloat(2.0)
        
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: nameTextField.frame.size.height*1.5, width:  nameTextField.frame.size.width, height: 1)
        border.borderWidth = width

        nameTextField.layer.addSublayer(border)
        nameTextField.attributedPlaceholder = NSAttributedString(string: "コミュニティー名を入力", attributes: [NSAttributedString.Key.foregroundColor : UIColor(displayP3Red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)])
        selectedImageView.image = selectedImage
        selectedImageView.contentMode = UIView.ContentMode.scaleAspectFit
    }

    // コミュニティー作成ボタンを押した場合
    @IBAction func createCommunity(_ sender: UIButton) {
        let name = nameTextField.text
        // ユニークキー自動生成
        let key = ref.child("communities").childByAutoId().key
        // DBに書き込み
        self.ref.child("communities").child(key!).setValue(["name":name!,"img":key!+"."+selectedImageType]) {
            (error:Error?, ref:DatabaseReference) in
            // エラー
            if let error = error {
                print("Data could not be saved: \(error).")
            } else {
            // 成功
                print("Data saved successfully!")
                let storage = Storage.storage()
                let storageRef = storage.reference().child("communities")
                // UIImagePNGRepresentationでUIImageをNSDataに変換
                if let data = self.selectedImageView.image!.pngData() {
                    let reference = storageRef.child(key!+"."+self.selectedImageType)
                    reference.putData(data, metadata: nil, completion: { metaData, error in
                        self.ref.child("locations").child(key!).setValue(["latitude":self.latitude, "longitude":self.longitude, "radius":200])
                        print(metaData as Any)
                        print(error as Any)
                    })
                }
                // 画像を空にする
                self.selectedImageView.image = nil
                // 閉じる
                self.dismiss(animated: true)
            }
        }
        
    }
    
    func setupLocationManager() {
        // 初期化
        locationManager = CLLocationManager()
        // 初期化に成功しているかどうか
        guard let locationManager = locationManager else { return }
        // 位置情報を許可するリクエスト
        locationManager.requestWhenInUseAuthorization()
        
        let status = CLLocationManager.authorizationStatus()
        // ユーザから「アプリ使用中の位置情報取得」の許可が得られた場合
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            // 管理マネージャが位置情報を更新するペース
            locationManager.distanceFilter = 20// メートル単位
            // 位置情報の取得を開始
            locationManager.startUpdatingLocation()
        }
    }
    
    // textfile以外の部分をタッチ
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
}

extension CreateViewController: CLLocationManagerDelegate {
    
    // 位置情報を取得・更新するたびに呼ばれる
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        latitude = String(describing: location!.coordinate.latitude)
        longitude = String(describing: location!.coordinate.longitude)
        
        print("latitude: \(latitude!)\nlongitude: \(longitude!)")
    }
    
    
    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .notDetermined:
//            print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
//            // 許可を求めるコードを記述する（後述）
//            break
//        case .denied:
//            print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
//            // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
//            break
//        case .restricted:
//            print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
//            // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
//            break
//        case .authorizedAlways:
//            print("常時、位置情報の取得が許可されています。")
//            // 位置情報取得の開始処理
//            break
//        case .authorizedWhenInUse:
//            print("起動時のみ、位置情報の取得が許可されています。")
//            // 位置情報取得の開始処理
//            break
//        }
//    }
}
//extension UIColor {
//    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
//        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
//    }
//}
