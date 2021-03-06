//
//  HomeViewController.swift
//  ELTCOINWALLET
//
//  Created by Oliver Mahoney on 12/10/2017.
//  Copyright © 2017 ELTCOIN. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class HomeViewController: UIViewController {

    // Member vars
    let reuseIdentifier = "TransactionCell"
    var walletTokens = [ETHToken]()
    var walletBalance: ETHTokenBalance?
    
    // TOP BAR
    var topBarBackgroundView = UIView()
    var topBarLogoImageView = UIImageView()
    var topBarShareButton = UIButton()
    var topBarSendButton = UIButton()
    var topBarBackgroundLineView = UIView()
    
    // WALLET SUMMARY
    var walletSummaryBackgroundView = UIView()
    var walletSummaryBackgroundLineView = UIView()
    var walletAvatarButton = UIButton()
    var walletAddressLabel = UILabel()
    var walletMainBalanceLabel = UILabel()
    var walletSubBalanceLabel = UILabel()

    // Tokens List
    var tableView = UITableView()
    
    // Empty Transaction List Label
    var emptyListLabel = UILabel()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeViewController.handleRefresh), for: UIControlEvents.valueChanged)
        
        return refreshControl
    }()
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        setupWalletUI {
            self.tableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    func setupWalletUI(_ completed: (()->Void)? = nil){
        
        topBarSendButton.isEnabled = false
        if let wallet = WalletManager.sharedInstance.getWalletUnEncrypted(){
            
            walletAddressLabel.text = wallet.address
            walletAvatarButton.setBackgroundImage(UIImage.generateQRCode(from: wallet.address), for: .normal)

            let walletManager = WalletTransactionsManager()
            
            walletManager.getBalance(balanceImportCompleted: { (walletBalance) in
                if  walletBalance.ETH != nil {
                    self.walletMainBalanceLabel.text = String(format:"%f ETH", (walletBalance.ETH?.balance)!)
                }else{
                    self.walletMainBalanceLabel.text = "Offline"
                }
                
                self.walletBalance = walletBalance
                self.walletTokens = walletBalance.tokens ?? [ETHToken]()
                
                self.emptyListLabel.isHidden = !(self.walletTokens.count == 0)
                
                self.topBarSendButton.isEnabled = true

                if completed != nil {
                    completed!()
                }
            })
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfWalletSetup()
        NotificationManager().registerForPushNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupWalletUI {
            self.tableView.reloadData()
        }
    }
    
    @objc func walletUpdated(){
        setupWalletUI {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.addSubview(self.refreshControl)
        self.tableView.refreshControl?.addTarget(self, action: #selector(HomeViewController.handleRefresh), for: UIControlEvents.valueChanged)
        self.navigationController?.isNavigationBarHidden = true

        // TOP VIEWS

        let topOffset = UIDevice.current.iPhoneX ? 20 : 0
        
        self.view.addSubview(topBarBackgroundView)
        topBarBackgroundView.snp.makeConstraints { (make) in
            make.height.equalTo(64)
            make.top.equalTo(view).offset(topOffset)
            make.centerX.width.equalTo(view)
        }
        
        topBarBackgroundView.addSubview(topBarLogoImageView)
        topBarLogoImageView.image = UIImage(imageLiteralResourceName: "logoText")
        topBarLogoImageView.contentMode = .scaleAspectFit
        topBarLogoImageView.snp.makeConstraints { (make) in
            make.height.equalTo(topBarBackgroundView).offset(-20)
            make.width.equalTo(topBarBackgroundView)
            make.centerX.equalTo(topBarBackgroundView)
            make.top.equalTo(topBarBackgroundView).offset(20)
        }
        
        topBarBackgroundView.addSubview(topBarBackgroundLineView)
        topBarBackgroundLineView.backgroundColor = UIColor.CustomColor.Grey.lightGrey
        topBarBackgroundLineView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.width.equalTo(view)
            make.top.equalTo(topBarBackgroundView.snp.bottom)
            make.height.equalTo(1)
        }
        
        topBarBackgroundView.addSubview(topBarShareButton)
        topBarShareButton.setBackgroundImage(UIImage(imageLiteralResourceName: "shareIcon"), for: UIControlState.normal);
        topBarShareButton.addTarget(self, action: #selector(HomeViewController.shareButtonPressed), for: .touchUpInside)
        topBarShareButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(28)
            make.top.equalTo(topBarBackgroundView).offset(25)
            make.right.equalTo(topBarBackgroundView.snp.right).offset(-10)
        }
        
        topBarBackgroundView.addSubview(topBarSendButton)
        topBarSendButton.setBackgroundImage(UIImage(imageLiteralResourceName: "iconSent"), for: UIControlState.normal);
        topBarSendButton.addTarget(self, action: #selector(HomeViewController.openSendModel), for: .touchUpInside)
        topBarSendButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(28)
            make.top.equalTo(topBarBackgroundView).offset(25)
            make.left.equalTo(topBarBackgroundView.snp.left).offset(10)
        }
        
        // WALLET SUMMARY
        
        self.view.addSubview(walletSummaryBackgroundView)
        walletSummaryBackgroundView.backgroundColor = UIColor.CustomColor.White.offwhite
        walletSummaryBackgroundView.snp.makeConstraints { (make) in
            make.top.equalTo(topBarBackgroundView.snp.bottom)
            make.height.equalTo(230)
            make.centerX.equalTo(view)
            make.width.equalTo(view)
        }
        
        walletSummaryBackgroundView.addSubview(walletAvatarButton)
        walletAvatarButton.addTarget(self, action: #selector(HomeViewController.displayMenu), for: .touchUpInside)
        walletAvatarButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.equalTo(view)
            make.top.equalTo(walletSummaryBackgroundView).offset(20)
        }
        
        walletSummaryBackgroundView.addSubview(walletAddressLabel)
        walletAddressLabel.textAlignment = .center
        walletAddressLabel.font = UIFont.systemFont(ofSize: 12)
        walletAddressLabel.text = ""
        walletAddressLabel.textColor = UIColor.CustomColor.Grey.midGrey
        walletAddressLabel.snp.makeConstraints { (make) in
            make.top.equalTo(walletAvatarButton.snp.bottom).offset(10)
            make.width.equalTo(walletSummaryBackgroundView)
            make.centerX.equalTo(view)
        }
        
        walletSummaryBackgroundView.addSubview(walletMainBalanceLabel)
        walletMainBalanceLabel.textAlignment = .center
        walletMainBalanceLabel.font = UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.bold)
        walletMainBalanceLabel.text = ""
        walletMainBalanceLabel.textColor = UIColor.black
        walletMainBalanceLabel.isUserInteractionEnabled = true
        walletMainBalanceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(etherBalancePressed)))
        
        walletMainBalanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(walletAddressLabel.snp.bottom).offset(5)
            make.width.equalTo(walletSummaryBackgroundView)
            make.centerX.equalTo(view)
        }
        
        walletSummaryBackgroundView.addSubview(walletSubBalanceLabel)
        walletSubBalanceLabel.textAlignment = .center
        walletSubBalanceLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.bold)
        walletSubBalanceLabel.text = ""
        walletSubBalanceLabel.textColor = UIColor.black
        walletSubBalanceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(walletMainBalanceLabel.snp.bottom).offset(5)
            make.width.equalTo(walletSummaryBackgroundView)
            make.centerX.equalTo(view)
        }
        
        walletSummaryBackgroundView.addSubview(walletSummaryBackgroundLineView)
        walletSummaryBackgroundLineView.backgroundColor = UIColor.CustomColor.Grey.lightGrey
        walletSummaryBackgroundLineView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.width.equalTo(view)
            make.bottom.equalTo(walletSummaryBackgroundView.snp.bottom).offset(-1)
            make.height.equalTo(1)
        }
        
        // Tableview
        view.addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TokenTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(walletSummaryBackgroundView.snp.bottom).offset(1)
            make.width.bottom.equalTo(view)
        }
        
        view.addSubview(emptyListLabel)
        emptyListLabel.text = "There's no tokens to show\n😥"
        emptyListLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
        emptyListLabel.numberOfLines = 0
        emptyListLabel.isHidden = true
        emptyListLabel.textAlignment = .center
        emptyListLabel.snp.makeConstraints { (make) in
            make.top.equalTo(walletSummaryBackgroundView.snp.bottom).offset(1)
            make.width.bottom.equalTo(view)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkIfWalletSetup), name: NSNotification.Name(rawValue: "LOGOUT"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(walletUpdated), name: NSNotification.Name(rawValue: "NEW_WALLET"), object: nil)
    }
    
    
    @objc func etherBalancePressed(){
        let transactionsViewController = TransactionsViewController()
        self.navigationController?.pushViewController(transactionsViewController, animated: true)
    }
    
    @objc func displayMenu(){
        
        let menuViewController = MenuViewController()
        menuViewController.hidesBottomBarWhenPushed = true
        
        let navController = PopupNavigationController(rootViewController: menuViewController)
        navController.navigationBar.isTranslucent = true
        navController.navigationBar.isHidden = true
        navController.modalPresentationStyle = .custom
        
        self.present(navController, animated: true)
    }
    
    @objc func openSendModel(){
        
        let sendCoinViewController = SendTokensViewController()
        
        // Default to ether
        let token = ETHToken()
        token.tokenInfo = ETHTokenInfo()
        token.tokenInfo?.symbol = "ETH"
        token.tokenInfo?.name = "Ethereum"
        token.tokenInfo?.decimals = 0.0
        token.balance = walletBalance?.ETH?.balance ?? 0.0

        sendCoinViewController.setToken(token)
        sendCoinViewController.hidesBottomBarWhenPushed = true

        let navController = PopupNavigationController(rootViewController: sendCoinViewController)
        navController.navigationBar.isTranslucent = true
        navController.navigationBar.isHidden = true
        navController.modalPresentationStyle = .custom
 
        self.present(navController, animated: true)
    }
    
    @objc func shareButtonPressed(){
        let wallet = WalletManager.sharedInstance.getWalletEncrypted()
        
        let file = "wallet-\(UUID().uuidString).json"
        let text = wallet?.toJSONString(prettyPrint: true)
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            do {
                try text?.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print("Error writing wallet")
            }
            
            let activityItem:NSURL = NSURL(fileURLWithPath: fileURL.path)
            
            let activityVC = UIActivityViewController(activityItems: [activityItem], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @objc func checkIfWalletSetup(){
        
        if let wallet = WalletManager.sharedInstance.getWalletUnEncrypted(){
            if wallet.address.count == 0 {
                attachWallet()
            }
        }else{
            attachWallet()
        }
    }
    
    func attachWallet(){
        
        let newWalletViewController = NewWalletViewController()
        newWalletViewController.hidesBottomBarWhenPushed = true
        
        let navController = PopupNavigationController(rootViewController: newWalletViewController)
        navController.navigationBar.isTranslucent = true
        navController.navigationBar.isHidden = true
        navController.modalPresentationStyle = .custom
        
        self.present(navController, animated: true)
    }
}

extension HomeViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: TokenTableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! TokenTableViewCell
        
        cell.setupCell(token: walletTokens[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transactionsViewController = TransactionsViewController()
        transactionsViewController.token = walletTokens[indexPath.row]
        self.navigationController?.pushViewController(transactionsViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return walletTokens.count;
    }
}
