//
//  LogInViewController.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 24/08/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import WebKit

protocol LogInViewControllerDelegate: class {
    func logInViewControllerDidFinish(_ viewController: LogInViewController)
}

class LogInViewController: UIViewController {
    weak var delegate: LogInViewControllerDelegate?
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self

        // TODO - Create the URL in a different place
        guard let url = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=e697e3cded0fc0c&response_type=token&state=stateExample123") else {
            // TODO - Show an error message
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension LogInViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else { return }

        Environment.credentials = parseCredentials(in: url)
        delegate?.logInViewControllerDidFinish(self)
    }

    /// Extract the credentials from the fragment part of the url, in the form:
    /// https://imgur.com/?state=abcdef#access_token=abcdef&expires_in=123&token_type=bearer&refresh_token=abcdef&account_username=abcdef&account_id=123
    private func parseCredentials(in url: URL) -> Credentials? {
        guard let fragment = url.fragment else { return nil }
        let fragmentParts = fragment
            // Separate by "&"
            .split(separator: "&")
            .map { "\($0)" }
            // Separate each key value in a tuple
            .map { fragmentComponent -> (String, String) in
                let keyAndValue = fragmentComponent.split(separator: "=")
                return ("\(keyAndValue[0])", "\(keyAndValue[1])")
            }
            // Join the tuples in a dict
            .reduce(into: [String:String]()) { (result, tuple) in
                result[tuple.0] = tuple.1
            }

        return Credentials.decode(from: fragmentParts)
    }
}
