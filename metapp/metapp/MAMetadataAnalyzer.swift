//
//  MAMetadataAnalyzer.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/2/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import Photos
import RxSwift
import RxCocoa
import Carpaccio

protocol MAMetadataAnalyzer {
    var progress: BehaviorSubject<Int> {get}
    func analyzeImage(_ image:PHAsset)
    func cancel()
}

final class MABgMetadataAnalyzer: MAMetadataAnalyzer {
    let progress: BehaviorSubject<Int> = BehaviorSubject<Int>(value: 0)
    let queue: PublishSubject<PHAsset> = PublishSubject<PHAsset>()
    let disposeBag: DisposeBag = DisposeBag()
    let imageManager: PHImageManager = PHImageManager()
    
    init() {
        queue.observeOn(SerialDispatchQueueScheduler.init(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), internalSerialQueueName: "QueueMetadataAnalyzer")).subscribe(onNext: onNextImage, onError: nil, onCompleted: nil, onDisposed: nil).addDisposableTo(disposeBag)
    }
    
    // MARK: Public functions
    
    func analyzeImage(_ image:PHAsset) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true
        options.resizeMode = .none
        
        //log?.debug("Requesting image for asset id: \(image.localIdentifier)")
        
        imageManager.requestImageData(for: image, options: options) { imageData, dataUTI, orientation, info in
            
            //let converter = RAWImageLoader(imageURL: img1URL, thumbnailScheme: .fullImageWhenThumbnailMissing)

        }
    }
    
    func cancel() {
        
    }
    
    // MARK: Private functions
    
    func onNextImage(_ image:PHAsset) {
       
        let converter = RAWImageLoader(imageURL: img1URL, thumbnailScheme: .fullImageWhenThumbnailMissing)
    }
    
    
}
