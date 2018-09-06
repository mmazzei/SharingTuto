//
//  AlbumViewController.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import MobileCoreServices

class AlbumViewController: UICollectionViewController {
    private enum State {
        case loading
        case ready(images: [Image])
        case imageSelected(UIImage, currentImages: [Image])
        case uploading(currentImages: [Image])

        var images: [Image] {
            switch self {
            case .ready(let images),
                 .imageSelected(_, let images),
                 .uploading(let images):
                return images
            default:
                return []
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
                self.state = .ready(images: images)
            }
        }
    }

    private func updateViewFromState() {
        switch state! {
        case .loading:
            // TODO
            break

        case .ready:
            collectionView?.reloadData()
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showImagePicker(_:)))

        case .imageSelected:
            askForImageTitle()

        case .uploading:
            let activityIndicator = UIActivityIndicatorView()
            let newBarButtonItem = UIBarButtonItem(customView: activityIndicator)
            navigationItem.rightBarButtonItem = newBarButtonItem
            activityIndicator.activityIndicatorViewStyle = .gray
            activityIndicator.startAnimating()
        }
    }

    private func askForImageTitle() {
        let alert = UIAlertController(title: "Write a title for your image", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Image title"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) {[unowned self] _ in
            let title = alert.textFields?.first?.text ?? ""
            self.uploadImage(withTitle: title)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) {[unowned self] _ in
            self.dismiss(animated: true) {
                self.state = .ready(images: self.state.images)
            }
        })
        present(alert, animated: true, completion: nil)
    }

    private func uploadImage(withTitle title: String) {
        guard case .imageSelected(let image, _)? = state else {
            print("Invalid state: \(state)")
            return
        }

        guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {
            print("Couldn't represent the image as JPEG")
            return
        }

        state = .uploading(currentImages: state.images)
        ImgurAPI.uploadImage(imageData, titled: title, into: album) {[weak self] result in
            guard self != nil else { return }
            switch result {
            case .error(let error):
                print("Error while uploading: \(error)")
                self!.state = .ready(images: self!.state.images)
            case .success(let image):
                self!.state = .ready(images: self!.state.images + [image])
            }
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

    @IBAction func showImagePicker(_ sender: Any) {
        let requiredMediaType = kUTTypeImage as String
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum), (UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) ?? []).contains(requiredMediaType) else {
            print("Content not available")
            return
        }

        let picker = UIImagePickerController()
        picker.mediaTypes = [requiredMediaType]
        picker.modalPresentationStyle = .popover
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension AlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true) {
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                print("Selected image not available")
                return
            }

            self.state = .imageSelected(image, currentImages: self.state.images)
        }
    }
}
