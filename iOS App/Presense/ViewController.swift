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
    
    @IBAction func testButton(_ sender: AnyObject) {
        do {
            try saveName(nameField.text!, url: textField.text!)
            try sendMessage("available")
            self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
            busyButton.isEnabled = true
            availableButton.isEnabled = false
            saveStatus("available")
        } catch FieldError.emptyName {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid name!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            do {try saveName(tmp[0], url: tmp[1])} catch {}
        } catch FieldError.beaconsNotFound {
            let alertController = UIAlertController(title: "Error", message:
                "Beacon Not Found!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            do {try saveName(tmp[0], url: tmp[1])} catch {}
        } catch {
        }
    }
    
    @IBAction func availableButton(_ sender: AnyObject) {
        do {
            availableButton.isEnabled = false
            busyButton.isEnabled = true
            try sendMessage("available")
            self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
            saveStatus("available")
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        } catch {
        }
    }
    
    @IBAction func busyButton(_ sender: AnyObject) {
        
        do {
            busyButton.isEnabled = false
            availableButton.isEnabled = true
            try sendMessage("busy")
            self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
            saveStatus("busy")
        } catch FieldError.invalidURL {
            let alertController = UIAlertController(title: "Error", message:
                "Enter a valid URL!", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        } catch {
        }
                
    }
    
    var beaconManager:ESTBeaconManager!
    var nearestBeacon:CLBeacon!
    var beaconFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconManager = ESTBeaconManager()
        beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground(_:)), name: NSNotification.Name(rawValue: "EventNotification"), object: nil)
        beaconManager.startRangingBeacons(in: CLBeaconRegion(proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!, identifier: "any"))
    }
    
    func willEnterForeground(_ notification: Notification!) {
        refresh()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: nil, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    
    func refresh() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            if (result.count > 0) {
                identity = result[0] as? NSManagedObject
                
                nameField.attributedPlaceholder = NSAttributedString(string: "\(identity!.value(forKey: "name") as! String)")
                nameField.text = ""
                textField.attributedPlaceholder = NSAttributedString(string: "\(identity!.value(forKey: "url") as! String)")
                textField.text = ""
                nearestField.text = "Nearest Beacon: \(identity!.value(forKey: "major") as! NSNumber):\(identity!.value(forKey: "minor") as! NSNumber)"
                if ((identity!.value(forKey: "status") as! String) == "busy") {
                    self.view.backgroundColor = UIColor(red: CGFloat(58)/255.0, green: CGFloat(145)/255.0, blue: CGFloat(219)/255.0, alpha: 1.0)
                    busyButton.isEnabled = false
                    availableButton.isEnabled = true
                }
                else if ((identity!.value(forKey: "status") as! String) == "available") {
                    self.view.backgroundColor = UIColor(red: CGFloat(98)/255.0, green: CGFloat(177)/255.0, blue: CGFloat(126)/255.0, alpha: 1.0)
                    availableButton.isEnabled = false
                    busyButton.isEnabled = true
                }
                else {
                    self.view.backgroundColor = UIColor(red: CGFloat(224)/255.0, green: CGFloat(255)/255.0, blue: CGFloat(237)/255.0, alpha: 1.0)
                    availableButton.isEnabled = false
                    busyButton.isEnabled = false
                }
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func saveName(_ name: String, url: String) throws {
        
        if name == "" {
            throw FieldError.emptyName
        }
        
        if (!beaconFound) {
            throw FieldError.beaconsNotFound
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SlackData")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let result = try managedContext.fetch(fetchRequest)
            let count = result.count
            let entity =  NSEntityDescription.entity(forEntityName: "SlackData", in:managedContext)
            var webhookURL = NSManagedObject(entity: entity!, insertInto: managedContext)
            
            if (count > 0) {
                webhookURL = result[0] as! NSManagedObject
                tmp = [webhookURL.value(forKey: "name") as! String, webhookURL.value(forKey: "url") as! String]
                self.beaconManager.stopMonitoring(for: CLBeaconRegion(
                    proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                    major: UInt16(webhookURL.value(forKey: "major") as! Int),
                    minor: UInt16(webhookURL.value(forKey: "minor") as! Int),
                    identifier: "any"))
            }
            
            webhookURL.setValue(url, forKey: "url")
            webhookURL.setValue(name, forKey: "name")
            webhookURL.setValue(Date(), forKey: "date")
            webhookURL.setValue(nearestBeacon.major, forKey: "major")
            webhookURL.setValue(nearestBeacon.minor, forKey: "minor")
            webhookURL.setValue("registered", forKey: "status")
            
            try webhookURL.managedObjectContext?.save()
            
            identity = webhookURL
            
            self.beaconManager.startMonitoring(for: CLBeaconRegion(
                proximityUUID: UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
                major: UInt16(identity!.value(forKey: "major") as! Int),
                minor: UInt16(identity!.value(forKey: "minor") as! Int),
                identifier: "any"))
            
            nameField.attributedPlaceholder = NSAttributedString(string: "\(identity!.value(forKey: "name") as! String)")
            nameField.text = ""
            textField.attributedPlaceholder = NSAttributedString(string: "\(identity!.value(forKey: "url") as! String)")
            textField.text = ""
            nearestField.text = "Nearest Beacon: \((identity!.value(forKey: "major") as? NSNumber)!):\((identity!.value(forKey: "minor") as? NSNumber)!)"
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func beaconManager(_ manager: Any, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
            if (beacon.major == (identity!.value(forKey: "major") as? NSNumber)! && beacon.minor == (identity!.value(forKey: "minor") as? NSNumber)! && (identity!.value(forKey: "status") as! String) == "out of office") {
                saveStatus("available")
                refresh()
            }
        }
        
        if let nearest = beacons.first {
            nearestBeacon = nearest
            if (nearest.major != 0 && nearest.minor != 0) {
                beaconFound = true
            }
            else {
                beaconFound = false
            }
            print("\(nearest.major) \(nearest.minor)")
        }
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = UserDefaults.standard
        
        if let isAppAlreadyLaunchedOnce = defaults.string(forKey: "isAppAlreadyLaunchedOnce") {
            print(isAppAlreadyLaunchedOnce)
            return true
        } else{
            return false
        }
    }
}



