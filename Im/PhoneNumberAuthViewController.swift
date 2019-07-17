//
//  MobileAuthViewController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/06.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import CoreTelephony

class PhoneNumberAuthViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var requestBtn: UIButton!
    
    var phoneNumber: String!
    var verificationId: String?
    var fullNumber:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        
        view.setGradientLayer()
        wrapperView.layer.cornerRadius = 20
        phoneNumberTextField.borderGradient(
            startColor: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            endColor: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0),
            radius: 0
        )
        requestBtn.setGradientBackground(
            colorOne: UIColor(displayP3Red: 147/255, green: 6/255, blue: 229/255, alpha: 1.0),
            colorTwo: UIColor(displayP3Red: 23/255, green: 232/255, blue: 252/255, alpha: 1.0)
        )
        self.navigationController?.navigationBar.barTintColor = .clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(),for: .any,barMetrics: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layer.borderColor = UIColor.clear.cgColor
    }

    
    @IBAction func sentMail(_ sender: Any) {
        
        // request code
        if phoneNumberTextField.text != "" {
            
            phoneNumber = phoneNumberTextField.text
            fullNumber = "+81" + String(phoneNumber.suffix(phoneNumber.count - 1))
            
            Auth.auth().languageCode = "ja"
            PhoneAuthProvider.provider().verifyPhoneNumber(fullNumber, uiDelegate: nil) { (verificationID, error) in

                if let error = error {
                    print(error.localizedDescription)
                    self.showMessagePrompt(message: "正しい番号を入力してください")
                    return
                }
                // Sign in using the verificationID and the code sent to the user
                self.verificationId = verificationID
                self.performSegue(withIdentifier: "toPhoneNumberCheckViewController", sender: verificationID)
                
            }
        } else {
            showMessagePrompt(message: "番号を入力してください")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toPhoneNumberCheckViewController" {
            let phoneNumberCheckViewController = segue.destination as! PhoneNumberCheckViewController
            phoneNumberCheckViewController.verificationId = sender as? String ?? ""
            phoneNumberCheckViewController.phoneNumber = fullNumber
        }
    }
    
    @IBAction func closeViewController(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension UIViewController {
    func showMessagePrompt(message: String) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        (navigationController ?? self)?.present(alertController, animated: true, completion: nil)
    }
}
