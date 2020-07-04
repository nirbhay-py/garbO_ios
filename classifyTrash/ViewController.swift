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
import Charts

var predi:String=""
var confidence_str:String!
var plasti:String=""
class ViewController: UIViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate{

    @IBOutlet weak var legendLbl: UILabel!
    @IBOutlet weak var insideVIew: UIView!
    @IBOutlet weak var pieChartView: PieChartView!
    
    var pred:String=""
    var img:UIImage!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("globalUserEmail:\(String(describing: globalUser.email))")
        if(globalUser.itemsScanned != 0){
            pieChartView.isHidden = true
            legendLbl.isHidden = true
             logoView.isHidden = false
            print("hidden")
            if(globalUser.plasticScanned != 0){
                setChart()
                pieChartView.isHidden = false
                logoView.isHidden = true
                legendLbl.isHidden = false
                legendLbl.text = "Plastics \(String(globalUser.plasticScanned)) and Non-plastics \(String(globalUser.itemsScanned-globalUser.plasticScanned))"
                 print("show")
            }else{
                pieChartView.isHidden = true
                legendLbl.isHidden = true
                logoView.isHidden = false
                 print("hidden")
            }
        }
    }


    @IBAction func camBtnPressed(_ sender: Any) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        present(vc, animated: true)
    }
    

    @IBAction func doneBtnPressed(_ sender: Any) {
        if(self.img==nil){
            showAlert(msg: "You can't carry on without taking an image.")
            return
        }
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
        predi = trashPrediction.classLabel
        print(predi)
        var confidence = trashPrediction.classLabelProbs[trashPrediction.classLabel]
        confidence! *= 100
        confidence! = confidence!.round(to: 2)
        let cString:String = String(format:"%.1f", confidence as! CVarArg)
        confidence_str = cString
        print("Confidence:\(confidence!))")
        var plasticsScanned:Int!
        var itemsScanned:Int!
        if(trashPrediction.classLabel != "plastic"){
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
                        self.performSegue(withIdentifier: "res", sender: nil)
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
            print("PlasticDetected\nRunningPlasticClassifer")
            guard let plasticPrediction = try? plasticModel.prediction(image: imgBuffer)
            else {
                print("FatalErrorOccured")
                showAlert(msg:"An unexpected error occured. Please try again.")
                hud.dismiss()
                return
            }
            print("PredictedPlasticClass:\(plasticPrediction.classLabel)")
            var confidence = plasticPrediction.classLabelProbs[plasticPrediction.classLabel]
            confidence! *= 100
            confidence! = confidence!.round(to: 2)
            let cString:String = String(format:"%.1f", confidence as! CVarArg)
            print("Confidence:\(confidence!))")
            predi = trashPrediction.classLabel + " trash"
            var plasticType = plasticPrediction.classLabel
            plasti = "a " + sanitisePlasticInput(str:plasticType)
            confidence_str = String(cString) + "%"
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
        self.performSegue(withIdentifier: "res", sender: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        print("OriginalSize:\(image.size)")
        self.imageView.image = image
        self.imageView.borderWidth = 5
        self.imageView.borderColor = UIColor.white
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
        func setChart() {
            let plastics = PieChartDataEntry(value: Double(globalUser.plasticScanned!))
            let nonPlastics = PieChartDataEntry(value: Double(globalUser.itemsScanned-globalUser.plasticScanned))
            let dataset = PieChartDataSet(entries:[plastics,nonPlastics],label:"Plastics vs Non-plastics")
            dataset.colors = ChartColorTemplates.material()
            dataset.drawValuesEnabled = false
            pieChartView.legend.font = UIFont.systemFont(ofSize: 20)
            pieChartView.chartDescription?.textAlign = NSTextAlignment.left
            pieChartView.legend.enabled = false
            pieChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
            let data = PieChartData(dataSet: dataset)
            pieChartView.data = data
            pieChartView.notifyDataSetChanged()

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
