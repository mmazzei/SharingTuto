//
//  ChooseAlbumViewController.swift
//  SharingTutoExtension
//
//  Created by Matías Mazzei on 31/08/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit
import SharingTutoFwk

protocol ChooseAlbumViewControllerDelegate: class {
    func chooseAlbumViewController(_ viewController: ChooseAlbumViewController, didSelect album: Album)
}

/// Presents the albums list allowing to select only one and then notifying the delegate.
class ChooseAlbumViewController: UITableViewController {
    private enum State {
        case loaded(albums: [Album])
        case loading

        var albums: [Album] {
            switch self {
            case .loaded(let albums): return albums
            default: return []
            }
        }
    }
    private static let cellIdentifier = "ChooseAlbumViewControllerCell"
    private var state: State! {
        didSet {
            DispatchQueue.main.async {
                self.updateViewFromState()
            }
        }
    }

    weak var delegate: ChooseAlbumViewControllerDelegate?
    /// Currently selected album, to be highlighted in the UI
    var selectedAlbum: Album?

    override func viewDidLoad() {
        super.viewDidLoad()
        state = .loading
        updateStateFromModel()
    }


    private func updateStateFromModel() {
        guard let credentials = Environment.credentials else {
            return
        }

        state = .loading
        ImgurAPI.getAlbums(username: credentials.accountUsername) {[unowned self] result in
            switch result {
            case .error(let error):
                print(error)
                // self.state = .loggedOut
            // TODO - Go back
            case .success(let albums):
                self.state = .loaded(albums: albums)
            }
        }
    }

    private func updateViewFromState() {
        switch state! {
        case .loading:
            // TODO
            break

        case .loaded:
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.albums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChooseAlbumViewController.cellIdentifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: ChooseAlbumViewController.cellIdentifier)

        let album = state.albums[indexPath.row]
        cell.textLabel?.text = album.title
        cell.accessoryType = album.id == selectedAlbum?.id ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.chooseAlbumViewController(self, didSelect: state.albums[indexPath.row])
    }
}
