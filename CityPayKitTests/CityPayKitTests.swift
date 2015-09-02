//
//  CityPayKitTests.swift
//  CityPayKitTests
//
//  Created by Gary Feltham on 26/08/2015.
//  Copyright (c) 2015 CityPay Limited. All rights reserved.
//

import UIKit
import XCTest
import CityPayKit

class CityPayKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // basic test with only amount, currency and identifier - testing for missing data
    func testResponseExample1() {
        if let response = loadJsonExampleAndTest("example1", ofType: "json") {
            XCTAssertEqual(5500, response.amount, "Amount should match")
            XCTAssertEqual("GBP", response.currency, "Currency should match")
            XCTAssertEqual("Example1", response.identifier, "Identifier should match")
        }
    }
    
    func testSHA256() {
        if let response = loadJsonExampleAndTest("sha256-example", ofType: "json") {
            XCTAssertEqual(10000, response.amount, "Amount should match")
            XCTAssertEqual("GBP", response.currency, "Currency should match")
            XCTAssertEqual("MockAuthSuccess", response.identifier, "Identifier should match")
            XCTAssertEqual("400000******0002", response.maskedPan, "maskedPan should match")
            XCTAssertEqual("M12345", response.authcode!, "authcode should match")
            XCTAssertEqual("000", response.errorcode, "errorcode should match")
            XCTAssertEqual(105, response.merchantId, "merchantid should match")
            XCTAssertEqual(252, response.transno, "transno should match")
            XCTAssert(response.isValid("A4123412341234"), "SHA256 digest should be valid")
        }
    }
    
    // test which vali
    func testResponseExample2() {
        
    }
    
    func loadJsonExampleAndTest(name:String?, ofType: String?) -> CityPayResponse? {
        if let path = NSBundle(forClass: CityPayKitTests.self).pathForResource(name, ofType: ofType) {
            println("Found \(path)")
            if let data = NSData(contentsOfFile: path) {
               return CityPayResponse(data: data)
            } else {
                XCTFail("Failed to obtain a JSON object")
            }
        } else {
            XCTFail("Could not find path \(name).\(ofType)")
        }
        return nil
    }
    
    func testJsonRequest() {
        let pay = CityPayRequest(merchantId: 13245, licenceKey: "LK", identifier: "Test1", test: true)
        if let json = pay.toJson() {
            let str = NSString(data: json, encoding: NSUTF8StringEncoding)
            println(str)
            // need to link in swifty to tests
            let decoded = JSON(data: json, options: NSJSONReadingOptions.AllowFragments, error: nil)
            XCTAssertEqual(decoded["merchantId"], 13245, "Expect merchant id to match")
            XCTAssertEqual(decoded["licenceKey"], "LK", "Expect licencekey to match")
            XCTAssertEqual(decoded["identifier"], "Test1", "Expect identifier to match")
        } else {
            XCTFail("Json cannot be generated")
        }
    }
    
    
}
