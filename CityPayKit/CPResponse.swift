//
//  CPResponse.swift
//  CityPayKit
//
//  Created by Gary Feltham on 27/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import CommonCrypto

/**

The CPResponse models the response object from the gateway for generic processing
using the **CityPay HTTP PayPOST API**.

To determine if a transaction has been accepted review the *authorised* parameter and ensure you know if you are in *test* mode or *live*

Initialisation of a CPResponse instance is provided by the API as a JSON packet which can be reinstated
using standard JSON serialization methods and

    let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&parseError)

    if let json = jsonObject as? NSDictionary {
        let response = CPResponse(json)
    } else {
        // error checking code.
    }

*/
public class CPResponse: NSObject {
    
    public let amount: Int
    public let currency: String
    public let authcode: String?
    public let authorised: Bool
    public let AvsResponse: String?
    public let CscResponse: String?
    public let errorcode: String
    public let errormsg: String
    public let expMonth: Int
    public let expYear: Int
    public let identifier: String
    public let maskedPan: String
    public let merchantId: Int
    public let mode: String
    public let result: Int
    public let sha1: String
    public let sha256: String
    public let status: String
    public let title: String?
    public let firstname:String?
    public let lastname:String?
    public let email: String?
    public let postcode: String?
    public let transno: Int
    
    private func b64_sha256(data : NSData) -> String {
        var hash = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA256(data.bytes, CC_LONG(data.length), &hash)
        let res = NSData(bytes: hash, length: Int(CC_SHA256_DIGEST_LENGTH))
        return res.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
    }
    
    /// Determines if the data provided is valid based on the sha256 value. The licence key provides a salt
    /// into the hash function
    public func isValid(licenceKey: String) -> Bool {
       
        var str = authcode ?? ""
        str += toString(amount) +
            errorcode +
            toString(merchantId) +
            toString(transno) +
            identifier +
            licenceKey
        
        if let data = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            let b64 = b64_sha256(data)
            return b64 == sha256
        }
        return false

        
    }


    /// only way to initialise is via a JSON packet
    public init(data: NSData) {
        var e: NSError?
        let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: &e)
        if let error = e {
            NSLog("Error parsing JSON \(error)")
        }
        self.amount = json["amount"].int ?? 0
        self.currency = json["currency"].stringValue
        self.authcode = json["authcode"].string
        self.authorised = json["authorised"].bool ?? false
        self.AvsResponse = json["AVSResponse"].string
        self.CscResponse = json["CSCResponse"].string
        self.errorcode = json["errorcode"].string ?? "F007"
        self.errormsg = json["errormessage"].string ?? "No valid response from JSON packet"
        self.expMonth = json["expMonth"].int ?? 0
        self.expYear = json["expYear"].int ?? 0
        self.identifier = json["identifier"].string ?? "unknown"
        self.maskedPan = json["maskedPan"].string ?? "n/a"
        self.merchantId = json["merchantid"].int ?? 0
        self.mode = json["mode"].string ?? "?"
        self.result = json["result"].int ?? 20 // unknown
        self.sha1 = json["sha1"].string ?? ""
        self.sha256 = json["sha256"].string ?? ""
        self.status = json["status"].string ?? "?" // unknown
        self.title = json["title"].string
        self.firstname = json["firstname"].string
        self.lastname = json["lastname"].string
        self.email = json["email"].string
        self.postcode = json["postcode"].string
        self.transno = json["transno"].int ?? -1
        
        
    }
    
    
    
}

