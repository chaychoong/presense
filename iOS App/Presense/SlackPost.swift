//
//  SlackPost.swift
//  Presense
//
//  Created by Chay Choong on 21/3/16.
//  Copyright © 2016 SUTDiot. All rights reserved.
//

import UIKit
import Foundation
import CoreData

enum FieldError: Error {
    case emptyName
    case invalidURL
    case beaconsNotFound
}

func sendMessage(_ message: String) throws {
    
    var err: String = ""
    let semaphore = DispatchSemaphore(value: 0)
    
//    let payload = "payload={\"channel\": \"#presensetest\", \"username\": \"webhookbot\", \"icon_emoji\":\":calling:\", \"text\": \"\(message)\"}"
    let payload = "payload={\"user\": \"\(identity!.value(forKey: "name") as! String)\", \"status\": \"\(message)\"}"
    let data = (payload as NSString).data(using: String.Encoding.utf8.rawValue)
    if let url = URL(string: (identity!.value(forKey: "url") as? String)!)
    {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in

            if error != nil {
                let nserr = error as! NSError
                err = ("error: \(error!.localizedDescription): \(nserr.userInfo)")
                print(err)
            }
            else if data != nil {
                if let str = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) {
                    print("\(str)")
                }
                else {
                    err = ("error")
                }
            }
            semaphore.signal()
        }) 
        task.resume()
        
    }
    else {
        err = ("error")
    }
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    if (err != "") {
        throw FieldError.invalidURL
    }
}

func saveStatus(_ status: String) {
    
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
        }
        
        webhookURL.setValue(status, forKey: "status")
        
        try webhookURL.managedObjectContext?.save()
        print("Status changed to \(status)")
        
        identity = webhookURL
        
    } catch let error as NSError {
        print("Could not fetch \(error), \(error.userInfo)")
    }
}
