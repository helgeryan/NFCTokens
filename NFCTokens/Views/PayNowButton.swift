//
//  PayNowButton.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/20/22.
//

import Foundation
import UIKit

class PayNowButton: UIButton {
    func setupBackground() {
        if isUserInteractionEnabled {
            self.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
        } else {
            self.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        }
    }
}
