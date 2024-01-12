//
//  ConfirmPaymentViewController.swift
//  NFCTokens
//
//  Created by Ryan Helgeson on 12/21/22.
//

import UIKit
import Lottie

class ConfirmPaymentViewController: UIViewController {
    // MARK: - Properties
    let reloadAmount: ReloadAmount
    
    // MARK: - UI Elements
    @IBOutlet weak var confirmationLabel: UILabel!
    @IBOutlet weak var confirmationAnimationContainerView: UIView!
    private var animationView: LottieAnimationView = .init(name: "checkmark")
    
    // MARK: - Constructors
    init(amount: ReloadAmount) {
        self.reloadAmount = amount
        super.init(nibName: "ConfirmPaymentViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.reloadAmount = ReloadAmount(value: 0)
        super.init(nibName: "ConfirmPaymentViewController", bundle: nil)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabel()
        setupCheckMark()
        addGestures()
    }
    
    func addGestures() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
    }

    func setupLabel() {
        confirmationLabel.text = "\(reloadAmount.dollarString) Successfully Added!"
        confirmationLabel.font = UIFont(name: "Mont-Bold", size: confirmationLabel.font.pointSize)
    }
    
    func setupCheckMark() {
        animationView.frame = confirmationAnimationContainerView.bounds
        confirmationAnimationContainerView.addSubview(animationView)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.animationSpeed = 0.5
        animationView.play()
    }
    
    // MARK: - Actions
    @objc func dismissSelf() {
        self.dismiss(animated: true)
    }
}
