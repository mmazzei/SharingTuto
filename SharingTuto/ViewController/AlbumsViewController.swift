//
//  AlbumsViewController.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit

class AlbumsViewController: UITableViewController {
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
    private enum Segues: String {
        case showAlbumImages
    }
    private static let cellIdentifier = "AlbumsViewController.cell"

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
        let cell = tableView.dequeueReusableCell(withIdentifier: AlbumsViewController.cellIdentifier, for: indexPath)
        cell.textLabel?.text = state.albums[indexPath.row].title
        cell.detailTextLabel?.text = state.albums[indexPath.row].description

        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch Segues(rawValue: segue.identifier ?? "") {
        case .showAlbumImages?:
            if let viewController = segue.destination as? AlbumViewController, let row = tableView.indexPathForSelectedRow?.row {
                viewController.album = state.albums[row]
            }
        default:
            break
        }
    }
}
