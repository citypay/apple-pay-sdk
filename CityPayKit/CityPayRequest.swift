//
//  CityPayKit
//
//  Created by Gary Feltham on 26/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import PassKit

struct CityPayConstants {
    static let url = NSURL(string: "https://secure.citypay.com/applepay/v1")
}

enum CityPayPolicy: Int {
    case Default = 0
    case Enforce
    case Bypass
}

public class CityPayRequest: NSObject {

    let merchantId: Int
    let licenceKey: String
    let identifier: String
    let test: Bool
    let version: String = CityPayRequest.getVersionFromClassBundle(CityPayRequest.self)
        ?? "<Unknown> (<Unknown>)"
    
    var avsAddressPolicy: CityPayPolicy = CityPayPolicy.Default
    var avsPostcodePolicy: CityPayPolicy = CityPayPolicy.Default
    
    /**

        Get the version string for the relevant bundle.

     */
    private static func getVersionFromBundle(bundle: NSBundle) -> String? {
        var infoDic: [String: AnyObject]? = bundle.infoDictionary
        if (infoDic != nil) {
            return (infoDic!["CFBundleShortVersionString"] as? String ?? "<Unknown>")
                + " ("
                + (infoDic!["CFBundleVersion"] as? String ?? "<Unknown>")
                + ")"
        } else {
            return nil
        }
    }
    
    /**

        Get the bundle object most closely associated with the specified
        class.

     */
    private static func getVersionFromClassBundle(forClass aClass: AnyClass) -> String? {
        return getVersionFromBundle(
            NSBundle(forClass: aClass)
        )
    }
    
    public init(merchantId: Int, licenceKey: String, identifier: String, test: Bool) {
        assert(merchantId > 0, "Merchant ID is not valid")
        assert(licenceKey != "", "Licence Key is not provided")
        assert(identifier != "", "Identifier is not provided")
        assert(identifier.characters.count >= 5, "Identifier must be between 5 and 50 characters")
        assert(identifier.characters.count < 50, "Identifier must be between 5 and 50 characters")
        self.merchantId = merchantId
        self.licenceKey = licenceKey
        self.identifier = identifier
        self.test = test
        NSLog(self.version)
    }
    
    func cpJson() -> NSDictionary {
        return [
            "merchantId": merchantId,
            "licenceKey": licenceKey,
            "identifier": identifier,
            "test": test,
            "sdkVersion": version,
            "deviceVersion": NSProcessInfo().operatingSystemVersionString
        ]
    }
    
    // used for testing
    @objc public func toJson() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(cpJson(), options: NSJSONWritingOptions())
    }
    
    
    // function for processing ApplePay transactions using a PKPaymentAuthorizationViewControllerDelegate
    // the delegate instance should implement paymentAuthorizationViewController which is called by the UI
    // and call this function
    public func applePay(controller: PKPaymentAuthorizationViewController, payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void, paymentResponse: (CityPayResponse) -> Void) {
    
        NSLog("ApplePay payment started")
        
        var obj = [
            "payment": payment.token.paymentData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions()),
            "transactionIdentifier": payment.token.transactionIdentifier,
            "gateway": cpJson()]
        
        let os = NSProcessInfo().operatingSystemVersion
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (8, _, _):
            obj["billing"] = "" // TODO addition of billing data from ABRecord
        default:
            NSLog("Using PKContact")
            let billdata = [
                "title": payment.billingContact?.name?.namePrefix ?? "",
                "lastname": payment.billingContact?.name?.familyName ?? "",
                "firstname": payment.billingContact?.name?.givenName ?? "",
                "email": payment.billingContact?.emailAddress ?? "",
                "address1": payment.billingContact?.postalAddress?.street ?? "",
                "address2": payment.billingContact?.postalAddress?.city ?? "",
                "area": payment.billingContact?.postalAddress?.state ?? "",
                "postcode": payment.billingContact?.postalAddress?.postalCode ?? "",
                "country": payment.billingContact?.postalAddress?.ISOCountryCode ?? ""
            ]
            
            obj["billing"] = billdata
        }
        
        if (avsAddressPolicy != CityPayPolicy.Default || avsPostcodePolicy != CityPayPolicy.Default) {
            obj["options"] = [
                "avsAddressPolicy": String(avsAddressPolicy.rawValue),
                "avsPostcodePolicy": String(avsPostcodePolicy.rawValue)
            ]
        }
        
//        
        NSLog("Serializing JSON")
        if let json: NSData = try? NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions()) {
            
            let request = NSMutableURLRequest()
            request.URL = CityPayConstants.url
            request.HTTPMethod = "POST"
            request.HTTPBody = json
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            NSLog("Sending call to \(CityPayConstants.url)")
            let task: NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                data, response, error in
                
                if let http = response as? NSHTTPURLResponse {
                    NSLog("Response: \(http.statusCode)")
                    
                    // decode the response
                    let resp = CityPayResponse(data: data!)
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
            }
            task.resume()
        } else {
            assert(false, "JSON creation failure")
        }
    }

}
