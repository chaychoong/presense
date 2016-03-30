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
var tmp: [String] = ["Name", "Slackbot URL"]

class ViewController: UIViewController, ESTBeaconManagerDelegate {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var nearestField: UILabel!
    
    @IBOutlet weak var availableButton: UIButton!
    @IBOutlet weak var busyButton: UIButton!
    
    @IBAction func testButton(sender: AnyObject) {
        do {
            try saveName(nameField.text!, url: textField.text!)
            try sendMessage("registered under \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)")
            self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
            busyButton.enabled = true
            availableButton.enabled = false
            saveStatus("available")
        } catch FieldError.emptyName {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid name!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            do {try saveName(tmp[0], url: tmp[1])} catch {}
        } catch FieldError.beaconsNotFound {
            let alertController = UIAlertController(title: "Error", message:
                "Beacon Not Found!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            do {try saveName(tmp[0], url: tmp[1])} catch {}
        } catch {
        }
    }
    
    @IBAction func availableButton(sender: AnyObject) {
        do {
            availableButton.enabled = false
            busyButton.enabled = true
            try sendMessage("available")
            self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
            saveStatus("available")
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } catch {
        }
    }
    
    @IBAction func busyButton(sender: AnyObject) {
        
        do {
            busyButton.enabled = false
            availableButton.enabled = true
            try sendMessage("busy")
            self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
            saveStatus("busy")
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } catch {
        }
                
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.willEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.willEnterForeground(_:)), name: "EventNotification", object: nil)
        beaconManager.startRangingBeaconsInRegion(CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, identifier: "any"))
    }
    
    func willEnterForeground(notification: NSNotification!) {
        refresh()
    }
    
    deinit {
        // make sure to remove the observer when this view controller is dismissed/deallocated
        NSNotificationCenter.defaultCenter().removeObserver(self, name: nil, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try managedContext.executeFetchRequest(fetchRequest)
            if (result.count > 0) {
                identity = result[0] as? NSManagedObject
                
                nameField.attributedPlaceholder = NSAttributedString(string: "\(identity!.valueForKey("name") as! String)")
                nameField.text = ""
                textField.attributedPlaceholder = NSAttributedString(string: "\(identity!.valueForKey("url") as! String)")
                textField.text = ""
                nearestField.text = "Nearest Beacon: \(identity!.valueForKey("major") as! NSNumber):\(identity!.valueForKey("minor") as! NSNumber)"
                if ((identity!.valueForKey("status") as! String) == "busy") {
                    self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
                    busyButton.enabled = false
                    availableButton.enabled = true
                }
                else if ((identity!.valueForKey("status") as! String) == "available") {
                    self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
                    availableButton.enabled = false
                    busyButton.enabled = true
                }
                else {
                    self.view.backgroundColor = UIColor(red: CGFloat(224)/255.0, green: CGFloat(255)/255.0, blue: CGFloat(237)/255.0, alpha: 1.0)
                    availableButton.enabled = false
                    busyButton.enabled = false
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
    
    func saveName(name: String, url: String) throws {
        
        if name == "" {
            throw FieldError.emptyName
        }
        
        if (!beaconFound) {
            throw FieldError.beaconsNotFound
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        
        let fetchRequest = NSFetchRequest(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let result = try managedContext.executeFetchRequest(fetchRequest)
            let count = result.count
            let entity =  NSEntityDescription.entityForName("SlackData", inManagedObjectContext:managedContext)
            var webhookURL = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            if (count > 0) {
                webhookURL = result[0] as! NSManagedObject
                tmp = [webhookURL.valueForKey("name") as! String, webhookURL.valueForKey("url") as! String]
                self.beaconManager.stopMonitoringForRegion(CLBeaconRegion(
                    proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                    major: UInt16(webhookURL.valueForKey("major") as! Int),
                    minor: UInt16(webhookURL.valueForKey("minor") as! Int),
                    identifier: "any"))
            }
            
            webhookURL.setValue(url, forKey: "url")
            webhookURL.setValue(name, forKey: "name")
            webhookURL.setValue(NSDate(), forKey: "date")
            webhookURL.setValue(nearestBeacon.major, forKey: "major")
            webhookURL.setValue(nearestBeacon.minor, forKey: "minor")
            webhookURL.setValue("registered", forKey: "status")
            
            try webhookURL.managedObjectContext?.save()
            
            identity = webhookURL
            
            self.beaconManager.startMonitoringForRegion(CLBeaconRegion(
                proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                major: UInt16(identity!.valueForKey("major") as! Int),
                minor: UInt16(identity!.valueForKey("minor") as! Int),
                identifier: "any"))
            
            nameField.attributedPlaceholder = NSAttributedString(string: "\(identity!.valueForKey("name") as! String)")
            nameField.text = ""
            textField.attributedPlaceholder = NSAttributedString(string: "\(identity!.valueForKey("url") as! String)")
            textField.text = ""
            nearestField.text = "Nearest Beacon: \((identity!.valueForKey("major") as? NSNumber)!):\((identity!.valueForKey("minor") as? NSNumber)!)"
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon],
                       inRegion region: CLBeaconRegion) {
        if let nearest = beacons.first {
            nearestBeacon = nearest
            if (nearest.major != 0 && nearest.minor != 0) {
                beaconFound = true
            }
            else {
                beaconFound = false
            }
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



