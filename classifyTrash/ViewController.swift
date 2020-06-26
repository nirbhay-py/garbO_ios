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
    
    @IBOutlet weak var lbl3: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var plasticLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var img:UIImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.roundedImage()
        changeState(state: true,plas:true)
    }
    func changeState(state:Bool,plas:Bool)
    {
        self.classLbl.isHidden = state
        self.lbl1.isHidden = state
        self.lbl2.isHidden = state
        self.lbl3.isHidden = state
        self.plasticLbl.isHidden = plas
        self.confidenceLbl
            .isHidden = state
    }

    @IBAction func camBtnPressed(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
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
        var confidence = trashPrediction.classLabelProbs[trashPrediction.classLabel]
        confidence! *= 100
        confidence! = confidence!.round(to: 2)
        let cString:String = String(format:"%.1f", confidence as! CVarArg)
        print("Confidence:\(confidence!))")
        if(trashPrediction.classLabel != "plastic"){
            showSuccess(msg:"Yay! We know what that looks like!")
            changeState(state: false, plas: true)
            self.classLbl.text = trashPrediction.classLabel + " trash"
            self.confidenceLbl.text = String(cString) + "%"
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

