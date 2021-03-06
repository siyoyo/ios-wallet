//
//  WalletSendTokensManager.swift
//  ELTCOINWALLET
//
//  Created by Oliver Mahoney on 17/10/2017.
//  Copyright © 2017 ELTCOIN. All rights reserved.
//

import Foundation
import WebKit

class WalletSendTokensManager: NSObject {

    private var webView = WKWebView()

    private var isEther = true
    private var token: ETHToken?
    private var coinVolume: Double = 0.0
    private var gasLimit: Double = 0.0
    private var destinationAddress = ""
    
    public var sendCompleted: (()->Void)?
    public var errBlock: ((String)->Void)?
    
    init(isEther: Bool, token: ETHToken, coinVolume: Double, gasLimit: Double, destinationAddress: String, sendCompleted: @escaping (()->Void), errBlock: @escaping ((String)->Void)) {
        super.init()
        self.isEther = isEther
        self.token = token
        self.coinVolume = coinVolume
        self.gasLimit = gasLimit
        self.destinationAddress = destinationAddress
        self.sendCompleted = sendCompleted
        self.errBlock = errBlock
    }
    
    func startSending(){
        let contentController = WKUserContentController();
        let userScript = WKUserScript(
            source: "redHeader()",
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(
            self,
            name: "callbackHandler"
        )
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: CGRect(), configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        
        let url = Bundle.main.url(forResource: "dist/index", withExtension: "html")
        let urlstr = (url?.absoluteString)! + "#send-transaction"
        let url2 = URL(string: urlstr)
        
        webView.load(URLRequest(url: url2!))
    }
    
}

extension WalletSendTokensManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Navigated to: " + (webView.url?.absoluteString)!)
        
        if webView.url?.absoluteString.range(of:"index.html#send-transaction") != nil {
            
            if let privateKey = WalletManager.sharedInstance.getWalletUnEncrypted()?.privKey {
                
                let jsStr = "step1WithPrivateKey('\(privateKey)', \(coinVolume), \(gasLimit), '\(destinationAddress)', \(isEther.description), '\(token?.tokenInfo?.address ?? "" )', '\(token?.tokenInfo?.symbol ?? "")', \(token?.tokenInfo?.decimals ?? 0.0))";
                
                print(jsStr)
                webView.evaluateJavaScript(jsStr, completionHandler: nil)
            }
        }
    }
}

extension WalletSendTokensManager: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            
            print("JavaScript is sending a message: \(message.body)")
            let str =  message.body as? String ?? ""
            
            if let parsedData = try? JSONSerialization.jsonObject(with: str.data(using: .utf8)!) as! [String:Any] {
                print(parsedData)
                
                if let tag: String = parsedData["tag"] as? String{
                    switch tag {
                    case WalletManager.WALLET_EVENTS.SEND_TOKEN_ERR.rawValue:
                        
                        if errBlock != nil {
                            if let errorMessage: String = parsedData["payload"] as? String{
                                self.errBlock!(errorMessage)
                            }else{
                                self.errBlock!("There was a problem creating your wallet")
                            }
                        }
                        
                    case WalletManager.WALLET_EVENTS.SEND_TOKEN_COMPLETE.rawValue:
                        
                        if let message: String = parsedData["payload"] as? String{
                            print(message)
                        }
                        if sendCompleted != nil {
                            self.sendCompleted!()
                        }
                        
                    // TODO: case...
                        
                    default:
                        if errBlock != nil {
                            self.errBlock!("There was a problem decrypting your keystore file")
                        }
                    }
                }
                
            }
        }
    }
}
