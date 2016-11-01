//
//  MAViewModel.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import XCGLogger

open class MAViewModel: NSObject, Loggable {
    let log: XCGLogger?
    
    init (log: XCGLogger?) {
        self.log = log
    }
}
