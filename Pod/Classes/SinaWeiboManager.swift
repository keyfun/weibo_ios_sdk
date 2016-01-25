//
//  SinaWeiboManager.swift
//
//  Created by Key Hui on 14/9/15.
//

public class SinaWeiboManager:NSObject, WeiboSDKDelegate {
    
    static public var sharedInstance = SinaWeiboManager()
    var expiresIn:Double = 0
    var userId:String = ""
    var accessToken:String = ""
    var refreshToken:String = ""
    
    var returnsTheCallback : (() -> ())?
    
    override init() {
        super.init()
    }
    
    public func registerApp(appKey:String) {
        
        // marco define in build-settings Swift Custom Flags
        #if DEBUG
            WeiboSDK.enableDebugMode(true)
        #else
            WeiboSDK.enableDebugMode(false)
        #endif
        
        WeiboSDK.registerApp(appKey)
        print("[WeiboManager] WeiboSDK Version = \(WeiboSDK.getSDKVersion())")
    }
    
    public func isAppInstalled() -> Bool {
        return WeiboSDK.isWeiboAppInstalled()
    }
    
    public func didReceiveWeiboRequest(request: WBBaseRequest!) {
        print("[SinaWeiboManager] didReceiveWeiboRequest request = \(request.description)")
        if (request.isKindOfClass(WBProvideMessageForWeiboRequest)) {
            //TODO: sth
        }
    }
    
    public func didReceiveWeiboResponse(response: WBBaseResponse!) {
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
                userId = tmpRes.userID
                accessToken = tmpRes.accessToken
                refreshToken = tmpRes.refreshToken
                expiresIn = NSDate().timeIntervalSinceDate(tmpRes.expirationDate)
                expiresIn = -1 * floor(expiresIn)
            }
        }
    }
    
    public func auth() {
        let request:WBAuthorizeRequest! = WBAuthorizeRequest.request() as! WBAuthorizeRequest
        request.redirectURI = "http://sinaweibo.com"
        request.scope = "all"
        WeiboSDK.sendRequest(request)
    }
    
    public func renewAccessToken(refreshToken:String, completion: (result: AnyObject?, error: NSError?)->()) {
        let request = WBHttpRequest(forRenewAccessTokenWithRefreshToken: refreshToken, queue: nil,
            withCompletionHandler:{
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
                
                if(result != nil && error == nil) {
                    print(result)
                    completion(result: result, error: nil)
                } else {
                    completion(result: nil, error: error)
                    print("[WeiboManager] callRefreshToken error = \(error.debugDescription)")
                }
        })
        
        print("[WeiboManager] renewAccessToken = \(request)")
    }
    
    public func logout() {
        WeiboSDK.logOutWithToken(accessToken, delegate: nil, withTag: "")
    }
    
    public func getUserProfile(completion: (result: WeiboUser?, error: NSError?)->()) {
        
        _ = WBHttpRequest(forUserProfile: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler:{
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            
            if(error == nil) {
                let wbUser:WeiboUser = result as! WeiboUser
                completion(result: wbUser, error: nil)
            } else {
                completion(result: nil, error: error)
                print("[WeiboManager] getUserProfile = \(error.debugDescription)")
            }
        })
    }
    
    public func getFriendsListOfUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func getFollowersListOfUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func getStatusIDsFromCurrentUser(completion: (result: AnyObject?, error: NSError?)->()) {
        
        let request = WBHttpRequest(forStatusIDsFromCurrentUser: userId, withAccessToken: accessToken, andOtherProperties: nil, queue: nil, withCompletionHandler: {
        
            (httpRequest: WBHttpRequest!,result: AnyObject!, error: NSError!) in
            print("[WeiboManager] getStatusIDsFromCurrentUser result = \(result.description)")
            
            if(error == nil) {
                completion(result: result, error: nil)
            }

        })
        print("[WeiboManager] getStatusIDsFromCurrentUser = \(request)")
    }
    
    public func getUserStatuses(completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func shareStatus(title:String?, imageData:NSData?, completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func shareStatusViaApp(title:String?, imageData:NSData?, completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func followUser(screenName screenName:String, completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func getUserComments(completion: (result: AnyObject?, error: NSError?)->()) {
        
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
    
    public func handleOpenURL(openURL url: NSURL, sourceApplication: String?) -> Bool {
        return WeiboSDK.handleOpenURL(url, delegate: SinaWeiboManager.sharedInstance)
    }
    
}