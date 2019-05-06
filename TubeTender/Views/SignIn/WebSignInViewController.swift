//
//  WebSignInViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 28.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import WebKit

class WebSignInViewController: UIViewController {
    var webView: WKWebView!
    var manualLoad = false

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.customUserAgent = HomeFeedAPI.userAgent
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myURL = URL(string: "https://www.youtube.com/?app=desktop&persist_app=1")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
}

extension WebSignInViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let path = webView.url?.path, path == "/" {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
//                let loginCookies = cookies.filter { $0.name == "LOGIN_INFO" }
//                if !loginCookies.isEmpty {
//                    self.onLoggedIn(cookies: cookies)
//                }
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let host = url.host, host == "www.youtube.com", url.path.contains("signin"), !manualLoad {
            decisionHandler(.cancel)

            manualLoad = true
            webView.load(URLRequest(url: navigationAction.request.url!))
        } else {
            manualLoad = false
            decisionHandler(.allow)
        }
    }
}
