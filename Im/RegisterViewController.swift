//
//  RegisterViewController.swift
//  Im
//
//  Created by nobumitsu on が19/06/06.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import RSKImageCropper
import FirebaseFirestore
import KRProgressHUD

class RegisterViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var birthdayTextField: DatePickerKeyboard!
    @IBOutlet weak var sexTextField: UITextField!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    
    private let storageRef = Storage.storage().reference()
    private let db = Firestore.firestore()
    var sexArr = ["男性", "女性"]
    let pickerView = UIPickerView()
    var picker: UIImagePickerController! = UIImagePickerController()
    var changeImgFlg = false
    var selectedImageType: String!
    var fromWhere = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        view.setGradientLayer()
        wrapperView.layer.cornerRadius = 20
        nameTextField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        sexTextField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        birthdayTextField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        registerBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )
        
        self.imgView.layer.cornerRadius = self.imgView.frame.size.width * 0.5
        self.imgView.clipsToBounds = true
        imgBtn.imageEdgeInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)// ボタンの画像縮小
        imgBtn.layer.cornerRadius = self.imgView.frame.size.width * 0.5
        wrapperView.layer.cornerRadius = 20
        
        nameTextField.text = RootTabBarController.UserInfo["name"] as? String
        
        let imageView = UIImageView()
        let image = UIImage(named: "RegisterPicker")
        imageView.image = image
        imageView.frame = CGRect(x: CGFloat(birthdayTextField.frame.size.width - 50), y: CGFloat(30), width: CGFloat(25), height: CGFloat(25))
        birthdayTextField.rightView = imageView
        birthdayTextField.rightViewMode = UITextField.ViewMode.always
        
        if RootTabBarController.UserInfo["img"] as? String !=  "" {
            let ref = storageRef.child("users/\(RootTabBarController.UserInfo["img"] as! String)")
            imgView.sd_setImage(with: ref)
        } else {
            imgView.image =  UIImage(named: "UserImg")
        }
        
        initField(textField: sexTextField)
        birthdayTextField.datePicker.addTarget(self, action: #selector(setText), for: .valueChanged)
    }
    
    func initField (textField: UITextField) {
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        textField.inputView = pickerView
        textField.inputAccessoryView = createToolbar()
        textField.tintColor = .clear
        
        let imageView = UIImageView()
        let image = UIImage(named: "RegisterPicker")
        imageView.image = image
        imageView.frame = CGRect(x: CGFloat(textField.frame.size.width - 50), y: CGFloat(30), width: CGFloat(25), height: CGFloat(25))
        textField.rightView = imageView
        textField.rightViewMode = UITextField.ViewMode.always
        
    }
    
    // datePickerの日付けをtextFieldのtextに反映させる
    @objc private func setText() {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "ja")
        birthdayTextField.text = f.string(from: birthdayTextField.datePicker.date)
    }
    

    @IBAction func register(_ sender: Any) {
        
        guard nameTextField.text != "" else {
            showMessagePrompt(message: "名前を入力してください")
            return
        }
        
        guard sexTextField.text != "" else {
            showMessagePrompt(message: "性別を選択してください")
            return
        }
        
        // ローディング開始
        let appearance = KRProgressHUD.appearance()
        appearance.activityIndicatorColors = [UIColor]([
            UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
            ])
        KRProgressHUD.show()
        
        let name = nameTextField.text!
        let sex  = sexTextField.text!
        
        var birthday = 0
        if birthdayTextField.text != "" {
            birthday = birthdayToInt(birthdayStr: birthdayTextField.text!)
        }
        
        if changeImgFlg {
        // 画像変更 あり
                
            // リサイズ
            var img = self.imgView.image
            if self.imgView.image?.size.width ?? 0 > CGFloat(1024) {
                let aspect = self.imgView.image!.size.height / self.imgView.image!.size.width
                img = self.imgView.image?.resize(size: CGSize(width: CGFloat(1024), height: CGFloat(1024) * aspect))
            }
                
            // jpeg変換
            guard let imgData = img?.jpegData(compressionQuality: 0.7) else {
                return
            }

            let date = Date().toStringDateImg()
            let fileName = RootTabBarController.UserId + date + ".jpg"
            let meta = StorageMetadata()
            meta.contentType = "image/jpeg"
            // アップロード
            let ref = self.storageRef.child("users").child(fileName)
            ref.putData(imgData, metadata: meta, completion: { metaData, error in
                
                if error != nil {
                    print(error!.localizedDescription)
                    KRProgressHUD.dismiss()// ローディング終了
                    return
                }
                
                // プロフ画URL取得
                ref.downloadURL(completion: { (url, err) in
                    
                    if let err = err {
                        print(err.localizedDescription)
                        KRProgressHUD.dismiss()// ローディング終了
                        return
                    }
                    
                    // DB 本登録
                    self.db.collection("users").document(RootTabBarController.UserId).updateData(
                        ["name": name, "birthday": birthday, "sex": sex, "status": 1, "img": fileName, "imgUrl": url!.absoluteString]
                    ) { err in
                        
                        if let err = err {
                            print("Error updating document: \(err)")
                            KRProgressHUD.dismiss()// ローディング終了
                            return
                        }
                        
                        RootTabBarController.UserInfo["name"] = name
                        RootTabBarController.UserInfo["birthday"] = birthday
                        RootTabBarController.UserInfo["imgUrl"] = url!.absoluteString
                        RootTabBarController.UserInfo["sex"] = sex
                        RootTabBarController.UserInfo["status"] = 1
                        
                        // プロフィール画像が空の場合
                        guard RootTabBarController.UserInfo["img"] as? String != ""  else {
                            RootTabBarController.UserInfo["img"] = fileName
                            // 仮登録直後の電話番号認証から
                            if self.fromWhere == "PhoneNumberCheckViewController" {
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController!.presentingViewController!.presentingViewController as! RootTabBarController
                                self.presentingViewController!.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            } else if self.fromWhere == "snsAuth" {
                                // 仮登録直後のSNS認証から
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController!.presentingViewController as! RootTabBarController
                                self.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            } else {
                                // 仮登録のままだったユーザー
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController as! RootTabBarController
                                self.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            }
                            return
                        }
                        
                        // 既存ファイル削除
                        self.storageRef.child("users").child(RootTabBarController.UserInfo["img"] as! String).delete { delError in
                            if let delError = delError {
                                // Uh-oh, an error occurred!
                                print(delError.localizedDescription)
                            }
                            
                            RootTabBarController.UserInfo["img"] = fileName
                            // 仮登録直後の電話番号認証から
                            if self.fromWhere == "PhoneNumberCheckViewController" {
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController!.presentingViewController!.presentingViewController as! RootTabBarController
                                self.presentingViewController!.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            } else if self.fromWhere == "snsAuth" {
                                // 仮登録直後のSNS認証から
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController!.presentingViewController as! RootTabBarController
                                self.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            } else {
                                // 仮登録のままだったユーザー
                                KRProgressHUD.dismiss()// ローディング終了
                                let referenceForTabBarController = self.presentingViewController as! RootTabBarController
                                self.dismiss(animated: true, completion: {
                                    referenceForTabBarController.selectedIndex = 3
                                })
                            }
                            
                        }
                        
                    }
                })

                
            })

        } else {
        // 画像変更 なし
            // DB 本登録
            self.db.collection("users").document(RootTabBarController.UserId).updateData(["name": name, "birthday": birthday, "sex": sex, "status": 1]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                    KRProgressHUD.dismiss()// ローディング終了
                    return
                }
                
                RootTabBarController.UserInfo["name"] = name
                RootTabBarController.UserInfo["birthday"] = birthday
                RootTabBarController.UserInfo["sex"] = sex
                RootTabBarController.UserInfo["status"] = 1
                
                // 仮登録直後の場合
                if self.fromWhere == "PhoneNumberCheckViewController" {
                    KRProgressHUD.dismiss()// ローディング終了
                    let referenceForTabBarController = self.presentingViewController!.presentingViewController!.presentingViewController as! RootTabBarController
                    self.presentingViewController!.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: {
                        referenceForTabBarController.selectedIndex = 3
                    })
                } else if self.fromWhere == "snsAuth" {
                    KRProgressHUD.dismiss()// ローディング終了
                    let referenceForTabBarController = self.presentingViewController!.presentingViewController as! RootTabBarController
                    self.presentingViewController!.presentingViewController!.dismiss(animated: false, completion: {
                        referenceForTabBarController.selectedIndex = 3
                    })
                } else {
                    KRProgressHUD.dismiss()// ローディング終了
                    let referenceForTabBarController = self.presentingViewController as! RootTabBarController
                    self.dismiss(animated: true, completion: {
                        referenceForTabBarController.selectedIndex = 3
                    })
                }
            }
        }
