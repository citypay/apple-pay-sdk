//
//  CityPayResponse.swift
//  CityPayKit
//
//  Created by Gary Feltham on 27/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import CommonCrypto

/**

 The CityPayResponse class models the response data received from the CityPay
 payment gateway.
 
 To determine if a transaction has been accepted review the *authorised*
 parameter and ensure you know if you are in *test* mode or *live* mode.

 The CityPayResponse object is initialized by passing a JSON packet as
 a parameter to the principal designated initializer. The JSON packet
 is processed using standard JSON serialization methods:
 
    ``
    let jsonObject: AnyObject?
        = NSJSONSerialization
            .JSONObjectWithData(
                data,
                options: NSJSONReadingOptions.AllowFragments,
                error:&parseError
            )

    if let json = jsonObject as? NSDictionary {
        let response = CityPayResponse(json)
    } else {
        //
        //  Error checking code.
        //
    }
    ``

*/
public class CityPayResponse: NSObject {
    
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
    public let sha256: String
    public let status: String
    public let title: String?
    public let firstname:String?
    public let lastname:String?
    public let email: String?
    public let postcode: String?
    public let transno: Int
    
    /**

     */
    private func b64_sha256(data : NSData) -> String {
        var hash = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA256(data.bytes, CC_LONG(data.length), &hash)
        let res = NSData(bytes: hash, length: Int(CC_SHA256_DIGEST_LENGTH))
        return res.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
    
    /**

     */
    func log() -> String {
        return "RS:\(identifier),amount=\(amount),card=\(maskedPan),\(expMonth)\(expYear),authorised=\(authorised),mode=\(mode)"
    }
    
    /**
     
     A private designated initializer for the CityPayResponse object.
     
     - parameters
     
     */
    private init(
        amount: Int,
        currency: String,
        authcode: String?,
        authorised: Bool,
        AvsResponse: String?,
        CscResponse: String?,
        errorcode: String,
        errormsg: String,
        expMonth: Int,
        expYear: Int,
        identifier: String,
        maskedPan: String,
        merchantId: Int,
        mode: String,
        result: Int,
        sha256: String,
        status: String,
        title: String?,
        firstname:String?,
        lastname:String?,
        email: String?,
        postcode: String?,
        transno: Int
    ) {
        self.amount = amount
        self.currency = currency
        self.authcode = authcode
        self.authorised = authorised
        self.AvsResponse = AvsResponse
        self.CscResponse = CscResponse
        self.errorcode = errorcode
        self.errormsg = errormsg
        self.expMonth = expMonth
        self.expYear = expYear
        self.identifier = identifier
        self.maskedPan = maskedPan
        self.merchantId = merchantId
        self.mode = mode
        self.result = result
        self.sha256 = sha256
        self.status = status
        self.title = title
        self.firstname = firstname
        self.lastname = lastname
        self.email = email
        self.postcode = postcode
        self.transno = transno
    }
    
    /**
    
     A public designated initializer for the CityPayResponse object.
    
     - parameters
    
       - data:
         contains the JSON encoded response received from the CityPay
         payment gateway.
    
     */
    public init(data: NSData) {
        
        var e: NSError?
        let json = JSON(
            data: data,
            options: NSJSONReadingOptions.AllowFragments,
            error: &e
        )
        
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
        self.sha256 = json["sha256"].string ?? ""
        self.status = json["status"].string ?? "?" // unknown
        self.title = json["title"].string
        self.firstname = json["firstname"].string
        self.lastname = json["lastname"].string
        self.email = json["email"].string
        self.postcode = json["postcode"].string
        self.transno = json["transno"].int ?? -1
    }
    
    /**

     Determines if the data provided is valid based on the SHA-256 value.
     The licence key provides a salt into the hash function.
     
     */
    public func isValid(licenceKey: String) -> Bool {
       
        var str = authcode ?? ""
        str += String(amount) +
            errorcode +
            String(merchantId) +
            String(transno) +
            identifier +
            licenceKey
        
        if let data = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            let b64 = b64_sha256(data)
            return b64 == sha256
        }
        return false
    }
    
    /**
    
     Creates a "rejected transaction" CityPayResponse object based on the
     content of the instant response. This allows an alternate CityPayResponse
     to generated programmatically in the event that, for example, invalid
     digest information is identified.

     */
    func rejectAuth(licenceKey: String, errormsg: String) -> CityPayResponse {
        NSLog("Rejecting auth \(errormsg)")
        
        //
        //  Re-calculate CityPayResponse SHA-256 digest value.
        //
        let ec = "099"
        var str = authcode ?? ""
        str += String(amount) +
            ec +
            String(merchantId) +
            String(transno) +
            identifier +
            licenceKey
        let data = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
        let digest = b64_sha256(data)
        return CityPayResponse(
            amount: self.amount,
            currency: self.currency,
            authcode: self.authcode,
            authorised: false,
            AvsResponse: self.AvsResponse,
            CscResponse: self.CscResponse,
            errorcode: ec,
            errormsg: errormsg,
            expMonth: self.expMonth,
            expYear: self.expYear,
            identifier: self.identifier,
            maskedPan: self.maskedPan,
            merchantId: self.merchantId,
            mode: self.mode,
            result: 2,
            sha256: digest,
            status: status,
            title: self.title,
            firstname: self.firstname,
            lastname: self.lastname,
            email: self.email,
            postcode: self.postcode,
            transno: self.transno
        )
    }
    
}

