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
//import RxCocoa
import Photos

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

extension MAPhoto : IdentifiableType  {
	typealias Identity = String
	
	var identity: String {
		return id as! String
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
}

final class MainViewController: UIViewController, UICollectionViewDelegate {
	
	let disposeBag = DisposeBag()
	
	let collectionDataSource = RxCollectionViewSectionedAnimatedDataSource<PhotoSection>()
	
	// MARK: Properties
	var viewModel: MainViewModel?
    let photoItems: PublishSubject<MAPhoto> = PublishSubject<MAPhoto>()
    
	@IBOutlet weak var collectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib
		
		guard (viewModel != nil) else {
			return
		}
		
        viewModel?.rx.observe(CGSize.self, "imageSize")
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { (size) in
                if size != CGSize.zero {
                    (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = size!
                    self.collectionView.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
		collectionDataSource.configureCell = { (ds, cv, ip, i) in
			let cell = cv.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: ip) as! PhotoCell
			let photoModel = ds[ip]
			self.viewModel!.requestImage(photoModel.asset!, { (image) in
				print("loading photo \(photoModel.identity) +  for \(ip.description)")
				cell.image.image = image
			})
			return cell
        }
    
		collectionView.rx
			.setDelegate(self)
			.addDisposableTo(disposeBag)
		
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
		
        viewModel!.assets.subscribe{ event in
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

	}
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel?.imageSize = calcOptimalImageSize()
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    func calcOptimalImageSize() -> CGSize {
        let dimension: Double = Double(collectionView.bounds.width) / 2.0 - 5.0*2
        print("collection view size is \(collectionView.bounds.debugDescription). Image size is \(dimension)")
        return CGSize(width: dimension, height: dimension)
    }
}
