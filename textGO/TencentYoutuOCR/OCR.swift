//
//  TencentYouTuOCR.swift
//  textGO
//
//  Created by 5km on 2019/8/27.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

class YoutuOCR {
    
    static let share = YoutuOCR()
    
    enum Method {
        case general, hp
        
        var name: String {
            switch self {
            case .general:
                return "youtu/ocrapi/generalocr"
            default:
                return "youtu/ocrapi/hpgeneralocr"
            }
        }
        
        var url: String {
            return "https://api.youtu.qq.com/\(self.name)"
        }
    }
    
    enum ErrorType: Int {
        case accessTokenInvalid
    }
    
    func ocr(_ imgData: NSData, callback: @escaping ((String?, (ErrorType, String)?) -> Void)) {
        let session = URLSession(configuration: .default)
        let url = URL(string: Method.general.url)
        var request = URLRequest(url: url!)
        request.addValue("text/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Authorization.share.sign(), forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let postString = "{\"app_id\":\"\(Authorization.share.appID)\",\"image\":\"\(imgData.base64EncodedString())\"}"
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request) {(data, response, error) in
            DispatchQueue.main.async {
                do {
                    let result = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    print(result)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        task.resume()
    }
}
