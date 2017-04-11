//
//  ViewController.swift
//  AuthManager
//
//  Created by Borys Khliebnikov on 4/11/17.
//  Copyright © 2017 Borys Khliebnikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet private weak var currentTokenLabel: UILabel!
    @IBOutlet fileprivate weak var tokenTextField: UITextField!
    @IBOutlet fileprivate weak var usernameTextField: UITextField!
    
    // MARK: Variables
    
    fileprivate var userName: String?
    fileprivate var userToken: String?
    
    
    // MARK: VCLC
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    // MARK: Helpers
    
    private func validation() -> Bool {
        if userToken == nil {
            return false
        }
        if userName == nil {
            return false
        }
        return true
    }
    
    // MARK: IBActions

    @IBAction func hideKeyboardOnTap(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func pressSetToken(_ sender: Any) {
        self.view.endEditing(true)
        guard self.validation() else {
            self.showAlert(title: "Error", message: "Fields should not be empty", buttonTitle: "OK", handler: nil)
            return
        }
        let keychain = KeychainManager.init(service: "steelkiwiSampleApp", account: self.userName!)
        do {
            try keychain.saveToken(self.userToken!)
        } catch {
            self.showAlert(title: "Error", message: "Error saving keychain", buttonTitle: "OK", handler: nil)
        }
        self.showAlert(title: "Success", message: "Token saved", buttonTitle: "OK", handler: nil)
    }

    @IBAction func pressShowCurrentToken(_ sender: Any) {
        if userName == nil {
            self.showAlert(title: "Error", message: "Username should not be empty", buttonTitle: "OK", handler: nil)
            return
        }
        TouchIDManager.requestAccess(reason: "Reason string for using TouchID") { (result, error) in
            switch result {
            case true:
                let keychain = KeychainManager.init(service: "steelkiwiSampleApp", account: self.userName!)
                do {
                    self.userToken = try keychain.readToken()
                    DispatchQueue.main.async {
                        self.currentTokenLabel.text = self.userToken;
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error", message: "Error reading keychain", buttonTitle: "OK", handler: nil)
                    }
                }
            case false:
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: error?.localizedDescription, buttonTitle: "OK", handler: nil)
                }
            }
        }
    }
}

// MARK: UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case usernameTextField:
            self.userName = textField.text
        default:
            self.userToken = textField.text
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
}

extension ViewController {
    
    /// Simple alert popup extension
    /// - Parameter title: Alert title
    /// - Parameter message: Alert message
    /// - Parameter buttonTitle: Cancel action button title
    func showAlert(title: String! = "", message: String!, buttonTitle: String! = "OK", handler: ((UIAlertAction) -> Void)? = nil) {
        let controller = UIAlertController.init(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction.init(title: buttonTitle, style: UIAlertActionStyle.cancel, handler: handler)
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
}

