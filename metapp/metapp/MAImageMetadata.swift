//
//  MAImageMetadata.swift
//  metapp
//
//  Created by Mikhail Merkulov on 11/4/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import RealmSwift
import Carpaccio

class MAImageMetadata: Object {
    public dynamic var id: String? = UUID().uuidString
    
	dynamic var exifMetadata: MAExifMetadata?
    
    convenience init(_ metadata: ImageMetadata) {
        self.init()
        
        exifMetadata = MAExifMetadata(metadata.exif)
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

class Size: Object {
	public let width: RealmOptional<Double> = RealmOptional<Double>()
	public let height: RealmOptional<Double> = RealmOptional<Double>()
	
	
    convenience init(_ size: CGSize) {
        self.init()
        
		self.width.value = Double(size.width)
		self.height.value = Double(size.height)
	}
}

class SubjectAreaItem: Object {
    public let coordinate: RealmOptional<Double> = RealmOptional<Double>()
    
    convenience init(_ value: Double) {
        self.init()
        
        self.coordinate.value = value
    }
}

class SubjectArea: Object {
    
    public let coordinates: List<SubjectAreaItem> = List<SubjectAreaItem>()
    
    convenience init(_ coordsArray: [Double]?) {
        self.init()
        
        guard let array = coordsArray else {
            return
        }
        
        for coordinateValue in array {
            coordinates.append(SubjectAreaItem(coordinateValue))
        }
    }
}

class MAExifMetadata: Object
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
	
	public dynamic var originalTimestamp: NSDate? = nil
	public dynamic var digitizedTimestamp: NSDate? = nil
	
	public let subjectDistance: RealmOptional<Double> = RealmOptional<Double>()
    public dynamic var subjectArea: SubjectArea?
    public let flashModeRawValue = RealmOptional<Int>()
    
	public var flashMode: FlashMode?
    {
        get {
            return flashModeRawValue.value == nil ? nil : FlashMode(rawValue: flashModeRawValue.value!)
        }
        set {
            flashModeRawValue.value = newValue?.rawValue
        }
    }
    
    convenience init(_ exif: ExifMetadata) {
        self.init()
        
        imageId = exif.imageId
        bodySerialNumber = exif.bodySerialNumber
        lensSpecification = exif.lensSpecification
        lensMake = exif.lensMake
        lensModel = exif.lensModel
        lensSerialNumber = exif.lensSerialNumber
        colorSpace = exif.colorSpace?.name as? String
        fNumber.value = exif.fNumber
        focalLength.value = exif.focalLength
        focalLength35mmEquivalent.value = exif.focalLength35mmEquivalent
        iso.value = exif.iso
        shutterSpeed.value = exif.shutterSpeed
        nativeSize = Size(exif.nativeSize)
        originalTimestamp = exif.originalTimestamp as NSDate?
        digitizedTimestamp = exif.digitizedTimestamp as NSDate?
        subjectDistance.value = exif.subjectDistance
        subjectArea = exif.subjectArea == nil ? nil : SubjectArea(exif.subjectArea)
        flashMode = exif.flashMode
    }
}
