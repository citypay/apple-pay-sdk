# apple-pay-sdk
![CityPay Logo](http://citypay.com/img/logo-x250.png)

## CityPay iOS Apple Pay SDK

SDK for integrating Apple Pay with CityPay's gateway. The SDK provides a delegate process for the Apple PKPaymentAuthorizationViewController

---
# Guide
Also See [http://citypay.com/docs]

## Setting up the payment button
The payment button should only be displayed if the user can make payments. There are 2 levels to check 
`canMakePayments` determines that the device is capable of conducting ApplePay payments; and
`canMakePaymentsUsingNetworks` determines that the device can use the given network. The actual decision on this is complex and determined by Apple and the Card Issuer. 
```swift
import PassKit
import UIKit
import CityPayKit
 
class MyApplePayController: UIViewController {
     
    let SupportedPaymentNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkVisa, PKPaymentNetworkMasterCard]
 
    @IBOutlet weak var applePayButton: PKPaymentButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        if (PKPaymentAuthorizationViewController.canMakePayments() &&
            PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(SupportedPaymentNetworks)) {
            applePayButton.hidden = false
        } else {
            applePayButton.hidden = true
        }
    }
 
    // example purchase function which creates a payment on touch of the payment button
    @IBAction func purchase(sender: PKPaymentButton) {
        //...
    }
}
```

## Initialise a PKPaymentRequest
Apple Pay is centralised around the PKPaymentRequest which should be used to initialise the Apple Pay payment.
```swift
// initialise a PK Payment Request
let request = PKPaymentRequest()
request.merchantIdentifier = "YOUR_APPLE_PAY_MERCHANT_ID"
request.supportedNetworks = SupportedPaymentNetworks
// All CityPay payments are performed with 3DS
request.merchantCapabilities = PKMerchantCapability.Capability3DS
request.countryCode = "GB"
request.currencyCode = "GBP"
 
// determine required fields e.g. based on the selected item type
switch (demo.ItemType) {
    case ItemType.Delivered:
        request.requiredShippingAddressFields = PKAddressField.PostalAddress
    case ItemType.Electronic:
        request.requiredShippingAddressFields = PKAddressField.Email
}
 
// calculate shipping if needed
let shippingPrice: NSDecimalNumber = NSDecimalNumber(string: "5.0")
request.paymentSummaryItems = [
    PKPaymentSummaryItem(label: swag.title, amount: swag.price),
    PKPaymentSummaryItem(label: "Shipping", amount: shippingPrice),
    PKPaymentSummaryItem(label: "CityPay", amount: swag.price.decimalNumberByAdding(shippingPrice))
]
```

The following recommendations are made
* Use the country code where your business is located
* The currency code must match what you can process with your CityPay merchant id.
* Only the  PKMerchantCapability.Capability3DS is supported, EMV is for in store payments
* SupportedPaymentNetworks should match what your able to process. Note that Apple do not allow filtering by debit or credit cards. The CityPay gateway will be able to determine this and return an authorised or rejected transaction response accordingly

## Create a PKPaymentAuthorizationViewController
When the user selects the Apply Pay button you will need to add a controller to initiate the Apple Pay process
```swift
// initialise the payment view controller with the payment request
let applePayController = PKPaymentAuthorizationViewController(paymentRequest: request)
// set as controller's delegate to manage payment
applePayController.delegate = self
self.presentViewController(applePayController, animated: true, completion: nil)
```

## Implement PKPaymentAuthorizationViewControllerDelegate
Once the user has authenticated payment a delegate of the controller runs the payment authorisation process. This is where we implement the CityPayKit into the Apple Pay process. 
```swift
// create an implementation of the PKPaymentAuthorizationViewControllerDelegate
extension BuySwagViewController: PKPaymentAuthorizationViewControllerDelegate {
 
    // implement paymentAuthorizationViewController and offest the payment processing to CityPay
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, 
            didAuthorizePayment payment: PKPayment, 
            completion: (PKPaymentAuthorizationStatus) -> Void) {
             
                let cp = CityPayRequest(
                    merchantId: 105, 
                    licenceKey: "LK", 
                    identifier: "ApplePayTest1", 
                    test: true
                )
                cp.applePay(
                    controller,
                    payment: payment,
                    completion: completion,
                    paymentResponse: { (response:CityPayResponse) -> Void in
                        // todo business logic on your side...
                })
 
 
 
    }
 
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
```
An implementation will adapt the paymentAuthorizationViewController function to a CityPayRequest instance. At this point you are able to 
* provide the CityPay merchant id. This should match the processing currency of your transaction.
* provide the CityPay licence key which is used for processing Apple Pay payments. 
* provide an identifier which is your reference for the transaction
* provide a Bool value whether the transaction is for testing or false for production.

Once the request object has been initialised, call the applePay function on the instance. You will be required to provide 
* The controller instance
* the PKPayment object which contains the encrypted card data and payment information
* a reference to the completion handler which informs PassKit whether a transaction was successful
* a paymentResponse closure which provides an instance of the CityPayResponse object outlining the result of the transaction. This is included to determine the result of processing and therefore update your systems accordingly. 
