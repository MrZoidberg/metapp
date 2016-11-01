//
//  MACachedPhotoRequestor.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/1/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import UIKit
import Photos
import XCGLogger

protocol MAPhotoRequestor {
    func requestImage(_ asset: PHAsset, _ imageSize: CGSize, _ usingBlock: @escaping (UIImage) -> Void)
    func stopCachingImagesForAllAssets()
}

final class MACachedPhotoRequestor: PHCachingImageManager, MAPhotoRequestor {
    
    let log: XCGLogger?
    
    init(log: XCGLogger?) {
        self.log = log
    }
    
    func requestImage(_ asset: PHAsset, _ imageSize: CGSize, _ usingBlock: @escaping (UIImage) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        log?.debug("Requesting image for asset id: \(asset.localIdentifier)")
        
        self.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFit, options: options)
        { result, info in
            usingBlock(result!)
        }
    }
}
