//
//  UIView+extensions.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/20/22.
//

import Foundation
import UIKit

extension UIView {
    /// Load a view using a nib file of the same classname
    ///
    /// ```
    /// let gradientView: GradientView = .fromNib()
    /// ```
    ///
    /// > Warning: Must specify the type or the View in the decaration
    ///
    /// - Returns: View loaded from a nib of the classname.
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    func fixInView(parentView: UIView) {
        parentView.addSubview(self)
        self.frame = parentView.bounds
    }
}
