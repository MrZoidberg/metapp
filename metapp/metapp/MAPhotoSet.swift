//
//  MAPhotoSet.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/8/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import RealmSwift

enum PhotoSetId: String {
    case main = "mainPhotoSet"
}

final class MAPhotoSetRepresentation: Object {
    
    dynamic var photoSetData = NSData()
    dynamic var id: String? = PhotoSetId.main.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

protocol PhotoSet {
    var set: Set<String> {get set}
    
    func load()
    func save()
}

final class MAPhotoSet: PhotoSet {
    
    private var inner: MAPhotoSetRepresentation
    var set = Set<String>()
    private let realmFactory: RealmFactory
    
    init(_ innerRepresentation: MAPhotoSetRepresentation, realm: @escaping RealmFactory) {
        inner = innerRepresentation
        realmFactory = realm
        
        load()
    }
    
    func load() {
        let obj = try! JSONSerialization.jsonObject(with: inner.photoSetData as Data)
        guard let array = obj as? Array<String> else {
            return
        }
        
        set = Set<String>(array)
    }
    
    func save() {
        let array = Array(set)
        try! inner.photoSetData = JSONSerialization.data(withJSONObject: array) as NSData
        
        let realm = realmFactory()
        realm.add(inner, update: true)
    }
}
