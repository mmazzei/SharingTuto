//
//  ImgurAPI.swift
//  SharingTuto
//
//  Created by Matías Mazzei on 05/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case error(Error)
}

private struct GetUserInfoResponse: Codable {
    var data: User
}

private struct GetAlbumsResponse: Codable {
    var data: [Album]
}

private struct GetAlbumImagesResponse: Codable {
    var data: [Image]
}

private struct ImageUploadResponse: Codable {
    var data: Image
}

/// Implements requests to some of the endpoints defined in https://apidocs.imgur.com
// TODO - Refactor the repeated code
public struct ImgurAPI {
    private init() {}

    public static func getUserInfo(username: String, _ callback: @escaping (Result<User>) -> Void) {
        let url = URL(string: Constants.apiBaseUrl)!.appendingPathComponent("/account/\(username)")
        var request = URLRequest(url: url)
        request.addAuthHeader()

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil, let userJsonData = data else {
                callback(.error(error!))
                return
            }

            do {
                let userInfo = try JSONDecoder().decode(GetUserInfoResponse.self, from: userJsonData)
                callback(.success(userInfo.data))
            } catch {
                callback(.error(error))
            }
            }.resume()
    }

    public static func getAlbums(username: String, _ callback: @escaping (Result<[Album]>) -> Void) {
        let url = URL(string: Constants.apiBaseUrl)!.appendingPathComponent("/account/\(username)/albums")
        var request = URLRequest(url: url)
        request.addAuthHeader()

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil, let albumsData = data else {
                callback(.error(error!))
                return
            }

            do {
                let albumsInfo = try JSONDecoder().decode(GetAlbumsResponse.self, from: albumsData)
                callback(.success(albumsInfo.data))
            } catch {
                callback(.error(error))
            }
            }.resume()
    }

    public static func getAlbumImages(username: String, album: Album, _ callback: @escaping (Result<[Image]>) -> Void) {
        let url = URL(string: Constants.apiBaseUrl)!.appendingPathComponent("/account/\(username)/album/\(album.id)/images")
        var request = URLRequest(url: url)
        request.addAuthHeader()

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil, let imagesData = data else {
                callback(.error(error!))
                return
            }

            do {
                let imagesInfo = try JSONDecoder().decode(GetAlbumImagesResponse.self, from: imagesData)
                callback(.success(imagesInfo.data))
            } catch {
                callback(.error(error))
            }
            }.resume()
    }

    /// Only supports jpeg images for now.
    public static func uploadImage(_ imageData: Data, titled title: String, into album: Album, _ callback: @escaping (Result<Image>) -> Void) {
        var urlComponents = URLComponents(string: Constants.apiBaseUrl)!
        urlComponents.path.append("/image")
        urlComponents.queryItems = [
            URLQueryItem(name: "album", value: album.id),
            URLQueryItem(name: "title", value: title)
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addAuthHeader()
        // The jpeg restriction is just because this
        request.setValue("image/jpeg", forHTTPHeaderField: "content-type")
        request.httpBody = imageData

        BackgroundSession.shared.uploadTask(with: request, from: imageData) { result in
            switch result {
            case .success(let imageData):
                do {
                    let imageInfo = try JSONDecoder().decode(ImageUploadResponse.self, from: imageData!)
                    callback(.success(imageInfo.data))
                } catch {
                    callback(.error(error))
                }

            case .error(let error):
                callback(.error(error))
            }
        }
    }
}

private extension URLRequest {
    mutating func addAuthHeader() {
        setValue("Bearer \(Environment.credentials?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
    }
}
