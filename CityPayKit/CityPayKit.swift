//
//  HelloWorld.swift
//  CityPayKit
//
//  Created by Gary Feltham on 26/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import PassKit


public class CPPayment: NSObject {

    let merchantId: Int
    let licenceKey: String
    let identifier: String
    let test: Bool

    
    public init(merchantId: Int, licenceKey: String, identifier: String, test: Bool) {
        assert(merchantId > 0, "Merchant ID is not valid")
        assert(licenceKey != "", "Licence Key is not provided")
        assert(identifier != "", "Identifier is not provided")
        assert(count(identifier) >= 5, "Identifier must be between 5 and 50 characters")
        assert(count(identifier) < 50, "Identifier must be between 5 and 50 characters")
        self.merchantId = merchantId
        self.licenceKey = licenceKey
        self.identifier = identifier
        self.test = test
    }    
    
    @objc public func toJson() -> NSData? {
        
        let obj = [
            "merchantId": merchantId,
            "licenceKey": licenceKey,
            "identifier": identifier,
            "test": toString(test)
        ]
        
        return NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.allZeros, error: nil)
    }
    
    /// direct function to process json data to the configured endpoint
    public func call(data: NSData) {
        let url = NSURL(string: "https://secure.citypay.com/paylink3/http-logger")
        let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig)
        
        let request = NSMutableURLRequest()
        request.URL = url
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        println("Sending call to \(url)")
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(),
            completionHandler: {(response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            println("here...")
            if let http = response as? NSHTTPURLResponse {
                NSLog("Response: \(http.statusCode)")
            } else {
                NSLog("Response: \(error)")
            }
        })
    }
    
}
