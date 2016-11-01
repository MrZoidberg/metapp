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

struct MAPhoto: Equatable {
	var image: UIImage?
	var id: AnyHashable?
	var asset: PHAsset?
}

func == (lhs: MAPhoto, rhs: MAPhoto) -> Bool {
	return lhs.id == rhs.id
}

extension MAPhoto : IdentifiableType  {
    typealias Identity = String
    
    var identity: String {
        return id as! String
    }
}

