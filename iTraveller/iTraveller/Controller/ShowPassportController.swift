//
//  ShowPassportController.swift
//  iTraveller
//
//  Created by MAS on 3/20/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit

class ShowPassportController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var passportQRImage: UIImageView!
    var passportString : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        passportQRImage.image = generatedQR()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
    }
    
    @objc func appMovedToBackground() {
        performSegue(withIdentifier: "logout", sender: self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func generatedQR() -> UIImage {  // QR Generator code is based on: https://medium.com/@dominicholmes.dev/generating-qr-codes-in-swift-4-b5dacc75727c
        
        // import UIKit
        // 1
        let myString = passportString
        // 2
        let data = myString.data(using: String.Encoding.ascii)
        // 3
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        // 4
        qrFilter!.setValue(data, forKey: "inputMessage")
        // 5
        let qrImage = qrFilter?.outputImage
        
        // Scale the image
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage!.transformed(by: transform)
        
        // Invert the colors
        let colorInvertFilter = CIFilter(name: "CIColorInvert")
        colorInvertFilter!.setValue(scaledQrImage, forKey: "inputImage")
        let outputInvertedImage = colorInvertFilter?.outputImage
        
        // Replace the black with transparency
        let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha")
        maskToAlphaFilter!.setValue(outputInvertedImage, forKey: "inputImage")
        let outputCIImage = maskToAlphaFilter?.outputImage
        
        // Do some processing to get the UIImage
        let context = CIContext()
        let cgImage = context.createCGImage(outputCIImage!, from: outputCIImage!.extent)
        let processedImage = UIImage(cgImage: cgImage!)
        
        return processedImage
    }
}
