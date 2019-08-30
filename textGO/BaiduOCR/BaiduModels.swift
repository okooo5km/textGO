//
//  File.swift
//  textGO
//
//  Created by 5km on 2019/8/30.
//  Copyright © 2019 5km. All rights reserved.
//

import Foundation

struct BaiduLocation: Codable {
    var top: Int
    var left: Int
    var width: Int
    var height: Int
}

struct BaiduWords: Codable {
    var location: BaiduLocation
    var words: String
}

struct BaiduResult: Codable {
    var log_id: Int
    var words_result: [BaiduWords]
    var words_result_num: Int
}
