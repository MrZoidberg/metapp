//
//  AppDelegate.swift
//  metapp
//
//  Created by Mikhail Merkulov on 9/22/16.
//  Copyright © 2016 ZoidSoft. All rights reserved.
//

import UIKit
import Swinject
import SwinjectStoryboard
import XCGLogger
import Carpaccio
import RealmSwift

typealias RealmFactory = () -> Realm

func synchronized(_ lock: AnyObject, _ body: () -> ()) {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    body()
}

func synchronized<T>(_ lockObj: AnyObject!, _ closure: () throws -> T) rethrows ->  T
{
    objc_sync_enter(lockObj)
    defer {
        objc_sync_exit(lockObj)
    }
    
    return try closure()
}

extension SwinjectStoryboard {
	class func setup() {
		
        defaultContainer.registerForStoryboard(MainViewController.self) {r, c in
            c.viewModel = MainViewModel(photoRequestorFactory: { r.resolve(MAPhotoRequestor.self)! },
                                        analyzer: r.resolve(MAMetadataAnalyzer.self)!,
                                        realm: r.resolve(Realm.self)!,
                                        log: r.resolve(XCGLogger.self)
            )
		}
        
        defaultContainer.register(XCGLogger.self) { _ in
            let log = XCGLogger.default
            log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
            
            let emojiLogFormatter = PrePostFixLogFormatter()
            emojiLogFormatter.apply(prefix: "🗯", postfix: "", to: .verbose)
            emojiLogFormatter.apply(prefix: "🔹", postfix: "", to: .debug)
            emojiLogFormatter.apply(prefix: "ℹ️", postfix: "", to: .info)
            emojiLogFormatter.apply(prefix: "⚠️", postfix: "", to: .warning)
            emojiLogFormatter.apply(prefix: "‼️", postfix: "", to: .error)
            emojiLogFormatter.apply(prefix: "💣", postfix: "", to: .severe)
            log.formatters = [emojiLogFormatter]

            return log
        }.inObjectScope(ObjectScope.container)
        
        defaultContainer.register(MAPhotoRequestor.self) {r in
            MACachedPhotoRequestor(log: r.resolve(XCGLogger.self))
        }.inObjectScope(ObjectScope.container)
		
		defaultContainer.register(ImageMetadataLoader.self) {r in
			RAWImageMetadataLoader()
			}
		
		defaultContainer.register(MAMetadataAnalyzer.self) {r in
			MABgMetadataAnalyzer(imageMetadataLoaderFactory: { r.resolve(ImageMetadataLoader.self)!},
			                     realm:{ r.resolve(Realm.self)!},
			                     log: r.resolve(XCGLogger.self))
			}.inObjectScope(ObjectScope.container)
        
        defaultContainer.register(Realm.Configuration.self) { _ in
            // not really necessary if you stick to the defaults everywhere
            return Realm.Configuration()
        }
        
        defaultContainer.register(Realm.self) { r in
            try! Realm(configuration: r.resolve(Realm.Configuration.self)!)
        }
        
        defaultContainer.register(PhotoSet.self) { r in
            return MAPhotoSet((r.resolve(Realm.self)?.object(ofType: MAPhotoSetRepresentation.self, forPrimaryKey: PhotoSetId.main.rawValue)) ?? MAPhotoSetRepresentation(), realm: { r.resolve(Realm.self)!})
        }.inObjectScope(ObjectScope.container)
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

