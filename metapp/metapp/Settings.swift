//
//  Settings.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/7/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation

class Settings {
    private static let lastAnalyzedModificationDateKey = "lastAnalyzedModificationDate"
    
    class var lastAnalyzedModificationDate: Date? {
        get {
           return UserDefaults.standard.object(forKey: lastAnalyzedModificationDateKey) as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKeyPath: lastAnalyzedModificationDateKey)
        }
    }
}
