//
//  ImageCell.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView! {
        didSet {
            imageView.kf.indicatorType = .activity
        }
    }
    @IBOutlet private weak var titleLabel: UILabel!

    var image: Image! {
        didSet { updateViewFromState() }
    }

    private func updateViewFromState() {
        imageView.kf.setImage(with: image.link)
        titleLabel.text = image.title ?? image.description ?? image.id
    }
}
