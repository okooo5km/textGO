//
//  BaiduAI.swift
//  textGO
//
//  Created by 5km on 2019/1/20.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa


class BaiduAI {
    
    static let share = BaiduAI()
    
    enum ErrorType: Int {
        case accessTokenInvalid = 110   // 无效的 access token
        case connectInvalid = 111       // 连接错误
        case openApiLimited = 17        // 每日的限制次数已达上限
        case resultEmpty                // 没有结果
    }
    
    enum OcrUrl: String {
        case basic = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token="
        case accurate = "https://aip.baidubce.com/rest/2.0/ocr/v1/accurate?access_token="
    }
    
    private var tryCount: Int = 0
    private var ocrUrl = OcrUrl.accurate
    private var _baiduParams: [String: String]? = [String: String]()
    var baiduParams: [String: String]? {
        get {
            if UserDefaults.standard.dictionary(forKey: "baiduAIParams") == nil {
                _baiduParams!["apiKey"] = "HGuY2oEGhPQAPC5VQrRIA40S"
                _baiduParams!["secretKey"] = "L3SUNohBY5vnAndfkp8IKYtPwv5Td908"
                _baiduParams!["accessToken"] = ""
                UserDefaults.standard.set(_baiduParams, forKey: "baiduAIParams")
                self.updateAccessToken()
            }
            return  (UserDefaults.standard.dictionary(forKey: "baiduAIParams") as? [String : String])
        }
        set {
            _baiduParams = newValue
            UserDefaults.standard.set(newValue, forKey: "baiduAIParams")
        }
    }
    
    var apiKey: String? {
        get {
            return baiduParams!["apiKey"]
        }
        
        set {
            baiduParams!["apiKey"] = newValue
        }
    }
    
    var secretKey: String? {
        get {
            return baiduParams!["secretKey"]
        }
        
        set {
            baiduParams!["secretKey"] = newValue
        }
    }
    
    var accessToken: String? {
        get {
            return baiduParams!["accessToken"]
        }
        
        set {
            baiduParams!["accessToken"] = newValue
        }
    }
    
    func reset() {
        apiKey = ""
        secretKey = ""
        accessToken = ""
    }
    
    func ocr(_ imgData: NSData, callback: @escaping ((String?, String?) -> Void)) {
        
        if accessToken == nil {
            return
        }
        
        let session = URLSession(configuration: .default)
        let url = URL(string: "\(ocrUrl.rawValue)\(accessToken ?? "")")
        var request = URLRequest(url: url!)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postData = ["image_type": "BASE64", "image": base64From(imgData)!, "group_id": "textGO", "user_id": "5km"]
        let postString = postData.compactMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }).joined(separator: "&")
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request) {(data, response, error) in
            self.requestCompletionHandler(imgData: imgData, data: data, response: response, error: error, callback: callback)
        }
        task.resume()
    }
    
    private func requestCompletionHandler(imgData: NSData, data: Data?, response: URLResponse?, error: Error?, callback: @escaping ((String?, String?) -> Void)) {
        DispatchQueue.main.async {
            do {
                let r = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                if let errorCode = r.value(forKey: "error_code") as? Int {
                    if let errorType = ErrorType(rawValue: errorCode) {
                        switch (errorType) {
                        case ErrorType.accessTokenInvalid:
                            self.updateAccessToken()
                        case ErrorType.openApiLimited:
                            self.ocrUrl = OcrUrl.basic
                            self.ocr(imgData, callback: callback)
                        case ErrorType.connectInvalid:  // 此时的错误是 Access token expired
                            self.updateAccessToken()
                            self.ocr(imgData, callback: callback)
                        default:
                            print("")
                        }
                        callback(nil, (r.value(forKey: "error_msg") as! String))
                    } else {
                        print(r)
                    }
                } else {
                    if let wordsResult = r.value(forKey: "words_result") as? NSArray {
                        var wordsArray = [String]()
                        for lineResult in wordsResult {
                            let words = (lineResult as! NSDictionary).value(forKey: "words") as! String
                            wordsArray.append(words)
                        }
                        let wordsStr = wordsArray.joined(separator: "\n")
                        callback(wordsStr, nil)
                    } else {
                        callback(nil, "result is empty")
                    }
                }
            } catch {
                callback(nil, "can not connect to server")
                return
            }
        }
    }
    
    private func base64From(_ imgData: NSData) -> String? {
        let b64Str = imgData.base64EncodedString()
        return b64Str.urlEncoded
    }
    
    func updateAccessToken() {
        if apiKey == "" || secretKey == "" {
            accessToken = nil
            return
        }
        let session = URLSession(configuration: .default)
        let url = URL(string: "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=\(apiKey ?? "")&client_secret=\(secretKey ?? "")")
        let task = session.dataTask(with: url!) {
            (data, response, error) in
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let jsonDict = try JSONSerialization.jsonObject(with: responseData, options: [])
                    as? [String: Any] else {
                        print("error trying to convert data to JSON")
                        return
                }
                // now we have the todo
                self.accessToken = jsonDict["access_token"] as? String
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
    
}

extension String {
    //将原始的url编码为合法的url
    var urlEncoded: String? {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
    
    //将编码后的url转换回原始的url
    var urlDecoded: String? {
        return removingPercentEncoding
    }
}
