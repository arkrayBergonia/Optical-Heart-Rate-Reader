//
//  IntroViewController.swift
//  Heart Rate Detector
//
//  Created by Francis Jemuel Bergonia on 15/10/2019.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    @IBOutlet weak var mainButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mainButton.layer.cornerRadius = 10
        self.mainButton.clipsToBounds = true
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    

}
