//
//  ViewController.swift
//  iTraveller
//
//  Created by MAS on 3/19/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import Alamofire
import SystemConfiguration
import CommonCrypto

public let baseURL = "https://printandgo.today"

class LoginController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    var csrf: String = ""
    var salt: String = "3GF94NFKA-A342"
    var offlinePassport : String = ""
    
    let urlString = baseURL + "/login"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        usernameField.text = "tester"//"John_Doe_95"
        passwordField.isSecureTextEntry = true
        passwordField.text = "12345678"//"dummyPassword"
        
        self.hideKeyboardWhenTappedAround()
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        }else{
            print("Internet Connection not Available!")
        }
    }
    
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func loginAttempt(_ sender: Any) {
        
        if !Reachability.isConnectedToNetwork(){
            if let savedHash = KeyChain.load(key: usernameField.text!){
                if savedHash == hashedPassword(), let savedPassport = KeyChain.load(key: usernameField.text! + "passport") {
                    if String(data: savedPassport, encoding: .utf8) != nil {
                        offlinePassport = String(data: savedPassport, encoding: .utf8)!
                        performSegue(withIdentifier: "showPassportOffline", sender: self)
                    }
                }
            } else {
                createAlert(title: "Network Error", message: "Internet (Cellular or WIFI) connection is needed to proceed", sender: self)
            }
        } else {
            if let savedHash = KeyChain.load(key: usernameField.text!){
                if savedHash == hashedPassword(), let savedPassport = KeyChain.load(key: usernameField.text! + "passport") {
                    if String(data: savedPassport, encoding: .utf8) != nil {
                        offlinePassport = String(data: savedPassport, encoding: .utf8)!
                    }
                }
            }
        }
        
        AF.request(self.urlString).response{response in
            switch response.result {
            case .success:
                if let data = response.data {
                    if let utf8Text = String(data: data, encoding: .utf8){
                        self.csrf = htmlGetValue(htmlString: utf8Text, key: "name=\"_csrf\" value=\"")
                        self.loginWithCSRF()
                    }
                }
            case .failure( _):
                createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
            }
        }
    }
    
    func loginWithCSRF() {
        let parameters: [String: String] = [
            "username" : usernameField.text!,
            "password" : passwordField.text!,
            "_csrf": self.csrf
        ]
        
        AF.request(self.urlString, method: .post, parameters: parameters)
            .response { response in
                switch response.result {
                case .success:
                    if let responseURL = response.response?.url?.absoluteString {
                        if responseURL.contains("error"){ 
                            createAlert(title: "Login Failed", message: "Invalid username/password", sender: self)
                        } else {
                            self.performSegue(withIdentifier: "legitTraveller", sender: self)
                        }
                    }
                case .failure( _):
                    createAlert(title: "Connection Failure", message: "Cannot connect to the server", sender: self)
                }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "legitTraveller"){
            let homeController = segue.destination as! HomeController
            homeController.csrf = self.csrf
            homeController.username = self.usernameField.text!
            
            if Reachability.isConnectedToNetwork() {
                KeyChain.save(key: usernameField.text!, data: hashedPassword())
            }
            
//            if !offlinePassport.isEmpty{
//                homeController.passportString = offlinePassport
//            }
            
        } else if (segue.identifier == "showPassportOffline"){
            let showPassportController = segue.destination as! ShowPassportController
            showPassportController.passportString = self.offlinePassport
        }
    }
    
    func hashedPassword() -> Data{
        var salted : String
        switch usernameField.text!.characters.count % 3 {
        case 0:
            salted = passwordField.text! + salt + usernameField.text!
        case 1:
            salted = salt + passwordField.text! + usernameField.text!
        default:
            salted = passwordField.text! + usernameField.text! + salt
        }
        return sha256(data: salted.data(using: .utf8)!)
    }
    
    func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}


public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}

func createAlert(title: String, message: String, sender: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { (action) in
        alert.dismiss(animated: true, completion: nil)
    }))
    
    sender.present(alert, animated: true, completion: nil)
}

func htmlGetValue(htmlString: String, key: String) -> String{
    if let range = htmlString.range(of: key) {
        var substring = htmlString[range.upperBound...]
        if let index = substring.firstIndex(of: "\""){
            substring = substring[..<index]
            return String(substring)
        } else {
            return ""
        }
    } else{
        return ""
    }
}
