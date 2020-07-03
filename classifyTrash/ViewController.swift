//
//  ViewController.swift
//  classifyTrash
//
//  Created by Nirbhay Singh on 25/06/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import CoreML
import VisionKit
import JGProgressHUD
import Firebase

class ViewController: UIViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate{
    @IBOutlet weak var classLbl: UILabel!

    @IBOutlet weak var confidenceLbl: UILabel!
    var pred:String=""
    @IBOutlet weak var lbl4: UILabel!
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var plasticLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoBtn: UIButton!
    var img:UIImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        changeState(state: true,plas:true)
        print("globalUserEmail:\(String(describing: globalUser.email))")
    }
    func changeState(state:Bool,plas:Bool)
    {
        self.classLbl.isHidden = state
        self.lbl1.isHidden = state
        self.lbl2.isHidden = plas
        self.lbl4.isHidden = state
        self.lbl3.isHidden = state
        self.infoBtn.isHidden = state
        self.plasticLbl.isHidden = plas
        self.confidenceLbl
            .isHidden = state
    }

    @IBAction func camBtnPressed(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @IBAction func profileBtnPressed(_ sender: Any) {
        showInfo(msg: """
            You've scanned \(globalUser.itemsScanned!) items with garbO
            
            Out of which \(globalUser.plasticScanned!) were plastic items.
            """, title: "Your stats")
    }
    @IBAction func doneBtnPressed(_ sender: Any) {
        if(self.img==nil){
            showAlert(msg: "You can't carry on without taking an image.")
            return
        }
        changeState(state: true, plas: true)
        let hud = JGProgressHUD.init()
        hud.show(in: self.view)
        let trashModel = trashClassifier()
        let plasticModel = plasticClassifier()
        self.img = self.img.resizeImage(targetSize: CGSize(width:299, height:299))
        print("ModifiedSize:\(self.img.size)")
        guard let imgBuffer = buffer(from: self.img) else {
            print("CouldNotConvertToCVPixelBuffer")
            showAlert(msg:"An unexpected error occured. Please try again.")
            hud.dismiss()
            return
        }
        guard let trashPrediction = try? trashModel.prediction(image: imgBuffer) else{
            print("FatalErrorOccured")
            showAlert(msg:"An unexpected error occured. Please try again.")
            hud.dismiss()
            return
        }
        print("PredictedClass:\(trashPrediction.classLabel)")
        self.pred = trashPrediction.classLabel
        var confidence = trashPrediction.classLabelProbs[trashPrediction.classLabel]
        confidence! *= 100
        confidence! = confidence!.round(to: 2)
        let cString:String = String(format:"%.1f", confidence as! CVarArg)
        print("Confidence:\(confidence!))")
        var plasticsScanned:Int!
        var itemsScanned:Int!
        if(trashPrediction.classLabel != "plastic"){
            showSuccess(msg:"Yay! We know what that looks like!")
            changeState(state: false, plas: true)
            self.classLbl.text = trashPrediction.classLabel + " trash"
            self.confidenceLbl.text = String(cString) + "%"
            let userNode = Database.database().reference().child("user-node").child(splitString(str: globalUser.email, delimiter: "."))
            userNode.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                plasticsScanned = value?["plastics-scanned"] as? Int ?? 0
                itemsScanned = value?["items-scanned"] as? Int ?? 0
                print("UserDataFetchedWithSuccess")
                let updates:[String:Any]=["items-scanned":itemsScanned+1]
                
                userNode.updateChildValues(updates) {(error,ref) in
                    if(error != nil){
                        hud.dismiss()
                        showAlert(msg: "We were unable to connect to our servers, you may be facing connectivity issues at the moment.")
                        print("ErrorOccuredWhileUpdatingUserData:\(String(describing: error!.localizedDescription))")
                    }else{
                        hud.dismiss()
                        globalUser.itemsScanned+=1
                        
                    }
                }
              }) { (error) in
                print("ErrorOccuredWhileFetchingUserData:\(String(describing: error.localizedDescription))")
                hud.dismiss()
                showAlert(msg: "We were unable to connect to our servers, you may be facing connectivity issues at the moment.")
                
            }
            

            hud.dismiss()
        }
        else{
            changeState(state: false, plas: false)
            print("PlasticDetected\nRunningPlasticClassifer")
            guard let plasticPrediction = try? plasticModel.prediction(image: imgBuffer)
            else {
                print("FatalErrorOccured")
                showAlert(msg:"An unexpected error occured. Please try again.")
                hud.dismiss()
                return
            }
            print("PredictedPlasticClass:\(plasticPrediction.classLabel)")
            showSuccess(msg:"Yay! We know what that looks like!")
            var confidence = plasticPrediction.classLabelProbs[plasticPrediction.classLabel]
            confidence! *= 100
            confidence! = confidence!.round(to: 2)
            let cString:String = String(format:"%.1f", confidence as! CVarArg)
            print("Confidence:\(confidence!))")
            changeState(state: false, plas: false)
            self.classLbl.text = trashPrediction.classLabel + " trash"
            var plasticType = plasticPrediction.classLabel
            self.plasticLbl.text = "a " + sanitisePlasticInput(str:plasticType)
            self.confidenceLbl.text = String(cString) + "%"
            let userNode = Database.database().reference().child("user-node").child(splitString(str: globalUser.email, delimiter: "."))
            userNode.observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                plasticsScanned = value?["plastics-scanned"] as? Int ?? 0
                itemsScanned = value?["items-scanned"] as? Int ?? 0
                print("UserDataFetchedWithSuccess")
                let updates:[String:Any]=["items-scanned":itemsScanned+1,"plastics-scanned":plasticsScanned+1]
                userNode.updateChildValues(updates) {(error,ref) in
                    if(error != nil){
                        hud.dismiss()
                        showAlert(msg: "We were unable to connect to our servers, you may be facing connectivity issues at the moment.")
                        print("ErrorOccuredWhileUpdatingUserData:\(String(describing: error!.localizedDescription))")
                    }else{
                        hud.dismiss()
                        globalUser.plasticScanned+=1
                        globalUser.itemsScanned+=1
                    }
                }
              }) { (error) in
                print("ErrorOccuredWhileFetchingUserData:\(String(describing: error.localizedDescription))")
                hud.dismiss()
                showAlert(msg: "We were unable to connect to our servers, you may be facing connectivity issues at the moment.")
                
            }
            hud.dismiss()
        }
        print("DetectionProcessedFinishedWithSuccess")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        print("OriginalSize:\(image.size)")
        self.imageView.image = image
        self.imageView.roundedImage()
        self.imageView.borderWidth = 5
        self.imageView.borderColor = UIColor.white
        changeState(state: true, plas: true)
        self.img = image
    }
    func sanitisePlasticInput(str:String)->String{
        var newStr = ""
        for char in str{
            if(char != "_"){
                newStr = newStr + String(char)
            }else{
                newStr = newStr + " "
            }
        }
        return newStr
    }
    @IBAction func infoBtnPressed(_ sender: Any) {
        var msg:String!
        if(self.pred=="cardboard"){
            showInfo(msg: """
            Yes! Cardboard can be recycled in fact it can be recycled up to 5 times.

            A country can create upto 400 billion square feet of cardboard in a year!

            By recycling cardboard, you would be saving 50% of the pollution that would have been released if you trashed it!
        """, title: "Recycle it!")
        }else if(self.pred=="plastic")
        {
            showInfo(msg: """
            More than 8 million tonnes of plastic is dumped into the ocean every year!

            Only 8% of totally recyclable plastic actually ends up getting recycled

            Over 90% of bird species are chewing on your plastic right now!

            """, title: "Recycle it!")
        }else if(self.pred=="organic"){
            showInfo(msg: """
            Try finding a compost site nearby!

            You can save over 25% of your waste if you decide to compost your organic waste

            You can save 10 people from respiratory diseases. This waste is likely to be burnt and worsen the AQI in your city

            """, title: "Use it as compost!")
        }else if(self.pred=="paper"){
            showInfo(msg: """
            Paper produced from recycled paper represents an energy saving of 70%

            As you read this information, over 200 tonnes of paper was just produced

            The newspaper you receive everyday is made up of 75,000 tress


            """, title: "Recycle it!")
        }
        else if(self.pred=="metal"){
            showInfo(msg: """
            If you have any sort of electronic waste, please employ e-waste recycling options.

            Making new products from recycled steel cans helps save up to 75% of the energy and 40% of the water needed to make steel from raw materials



            """, title: "Maybe recycable")
        }
        else {
            showInfo(msg: """
            You can recycle glass!
            Try finding a recycling plant nearby!
            """, title: "Recycle it!")
        }
    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)
      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
}

extension UIImage {
  func resizeImage(targetSize: CGSize) -> UIImage {
    let size = self.size
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
  }
    }

