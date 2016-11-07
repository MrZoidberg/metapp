//
//  MainViewModel.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Photos
import XCGLogger
import RealmSwift
import RxRealm

typealias PhotoRequestorFactory = () -> MAPhotoRequestor

final class MainViewModel: MAViewModel {
	// MARK: Properties
	/// Scope dispose to avoid leaking
	var disposeBag = DisposeBag()
	
    private var photoRequestorFactory: PhotoRequestorFactory?
	private var imageManager: MAPhotoRequestor?
	private var fetchResult: PHFetchResult<PHAsset>?
	private var analyzer: MAMetadataAnalyzer?
    private var realm: Realm?
    
    var photoSource: Results<MAPhoto>!
    //var photos: Observable<(Results<MAPhoto>, RealmChangeset?)>?
    let imageSize: Variable<CGSize> = Variable(CGSize.zero)
    
    var analyzerProgress: BehaviorSubject<Int>? {
        return analyzer?.progress
    }

    func setImageSize(_ size: CGSize) {
        imageSize.value = size;
        imageManager?.stopCachingImagesForAllAssets()
    }

    // MARK: Public methods
    init(photoRequestorFactory: @escaping PhotoRequestorFactory, analyzer: MAMetadataAnalyzer, realm: Realm, log: XCGLogger?) {
		super.init(log: log)
        
        self.photoRequestorFactory = photoRequestorFactory
		self.analyzer = analyzer
        self.realm = realm
        
        self.photoSource = realm.objects(MAPhoto.self).sorted(byProperty: "modificationDate", ascending: false)
        //self.photos = Observable.changesetFrom(photoSource)
    
		// Never load photos Unless the user allows to access to photo album
		checkPhotoAuth({() -> Void in
            DispatchQueue.global(qos: .background).async {[weak self] in
                self?.startPhotoAnalyzer()
            }
        },{ () -> Void in
				
		})
	}
    
    private func startPhotoAnalyzer() {
        // Sorting condition
        let options = PHFetchOptions()
        options.includeAssetSourceTypes = .typeUserLibrary
        if Settings.lastAnalyzedModificationDate != nil {
            options.sortDescriptors = [
                NSSortDescriptor(key: "modificationDate", ascending: true)
            ]
            options.predicate = NSPredicate(format: "modificationDate > %@", Settings.lastAnalyzedModificationDate! as NSDate)
        } else {
            options.sortDescriptors = [
                NSSortDescriptor(key: "modificationDate", ascending: false)
            ]
        }
        //options.fetchLimit = 100
        
        self.fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        self.sendPhotosToAnalyzer()
        PHPhotoLibrary.shared().register(self)
    }
    
    private func sendPhotosToAnalyzer() {
        let count = self.fetchResult!.count
        guard let ar = self.fetchResult?.objects(at: IndexSet(0..<count)) else {
            return
        }
        
        self.analyzer?.analyzeImages(ar)
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
	
	func requestImage(_ imageId: String, _ usingBlock: @escaping (UIImage) -> Void) {
        self.imageManager?.requestImage(imageId, self.imageSize.value, usingBlock)
	}
}

extension MainViewModel: PHPhotoLibraryChangeObserver
{
    func photoLibraryDidChange(_ changeInstance: PHChange)
    {
        
    }
}
