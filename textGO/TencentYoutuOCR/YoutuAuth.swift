//
//  Auth.swift
//  textGO
//
//  Created by 5km on 2019/8/28.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa
import CommonCrypto

class YoutuAuth {
    var appID: String
    private var qq: String
    private var secretID:String
    private var secretKey: String
    
    static let shared = YoutuAuth(qq: "1206407149",
                                     appID: "10187428",
                                     secretID: "AKIDmRhBVlEkaoq1efu7irq84JC0M2V0vdDo",
                                     secretKey: "bSzTKF8SmvqfjdyMtO3XXuTlIk1Q3Yo0")
    
    init(qq _qq:String, appID _appID:String, secretID _secretID:String, secretKey _secretKey:String) {
        self.qq = _qq
        self.appID = _appID
        self.secretID = _secretID
        self.secretKey = _secretKey
    }
    
    func sign() -> String {
        let now = Int(NSDate().timeIntervalSince1970)
        let random = Int.random(in: 0...1000000000)
        
        let plainText = "u=\(qq)&a=\(appID)&k=\(secretID)&e=\(0)&t=\(now)&r=\(random)&f="
        
        var data = plainText.hmac(algorithm: .SHA1, key: secretKey)
        data.append(plainText.data(using: .utf8)!)
        return data.base64EncodedString()
    }
}

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> Data {
        let cKeyString = key.cString(using: .utf8)
        let cDataString = self.cString(using: .utf8)
        let len = algorithm.digestLength
        var cHMAC = [UInt8](repeating: 0, count: Int(len))
        
        CCHmac(algorithm.HMACAlgorithm, cKeyString, key.count, cDataString, self.count, &cHMAC)
        
        return Data(cHMAC)
    }
}
