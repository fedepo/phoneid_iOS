//
//  ContactsLoader.swift
//  phoneid_iOS
//
//  Copyright 2015 Federico Pomi
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import Foundation
import AddressBook

// Going to switch to Contacts framework as soon we drop support of iOS8

class ContactsLoader: NSObject {

    var book : ABAddressBook!
    
    func createAddressBook() -> Bool {
        
        if self.book != nil {
            return true
        }
        
        var err : Unmanaged<CFError>? = nil
        let adbk : ABAddressBook? = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        if adbk == nil {
            print(err)
            self.book = nil
            return false
        }
        
        self.book = adbk
        
        return true
    }
    
    func determineStatus(completion:(Bool)->Void){
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
        case .Authorized:
            self.createAddressBook()
            completion(true)
            
        case .NotDetermined:
            ABAddressBookRequestAccessWithCompletion(nil) {
                (granted:Bool, err:CFError!) in
                dispatch_async(dispatch_get_main_queue()) {
                    if granted {
                        self.createAddressBook()
                    }else{
                        self.book = nil
                    }
                    completion(granted)
                }
            }
        case .Restricted, .Denied:
            self.book = nil
            completion(false)
        }
    }
    
    func getContacts(defaultISOCountryCode:String, completion: ([ContactInfo]?) -> Void){
                       
        determineStatus { [unowned self] (authenticated) -> Void in
            
            var result:[ContactInfo]?
            
            if(authenticated){
                
                let people = ABAddressBookCopyArrayOfAllPeople(self.book).takeRetainedValue() as NSArray as [ABRecord]
                for person:ABRecordRef in people {
                    
                    var contactInfo:ContactInfo!
                    
                    let phonesRef: ABMultiValueRef = ABRecordCopyValue(person, kABPersonPhoneProperty).takeRetainedValue() as ABMultiValueRef
                    
                    for var i:Int = 0; i < ABMultiValueGetCount(phonesRef); i++ {
                        
                        if let value = ABMultiValueCopyValueAtIndex(phonesRef, i).takeRetainedValue() as? String {

                            if let number =  NumberInfo.e164Format(value, iso: defaultISOCountryCode){
                                
                                contactInfo = ContactInfo()
                                
                                contactInfo.number = number
                                
                                let rawLabel = ABMultiValueCopyLabelAtIndex(phonesRef, i)?.takeRetainedValue()
                                
                                contactInfo.kind = ABAddressBookCopyLocalizedLabel(rawLabel)?.takeRetainedValue() as? String
                                
                                if let firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty)?.takeRetainedValue() as? String {
                                    contactInfo.firstName = firstName
                                }
                                
                                if let lastName = ABRecordCopyValue(person, kABPersonLastNameProperty)?.takeRetainedValue() as? String {
                                    contactInfo.lastName = lastName
                                }
                                
                                if let lastName = ABRecordCopyValue(person, kABPersonOrganizationProperty)?.takeRetainedValue() as? String {
                                    contactInfo.company = lastName
                                }
                            }
                        }
                        if(contactInfo != nil){
                            if result == nil {
                                result = []
                            }
                            result?.append(contactInfo)
                        }
                    }
                    
                    
                }
                
            }
            completion(result)
        }
    }


}