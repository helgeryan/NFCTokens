//
//  HomeViewController.swift
//  Xeal Challenge App
//
//  Created by Ryan Helgeson on 12/20/22.
//

import UIKit
import Lottie
import CoreData
import CoreNFC

class HomeViewController: UIViewController {
    // MARK: - Properties
    var model = HomeViewModel()
    var isPaymentProcessing: Bool = false // Whether a payment is processing or not
    var tagData: Data?
    
    // MARK: - UI Elements
    private var animationView: LottieAnimationView = .init(name: "smallspinner")
    @IBOutlet weak var payNowButton: PayNowButton!
    @IBOutlet weak var gradientBackgroundView: GradientView!
    
    @IBOutlet weak var currentFundsLabel: UILabel!
    @IBOutlet weak var fundsAvailableLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectReloadAmountLabel: UILabel!
    
    @IBOutlet weak var fundsAvailableView: FundsAvailableView!
    @IBOutlet weak var reloadContainerView1: UIView!
    @IBOutlet weak var reloadContainerView2: UIView!
    @IBOutlet weak var reloadContainerView3: UIView!
    var reloadAmountView1: ReloadAmountView = .fromNib()
    var reloadAmountView2: ReloadAmountView = .fromNib()
    var reloadAmountView3: ReloadAmountView = .fromNib()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupReloadAmounts()
        setupFonts()
        setupSpinner()
        setupFundsButton()
        model.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Need this so the font does not get set back to system normal on press
        payNowButton.titleLabel?.font = UIFont(name: UIFont.montBold, size: 16)
    }
    
    func setupFundsButton() {
        fundsAvailableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(doReadAccount)))
    }
    
    func setupReloadAmounts() {
        addReloadAmount(containerView: reloadContainerView1, amountView: reloadAmountView1, amount: 5)
        addReloadAmount(containerView: reloadContainerView2, amountView: reloadAmountView2, amount: 25)
        addReloadAmount(containerView: reloadContainerView3, amountView: reloadAmountView3, amount: 50)
    }
    
    func addReloadAmount(containerView: UIView, amountView: ReloadAmountView, amount: Double) {
        amountView.fixInView(parentView: containerView)
        amountView.reloadAmount = ReloadAmount(value: amount)
        amountView.delegate = self
    }
    
    func setupFonts() {
        nameLabel.font = UIFont(name: UIFont.montBold, size: nameLabel.font.pointSize)
        currentFundsLabel.font = UIFont(name: UIFont.montBold, size: currentFundsLabel.font.pointSize)
        fundsAvailableLabel.font = UIFont(name: UIFont.montSemiBold, size: fundsAvailableLabel.font.pointSize)
        selectReloadAmountLabel.font = UIFont(name: UIFont.montBold, size: selectReloadAmountLabel.font.pointSize)
        payNowButton.titleLabel?.font = UIFont(name: UIFont.montBold, size: 16)
    }
    
    func setupSpinner() {
        animationView.frame = payNowButton.bounds
        payNowButton.addSubview(animationView)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.animationSpeed = 3
        animationView.isHidden = true
    }
    
    func setupWithUser(_ user: XealUser) {
        nameLabel.text = user.name
        currentFundsLabel.text = user.fundsAvailable
    }
    
    func syncReloadViews() {
        let views = [reloadAmountView1, reloadAmountView2, reloadAmountView3]
        for view in views {
            if view.reloadAmount == self.model.selectedReloadAmount {
                view.setSelected()
            } else {
                view.setUnselected()
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func doPayNow(_ sender: Any) {
        if model.currUser == nil {
            popupAlert(title: nil, message: "Please tap the funds available to load your user before proceeding.")
            model.selectedReloadAmount = nil
            syncReloadViews()
            setupPayNowButton()
            return
        }
        model.setupSession()
    }
    
    @objc func doReadAccount() {
        model.setupReadUserSession()
//        fundsAvailableView.doReadSession()
    }
    
    // MARK: - Demo Payment Processing
    func pay() {
        if isPaymentProcessing {
            return
        }
        
        isPaymentProcessing = true
        self.startAnimation()
        if let selectedReloadAmount = model.selectedReloadAmount {
            processPayment(reloadAmount: selectedReloadAmount, completion: { success in
                self.stopAnimation()
                if success {
                    self.presentPaymentConfirmation(selectedReloadAmount)
                    self.model.selectedReloadAmount = nil
                    self.setupReloadViews()
                    self.setupPayNowButton()
                } else {
                    self.popupAlert(title: "Payment Failed to process.", message: "Please try again.")
                }
                self.isPaymentProcessing = false
            })
        }
    }
    
    func processPayment( reloadAmount: ReloadAmount, completion: @escaping (Bool) -> (Void)) {
        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false, block: {
            _ in
            completion(true)
        })
    }

    func startAnimation() {
        animationView.play()
        animationView.isHidden = false
        payNowButton.setTitle("", for: .normal)
    }
    
    func stopAnimation() {
        self.animationView.pause()
        self.animationView.isHidden = true
        self.payNowButton.setTitle("Pay Now", for: .normal)
    }
    
    // MARK: - Alerts
    func popupAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        self.present(alert, animated: true)
    }
    
    // MARK: - Naviagation
    func presentPaymentConfirmation(_ amount: ReloadAmount) {
        let confirmVc = ConfirmPaymentViewController(amount: amount)
        confirmVc.modalPresentationStyle = .fullScreen
        confirmVc.modalTransitionStyle = .crossDissolve
        self.present(confirmVc, animated: true)
    }
}

// MARK: - ReloadAmountViewDelegate
extension HomeViewController: ReloadAmountViewDelegate {
    func selectedReloadAmount(amount: ReloadAmount) {
        if self.model.selectedReloadAmount == amount {
            self.model.selectedReloadAmount = nil
        } else {
            self.model.selectedReloadAmount = amount
        }
        setupReloadViews()
        setupPayNowButton()
    }
    
    func setupReloadViews() {
        syncReloadViews()
    }
    
    func setupPayNowButton() {
        payNowButton.isUserInteractionEnabled = model.selectedReloadAmount != nil
        payNowButton.setupBackground()
    }
}

extension HomeViewController: HomeViewModelDelegate {
    func userUpdated(_ user: XealUser) {
        setupWithUser(user)
    }
    
    func paymentSuccess(_ user: XealUser) {
        setupWithUser(user)
        pay()
    }
    
    func noUserFound() {
        promptNewUserSession()
    }
    
    func promptNewUserSession() {
        let alert = UIAlertController(title: "No user found.", message: "Use a demo user?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.model.setupNewUserSession()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        self.present(alert, animated: true)
    }
}
