//
//  GradientView.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/20/22.
//

import UIKit

class GradientView: UIView {
    // MARK: - Properties
    var gradientStartColor: UIColor = .clear
    var gradientEndColor: UIColor = .clear
    
    // MARK: - IBInspectables
    @IBInspectable var startColor: UIColor {
        set {
            self.gradientStartColor = newValue
        }
        get {
            return self.gradientStartColor
        }
    }
    
    @IBInspectable var endColor: UIColor {
        set {
            self.gradientEndColor = newValue
        }
        get {
            return self.gradientEndColor
        }
    }
    
    // MARK: - Overrides
    override func draw(_ rect: CGRect) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: CGFloat(0),
                                y: CGFloat(0),
                                width: superview!.frame.size.width,
                                height: superview!.frame.size.height)
        gradient.colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        gradient.zPosition = -1
        layer.addSublayer(gradient)
    }
}
