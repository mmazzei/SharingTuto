//
//  ShareViewController.swift
//  SharingTutoExtension
//
//  Created by Matías Mazzei on 31/08/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
    var album: Album? {
        didSet {
            albumCofigurationItem.value = album?.name ?? "..."
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

    override func isContentValid() -> Bool {
        return (contentText.count > 3) && (album != nil)
    }

    override func didSelectPost() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
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
}

extension ShareViewController: ChooseAlbumViewControllerDelegate {
    func chooseAlbumViewController(_ viewController: ChooseAlbumViewController, didSelect album: Album) {
        self.album = album
        popConfigurationViewController()
    }
}