//        self.tabBarController?.selectedIndex = 3
    }
    
    // textfile以外の部分をタッチ
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // キーボードを閉じる
        self.view.endEditing(true)
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
            selectedImageType = imageType.pathExtension
            self.dismiss(animated: false)
            present(imageCropVC, animated: true)
        } else {
            print("error")
        }
        
    }
    
    func birthdayToInt(birthdayStr:String) -> Int {
        let componentsYear = birthdayStr.components(separatedBy: "年")
        let componentsMonth = componentsYear[1].components(separatedBy: "月")
        
        let year = componentsYear[0]
        let month = String(format: "%02d", Int(componentsMonth[0])!)
        let day = String(format: "%02d", Int(componentsMonth[1].replacingOccurrences(of: "日", with: ""))!)
        
        return Int(year+month+day) ?? 0
    }
    
    // カーソル非表示
    func caretRect(for position: UITextPosition) -> CGRect {
        print("カーソル")
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
}

extension RegisterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // キーボードのアクセサリービューを作成する
    func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 44)
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        space.width = 12
        let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneButtonItem = UIBarButtonItem(title: "完了",style: .done, target: self, action: #selector(done))
        let toolbarItems = [flexSpaceItem, doneButtonItem, space]
        
        toolbar.setItems(toolbarItems, animated: true)
        
        return toolbar
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sexArr.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sexArr[row]
    }
    // 選択時
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sexTextField.text = sexArr[row]
    }
    
    @objc func done() {
        // キーボードを閉じる
        sexTextField.text = sexArr[pickerView.selectedRow(inComponent: 0)]
        self.view.endEditing(true)
    }
    
}


extension RegisterViewController: RSKImageCropViewControllerDelegate {
    //キャンセルを押した時の処理
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    //完了を押した後の処理
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        
        changeImgFlg = true
        print("画像変更")
        self.imgView.image = croppedImage
        dismiss(animated: true)
    }
}
