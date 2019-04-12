//
//  EditProfileViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/04/08.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import RSKImageCropper

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var ref: DatabaseReference!
    var picker: UIImagePickerController! = UIImagePickerController()
    var nowName: String!
    var changeFlg = false
    var selectedImageType: String!
    let storage = Storage.storage()
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let border = CALayer()
        let width = CGFloat(2.0)
        
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height*1.5, width:  textField.frame.size.width, height: 1)
        border.borderWidth = width
        textField.layer.addSublayer(border)
        
        setupFirebase()
    }
    
    func setupFirebase() {
        ref = Database.database().reference()
        ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.exists())
            if snapshot.exists() {
                
            } else {
                // 画像設定
                let img = UIImage(named: "UserImg")
                self.imgView.image = img
                
                // 角丸にする
                self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
                self.imgView.clipsToBounds = true
                
                self.textField.text =  "未設定"
                self.nowName = "未設定"
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @IBAction func selectImg(_ sender: Any) {
        //PhotoLibraryから画像を選択
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        
        //デリゲートを設定する
        picker.delegate = self
        
        //現れるピッカーNavigationBarの文字色を設定する
        picker.navigationBar.tintColor = UIColor.white
        
        //現れるピッカーNavigationBarの背景色を設定する
        picker.navigationBar.barTintColor = UIColor.gray
        
        //ピッカーを表示する
        present(picker, animated: true, completion: nil)
    }
    
    //画像が選択された時に呼ばれる.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            let imageType = (info[.imageURL] as! NSURL).absoluteString! as NSString
            let imageCropVC = RSKImageCropViewController(image: image, cropMode: .circle)
            imageCropVC.moveAndScaleLabel.text = "切り取り範囲を選択"
            imageCropVC.cancelButton.setTitle("キャンセル", for: .normal)
            imageCropVC.chooseButton.setTitle("完了", for: .normal)
            imageCropVC.delegate = self
            changeFlg = true
            selectedImageType = imageType.pathExtension
            self.dismiss(animated: false)
            present(imageCropVC, animated: true)
        } else {
            print("error")
        }

    }
    
    @IBAction func saveProfile(_ sender: Any) {
        let getName = textField.text
        let userID = RootTabBarController.userId
        // 名前の変更がある場合
        if getName != nowName {
//            let post = ["name": getName]
            let childUpdates = ["/users/\(userID)/name/": getName]
            ref.updateChildValues(childUpdates as [AnyHashable : Any])
        }
        if changeFlg {
            let childUpdates = ["/users/\(userID)/img/": userID+"."+selectedImageType]
            ref.updateChildValues(childUpdates as [AnyHashable : Any])
            let storageRef = storage.reference().child("users")
            // UIImagePNGRepresentationでUIImageをNSDataに変換
            if let data = self.imgView.image!.pngData() {
                let reference = storageRef.child(userID+"."+self.selectedImageType)
                reference.putData(data, metadata: nil, completion: { metaData, error in
                    
                })
            }
            // 一つ前のViewControllerに戻る
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    // textfile以外の部分をタッチ
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        self.view.endEditing(true)
    }
}

extension EditProfileViewController: RSKImageCropViewControllerDelegate {
    //キャンセルを押した時の処理
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    //完了を押した後の処理
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        dismiss(animated: true)
        imgView.image = croppedImage
    }
}
