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
import XCGLogger

protocol MAMetadataAnalyzer {
    var progress: BehaviorSubject<Int> {get}
    
    func analyzeImages(_ images:[PHAsset])
    func cancel()
}

final class MABgMetadataAnalyzer: MAMetadataAnalyzer {
    private var totalItems: Int = 0
    private var processedItems: Int = 0
    private var totalTime: Double = 0
    
    let progress: BehaviorSubject<Int> = BehaviorSubject<Int>(value: 0)
    private let queue: PublishSubject<PHAsset> = PublishSubject<PHAsset>()
    private let imageManager: PHImageManager = PHImageManager()
	private let log: XCGLogger?
    
    let disposeBag: DisposeBag = DisposeBag()
    
    init(log: XCGLogger?) {
		self.log = log
		
        queue.observeOn(ConcurrentDispatchQueueScheduler.init(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)))
			.subscribe(onNext: self.onNextImage, onError: nil, onCompleted: nil, onDisposed: nil)
			.addDisposableTo(disposeBag)
    }
    
    // MARK: Public functions
    
    func analyzeImages(_ images:[PHAsset]) {
        totalItems += images.count
        for image in images {
            queue.onNext(image)
        }
    }
    
    func cancel() {
		queue.onCompleted()
    }
    
    // MARK: Private functions
    
    private func onNextImage(_ image:PHAsset) {
		let options = PHImageRequestOptions()
		options.isNetworkAccessAllowed = false
		options.isSynchronous = true
		options.resizeMode = .none
		
		//log?.debug("Requesting image for asset id: \(image.localIdentifier)")
        
        let start = DispatchTime.now() 
		
		imageManager.requestImageData(for: image, options: options) { imageData, dataUTI, orientation, info in
			guard let imageNsData = imageData as NSData?, let dataPtr = CFDataCreate(kCFAllocatorDefault, imageNsData.bytes.assumingMemoryBound(to: UInt8.self), imageNsData.length), let imageSourceData = CGImageSourceCreateWithData(dataPtr, nil) else {
                self.processedItems += 1
                self.reportProgress(start)
				return
			}
            
            let converter = RAWImageLoader(imageSource: imageSourceData, thumbnailScheme: .fullImageWhenThumbnailMissing)
            converter.loadImageMetadata({ metadata in
                
            }, errorHandler: {error in
                self.log?.error("Cannot get image metadata from \(image.localIdentifier): \(error)")
            })
            
            self.processedItems += 1
            let end = DispatchTime.now()
            self.reportProgress(start, end)
		}
	}
    
    private func reportProgress(_ jobStartTime: DispatchTime, _ jobEndTime: DispatchTime? = nil) {
        progress.onNext(processedItems * 100 / totalItems)
        
        if (jobEndTime != nil) {
            let nanoTime = jobEndTime!.uptimeNanoseconds - jobStartTime.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_0000 // Technically could overflow for long running tests
            self.totalTime += timeInterval
            
            log?.debug("processed \(self.processedItems) of \(self.totalItems) items. item time: \(timeInterval) ms. Total time: \(self.totalTime)")

        } else {
            log?.debug("processed \(self.processedItems) of \(self.totalItems) items. item didn't succeed")
        }
        
    }
}
