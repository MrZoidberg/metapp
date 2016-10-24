//
//  MAPhoto.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/23/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import UIKit

struct MAPhoto: Equatable {
	var image: UIImage?
	var id: AnyHashable?
	let index: Int
}

func == (lhs: MAPhoto, rhs: MAPhoto) -> Bool {
	return lhs.id == rhs.id && lhs.index == rhs.index
}

