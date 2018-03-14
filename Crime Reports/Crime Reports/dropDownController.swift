//
//  dropDownController.swift
//  Crime Reports
//
//  Created by Chris Haen on 3/13/18.
//  Copyright © 2018 Christopher Haen. All rights reserved.
//

import Foundation
import UIKit

class dropDownController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var startDate: UITextField!
    @IBOutlet weak var endDate: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDate.delegate = self
        endDate.delegate = self
    }
    
    @IBAction func printValue(_ sender: UITextField) {
        let text: String = sender.text!
        print(text)
    }
    
    //Keyboard Dismiss
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
