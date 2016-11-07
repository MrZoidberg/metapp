//
//  MAPhoto.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/23/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import UIKit
import Photos
import RxDataSources
import RealmSwift
import RxRealm

final class MAPhoto: Object {
    var image: UIImage?
    var asset: PHAsset?
    
    public dynamic var id: String? = nil
    public dynamic var metadata: MAImageMetadata?
    public dynamic var modificationDate: NSDate? = nil
    public dynamic var creationDate: NSDate? = nil
    
    convenience init(id: String, asset: PHAsset, metadata: MAImageMetadata) {
        self.init()
        self.id = id
        self.asset = asset
        self.metadata = metadata
        self.modificationDate  = asset.modificationDate as NSDate?
        self.creationDate = asset.creationDate as NSDate?
    }
    
    override static func ignoredProperties() -> [String] {
        return ["image", "asset"]
    }
    
    override static func indexedProperties() -> [String] {
        return ["modificationDate"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

func == (lhs: MAPhoto, rhs: MAPhoto) -> Bool {
	return lhs.id == rhs.id
}

extension MAPhoto : IdentifiableType  {
    typealias Identity = String
    
    var identity: String {
        return id!
    }
}

