//
//  User.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public struct User: Codable {
    public let id: Int
    public let url: String?
    public let bio: String?
    public let avatar: URL?
}
