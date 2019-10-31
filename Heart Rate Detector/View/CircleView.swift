//
//  CircleView.swift
//  Heart Rate Detector
//
//  Created by Francis Jemuel Bergonia on 10/31/19.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

import UIKit

@IBDesignable class CircleView: UIView {

    @IBInspectable var borderColor: CGColor = UIColor.red.cgColor
    @IBInspectable var backColor: CGColor = UIColor.white.cgColor
    
    override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
        
        self.layer.backgroundColor = backColor
        self.layer.borderColor = borderColor
        self.layer.borderWidth = 15.0
    }

}
