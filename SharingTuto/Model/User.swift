//
//  User.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

struct User: Codable {
    let id: Int
    let url: String?
    let bio: String?
    let avatar: URL?
}
