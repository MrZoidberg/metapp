//
//  MAImageMetadata.swift
//  metapp
//
//  Created by Mikhail Merkulov on 11/4/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import RealmSwift


class MAImageMetadata: Object {
	dynamic var exifMetadata: MAExifMetadata?
}

class Size {
	public let width: RealmOptional<Double> = RealmOptional<Double>()
	public let height: RealmOptional<Double> = RealmOptional<Double>()
	
	required init() {
		
	}
	
	optional init(_ size: CGSize) {
		width.value = Double(size.width)
		height.value = Double(szie.height)
	}
}

class MAExifMetadata
{
	public dynamic var imageId: String?
	public dynamic var bodySerialNumber: String?
	public dynamic var lensSpecification: String?
	public dynamic var lensMake: String?
	public dynamic var lensModel: String?
	public dynamic var lensSerialNumber: String?
	public dynamic var colorSpace: String?
	/** In common tog parlance, this'd be "aperture": f/2.8 etc.*/
	public let fNumber: RealmOptional<Double> = RealmOptional<Double>()
	public let focalLength: RealmOptional<Double> = RealmOptional<Double>()
	public let focalLength35mmEquivalent: RealmOptional<Double> = RealmOptional<Double>()
	public let iso: RealmOptional<Double> = RealmOptional<Double>()
	public let shutterSpeed: RealmOptional<Double> = RealmOptional<Double>()
	public dynamic var nativeSize: Size?
	
	public let originalTimestamp: Date?
	public let digitizedTimestamp: Date?
	
	public let subjectDistance: Double?
	public let subjectArea: [Double]?
	public let flashMode: FlashMode?
}
