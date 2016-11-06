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
import RealmSwift
import RxRealm

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

final class MainViewController: UIViewController, Loggable {
		
	//private let collectionDataSource = RxCollectionViewSectionedAnimatedDataSource<PhotoSection>()
	
	// MARK: Properties
	var viewModel: MainViewModel?
    //let photoItems: PublishSubject<MAPhoto> = PublishSubject<MAPhoto>()
    var log: XCGLogger?
    let disposeBag = DisposeBag()
    var photosUpdateToken: NotificationToken? = nil
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    deinit {
        photosUpdateToken?.stop()
    }
	
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
                    (self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = size
                    self.collectionView?.reloadData()
                }
            })
            .addDisposableTo(disposeBag)
        
        //let a = progressView.rx.progress.asObserver()
        
        viewModel?.analyzerProgress?.map({ p in
                return Float(p) / 100
            })
            .observeOn(MainScheduler.instance)
            .bindTo(progressView.rx.progress)
            .addDisposableTo(disposeBag)

        photosUpdateToken = viewModel?.photoSource.addNotificationBlock({[weak self] (changes) in
            self?.applyCollectionChange(changes)
        })
        
        //bind PhotoCell to data source
        /*
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
        */
        //bind delegate to collectionView
        /*
        self.collectionView.rx
			.setDelegate(self)
			.addDisposableTo(disposeBag)
		*/
        registerForPreviewing(with: self, sourceView: self.collectionView!)
	}
    
    override func viewDidAppear(_ animated: Bool) {
        viewModel?.setImageSize(calcOptimalImageSize())
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    /*
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        self.collectionViewLayout.invalidateLayout()
    }
 
    
    public override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.numberOfSections()
    }
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.numberOfRowsForSectionIndex(section)
    }
    */
    func calcOptimalImageSize() -> CGSize {
        self.collectionView!.collectionViewLayout.invalidateLayout()
        let contentSize = self.collectionView!.collectionViewLayout.collectionViewContentSize
        let dimension: Double = Double(contentSize.width) / 2.0 - 5.0*2
        self.log?.debug("collection view size is \(self.collectionView!.bounds.debugDescription). Image size is \(dimension)")
        return CGSize(width: dimension, height: dimension)
    }
}

extension MainViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return self.viewModel?.photoSource.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        guard let viewModel = self.viewModel else {
            return cell
        }
        
        let photoModel: MAPhoto = viewModel.photoSource[(indexPath as NSIndexPath).item]
        cell.viewModel = photoModel
        self.viewModel!.requestImage(photoModel.id!, {(image) in
            //self?.log?.debug("loading photo \(photoModel.identity) +  for \(ip.description)")
            cell.image.image = image
        })
        return cell
    }
}

extension MainViewController: UIViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                        viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.collectionView!.indexPathForItem(at: location), let cell = self.collectionView!.cellForItem(at: indexPath) as? PhotoCell,
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

extension MainViewController {
    func applyCollectionChange(_ changes: RealmCollectionChange<Results<MAPhoto>>) {
        switch changes {
        case .initial:
            self.collectionView?.reloadData()
        break
        case .update(_, deletions: let deletions, insertions: let insertions, modifications: let modifications):
            //Changeset<PhotoSection>
            self.collectionView?.performBatchUpdates({
                self.collectionView?.deleteItemsAtIndexPaths(self.indexesToIndexPathes(deletions), animationStyle: .automatic)
                self.collectionView?.insertItemsAtIndexPaths(self.indexesToIndexPathes(insertions), animationStyle: .automatic)
                self.collectionView?.reloadItemsAtIndexPaths(self.indexesToIndexPathes(modifications), animationStyle: .automatic)
                
            }, completion: { (b) in
                
            })
        break
        case .error(let err):
            self.log?.error("Cannot load photos. Error: \(err.localizedDescription)")
        // An error occurred while opening the Realm file on the background worker thread
        //fatalError("\(err)")
        break
               //insertItems(at: changes.inserted.map { IndexPath(row: $0, section: 0) })
        //reloadItems(at: changes.updated.map { IndexPath(row: $0, section: 0) })
        //deleteItems (at: changes.deleted.map { IndexPath(row: $0, section: 0) })
        }
    }
    
     func indexesToIndexPathes(_ indexes: [Int], atSection section: Int? = 0) -> [IndexPath] {
        return indexes.map({ (index) -> IndexPath in
            IndexPath(item: index, section: section!)
        })
    }
}
