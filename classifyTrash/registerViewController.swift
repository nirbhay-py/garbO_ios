//
//  registerViewController.swift
//  classifyTrash
//
//  Created by Nirbhay Singh on 26/06/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD


class registerViewController: UIViewController {

    @IBOutlet weak var nameTf: UITextField!
    @IBOutlet weak var emailTf: UITextField!
    @IBOutlet weak var pswdTf: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func registerBtnPressed(_ sender: Any) {
        if(nameTf.text==""||emailTf.text==""||pswdTf.text==""){
            showAlert(msg: "You can't leave these fields empty.")
        }
        else if(!(isValidEmail(emailTf.text!))){
            showAlert(msg: "Are you sure that's a valid email?")
        }else if(pswdTf.text!.count<8){
            showAlert(msg: "That password looks too small, enter one that's atleast 8 characters long.")
        }else if(nameTf.text!.count<3){
            showAlert(msg: "Are you sure that's your real name? Enter one that's at least 3 characters long.")
        }else{
            let hud = JGProgressHUD.init()
            hud.show(in: self.view)
            Auth.auth().createUser(withEmail: emailTf.text!, password: pswdTf.text!)
            {authResult, error in
                if(error != nil){
                    hud.dismiss()
                    showAlert(msg: "An error occured while signing up. The email address entered may already be in use or you may be facing connectivity issues.")
                    print("FailedToCreateUser:\(String(describing: error?.localizedDescription))")
                    
                }else{
                    hud.dismiss()
                    let db = Database.database().reference().child("user-node")
                    let userNode = db.child(splitString(str: self.emailTf.text!, delimiter: "."))
                    let userDic = [
                        "name":self.nameTf.text,
                        "plastics-scanned":0,
                        "items-scanned":0
                        ] as [String : Any]
                    userNode.setValue(userDic) { (error, ref) -> Void in
                        if(error != nil){
                            hud.dismiss()
                            showAlert(msg: "An error occured while signing up. You may be facing connectivity issues.")
                            print("FailedToWriteToFirebase:\(String(describing: error?.localizedDescription))")
                        }else{
                            showSuccess(msg: "Yay! You've successfully made a garbO account!")
                            globalUser = GarboUser(name: self.nameTf.text!, email: self.emailTf.text!, plasticScanned: 0, itemsScanned: 0)
                            print("RegistrationFinishedWithSuccess")
                            self.performSegue(withIdentifier: "registrationComplete", sender: nil)
                        }
                    }
                }
            }
        }
        
    }
}
