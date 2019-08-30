//
//  BaiduError.swift
//  textGO
//
//  Created by 5km on 2019/8/30.
//  Copyright © 2019 5km. All rights reserved.
//

import Foundation

struct BaiduError: Codable {
    var error_code: Int
    var error_msg: String
}
