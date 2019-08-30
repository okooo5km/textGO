//
//  BaiduAccessToken.swift
//  textGO
//
//  Created by 5km on 2019/8/30.
//  Copyright © 2019 5km. All rights reserved.
//

import Foundation

class BaiduAccessToken {
    
    struct BaiduParams: Codable {
        var apiKey: String
        var apiSecret: String
        var accessToken: String
    }
    
    static let shared = BaiduAccessToken(apiKey: "HGuY2oEGhPQAPC5VQrRIA40S",
                                         apiSecret: "L3SUNohBY5vnAndfkp8IKYtPwv5Td908")
    
    var value: String?
    private var apiKey: String
    private var apiSecret: String
    
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        if let data = UserDefaults.standard.value(forKey: "baiduAIParams") as? Data {
            if let params = try? JSONDecoder().decode(BaiduParams.self, from: data) {
                if params.apiKey != apiKey || params.apiSecret != apiSecret {
                    self.update()
                } else {
                    self.value = params.accessToken
                }
                return
            }
        }
        self.update()
    }
    
    func update() {
        
        let session = URLSession(configuration: .default)
        let url = URL(string: "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=\(apiKey)&client_secret=\(apiSecret)")
        let task = session.dataTask(with: url!) {
            (data, response, error) in
            guard error == nil else {
                print("error calling AccessToken")
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
                self.value = (jsonDict["access_token"] as? String)!
                let params = BaiduParams(apiKey: self.apiKey, apiSecret: self.apiSecret, accessToken: self.value!)
                if let data = try? JSONEncoder().encode(params) {
                    UserDefaults.standard.set(data, forKey: "baiduAIParams")
                    UserDefaults.standard.synchronize()
                }
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }
}
