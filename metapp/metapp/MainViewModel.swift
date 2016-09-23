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

class MainViewModel: MAViewModel, PHPhotoLibraryChangeObserver {
	// MARK: Properties
	/// Scope dispose to avoid leaking
	var disposeBag = DisposeBag()
	
	var imageManager: PHCachingImageManager?
	private var fetchResult: PHFetchResult<PHAsset>?
	
	var assets: PublishSubject<MAPhoto> = PublishSubject<MAPhoto>()
	
	override init() {
		super.init()
	
		
		// Never load photos Unless the user allows to access to photo album
		checkPhotoAuth({() -> Void in
			
			// Sorting condition
			let options = PHFetchOptions()
			options.sortDescriptors = [
				NSSortDescriptor(key: "creationDate", ascending: false)
			]
			
			self.fetchResult = PHAsset.fetchAssets(with: .image, options: options)
			Observable<Int>.generate(initialState: 0, condition: { i in i < self.fetchResult!.count }, iterate: { i in return i+1}).map({ i in
				return MAPhoto(image: nil, id: nil, index: i)
			}).bindTo(self.assets).addDisposableTo(self.disposeBag)
			
			
			/*
			if images.count > 0 {
			
			//changeImage(images[0] as! PHAsset)
			collectionView.reloadData()
			collectionView.selectItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: UICollectionViewScrollPosition.None)
			}
			*/
			PHPhotoLibrary.shared().register(self)
			},{ () -> Void in
				
		})
	}
	
	func photoLibraryDidChange(_ changeInstance: PHChange)
	{
		
	}
	
	// Check the status of authorization for PHPhotoLibrary
	private func checkPhotoAuth(_ successBlock: @escaping () -> Void,_ deniedBlock: @escaping () -> Void) {
		
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
