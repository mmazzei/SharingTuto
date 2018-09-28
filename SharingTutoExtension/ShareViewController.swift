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
    var album: Album? {
        didSet {
            albumCofigurationItem.value = album?.title ?? "..."
            validateContent()
        }
    }

    lazy var albumCofigurationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()!
        item.title = "Album"
        item.value = "..."
        item.tapHandler = showChooseAlbumViewController
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        BackgroundSession.shared.start()
    }

    override func isContentValid() -> Bool {
        return (contentText.count > 3) && (album != nil)
    }

    override func didSelectPost() {
        guard !BackgroundSession.shared.isUploadingNow else {
            showErrorAlert("Upload in progress, please try again later.")
            return
        }

        guard let context = extensionContext else { return }
        DispatchQueue.global(qos: .utility).async {
            context.loadImage {[weak self] (imageUrl) -> Void in
                self?.upload(from: imageUrl)

                self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
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
