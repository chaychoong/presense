//
//  BeaconsInfo.swift
//  Presense
//
//  Created by Chay Choong on 20/3/16.
//  Copyright © 2016 SUTDiot. All rights reserved.
//

import Foundation

let regions: [CLBeaconRegion: String] = [
    CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
        major: 42021, minor: 39673, identifier: "ice") : "ice",
    CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
        major: 56259, minor: 13079, identifier: "blueberry") : "blueberry",
    CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!,
        major: 7097, minor: 63537, identifier: "mint") : "mint"
]