//
//  firstViewController.swift
//  classifyTrash
//
//  Created by Nirbhay Singh on 26/06/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//
var globalUser:GarboUser!
import UIKit
import Firebase
import JGProgressHUD

class firstViewController: UIViewController {
    @IBOutlet weak var emailTf: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var pswdTf: UITextField!
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
//        let firebaseAuth = Auth.auth()
//        do {
//          try firebaseAuth.signOut()
//        } catch let signOutError as NSError {
//          print ("Error signing out: %@", signOutError)
//        }
          
        
        if(Auth.auth().currentUser != nil){
            print("UserAlreadyLoggedIn:\(String(describing: Auth.auth().currentUser?.email))")
            hideElements()
            let sanitisedEmail:String=splitString(str: (Auth.auth().currentUser?.email)!, delimiter: ".")
            print("SanitisedEmail:\(sanitisedEmail)")
            let db = Database.database().reference().child("user-node")
            let userNode = db.child(sanitisedEmail)
            userNode.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let username = value?["name"] as? String ?? "Error"
                let plasticsScanned = value?["plastics-scanned"] as? Int ?? 0
                let itemsScanned = value?["items-scanned"] as? Int ?? 0
                globalUser = GarboUser(name: username, email: self.emailTf.text!, plasticScanned: plasticsScanned, itemsScanned: itemsScanned)
                print("UserDataFetchedWithSuccess")
                self.performSegue(withIdentifier: "loginComplete", sender: nil)
              }) { (error) in
                print("ErrorOccuredWhileFetchingUserData:\(String(describing: error.localizedDescription))")
                showAlert(msg: "We were unable to sign you in, it looks like you may have connectivity.")
            }
            print("UserDetectedThreadFinished")
        }else{
            print("UserNotLoggedIn/nProceedToNormalLoginThread")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    @IBAction func loginPressed(_ sender: Any) {
        if(emailTf.text==""||pswdTf.text==""){
            showAlert(msg: "You can't leave these fields empty.")
        }else if(!(isValidEmail(emailTf.text!))){
            showAlert(msg: "Are you sure that's a valid email? Try again.")
        }else{
            let hud = JGProgressHUD.init()
            hud.show(in:self.view)
            Auth.auth().signIn(withEmail: emailTf.text!, password: pswdTf.text!) { [weak self] authResult, error in
                if(error != nil){
                    print("UserLoggedIn:\(String(describing: Auth.auth().currentUser?.email))\nAttemptingToAccessUserDataFromFirebase")
                    let sanitisedEmail:String=splitString(str: (Auth.auth().currentUser?.email)!, delimiter: ".")
                    print("SanitisedEmail:\(sanitisedEmail)")
                    let db = Database.database().reference().child("user-node")
                    let userNode = db.child(sanitisedEmail)
                    userNode.observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        let username = value?["name"] as? String ?? "Error"
                        let plasticsScanned = value?["plastics-scanned"] as? Int ?? 0
                        let itemsScanned = value?["items-scanned"] as? Int ?? 0
                        globalUser = GarboUser(name: username, email: self!.emailTf.text!, plasticScanned: plasticsScanned, itemsScanned: itemsScanned)
                        print("UserDataFetchedWithSuccess")
                        self!.performSegue(withIdentifier: "loginComplete", sender: nil)
                      }) { (error) in
                        print("ErrorOccuredWhileFetchingUserData:\(String(describing: error.localizedDescription))")
                        showAlert(msg: "We were unable to sign you in, it looks like you may have connectivity.")
                    }
                    print("UserDetectedThreadFinished")
                }else{
                    hud.dismiss()
                    showAlert(msg: "An error occured while signing up. You may have entered incorrect credentials or may be facing internet problems.")
                }
            }
        }
    }
    func hideElements(){
        self.emailTf.isHidden = true
        self.loginBtn.isHidden = true
        self.registerBtn.isHidden = true
        self.pswdTf.isHidden = true
    }
}
