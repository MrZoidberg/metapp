//
//  ViewController.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

typealias SectionPhotoModel = SectionModel<String, MAPhoto>

class PhotoCell: UICollectionViewCell {
	@IBOutlet var image: UIImage?
}

class MainViewController: UIViewController, UICollectionViewDelegate {
	
	let disposeBag = DisposeBag()
	
	let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, MAPhoto>>()
	
	// MARK: Properties
	var viewModel: MainViewModel?
	@IBOutlet weak var collectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib
		
		guard (viewModel != nil) else {
			return
		}
		
		dataSource.configureCell = { (ds, cv, ip, i) in
			let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: ip) as! PhotoCell
			cell.image = ds[ip].image
			return cell
		}
		
		viewModel?.assets.asObservable().reduce([MAPhoto](), accumulator: { ar, photo in
			ar.append(photo)
			return ar
			}, mapResult: { SectionPhotoModel(model: "1", items: $0 )})//.bindTo(a(dataSource: dataSource))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

