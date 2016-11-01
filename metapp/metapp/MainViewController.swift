//
//  ViewController.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Photos
import XCGLogger

struct PhotoSection {
	var header: String
	
	var photos: [MAPhoto]
	
	var updated: Date
	
	init(header: String, photos: [MAPhoto], updated: Date) {
		self.header = header
		self.photos = photos
		self.updated = updated
	}
}

extension PhotoSection : AnimatableSectionModelType {
	typealias Item = MAPhoto
	typealias Identity = String
	
	var identity: String {
		return header
	}
	
	var items: [MAPhoto] {
		return photos
	}
	
	init(original: PhotoSection, items: [Item]) {
		self = original
		self.photos = items
	}
}


class PhotoCell: UICollectionViewCell {
	@IBOutlet weak var image: UIImageView!
    var viewModel: MAPhoto?
}

final class MainViewController: UIViewController, UICollectionViewDelegate, Loggable {
		
	private let collectionDataSource = RxCollectionViewSectionedAnimatedDataSource<PhotoSection>()
	
	// MARK: Properties
	var viewModel: MainViewModel?
    let photoItems: PublishSubject<MAPhoto> = PublishSubject<MAPhoto>()
    var log: XCGLogger?
    let disposeBag = DisposeBag()
    
	@IBOutlet weak var collectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib
		
		guard (viewModel != nil) else {
			return
		}
		
        //bind imageSize from model to collectionView
        viewModel?.imageSize
            .asObservable()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: {[unowned self] (size) in
                if size != CGSize.zero {
                    (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = size
                    self.collectionView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        //bind PhotoCell to data source
		collectionDataSource.configureCell = {[unowned self] (ds, cv, ip, i) in
			let cell = cv.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: ip) as! PhotoCell
            let photoModel: MAPhoto = ds[ip]
            cell.viewModel = photoModel
			self.viewModel!.requestImage(photoModel.asset!, {[weak self] (image) in
				self?.log?.debug("loading photo \(photoModel.identity) +  for \(ip.description)")
				cell.image.image = image
			})
			return cell
        }
    
        //bind delegate to collectionView
		collectionView.rx
			.setDelegate(self)
			.addDisposableTo(disposeBag)
		
        //bind photos to collectionView
		photoItems.asObservable()
			.reduce([MAPhoto]()) {acc, photo in
				var newAcc = acc;
				newAcc.append(photo)
				return newAcc
			}
			.map { photos in
				return [PhotoSection(header: "1", photos: photos, updated: Date.init())]
			}
			.observeOn(MainScheduler.instance)
			.bindTo(collectionView.rx.items(dataSource: collectionDataSource))
			.addDisposableTo(disposeBag)
		
        //bind assets to photos
        viewModel!.assets.subscribe{[unowned self] event in
			switch(event)
			{
				case .completed:
					self.photoItems.onCompleted()
					return
				default: break
			}
			
			let asset = event.element!
			self.photoItems.onNext(MAPhoto(image: nil, id: asset.localIdentifier, asset: asset))
			
        }.addDisposableTo(disposeBag)
        
        registerForPreviewing(with: self, sourceView: collectionView)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel?.setImageSize(calcOptimalImageSize())
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    func calcOptimalImageSize() -> CGSize {
        collectionView.collectionViewLayout.invalidateLayout()
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        let dimension: Double = Double(contentSize.width) / 2.0 - 5.0*2
        self.log?.debug("collection view size is \(self.collectionView.bounds.debugDescription). Image size is \(dimension)")
        return CGSize(width: dimension, height: dimension)
    }
}

extension MainViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                        viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location), let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell,
            let photoModel = cell.viewModel else {
            return nil
        }
        
        
        guard let peekPhotoViewController = storyboard?.instantiateViewController(withIdentifier: "PeekPhotoViewController") as? PeekPhotoViewController else { return nil }
        
        peekPhotoViewController.viewModel = photoModel
        return peekPhotoViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
    }
}
