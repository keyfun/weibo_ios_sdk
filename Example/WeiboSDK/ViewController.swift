//
//  ViewController.swift
//  WeiboSDK
//
//  Created by Key on 01/21/2016.
//  Copyright (c) 2016 Key. All rights reserved.
//

import UIKit
import WeiboSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("START")
        print(WeiboSDK.getSDKVersion())
        print(WeiboSDK.isWeiboAppInstalled())
        WeiboSDK.registerApp("1234") // crash at getPublicKey
        //SinaWeiboManager.sharedInstance.registerApp("1234") // crash at getPublicKey
        print("END")
    }

}

