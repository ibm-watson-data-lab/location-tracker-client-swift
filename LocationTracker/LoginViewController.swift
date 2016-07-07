//
//  LoginViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // clear username/password fields
        self.usernameTextField.text = ""
        self.passwordTextField.text = "";
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // automatically log in if username/password exist
        let username = UsernamePasswordStore.loadUsername()
        if (username != nil) {
            let password = UsernamePasswordStore.loadPassword(username!)
            if (password != nil) {
                let apiKey = LocationDbInfoStore.loadApiKey()
                if (apiKey != nil) {
                    let apiPassword = LocationDbInfoStore.loadApiPassword(apiKey!)
                    if (apiPassword != nil) {
                        LocationDbInfoStore.loadDbHost()
                        LocationDbInfoStore.loadDbName()
                        self.performSegueWithIdentifier("ShowMap", sender: self)
                    }
                }
                // TODO: if online - login again???
                //login(username!, password: password!)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPressed(sender: UIButton) {
        self.login(self.usernameTextField.text!, password: self.passwordTextField.text!)
    }
    
    @IBAction func registerButtonPressed(sender: UIButton) {
        self.performSegueWithIdentifier("ShowRegisterViewController", sender: self)
    }
    
    func login(username: String, password: String) {
        self.showActivityIndicator()
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
        self.loginButton.hidden = true
        self.activityIndicator.hidden = false
    }
    
    func hideActivityIndicatory() {
        self.activityIndicator.hidden = true
        self.loginButton.hidden = false
        self.view.userInteractionEnabled = true
    }
    
    func showLoginErrorDialog() {
        let alert = UIAlertController(title:"Login Error", message:"Error logging in.", preferredStyle:UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.Default, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
