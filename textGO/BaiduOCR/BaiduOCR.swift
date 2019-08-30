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
    
    enum OcrUrl: String {
        case basic = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token="
        case accurate = "https://aip.baidubce.com/rest/2.0/ocr/v1/accurate?access_token="
    }
    
    private var tryCount: Int = 0
    private var ocrUrl = OcrUrl.accurate
    
    func ocr(_ imgData: NSData, callback: @escaping ((String?, String?) -> Void)) {
        
        let accessToken = BaiduAccessToken.shared.value
        
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
                
                if let err = try? JSONDecoder().decode(BaiduError.self, from: data!) {
                    if err.error_code == 111 {
                        BaiduAccessToken.shared.update()
                    }
                    callback(nil, err.error_msg)
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
