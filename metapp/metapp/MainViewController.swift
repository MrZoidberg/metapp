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

typealias SectionPhotoModel = SectionModel<String, MAPhoto>

class PhotoCell: UICollectionViewCell {
	@IBOutlet var image: UIImage?
}

class MainViewController: UIViewController, UICollectionViewDelegate {
	
	let disposeBag = DisposeBag()
	
	let collectionDataSource = RxCollectionViewSectionedReloadDataSource<SectionPhotoModel>()
	
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
		
		collectionDataSource.configureCell = { (ds, cv, ip, i) in
			let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: ip) as! PhotoCell
			cell.image = ds[ip].image
			return cell
        }
        
        Observable.from(viewModel!.assets!).subscribe{ event in
                self.viewModel!.requestImage(PHAsset(), { (image) in
                    self.photoItems.onNext(MAPhoto(image: image, id: event.element!?.localIdentifier, index: 0))
                })
        }.addDisposableTo(disposeBag)
    
        let r = photoItems.toArray()
            })//.bindTo(collectionView.rx.items(dataSource: self.collectionDataSource)).addDisposableTo(disposeBag)
        
        collectionView.rx
            .setDelegate(self)
            .addDisposableTo(disposeBag)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

