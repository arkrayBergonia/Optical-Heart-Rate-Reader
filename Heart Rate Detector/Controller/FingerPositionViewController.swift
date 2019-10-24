//
//  FingerPositionViewController.swift
//  Heart Rate Detector
//
//  Created by Francis Jemuel Bergonia on 24/10/2019.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

import UIKit

class FingerPositionViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var instructionImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissVC(_:)))
        self.view.addGestureRecognizer(tap)
    }
    

    @objc private func dismissVC(_ sender: UITapGestureRecognizer? = nil) {
        self.dismiss(animated: true, completion: nil)
    }

}
