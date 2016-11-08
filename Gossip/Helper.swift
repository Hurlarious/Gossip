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

class Helper {
    
    static let helper = Helper()
    
    func loginAnonymously() {
        
        print("login anon tapped")
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (anonymousUser: FIRUser?, error: NSError?) in
            
            if error == nil {
                
                print("UserID: \(anonymousUser!.uid)")
                self.switchToNavigationViewController()
                
            } else {
                
                print(error!.localizedDescription)
                return
            }
        })
    }
    
    func loginWithGoogle(authetication: GIDAuthentication) {
        
        let credential = FIRGoogleAuthProvider.credentialWithIDToken(authetication.idToken, accessToken: authetication.accessToken)
        
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user: FIRUser?, error: NSError?) in
            if error != nil {
                
                print(error!.localizedDescription)
                return
                
            } else {
                
                print(user?.email)
                print(user?.displayName)
                
                self.switchToNavigationViewController()
            }
        })
    }
    
    
    private func switchToNavigationViewController() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewControllerWithIdentifier("navigationVC") as! UINavigationController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = navigationVC
    }
    
    

    
}