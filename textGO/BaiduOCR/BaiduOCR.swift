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
    
    enum OCRMethod: String {
        case general_basic, accurate
        
        func url(withAccessToken accessToken: String) -> String {
            var result = ""
            switch self {
            case .general_basic:
                result = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=\(accessToken)"
            default:
                result = "https://aip.baidubce.com/rest/2.0/ocr/v1/accurate?access_token=\(accessToken)"
            }
            return result
        }
        
    }
    
    private var tryCount: Int = 0
    private var method: OCRMethod = .accurate
    
    func ocr(_ imgData: NSData, callback: @escaping ((String?, String?) -> Void)) {
        
        guard let accessToken = BaiduAccessToken.shared.value else {
            callback(nil, "BaiduAI: AccessToken 空")
            BaiduAccessToken.shared.update()
            return
        }
        
        let session = URLSession(configuration: .default)
        let url = URL(string: method.url(withAccessToken: accessToken))
        var request = URLRequest(url: url!)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postData = ["image_type": "BASE64", "image": base64From(imgData)!, "group_id": "textGO", "user_id": "5km"]
        let postString = postData.compactMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }).joined(separator: "&")
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
                    callback("", "BaiduAI: 数据空")
                    return
                }
                
                if let err = try? JSONDecoder().decode(BaiduError.self, from: data!) {
                    switch err.error_code {
                    case 17:    //  每日超量
                        self.method = .general_basic
                        self.ocr(imgData, callback: callback)
                    case 111:   //  accesstoken 过期
                        BaiduAccessToken.shared.update()
                    default:
                        callback(nil, "BaiduAI: " + err.error_msg)
                    }
                } else {
                    let result = try? JSONDecoder().decode(BaiduResult.self, from: data!)
                    var resultArray = [String]()
                    if let items = result?.words_result {
                        for item in items {
                            resultArray.append(item.words)
                        }
                    }
                    callback(resultArray.joined(separator: "\n"), nil)
                }
            }
        }
        task.resume()
    }
    
    private func base64From(_ imgData: NSData) -> String? {
        let b64Str = imgData.base64EncodedString()
        return b64Str.urlEncoded
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
