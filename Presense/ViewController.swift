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
    
    @IBOutlet weak var availableButton: UIButton!
    @IBOutlet weak var busyButton: UIButton!
    
    @IBAction func testButton(sender: AnyObject) {
        saveName(nameField.text!, url: textField.text!)
        sendMessage("\((identity!.valueForKey("name") as? String)!) registered under \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)")
        self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
        availableButton.enabled = false
        saveStatus("available")
    }
    
    @IBAction func availableButton(sender: AnyObject) {
        availableButton.enabled = false
        busyButton.enabled = true
        sendMessage("\((identity!.valueForKey("name") as? String)!) is available")
        self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
        saveStatus("available")
    }
    
    @IBAction func busyButton(sender: AnyObject) {
        busyButton.enabled = false
        availableButton.enabled = true
        sendMessage("\((identity!.valueForKey("name") as? String)!) is busy")
        self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
        saveStatus("busy")
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.fetchLimit = 1
        
        do {
            let result =
                try managedContext.executeFetchRequest(fetchRequest)
            if (result.count > 0) {
                identity = result[0] as? NSManagedObject
                
                nameLabel.text = "Name set to: \(identity!.valueForKey("name") as! String)"
                urlLabel.text = "URL set to: \(identity!.valueForKey("url") as! String)"
                nearestField.text = "Nearest Beacon: \(identity!.valueForKey("major") as! NSNumber):\(identity!.valueForKey("minor") as! NSNumber)"
                if ((identity!.valueForKey("status") as! String) == "busy") {
                    self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
                }
                else {
                    self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func saveName(name: String, url: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("SlackData", inManagedObjectContext:managedContext)
        
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.fetchLimit = 1
        
        var webhookURL = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        do {
            let result =
                try managedContext.executeFetchRequest(fetchRequest)
            if (result.count > 0) {
                webhookURL = result[0] as! NSManagedObject
                
                self.beaconManager.stopMonitoringForRegion(CLBeaconRegion(
                    proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                    major: UInt16(webhookURL.valueForKey("major") as! Int),
                    minor: UInt16(webhookURL.valueForKey("minor") as! Int),
                    identifier: "any"))
                
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        webhookURL.setValue(url, forKey: "url")
        webhookURL.setValue(name, forKey: "name")
        webhookURL.setValue(NSDate(), forKey: "date")
        
        if beaconFound {
            webhookURL.setValue(nearestBeacon.major, forKey: "major")
            webhookURL.setValue(nearestBeacon.minor, forKey: "minor")
        }
        
        do {
            try webhookURL.managedObjectContext?.save()
            
            identity = webhookURL
            
            self.beaconManager.startMonitoringForRegion(CLBeaconRegion(
                proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                major: UInt16(identity!.valueForKey("major") as! Int),
                minor: UInt16(identity!.valueForKey("minor") as! Int),
                identifier: "any"))
            
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
    
    func saveStatus(status: String) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("SlackData", inManagedObjectContext:managedContext)
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            fetchRequest.fetchLimit = 1
        var webhookURL = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        do {
            let result =
                try managedContext.executeFetchRequest(fetchRequest)
            if (result.count > 0) {
                webhookURL = result[0] as! NSManagedObject
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        webhookURL.setValue(status, forKey: "status")
        
        do {
            try webhookURL.managedObjectContext?.save()
            
            identity = webhookURL
            
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearest = beacons.first {
            nearestBeacon = nearest
            beaconFound = true
            print("\(nearest.major) \(nearest.minor)")
            // TODO: update the UI here
        }
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let isAppAlreadyLaunchedOnce = defaults.stringForKey("isAppAlreadyLaunchedOnce") {
            print(isAppAlreadyLaunchedOnce)
            return true
        } else{
            return false
        }
    }
}