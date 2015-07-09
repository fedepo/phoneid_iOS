//
//  PhoneIdLoginButton.swift
//  PhoneIdSDK
//
//  Created by Alyona on 7/1/15.
//  Copyright © 2015 phoneId. All rights reserved.
//

import Foundation

//TODO: add possibility to style differently depending on login/logout state

@IBDesignable public class PhoneIdLoginButton: UIButton, Customizable {

    public var colorScheme: ColorScheme!
    public var localizationBundle:NSBundle!
    public var localizationTableName:String!
    
    
    var phoneIdService: PhoneIdService! { return PhoneIdService.sharedInstance}
    var phoneIdComponentFactory: ComponentFactory! { return phoneIdService.componentFactory}
    
    var activityIndicator:UIActivityIndicatorView!
    
    // init from viewcontroller
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        prep()
        initUI()
    }
    
    // init from interface builder
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prep()
        initUI();
    }
    
    override public func prepareForInterfaceBuilder() {
        self.prep()
        initUI();
    }
    
    func prep(){
        localizationBundle = phoneIdComponentFactory.localizationBundle()
        localizationTableName = phoneIdComponentFactory.localizationTableName()
        colorScheme = phoneIdComponentFactory.colorScheme()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appNameUpdated", name: Notifications.UpdateAppName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginSuccess:", name: Notifications.LoginSuccess, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logout:", name: Notifications.Logout, object: nil)
    }
    
    func initUI() {
        let bgImage:UIImage = UIImage(namedInPhoneId: "phone")!
        setTitle(localizedString("button.title.login.with.phone.id"), forState: .Normal)
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.systemFontOfSize(20)
        
        setBackgroundImage(bgImage, forState:UIControlState.Normal)
        addTarget(self, action:"loginTouched", forControlEvents: .TouchUpInside)
        
        backgroundColor = colorScheme.mainAccent
        
        layer.cornerRadius = 3
        layer.masksToBounds = true
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(self.activityIndicator)
        
        addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant:-5))
        addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant:0))
        
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func appNameUpdated(){
        self.userInteractionEnabled = true
    }
    
    func loginTouched() {
        
        if(phoneIdService.clientId == nil){
            fatalError("Phone.id is not configured for use: clientId is not set. Please call configureClient(clientId) first")
        }
        
        
        if(phoneIdService.appName != nil){
            self.presentNumberInputController()
        }else{
            activityIndicator.startAnimating()
            phoneIdService.loadClients(phoneIdService.clientId!, completion: { [unowned self] (error) -> Void in
                
                self.activityIndicator.stopAnimating()
                
                if(error == nil){
                    self.presentNumberInputController()
                }else{
                    if(error != nil){
                        let alertController = UIAlertController(title:error?.localizedDescription, message:error?.localizedFailureReason, preferredStyle: .Alert)
                        
                        alertController.addAction(UIAlertAction(title:self.localizedString("button.title.dismiss"), style: .Cancel, handler:nil));
                        self.window?.rootViewController?.presentViewController(alertController, animated: true, completion:nil)
                    }
                }
            })
        }
    }
    
    private func presentNumberInputController(){
        let controller = phoneIdComponentFactory.numberInputViewController()
        window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
    }
    
    func loggedInTouched() {
        print("already logged in with phone id")
    }
    
    func loginSuccess(notification:NSNotification) -> Void {
        self.removeTarget(self, action: nil, forControlEvents: .TouchUpInside)
        
        self.setTitle(localizedString("button.title.logged.in"), forState:UIControlState.Normal)
        self.addTarget(self, action:"loggedInTouched", forControlEvents: .TouchUpInside)
    }
    
    func logout(notification:NSNotification) -> Void {
        
       self.removeTarget(self, action: nil, forControlEvents: .TouchUpInside)
        
       self.setTitle(localizedString("button.title.login.with.phone.id"), forState: .Normal)
       self.addTarget(self, action:"loginTouched", forControlEvents: .TouchUpInside)
    }
    
    
}