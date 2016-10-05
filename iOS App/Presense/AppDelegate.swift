//
//  AppDelegate.swift
//  Presense
//
//  Created by Chay Choong on 20/3/16.
//  Copyright © 2016 SUTDiot. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ESTBeaconManagerDelegate {

    var window: UIWindow?
    var operationQueue = OperationQueue()
    
    let beaconManager = ESTBeaconManager()

    
    func beaconManager(_ manager: Any, didEnter region: CLBeaconRegion) {
        print("didEnterRegion")
        let count = operationQueue.operationCount
        print(count)
        if (count > 0) {
            operationQueue.cancelAllOperations()
        }
        else {
            do {
                let notification = UILocalNotification()
                notification.alertBody = "You have entered the region"
                try sendMessage("available")
                notification.soundName = UILocalNotificationDefaultSoundName
                UIApplication.shared.presentLocalNotificationNow(notification)
                saveStatus("available")
            } catch {
                print("URL error")
            }
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "EventNotification"), object: nil, userInfo: ["data": "dummy"])
            })
        }
    }
    
    func beaconManager(_ manager: Any, didExitRegion region: CLBeaconRegion) {
        print("didExitRegion")
        print (operationQueue.operationCount)
        
        let operation1 = BlockOperation(block: {
            sleep(5)
        })
        let operation2 = BlockOperation(block: {
            do {
                let notification = UILocalNotification()
                notification.alertBody = "You have left the region"
                try sendMessage("out of office")
                UIApplication.shared.presentLocalNotificationNow(notification)
                saveStatus("out of office")
            } catch {
                print("URL error")
            }
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "EventNotification"), object: nil, userInfo: ["data": "dummy"])
            })
        })
        operationQueue.addOperation(operation1)
        operation2.addDependency(operation1)
        operationQueue.addOperation(operation2)
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Thread.sleep(forTimeInterval: 1)
        
        self.beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SlackData")
        
        do {
            let result =
                try managedContext.fetch(fetchRequest)
            if (result.count != 0) {
                identity = result[0] as? NSManagedObject
               
                self.beaconManager.startMonitoring(for: CLBeaconRegion(
                    proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                    major: UInt16(identity!.value(forKey: "major") as! Int),
                    minor: UInt16(identity!.value(forKey: "minor") as! Int),
                    identifier: "any"))
                
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        UIApplication.shared.registerUserNotificationSettings(
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SlackData")
        
        do {
            let result =
                try managedContext.fetch(fetchRequest)
            if (result.count != 0) {
                identity = result[0] as? NSManagedObject
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.iotlab.Presense" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Presense", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
//                abort()
            }
        }
    }

}

