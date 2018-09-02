//
//  ChooseAlbumViewController.swift
//  SharingTutoExtension
//
//  Created by Matías Mazzei on 31/08/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import UIKit

protocol ChooseAlbumViewControllerDelegate: class {
    func chooseAlbumViewController(_ viewController: ChooseAlbumViewController, didSelect album: Album)
}

/// Presents the albums list allowing to select only one and then notifying the delegate.
class ChooseAlbumViewController: UITableViewController {
    private static let cellIdentifier = "ChooseAlbumViewControllerCell"
    private static let mockedAlbums = [
        Album(id: 1, name: "Cumpleaños"),
        Album(id: 2, name: "Navidad"),
        Album(id: 3, name: "Vacaciones"),
        Album(id: 4, name: "Familia"),
        Album(id: 5, name: "Mascotas")
    ]

    weak var delegate: ChooseAlbumViewControllerDelegate?
    /// Currently selected album, to be highlighted in the UI
    var selectedAlbum: Album?

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ChooseAlbumViewController.mockedAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChooseAlbumViewController.cellIdentifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: ChooseAlbumViewController.cellIdentifier)

        let album = ChooseAlbumViewController.mockedAlbums[indexPath.row]
        cell.textLabel?.text = album.name
        cell.accessoryType = album == selectedAlbum ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.chooseAlbumViewController(self, didSelect: ChooseAlbumViewController.mockedAlbums[indexPath.row])
    }
}
