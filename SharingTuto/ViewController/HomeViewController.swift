//
//  HomeViewController.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import Kingfisher
import SharingTutoFwk

class HomeViewController: UIViewController {
    private enum State {
        case loggedIn(user: User)
        case loggedOut
        case loading
    }
    private enum Segues: String {
        case logIn
    }

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var userAvatarImage: UIImageView! {
        didSet { userAvatarImage.kf.indicatorType = .activity }
    }
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var loggedInContent: UIStackView!

    private var state: State! {
        didSet {
            DispatchQueue.main.async {
                self.updateViewFromState()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        state = .loading
        updateStateFromModel()
    }

    private func updateStateFromModel() {
        if let credentials = Environment.credentials {
            state = .loading
            ImgurAPI.getUserInfo(username: credentials.accountUsername) {[unowned self] result in
                switch result {
                case .error(let error):
                    print(error)
                    self.state = .loggedOut
                case .success(let user):
                    self.state = .loggedIn(user: user)
                }
            }
        } else {
            state = .loggedOut
        }
    }

    private func updateViewFromState() {
        switch state! {
        case .loading:
            loadingIndicator.startAnimating()
            logInButton.isHidden = true
            loggedInContent.isHidden = true

        case .loggedOut:
            loadingIndicator.stopAnimating()
            logInButton.isHidden = false
            loggedInContent.isHidden = true

        case .loggedIn(let user):
            loadingIndicator.stopAnimating()
            logInButton.isHidden = true
            userAvatarImage.kf.setImage(with: user.avatar)
            usernameLabel.text = "\(user.url ?? "")"
            loggedInContent.isHidden = false
        }
    }

    @IBAction func logout() {
        Environment.credentials = nil
        updateStateFromModel()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Segues(rawValue: segue.identifier ?? "") {
        case .logIn?:
            let viewController = segue.destination as? LogInViewController
            viewController?.delegate = self
        default:
            break
        }
    }
}

extension HomeViewController: LogInViewControllerDelegate {
    func logInViewControllerDidFinish(_ viewController: LogInViewController) {
        state = .loading
        dismiss(animated: true) {
            self.updateStateFromModel()
        }
    }
}
