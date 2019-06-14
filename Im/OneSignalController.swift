//
//  OneSignalController.swift
//  Im
//
//  Created by nobumitsu on 2019/06/11.
//  Copyright © 2019 im. All rights reserved.
//

import Foundation
import Firebase

func updateOneSignalId() {
    guard Auth.auth().currentUser != nil else {
        return
    }
    if let pushId = UserDefaults.standard.string(forKey: "pushID") {
        setOneSignalId(pushId: pushId)
    } else {
        removeOneSignalId()
    }
}

func setOneSignalId(pushId: String) {
//    updateCurrentUserOneSignalId(newId: pushId)
}

func removeOneSignalId() {
//    updateCurrentUserOneSignalId(newId: "")
}

//func updateCurrentUserOneSignalId(newId: String) {
//    print(newId)
////    updateCurrentUserInFireStore(withValues: ["pushID": newId]) { (error) in
////        if error != nil {
////            print("error updating push id \(error!.localizedDescription)")
////        }
////    }
//}
