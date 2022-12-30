//
//  ReloadAmountView.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 12/20/22.
//

import UIKit

// MARK: - ReloadAmountViewDelegate
protocol ReloadAmountViewDelegate {
    func selectedReloadAmount( amount: ReloadAmount)
}

class ReloadAmountView: UIView {
    // MARK: - Properties
    var delegate: ReloadAmountViewDelegate?
    
    // MARK: - UI Elements
    @IBOutlet weak var amountLabel: UILabel!
    
    var reloadAmount: ReloadAmount? {
        didSet {
            configure()
        }
    }
    
    // MARK: - Life Cycle
    override func layoutSubviews() {
        super.layoutSubviews()
        setupFonts()
        addGestures()
    }
    
    func setupFonts() {
        amountLabel.font = UIFont(name: "Mont-Bold", size: amountLabel.font.pointSize)
    }
    
    func addGestures() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectReloadAmount)))
    }

    func configure() {
        if let reloadAmount = reloadAmount {
            amountLabel.text = reloadAmount.dollarString
        }
    }
    
    func setSelected() {
        self.layer.borderWidth = 2
    }
    
    func setUnselected() {
        self.layer.borderWidth = 0
    }
    
    // MARK: - Actions
    @objc func selectReloadAmount() {
        if let reloadAmount = reloadAmount {
            delegate?.selectedReloadAmount(amount: reloadAmount)
        }
    }
}
