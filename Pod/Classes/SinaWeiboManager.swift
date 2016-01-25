//
//  SinaWeiboManager.swift
//
//  Created by Key Hui on 14/9/15.
//

final class SinaWeiboManager:NSObject, WeiboSDKDelegate {
    
    let kMale = "male"
    let kFemale = "female"
    
    static var sharedInstance = SinaWeiboManager()
    var expiresIn:Double = 0
    
    // for HeHa Login
    var socialInfo:String = ""
    var profileDict = [String:String]()
    
    var returnsTheCallback : (() -> ())?
    
    override init() {
        super.init()
    }
    override internal func getShareInstance() -> BaseManager? {
        return SinaWeiboManager.sharedInstance
    }
    
    override internal func setShareInstance(instance: BaseManager) {
        SinaWeiboManager.sharedInstance = instance as! SinaWeiboManager
    }
    
    override func registerApp() {
        
        // marco define in build-settings Swift Custom Flags
        #if DEBUG
            WeiboSDK.enableDebugMode(true)
        #else
            WeiboSDK.enableDebugMode(false)
        #endif
        
        WeiboSDK.registerApp(SocialConstants.sharedInstance.kWeiboAppKey)
        print("[WeiboManager] WeiboSDK Version = \(WeiboSDK.getSDKVersion())")
    }
    
    func isAppInstalled() -> Bool {
        return WeiboSDK.isWeiboAppInstalled()
    }
    
    func didReceiveWeiboRequest(request: WBBaseRequest!) {
        print("[SinaWeiboManager] didReceiveWeiboRequest request = \(request.description)")
        if (request.isKindOfClass(WBProvideMessageForWeiboRequest)) {
            //TODO: sth
        }
    }
    
    func didReceiveWeiboResponse(response: WBBaseResponse!) {
        if (response.isKindOfClass(WBSendMessageToWeiboResponse)) {
            let message = "响应状态:\(response.statusCode.rawValue)\n响应UserInfo数据:\(response.userInfo)\n原请求UserInfo数据:\(response.requestUserInfo)"
            
            print("[SinaWeiboManager] WBSendMessageToWeiboResponse message = \(message)")
            
            if returnsTheCallback != nil {
                returnsTheCallback!()
            }
            
        } else if (response.isKindOfClass(WBAuthorizeResponse)) {
            
            let tmpRes:WBAuthorizeResponse = response as! WBAuthorizeResponse
            
            let message = "响应状态: \(response.statusCode.rawValue)\nresponse.userId: \(tmpRes.userID)\nresponse.accessToken: \(tmpRes.accessToken)\n响应UserInfo数据: \(response.userInfo)\n原请求UserInfo数据: \(response.requestUserInfo)"
            
            print("[SinaWeiboManager] WBAuthorizeResponse message = \(message)")
            
            if(response.statusCode.rawValue >= 0) {
                let userId:String = tmpRes.userID
                let accessToken:String = tmpRes.accessToken
                let refreshToken:String = tmpRes.refreshToken
                var expiresIn:Double = NSDate().timeIntervalSinceDate(tmpRes.expirationDate)
                expiresIn = -1 * floor(expiresIn)
                self.setData(userId, accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                
//                delegate?.onWeiboAuthComplete(true)
                delegate?.onAuthComplete(self.provider, success: true)
            } else {
//                delegate?.onWeiboAuthComplete(false)
                delegate?.onAuthComplete(self.provider, success: false)
            }
        }
    }
    
    override func auth() {
        let request:WBAuthorizeRequest! = WBAuthorizeRequest.request() as! WBAuthorizeRequest
        request.redirectURI = SocialConstants.sharedInstance.kWeiboRedirectURI
        request.scope = "all"
        WeiboSDK.sendRequest(request)
    }
    
    override func renewAccessToken(completion: (result: AnyObject?, error: NSError?)->()) {
        let request = WBHttpRequest(forRenewAccessTokenWithRefreshToken: refreshToken, queue: nil,
            withCompletionHandler:{
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
                
                if(result != nil && error == nil) {
                    
                    let json:JSON = JSON(result!)
                    let userId:String = json["uid"].stringValue
                    let accessToken:String = json["access_token"].stringValue
                    let refreshToken:String = json["refresh_token"].stringValue
                    let expiresIn:Double = json["expires_in"].doubleValue
                    self.setData(userId, accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
                    
                    completion(result: result, error: nil)
                    //print("[WeiboManager] callRefreshToken result = \(result.debugDescription)")
                } else {
                    completion(result: nil, error: error)
                    print("[WeiboManager] callRefreshToken error = \(error.debugDescription)")
                }
        })
        
        print("[WeiboManager] renewAccessToken = \(request)")
    }
    
    func logout() {
        WeiboSDK.logOutWithToken(accessToken, delegate: nil, withTag: "")

        SocialManager.sharedInstance.clearStatus(self.provider)
        self.clearData()
    }
    
    func getUserProfile(completion: (result: WeiboUser?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forUserProfile: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler:{
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            //print("[WeiboManager] getUserInfo result = \(result.debugDescription)")
            
            if(error == nil) {
                let wbUser:WeiboUser = result as! WeiboUser
                //print("[WeiboManager] wbUser = \(wbUser.debugDescription)")
                //print("[WeiboManager] name = \(wbUser.name), profileImageUrl = \(wbUser.profileImageUrl)")
                
                self.setSocialInfoAndProfile(wbUser)
                
//                self.delegate?.onWeiboGetUserInfoComplete(true)
                self.delegate?.onGetUserInfoComplete(self.provider, success: true)
                completion(result: wbUser, error: nil)
            } else {
//                self.delegate?.onWeiboGetUserInfoComplete(false)
                self.delegate?.onGetUserInfoComplete(self.provider, success: false)
                completion(result: nil, error: error)
                print("[WeiboManager] getUserProfile = \(error.debugDescription)")
            }
        })
        
        print("[WeiboManager] getUserProfile = \(request)")
    }
    
    func getFriendsListOfUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forFriendsListOfUser: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler:{
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            
            if(result != nil && error == nil) {
                //print("[WeiboManager] getFriends result = \(result.description)")
                completion(result: result, error: nil)
            } else {
                //print("[WeiboManager] getFriends error = \(error.description)")
                completion(result: nil, error: error)
            }
        })
        
        print("[WeiboManager] getFriends = \(request)")
    }
    
