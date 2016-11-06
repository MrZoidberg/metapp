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
import RealmSwift

protocol MAMetadataAnalyzer {
    var progress: BehaviorSubject<Int> {get}
    
    func analyzeImages(_ images:[PHAsset])
    func cancel()
}

typealias ImageMetadataLoaderFactory = () -> ImageMetadataLoader

final class MABgMetadataAnalyzer: MAMetadataAnalyzer {
    private var totalItems: Int = 0
    private var processedItems: Int = 0
    private var totalTime: Double = 0
    
    let progress: BehaviorSubject<Int> = BehaviorSubject<Int>(value: 0)
    private let queue: PublishSubject<PHAsset> = PublishSubject<PHAsset>()
    private let imageManager: PHImageManager = PHImageManager()
	private let log: XCGLogger?
	private let imageMetadataLoaderFactory: ImageMetadataLoaderFactory
    private let realm: RealmFactory
    
    let disposeBag: DisposeBag = DisposeBag()
    
    public init(imageMetadataLoaderFactory: @escaping ImageMetadataLoaderFactory, realm: @escaping RealmFactory, log: XCGLogger?) {
        
		self.log = log
		self.imageMetadataLoaderFactory = imageMetadataLoaderFactory
        self.realm = realm
			
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
        
        let realm = self.realm()
        
        var photo = realm.object(ofType: MAPhoto.self, forPrimaryKey: image.localIdentifier)
        
		imageManager.requestImageData(for: image, options: options) { imageData, dataUTI, orientation, info in
			guard let imageNsData = imageData as NSData?, let dataPtr = CFDataCreate(kCFAllocatorDefault, imageNsData.bytes.assumingMemoryBound(to: UInt8.self), imageNsData.length), let imageSourceData = CGImageSourceCreateWithData(dataPtr, nil) else {
                self.reportProgress(start)
				return
			}
            
            let converter = self.imageMetadataLoaderFactory()
            var metadataStruct: ImageMetadata? = nil
            do {
                try metadataStruct = converter.loadImageMetadata(imageSource: imageSourceData)
            } catch ImageMetadataLoadError.imageUrlIsInvalid {
                //TODO: log error
            } catch ImageMetadataLoadError.cannotFindImageProperties {
                //TODO: log error
            } catch {
                //TODO: log error
            }
            
            if metadataStruct == nil {
                self.reportProgress(start)
                return
            }
            
            let metadata = MAImageMetadata(metadataStruct!)
            
            if photo == nil {
                photo = MAPhoto(id: image.localIdentifier, asset: image, metadata: metadata)
                try! realm.write {
                    realm.add(photo!)
                }
            } else {
                realm.beginWrite()
                photo?.modificationDate = image.modificationDate as NSDate?
                photo?.metadata = metadata
                try! realm.commitWrite()
            }
            
            let end = DispatchTime.now()
            self.reportProgress(start, end)
		}
	}
    
    private func reportProgress(_ jobStartTime: DispatchTime, _ jobEndTime: DispatchTime? = nil, error: Error? = nil) {
        self.processedItems += 1
        progress.onNext(processedItems * 100 / totalItems)
        
        if (jobEndTime != nil) {
            let nanoTime = jobEndTime!.uptimeNanoseconds - jobStartTime.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_0000 // Technically could overflow for long running tests
            self.totalTime += timeInterval
            
            log?.debug("processed \(self.processedItems) of \(self.totalItems) items. item time: \(timeInterval) ms. Total time: \(self.totalTime)")

        } else {
            log?.debug("processed \(self.processedItems) of \(self.totalItems) items. item didn't succeed. Error: \(error?.localizedDescription)")
        }
        
    }
}
