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

func sendMessage(message: String) {
    
    let payload = "payload={\"channel\": \"#presensetest\", \"username\": \"webhookbot\", \"icon_emoji\":\":calling:\", \"text\": \"\(message)\"}"
    let data = (payload as NSString).dataUsingEncoding(NSUTF8StringEncoding)
    if let url = NSURL(string: (identity!.valueForKey("url") as? String)!)
    {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = data
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error != nil {
                print("error: \(error!.localizedDescription): \(error!.userInfo)")
            }
            else if data != nil {
                if let str = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    print("\(str)")
                }
                else {
                    print("error")
                }
            }
        }
        task.resume()
    }
    else {
        print("url invalid")
    }
    
}