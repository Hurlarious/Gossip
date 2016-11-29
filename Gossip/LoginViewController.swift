//
//  LoginViewController.swift
//  Gossip
//
//  Created by Dave Hurley on 2016-11-07.
//  Copyright © 2016 Dave Hurley. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    // MARK: - Variables/Properties/Outlets
    
    @IBOutlet weak var anonButton: UIButton!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        
        super.viewDidLoad()
        anonButton.layer.borderWidth = 1.0
        anonButton.layer.borderColor = UIColor.white.cgColor
        GIDSignIn.sharedInstance().clientID = "320128774959-kdqagft8n72phipqi363tetk1gjlf6ep.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(FIRAuth.auth()?.currentUser)
        
        FIRAuth.auth()?.addStateDidChangeListener({ (auth: FIRAuth, user: FIRUser?) in
            if user != nil {
                print(user)
                Helper.helper.switchToNavigationViewController()
                
            } else  {
                print("unauthorized")
            }
        })
    }

    // MARK: - Actions
    
    @IBAction func loginAnonymouslyTapped(_ sender: UIButton) {
        
        print("login anon tapped")
        Helper.helper.loginAnonymously()
        
    }
    
    @IBAction func googleLoginTapped(_ sender: UIButton) {
        
        print("google login tapped")
        GIDSignIn.sharedInstance().signIn()
    }
    

    
    // MARK: - Delegate Functions
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if error != nil {
            print(error.localizedDescription)
            return
        }
        
        print(user.authentication)
        Helper.helper.loginWithGoogle(user.authentication)

    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
