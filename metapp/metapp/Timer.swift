//
//  Timer.swift
//  metapp
//
//  Created by Mykhaylo Merkulov on 11/2/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import Foundation

func elapsedTime <A> (_ f: @autoclosure () -> A) -> (result:A, duration: Double) {
    var info = mach_timebase_info(numer: 0, denom: 0)
    mach_timebase_info(&info)
    let begin = mach_absolute_time()
    let result = f()
    let diff = Double(mach_absolute_time() - begin) * Double(info.numer) / Double(info.denom)
    return (result, diff)
}
