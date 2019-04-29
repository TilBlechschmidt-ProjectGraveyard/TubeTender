//
//  WebSignInViewController.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 28.04.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import UIKit
import WebKit

private let userAgent: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
private let requiredCookies: [String] = ["SIDCC", "PREF", "VISITOR_INFO1_LIVE", "YSC", "APISID", "CONSENT", "HSID", "SAPISID", "SID", "SSID", "LOGIN_INFO"]
private let cookieDomain: String = ".youtube.com"
private let dataPrefix: String = "    window[\"ytInitialData\"] = "

class WebSignInViewController: UIViewController {
    var webView: WKWebView!
    var manualLoad = false

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.customUserAgent = userAgent
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myURL = URL(string: "https://www.youtube.com/?app=desktop&persist_app=1")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }

    func onLoggedIn(cookies: [HTTPCookie]) {
        var request = URLRequest(url: URL(string: "https://www.youtube.com/")!)

        let filteredCookies = cookies.filter { requiredCookies.contains($0.name) && $0.domain == cookieDomain }
        let cookieHeaders = HTTPCookie.requestHeaderFields(with: filteredCookies)
        request.allHTTPHeaderFields = cookieHeaders
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let html = String(data: data, encoding: .utf8) {
                let initialDataLine = html.components(separatedBy: "\n").filter { $0.contains("ytInitialData") }.first
                print(initialDataLine!.replacingOccurrences(of: dataPrefix, with: ""))
            } else if let error = error {
                print(error)
            }
        }.resume()
    }
}

extension WebSignInViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let path = webView.url?.path, path == "/" {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                let loginCookies = cookies.filter { $0.name == "LOGIN_INFO" }
                if !loginCookies.isEmpty {
                    self.onLoggedIn(cookies: cookies)
                }
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
