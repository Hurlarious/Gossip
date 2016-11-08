//
//  LoginViewController.swift
//  Gossip
//
//  Created by Dave Hurley on 2016-11-07.
//  Copyright © 2016 Dave Hurley. All rights reserved.
//

import UIKit
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    // MARK: - Variables/Properties/Outlets
    
    @IBOutlet weak var anonButton: UIButton!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        
        super.viewDidLoad()
        anonButton.layer.borderWidth = 1.0
        anonButton.layer.borderColor = UIColor.whiteColor().CGColor
        GIDSignIn.sharedInstance().clientID = "320128774959-kdqagft8n72phipqi363tetk1gjlf6ep.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self

    }

    // MARK: - Actions
    
    @IBAction func loginAnonymouslyTapped(sender: UIButton) {
        
        print("login anon tapped")
        Helper.helper.loginAnonymously()
        
    }
    
    @IBAction func googleLoginTapped(sender: UIButton) {
        
        print("google login tapped")
        GIDSignIn.sharedInstance().signIn()
    }
    

    
    // MARK: - Delegate Functions
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        
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
