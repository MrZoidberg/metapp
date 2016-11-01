//
//  Loggable.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/2/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation
import XCGLogger

protocol Loggable {
    var log: XCGLogger? { get }
}
