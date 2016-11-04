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

final class MAPhoto: Object {
    var image: UIImage?
    var asset: PHAsset?
    
    dynamic var id: String?
    
    convenience init(id: String, asset: PHAsset) {
        self.init()
        self.id = id
        self.asset = asset
    }
    
    override static func ignoredProperties() -> [String] {
        return ["image", "asset"]
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

