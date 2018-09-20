//
//  Image.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public struct Image: Codable {
    public let id: String
    public let title: String?
    public let description: String?
    public let link: URL
}
