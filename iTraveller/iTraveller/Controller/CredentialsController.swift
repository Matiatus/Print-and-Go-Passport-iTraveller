//
//  CredentialsController.swift
//  iTraveller
//
//  Created by MAS on 3/20/19.
//  Copyright © 2019 PrintAndGo. All rights reserved.
//

import UIKit
import Alamofire

class CredentialsController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var usernameField: UILabel!
    @IBOutlet weak var firstnameField: UILabel!
    @IBOutlet weak var lastnameField: UILabel!
    @IBOutlet weak var nationalidField: UILabel!
    @IBOutlet weak var dobField: UILabel!
    @IBOutlet weak var pobField: UILabel!
    @IBOutlet weak var ccField: UILabel!
    @IBOutlet weak var sexField: UILabel!
    
    var csrf: String = ""
    let urlString = baseURL + "/me"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let parameters: [String: String] = [
            "_csrf": self.csrf
        ]
        
        
        AF.request(self.urlString, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success:
                if let responseData = response.data, let utf8Text = String(data: responseData, encoding: .utf8) {
                    
                    self.usernameField.text = self.getValue(JSONString: utf8Text, key: "\"username\" : \"")
                    self.firstnameField.text = self.getValue(JSONString: utf8Text, key: "\"firstname\" : \"")
                    self.lastnameField.text = self.getValue(JSONString: utf8Text, key: "\"lastname\" : \"")
                    self.nationalidField.text = self.getValue(JSONString: utf8Text, key: "\"nationalid\" : \"")
                    self.pobField.text = self.getValue(JSONString: utf8Text, key: "\"pob\" : \"")
                    self.ccField.text = self.getValue(JSONString: utf8Text, key: "\"cc\" : \"")
                    self.sexField.text = self.getValue(JSONString: utf8Text, key: "\"sex\" : \"")
                    
                    let range = utf8Text.range(of: "\"dob\" : ")!
                    let substring = utf8Text[range.upperBound...]
                    let index = substring.firstIndex(of: ",")!
                    self.dobField.text = self.convertStringTimestampToStringDate( String(substring[..<index]))
                }
                
            case .failure( _):
                createAlert(title: "Connection Failure", message: "Failed to connect with the server", sender: self)
                
            }
        }
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
 
    func getValue(JSONString: String, key: String) -> String{
        if let range = JSONString.range(of: key) {
            var substring = JSONString[range.upperBound...]
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
    
    func convertStringTimestampToStringDate(_ dateandTime: String) -> String {
        
        let secondsSince1970 = Double(dateandTime)! / 1000
        let javaSqlDifference : Double = 24*60*60
        let dateFromServer = NSDate(timeIntervalSince1970: secondsSince1970 + javaSqlDifference)
        
        let dateFormater : DateFormatter = DateFormatter()
        dateFormater.dateFormat = "MM-dd-yyyy"
        
        let backToString = dateFormater.string(from: dateFromServer as Date)
        return backToString
        
    }
    
}
