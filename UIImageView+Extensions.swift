//
//  UIImageView+Extensions.swift
//  HushPhotoPicker
//
//  Created by Joshua Shen on 12/13/18.
//

import Foundation
import Photos

extension UIImageView {
    
    func loadImage(_ asset: PHAsset) {
        guard frame.size != CGSize.zero else {
            image = TLBundle.podBundleImage(named: "insertPhotoMaterial")
            return
        }
        
        if tag == 0 {
            image = TLBundle.podBundleImage(named: "insertPhotoMaterial")
        } else {
            PHImageManager.default().cancelImageRequest(PHImageRequestID(tag))
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let id = PHImageManager.default().requestImage(
            for: asset,
            targetSize: frame.size,
            contentMode: .aspectFill,
            options: options) { [weak self] image, _ in
                self?.image = image
        }
        
        tag = Int(id)
    }
    
}
