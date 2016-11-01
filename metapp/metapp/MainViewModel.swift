//
//  MainViewModel.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import RxSwift
import Photos
import Async
import XCGLogger

typealias PhotoRequestorFactory = () -> MAPhotoRequestor

final class MainViewModel: MAViewModel {
	// MARK: Properties
	/// Scope dispose to avoid leaking
	var disposeBag = DisposeBag()
	
    private var photoRequestorFactory: PhotoRequestorFactory?
	private var imageManager: MAPhotoRequestor?
	private var fetchResult: PHFetchResult<PHAsset>?
	
    let assets: PublishSubject<PHAsset> = PublishSubject<PHAsset>()
    let imageSize: Variable<CGSize> = Variable(CGSize.zero)

    func setImageSize(_ size: CGSize) {
        imageSize.value = size;
        imageManager?.stopCachingImagesForAllAssets()
    }

    // MARK: Public methods
    init(photoRequestorFactory: @escaping PhotoRequestorFactory, log: XCGLogger?) {
		super.init(log: log)
        
        self.photoRequestorFactory = photoRequestorFactory
		
		// Never load photos Unless the user allows to access to photo album
		checkPhotoAuth({() -> Void in
			
			// Sorting condition
			let options = PHFetchOptions()
			options.sortDescriptors = [
				NSSortDescriptor(key: "creationDate", ascending: false)
			]
			//options.fetchLimit = 100
			
			self.fetchResult = PHAsset.fetchAssets(with: .image, options: options)
			
			let count = self.fetchResult!.count
            self.fetchResult?.enumerateObjects({ (asset, idx, stop) in
				self.assets.onNext(asset)
				if (count == idx + 1) {
					self.assets.onCompleted()
				}
			})
			PHPhotoLibrary.shared().register(self)
        },{ () -> Void in
				
		})
	}
	
    // MARK: Private methods
    
	// Check the status of authorization for PHPhotoLibrary
	private func checkPhotoAuth(_ successBlock: @escaping () -> Void, _ deniedBlock: @escaping () -> Void) {
		
        log?.debug("Requesting access to PHPhotoLibrary")
        
		PHPhotoLibrary.requestAuthorization {[weak self] (status) -> Void in
			switch status {
                case .authorized:
                    self?.log?.debug("Access to PHPhotoLibrary granted")
                    self?.imageManager = self?.photoRequestorFactory!()
                    successBlock()
                    
                case .restricted, .denied:
                    self?.log?.debug("Access to PHPhotoLibrary denied")
                    deniedBlock()
                default:
                    break
			}
		}
	}
	
	func requestImage(_ asset: PHAsset, _ usingBlock: @escaping (UIImage) -> Void) {
        self.imageManager?.requestImage(asset, self.imageSize.value, usingBlock)
	}
}

extension MainViewModel: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(_ changeInstance: PHChange)
    {
        
    }
}
