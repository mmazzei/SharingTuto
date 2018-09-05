//
//  Album.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

struct Album: Codable {
    let id: String
    let title: String
    let description: String?
    let cover: String? // The ID of the album cover image
//    var images_count: Int
}
