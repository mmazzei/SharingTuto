//
//  AlbumViewController.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit

class AlbumViewController: UICollectionViewController {
    private enum State {
        case loaded(images: [Image])
        case loading

        var images: [Image] {
            switch self {
            case .loaded(let images): return images
            default: return []
            }
        }
    }

    private static let cellIdentifier = "imageCell"

    var album: Album!
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Set flow to a 2 columns grid
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        layout.itemSize.width = (view.bounds.width - layout.minimumInteritemSpacing * 2 - layout.sectionInset.left - layout.sectionInset.right) / 2
    }

    private func updateStateFromModel() {
        guard let credentials = Environment.credentials else {
            return
        }

        state = .loading
        ImgurAPI.getAlbumImages(username: credentials.accountUsername, album: album) {[unowned self] result in
            switch result {
            case .error(let error):
                print(error)
                // self.state = .loggedOut
                // TODO - Go back
            case .success(let images):
                self.state = .loaded(images: images)
            }
        }
    }

    private func updateViewFromState() {
        switch state! {
        case .loading:
            // TODO
            break

        case .loaded:
            collectionView?.reloadData()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return state.images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumViewController.cellIdentifier, for: indexPath) as! ImageCell
        cell.image = state.images[indexPath.item]
        return cell
    }
}
