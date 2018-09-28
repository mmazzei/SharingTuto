//
//  NSExtensionContext+SharingTuto.swift
//  SharingTutoExtension
//
//  Created by Matías Mazzei on 28/09/2018.
//  Copyright © 2018 mmazzei. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import SharingTutoFwk

extension NSExtensionContext {
    private static let imageTypeIdentifier = kUTTypeImage as String

    /// Get the media url from the context and then sends it and its mime type to the callback
    ///
    /// The callback parameters is the jpeg media url. It is no called in case of error.
    func loadImage(callback: @escaping (URL) -> Void) {
        guard let attachment = imageAttachment() else { return }

        attachment.loadItem(forTypeIdentifier: NSExtensionContext.imageTypeIdentifier, options: nil) {[unowned self] (item, error) in
            guard error == nil else {
                print("⚠️ NSExtensionContext - loadImage - error:  \(error!)")
                return
            }

            guard let url = item as? URL else {
                print("⚠️ NSExtensionContext - loadImage - error: URL couldn't be retrieved from the attachment item")
                return
            }

            guard let imageUrl = self.encodeImage(in: url) else {
                return
            }

            callback(imageUrl)
        }
    }

    private func imageAttachment() -> NSItemProvider? {
        guard let media = inputItems.first as? NSExtensionItem else { return nil}
        guard let attachments = media.attachments as? [NSItemProvider] else { return nil }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(NSExtensionContext.imageTypeIdentifier) {
                return attachment
            }
        }
        return nil
    }

    /// Returns the URL of the encoded image. `nil` in case of error
    private func encodeImage(in originalUrl: URL) -> URL? {
        guard let mediaData = try? Data(contentsOf: originalUrl) else {
            print("⚠️ NSExtensionContext - encodeImage - Image couldn't be loaded because url is invalid")
            return nil
        }

        guard let image = UIImage(data: mediaData) else {
            print("⚠️ NSExtensionContext - encodeImage - Image couldn't be loaded because data is invalid")
            return nil
        }

        // Once opened the image, we re-encode it as JPEG
        guard let imageJpegData = UIImageJPEGRepresentation(image, 0.8) else {
            print("⚠️ NSExtensionContext - encodeImage - Image couldn't be encoded as JPEG")
            return nil
        }

        let imageJpegUrl = Environment.sharedContainerUrl.appendingPathComponent(NSUUID().uuidString + ".jpeg")
        do {
            try imageJpegData.write(to: imageJpegUrl, options: .atomic)
        } catch {
            print("⚠️ NSExtensionContext - encodeImage - NSExtensionContext - encodeImage - error: \(error.localizedDescription)")
            return nil
        }

        return imageJpegUrl
    }
}