    func getFollowersListOfUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forFollowersListOfUser: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            
            if(result != nil && error == nil) {
                //print("[WeiboManager] getFollowersListOfUser result = \(result.description)")
                completion(result: result, error: nil)
            } else {
                //print("[WeiboManager] getFollowersListOfUser error = \(error.description)")
                completion(result: nil, error: error)
            }
        
        })
        print("[WeiboManager] getFollowersListOfUser = \(request)")
    }
    
    func getStatusIDsFromCurrentUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forStatusIDsFromCurrentUser: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            print("[WeiboManager] getStatusIDsFromCurrentUser result = \(result.description)")
            
            if(error == nil) {
                completion(result: result, error: nil)
            }

        })
        print("[WeiboManager] getStatusIDsFromCurrentUser = \(request)")
    }
    
    func getUserStatuses(completion: (result: AnyObject?, error: NSError?)->()) {
        
        var params:Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
        params["access_token"] = accessToken
        //params["uid"] = "3177101454"
        //params["screen_name"] = "hkzen"
        //params["count"] = "10" // max. 100
        
        let url:String = "https://api.weibo.com/2/statuses/user_timeline.json"
        //let url:String = "https://api.weibo.com/2/statuses/friends_timeline.json"
        
        let request = WBHttpRequest(URL: url, httpMethod: "GET", params: params, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            //print("[WeiboManager] getUserStatuses result = \(result.description)")

            if(error == nil) {
                completion(result: result, error: nil)
            } else {
                print("[WeiboManager] getUserStatuses error = \(error.description)")
                completion(result: nil, error: error)
            }
        
        })
        print("[WeiboManager] getUserStatuses = \(request)")
    }
    
    func shareStatus(title:String?, imageData:NSData?, completion: (result: AnyObject?, error: NSError?)->()) {
        
        var image:WBImageObject? = WBImageObject()
        if(imageData != nil) {
            image?.imageData = imageData
        } else {
            image = nil
        }
        
        let request = WBHttpRequest(forShareAStatus: title, contatinsAPicture: image, orPictureUrl: nil, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            
            if(error == nil) {
                print("[WeiboManager] shareStatus result = \(result.description)")
                completion(result: result, error: nil)
            } else {
                print("[WeiboManager] shareStatus error = \(error.description)")
                completion(result: nil, error: error)
            }
        
        })
        print("[WeiboManager] shareStatus = \(request)")
    }
    
    func shareStatusViaApp(title:String?, imageData:NSData?, completion: (result: AnyObject?, error: NSError?)->()) {
        
        // TODO: no completion callback yet
        let message = WBMessageObject()
        message.text = title
        
        if(imageData != nil) {
            let image:WBImageObject = WBImageObject()
            image.imageData = imageData
            message.imageObject = image
        }
        
        let request:WBSendMessageToWeiboRequest = WBSendMessageToWeiboRequest.requestWithMessage(message) as! WBSendMessageToWeiboRequest
        WeiboSDK.sendRequest(request)
    }
    
    func followUser(screenName screenName:String, completion: (result: AnyObject?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forFollowAUser: screenName, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            
            if(error == nil) {
                print("[WeiboManager] followUser result = \(result.description)")
                completion(result: result, error: nil)
            } else {
                print("[WeiboManager] followUser error = \(error.description)")
                completion(result: nil, error: error)
            }
        
        })
        print("[WeiboManager] followUser = \(request)")
    }
    
    func getUserComments(completion: (result: AnyObject?, error: NSError?)->()) {
        
        var params:Dictionary<NSObject, AnyObject> = Dictionary<NSObject, AnyObject>()
        params["access_token"] = accessToken
        
        let url:String = "https://api.weibo.com/2/comments/timeline.json"
        
        let request = WBHttpRequest(URL: url, httpMethod: "GET", params: params, queue: nil, withCompletionHandler: {
            
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            //print("[WeiboManager] getUserComments result = \(result.description)")
            
            if(error == nil) {
                completion(result: result, error: nil)
            } else {
                print("[WeiboManager] getUserComments error = \(error.description)")
                completion(result: nil, error: error)
            }
            
        })
        print("[WeiboManager] getUserComments = \(request)")
    }
    
    override func handleOpenURL(openURL url: NSURL, sourceApplication: String?) -> Bool {
        return WeiboSDK.handleOpenURL(url, delegate: SinaWeiboManager.sharedInstance)
    }
    
}