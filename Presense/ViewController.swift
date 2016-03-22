//
//  ViewController.swift
//  Presense
//
//  Created by Chay Choong on 20/3/16.
//  Copyright © 2016 SUTDiot. All rights reserved.
//

import UIKit
import CoreData


var identity: NSManagedObject?

class ViewController: UIViewController, ESTBeaconManagerDelegate {
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var nearestField: UILabel!
    @IBAction func testButton(sender: AnyObject) {
        saveName(nameField.text!, url: textField.text!)
        sendMessage("\((identity!.valueForKey("name") as? String)!) registered under \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)")
    }
    
    var beaconManager:ESTBeaconManager!
    var nearestBeacon:CLBeacon!
    var beaconFound = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        beaconManager = ESTBeaconManager()
        beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        
        beaconManager.startRangingBeaconsInRegion(CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, identifier: "any"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        do {
            let result =
                try managedContext.executeFetchRequest(fetchRequest)
            if (result.count != 0) {
                identity = result[0] as? NSManagedObject
                nameLabel.text = "Name set to: \((identity!.valueForKey("name") as? String)!)"
                urlLabel.text = "URL set to: \((identity!.valueForKey("url") as? String)!)"
                nearestField.text = "Nearest Beacon: \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)"
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func saveName(name: String, url: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("SlackData", inManagedObjectContext:managedContext)
        
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        fetchRequest.predicate = NSPredicate(format: "name == %@", (identity!.valueForKey("name") as? String)!)
        var webhookURL = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        do {
            let result =
                try managedContext.executeFetchRequest(fetchRequest)
            if (result.count != 0) {
                webhookURL = (result[0] as? NSManagedObject)!
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        webhookURL.setValue(url, forKey: "url")
        webhookURL.setValue(name, forKey: "name")
        
        if beaconFound {
            webhookURL.setValue(nearestBeacon.major, forKey: "major")
            webhookURL.setValue(nearestBeacon.minor, forKey: "minor")
        }
        
        do {
            try managedContext.save()
            
            identity = webhookURL
            
            urlLabel.text = "URL set to: \((identity!.valueForKey("url") as? String)!)"
            nameLabel.text = "Name set to: \((identity!.valueForKey("name") as? String)!)"
            if beaconFound {
                nearestField.text = "Nearest Beacon: \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)"
            }
            else {
                nearestField.text = "Nearest Beacon: Undetected"
            }
            
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearest = beacons.first {
            nearestBeacon = nearest
            beaconFound = true
            print(nearest.major)
            // TODO: update the UI here
        }
    }
}