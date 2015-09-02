//
//  HelloWorld.swift
//  CityPayKit
//
//  Created by Gary Feltham on 26/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import PassKit

struct CityPayConstants {
    static let url = NSURL(string: "https://secure.citypay.com/paylink3/http-logger")
}

public class CityPayRequest: NSObject {

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
    
    func cpJson() -> NSDictionary {
        return [
            "merchantId": merchantId,
            "licenceKey": licenceKey,
            "identifier": identifier,
            "test": toString(test)
        ]
    }
    
    // used for testing
    @objc public func toJson() -> NSData? {
        return NSJSONSerialization.dataWithJSONObject(cpJson(), options: NSJSONWritingOptions.allZeros, error: nil)
    }
    
    
    // function for processing ApplePay transactions using a PKPaymentAuthorizationViewControllerDelegate
    // the delegate instance should implement paymentAuthorizationViewController which is called by the UI
    // and call this function
    public func applePay(controller: PKPaymentAuthorizationViewController, payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void, paymentResponse: (CityPayResponse) -> Void) {
    
        let obj = [
            "payment": payment,
            "merchant": cpJson()]
        
        if let json = NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.allZeros, error: nil) {
            call(json, completionHandler: {(response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                if let http = response as? NSHTTPURLResponse {
                    NSLog("Response: \(http.statusCode)")
                    
                    // decode the response
                    let resp = CityPayResponse(data: data)
                    // check the result of the sha2 digest
                    if (resp.isValid(self.licenceKey)) {
                        // send to the completion handler for the UI based on the response
                        if (resp.authorised) {
                            NSLog("Successful payment: \(resp.log())")
                            completion(PKPaymentAuthorizationStatus.Success)
                        } else {
                            NSLog("Failed payment: \(resp.log())")
                            completion(PKPaymentAuthorizationStatus.Failure)
                        }
                        // send response message to the closure for data collection by the merchant
                        NSLog("Calling payment response")
                        paymentResponse(resp)
                    } else {
                        let rejectedAuth = resp.rejectAuth(self.licenceKey, errormsg: "Digest mismatch")
                        NSLog("Failed payment: \(rejectedAuth.log())")
                        completion(PKPaymentAuthorizationStatus.Failure)
                        // send response message to the closure for data collection by the merchant
                        NSLog("Calling payment response")
                        paymentResponse(rejectedAuth)
                    }

                } else {
                    NSLog("Response not NSHTTPURLResponse: \(error)")
                    completion(PKPaymentAuthorizationStatus.Failure)
                }
            })
        } else {
            assert(false, "JSON creation failure")
        }
        
    }
    
    /// direct function to process json data to the configured endpoint
    func call(data: NSData, completionHandler handler: (NSURLResponse!, NSData!, NSError!) -> Void) {
        
        let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig)
        
        let request = NSMutableURLRequest()
        request.URL = CityPayConstants.url
        request.HTTPMethod = "POST"
        request.HTTPBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        NSLog("Sending call to \(CityPayConstants.url)")
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: handler)
    }
    
}
