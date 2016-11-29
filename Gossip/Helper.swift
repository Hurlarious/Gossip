//
//  Helper.swift
//  
//
//  Created by Dave Hurley on 2016-11-07.
//
//

import Foundation
import FirebaseAuth
import UIKit
import GoogleSignIn
import FirebaseDatabase

class Helper {
    
    static let helper = Helper()
    
    func loginAnonymously() {
        
        print("login anon tapped")
        
        FIRAuth.auth()?.signInAnonymously(completion: { (anonymousUser, error) in
            
            if error == nil {
                
                print("UserID: \(anonymousUser!.uid)")
                
                let newUser = FIRDatabase.database().reference().child("users").child(anonymousUser!.uid)
                newUser.setValue(["displayName" : "Anon" , "id" : "\(anonymousUser!.uid)" , "profileUrl" : ""])
                
                self.switchToNavigationViewController()
                
            } else {
                
                print(error!.localizedDescription)
                return
            }
        })
    }
    
    func loginWithGoogle(_ authetication: GIDAuthentication) {
        
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authetication.idToken, accessToken: authetication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                
                print(error!.localizedDescription)
                return
                
            } else {
                
                print(user?.email)
                print(user?.displayName)
                print(user?.photoURL)
                
                let newUser = FIRDatabase.database().reference().child("users").child(user!.uid)
                newUser.setValue(["displayName" : "\(user!.displayName!)" , "id" : "\(user!.uid)" , "profileUrl" : "\(user!.photoURL!)"])
                
                self.switchToNavigationViewController()
            }
        })
    }
    
    
    func switchToNavigationViewController() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "navigationVC") as! UINavigationController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = navigationVC
    }
    
    

    
}
