//
//  ShareViewController.swift
//  SharingTutoExtension
//
//  Created by Matías Mazzei on 31/08/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import Social
import SharingTutoFwk

class ShareViewController: SLComposeServiceViewController {
    fileprivate var album: Album? {
        didSet {
            albumCofigurationItem.value = album?.title ?? "..."
            validateContent()
        }
    }

    private var imageUrl: URL? {
        didSet {
            DispatchQueue.main.async {
                self.validateContent()
                self.activityIndicator.stopAnimating()
            }
        }
    }

    private lazy var albumCofigurationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Album"
        item.value = "..."
        item.tapHandler = showChooseAlbumViewController
        return item
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        view.hidesWhenStopped = true
        view.startAnimating()
        return view
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        BackgroundSession.shared.start()

        guard let context = extensionContext else { return }
        DispatchQueue.global(qos: .utility).async {
            context.loadImage {[weak self] (imageUrl) -> Void in
                self?.imageUrl = imageUrl
            }
        }
    }

    override func loadPreviewView() -> UIView! {
        guard let previewView = super.loadPreviewView() else {
            return nil
        }
        previewView.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: previewView.bounds.midX, y: previewView.bounds.midY)
        return previewView
    }

    override func isContentValid() -> Bool {
        return (contentText.count > 3) && (album != nil) && (imageUrl != nil)
    }

    override func didSelectPost() {
        guard !BackgroundSession.shared.isUploadingNow else {
            showErrorAlert("Upload in progress, please try again later.")
            return
        }

        guard let imageUrl = imageUrl else { return }
        DispatchQueue.global(qos: .userInitiated).async {[weak self] in
            self?.upload(from: imageUrl)
        }
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func upload(from url: URL) {
        guard let title = contentText else { return }
        guard let album = album else { return }
        guard let imageData = try? Data(contentsOf: url) else { return }

        ImgurAPI.uploadImage(imageData, titled: title, into: album) {[unowned self] _ in
            // Nothing to do, as this callback will not be executed from the app
        }
    }

    override func configurationItems() -> [Any]! {
        return [albumCofigurationItem]
    }


    private func showChooseAlbumViewController() {
        let chooseAlbumViewController = ChooseAlbumViewController()
        chooseAlbumViewController.delegate = self
        chooseAlbumViewController.selectedAlbum = album
        pushConfigurationViewController(chooseAlbumViewController)
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {[weak self] _ in
            self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }))
        present(alert, animated: true)
        return
    }
}

extension ShareViewController: ChooseAlbumViewControllerDelegate {
    func chooseAlbumViewController(_ viewController: ChooseAlbumViewController, didSelect album: Album) {
        self.album = album
        popConfigurationViewController()
    }
}
