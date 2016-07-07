//
//  RegisterViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var registerButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func registerButtonPressed(sender: UIButton) {
        self.register(self.usernameTextField.text!, password: self.passwordTextField.text!)
    }

    func register(username: String, password: String) {
        self.showActivityIndicator()
        
        let _id = self.usernameTextField.text!
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/users/\(_id)")
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url!)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.HTTPMethod = "PUT"
        request.HTTPBody = self.getRegisterHttpBody(_id)
        
        let task = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let _:NSData = data, let _:NSURLResponse = response where error == nil else {
                    self.hideActivityIndicatory()
                    self.showRegiterErrorDialog(0)
                    return
                }
                var dict: NSDictionary!
                do {
                    dict = try NSJSONSerialization.JSONObjectWithData(data!, options:[]) as? NSDictionary
                }
                catch {
                    print(error)
                }
                if (dict != nil && (dict["ok"] as? Bool) == true) {
                    self.login(username, password: password)
                }
                else {
                    self.hideActivityIndicatory()
                    self.showRegiterErrorDialog((response as! NSHTTPURLResponse).statusCode)
                }
            }
            
        }
        
        task.resume()
    }
    
    func getRegisterHttpBody(_id:String) -> NSData {
        var params: [String:String] = [String:String]()
        params["username"] = self.usernameTextField.text
        params["password"] = self.passwordTextField.text
        params["type"] = "user"
        params["_id"] = _id
        var body: NSData!
        do {
            body = try NSJSONSerialization.dataWithJSONObject(params as NSDictionary, options: [])
        }
        catch {
            print(error)
        }
        return body
    }
    
    func login(username: String, password: String) {
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/login")
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url!)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.HTTPMethod = "POST"
        request.HTTPBody = self.getLoginHttpBody(username, password: password)
        //
        let task = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let _:NSData = data, let _:NSURLResponse = response where error == nil else {
                    self.hideActivityIndicatory()
                    self.showLoginErrorDialog()
                    return
                }
                var dict: NSDictionary!
                do {
                    dict = try NSJSONSerialization.JSONObjectWithData(data!, options:[]) as? NSDictionary
                }
                catch {
                    print(error)
                }
                if (dict != nil && (dict["ok"] as? Bool) == true) {
                    UsernamePasswordStore.saveUsernamePassword(username, password: password)
                    LocationDbInfoStore.saveApiKeyPasswordDbNameHost(
                        dict["api_key"] as! String,
                        apiPassword: dict["api_password"] as! String,
                        dbName: dict["location_db_name"] as! String,
                        dbHost: dict["location_db_host"] as! String,
                        dbHostProtocol: dict["location_db_host_protocol"] as? String
                    )
                    self.hideActivityIndicatory()
                    self.performSegueWithIdentifier("ShowMap", sender: self)
                }
                else {
                    self.hideActivityIndicatory()
                    self.showLoginErrorDialog()
                }
            }
        }
        //
        task.resume()
    }
    
    func getLoginHttpBody(username: String, password: String) -> NSData {
        var params: [String:String] = [String:String]()
        params["username"] = username
        params["password"] = password
        var body: NSData!
        do {
            body = try NSJSONSerialization.dataWithJSONObject(params as NSDictionary, options: [])
        }
        catch {
            print(error)
        }
        return body
    }
    
    func showActivityIndicator() {
        self.view.userInteractionEnabled = false
        self.registerButton.hidden = true
        self.activityIndicator.hidden = false
    }
    
    func hideActivityIndicatory() {
        self.activityIndicator.hidden = true
        self.registerButton.hidden = false
        self.view.userInteractionEnabled = true
    }
    
    func showRegiterErrorDialog(statusCode: Int) {
        var message = "Error registering."
        if (statusCode == 409) {
            message += " User already exists."
        }
        let alert = UIAlertController(title:"Register Error", message:message, preferredStyle:UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.Default, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLoginErrorDialog() {
        let alert = UIAlertController(title:"Login Error", message:"Error logging in.", preferredStyle:UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.Default, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
