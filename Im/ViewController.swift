//
//  ViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/03/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseUI

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePickUpButton:UIButton = UIButton()
    var picker: UIImagePickerController! = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //basicボタンが押されたら呼ばれます
//    func imagePickUpButtonClicked(sender: UIButton){
//
//        //PhotoLibraryから画像を選択
//        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
//
//        //デリゲートを設定する
//        picker.delegate = self
//
//        //現れるピッカーNavigationBarの文字色を設定する
//        picker.navigationBar.tintColor = UIColor.white
//
//        //現れるピッカーNavigationBarの背景色を設定する
//        picker.navigationBar.barTintColor = UIColor.gray
//
//        //ピッカーを表示する
//        present(picker, animated: true, completion: nil)
//    }
    
    

}

