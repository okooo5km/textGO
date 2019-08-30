//
//  TencentYouTuOCR.swift
//  textGO
//
//  Created by 5km on 2019/8/27.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

class YoutuOCR {
    
    static let shared = YoutuOCR()
    
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
    
    func ocr(_ imgData: NSData, callback: @escaping ((String?, String?) -> Void)) {
        let session = URLSession(configuration: .default)
        let url = URL(string: Method.hp.url)
        var request = URLRequest(url: url!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(YoutuAuth.shared.sign(), forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let postString = "{\"app_id\":\"\(YoutuAuth.shared.appID)\",\"image\":\"\(imgData.base64EncodedString())\"}"
        request.httpBody = postString.data(using: .utf8)
        let task = session.dataTask(with: request) {(data, response, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    if let httpResponse = response as? HTTPURLResponse {
                        callback(nil, YouTuError(code: httpResponse.statusCode).description)
                    }
                    return
                }
                
                guard data != nil else {
                    callback("", "数据空")
                    return
                }
                
                let result = try? JSONDecoder().decode(YouTuResult.self, from: data!)
                guard result?.errorcode == 0 else {
                    callback(nil, result?.errormsg)
                    return
                }
                
                var resultArray = [String]()
                if let items = result?.items {
                    for item in items {
                        resultArray.append(item.itemstring)
                    }
                }
                callback(resultArray.joined(separator: "\n"), nil)
            }
        }
        task.resume()
    }
}
