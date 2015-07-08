//
//  PIConfiguration.swift
//  PhoneIdTestapp
//
//  Created by Alyona on 6/19/15.
//  Copyright © 2015 Alberto Sarullo. All rights reserved.
//

import UIKit

import CoreTelephony.CTTelephonyNetworkInfo
import CoreTelephony.CTCarrier

import libPhoneNumber_iOS

class PhoneIdNumberValidationError:PhoneIdServiceError{
    class func validationFail(descriptionKey:String?) -> PhoneIdServiceError{
        return PhoneIdNumberValidationError(code: 1004, descriptionKey:descriptionKey!, reasonKey: nil)
    }
}

public class NumberInfo: NSObject {
    
    public var phoneNumber:String?
    public var phoneCountryCode:String?
    public var isoCountryCode:String?
    
    public let defaultCountryCode:String = "+1"
    public let defaultIsoCountryCode:String = "US"
    
    public private(set) var phoneCountryCodeSim:String?
    public private(set) var isoCountryCodeSim:String?
    
    public override init() {
        super.init()
        self.prep()
    }
    
    public convenience init(number:String, countryCode:String, isoCountryCode:String) {
        self.init()
        self.phoneNumber = number
        self.phoneCountryCode = countryCode
        self.isoCountryCode = isoCountryCode
    }
    
    public func validate() throws -> Bool {
        
        guard self.phoneNumber != nil else{
            throw PhoneIdNumberValidationError.validationFail("error.number.is.not.set")
        }
        
        guard self.phoneCountryCode != nil else{
            throw PhoneIdNumberValidationError.validationFail("error.country.code.is.not.set")
        }

        guard self.isoCountryCode != nil else{
            throw PhoneIdNumberValidationError.validationFail("error.iso.country.code.is.not.set")
        }
        
        let numberString:String = self.phoneCountryCode! + self.phoneNumber!
        var result:Bool = false
        do{
        
            var error: NSError?
            let number:NBPhoneNumber! = try phoneUtil.parse(numberString, defaultRegion: self.isoCountryCode)
            let validationResult:NBEValidationResult = phoneUtil.isPossibleNumberWithReason(number, error:&error)
            
            if(validationResult != NBEValidationResultIS_POSSIBLE){
                
                if let error = error{
                    throw PhoneIdNumberValidationError.validationFail(error.localizedDescription)
                }else{
                    throw PhoneIdNumberValidationError.validationFail("error.unkonwn.problem.phone.number.validation")
                }

            }
            result = phoneUtil.isValidNumber(number)
            
        }catch let error as PhoneIdNumberValidationError{
            throw error
        }catch let error as NSError{
            throw PhoneIdNumberValidationError.validationFail(error.localizedDescription)
        }
        
        return result;
    }
    
    public func isValid() -> (result: Bool, error: NSError?) {
        
        var result = false
        var error:NSError? = nil;
        
        do{
            result = try self.validate()
        }catch let e as NSError{
            error = e
        }        
        return (result, error);
    }
    
    private var phoneUtil: NBPhoneNumberUtil {return NBPhoneNumberUtil.sharedInstance()}
    
    private func prep(){
        let netInfo:CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()
        let carrier:CTCarrier! = netInfo.subscriberCellularProvider
        
        // device with sim reader
        if ((carrier) != nil) {

            if (carrier.mobileCountryCode == nil) {
                // device with sim reader but without sim
                
            } else {

                self.isoCountryCode = carrier.isoCountryCode!.uppercaseString // IT
                self.isoCountryCodeSim = self.isoCountryCode
                
                if let countryCode = phoneUtil.getCountryCodeForRegion(isoCountryCode){
                    self.phoneCountryCode = "+\(countryCode)"
                }
                
                self.phoneCountryCodeSim = self.phoneCountryCode
            }
        }
    }
    
    
    func isValidNumber(number: String) -> Bool {
        
        do {
            let myNumber: NBPhoneNumber! = try phoneUtil.parse(number, defaultRegion: self.isoCountryCode)
            if (phoneUtil.isValidNumber(myNumber)) {
                return true
            }
        }catch{
            
        }
        
        return false;
    }
    

    func e164Format() -> String? {
        var result: NSString? = nil;
        let number = self.phoneCountryCode! + self.phoneNumber!
        let formatted: NBPhoneNumber! = try! phoneUtil.parse(number, defaultRegion: self.isoCountryCode)
        
        result = try! phoneUtil.format(formatted, numberFormat: NBEPhoneNumberFormatE164)
        
        return result as? String
    }
    
    func formatNumber(number: String) -> NSString {
        
        do {
            let myNumber: NBPhoneNumber! = try phoneUtil.parse(number, defaultRegion: self.isoCountryCode);
            let countryCodeWithSpace: String = self.phoneCountryCode! + " "
            let tempNumber = try phoneUtil.format(myNumber, numberFormat: NBEPhoneNumberFormatINTERNATIONAL)
            return tempNumber.stringByReplacingOccurrencesOfString(countryCodeWithSpace, withString: "")
        }catch{
            return number
        }
    }
    
    override public var description: String {
        
        return "NumberInfo: {phoneCountryCode:\(phoneCountryCode),\n phoneNumber: \(phoneNumber),\nphoneCountryCodeSim: \(phoneCountryCodeSim), isoCountryCode: \(isoCountryCode), \nisoCountryCodeSim: \(isoCountryCodeSim)  }"
    }
    
}
