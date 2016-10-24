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

class MainViewModel: MAViewModel {
	// MARK: Properties
	/// Scope dispose to avoid leaking
	var disposeBag = DisposeBag()
	
	var imageManager: PHCachingImageManager?
	private var fetchResult: PHFetchResult<PHAsset>?
	
    let assets: PublishSubject<PHAsset> = PublishSubject<PHAsset>()
    private var photoCount = 0
    var count: Int {
        get {
            return photoCount
        }
    }
	
	override init() {
		super.init()
		
		// Never load photos Unless the user allows to access to photo album
		checkPhotoAuth({() -> Void in
			
			// Sorting condition
			let options = PHFetchOptions()
			options.sortDescriptors = [
				NSSortDescriptor(key: "creationDate", ascending: false)
			]
			options.fetchLimit = 100
			
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
	
	// Check the status of authorization for PHPhotoLibrary
	private func checkPhotoAuth(_ successBlock: @escaping () -> Void, _ deniedBlock: @escaping () -> Void) {
		
		PHPhotoLibrary.requestAuthorization { (status) -> Void in
			switch status {
			case .authorized:
				self.imageManager = PHCachingImageManager()
				successBlock()
				
			case .restricted, .denied:
				deniedBlock()
			default:
				break
			}
		}
	}
	
	func requestImage(_ asset: PHAsset, _ usingBlock: @escaping (UIImage) -> Void) {
		let options = PHImageRequestOptions()
		options.isNetworkAccessAllowed = true
		options.isSynchronous = false
		//options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic
        		
		self.imageManager!.requestImage(for: asset,
		                                        targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
		                                        contentMode: .aspectFill,
		                                        options: options) {
													result, info in
													
			usingBlock(result!)
		}
	}

}

extension MainViewModel: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(_ changeInstance: PHChange)
    {
        
    }
}
