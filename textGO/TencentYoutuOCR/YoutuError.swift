//
//  Error.swift
//  textGO
//
//  Created by 5km on 2019/8/29.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

enum YouTuError: Int, CaseIterable {
    case unknown = -1
    case badRequest = 400
    case unauthoized = 401
    case forbidden = 403
    case notFound = 404
    case requestNoLength = 411
    case requestLarge = 413
    case methodNotFound = 424
    case internalServerError = 500
    case badGateway = 502
    case serviceUnAvailable = 503
    case gatewayTimeout = 504
    
    var description: String {
        var result = ""
        switch self {
        case .badRequest:
            result = "请求不合法，包体格式错误"
        case .unauthoized:
            result = "权限验证失败"
        case .forbidden:
            result = "鉴权信息不合法，禁止访问"
        case .notFound:
            result = "请求失败"
        case .requestNoLength:
            result = "请求没有指定 ContentLength"
        case .requestLarge:
            result = "请求包体太大"
        case .methodNotFound:
            result = "请求的方法没有找到"
        case .internalServerError:
            result = "服务内部错误"
        case .badGateway:
            result = "网关错误，计算后台服务不可用"
        case .serviceUnAvailable:
            result = "服务不可用"
        case .gatewayTimeout:
            result = "后端服务超时或者处理失败"
        default:
            result = "未知错误"
        }
        return result
    }
    
    init(code: Int) {
        for err in YouTuError.allCases {
            if code == err.rawValue {
                self = err
                return
            }
        }
        self = .unknown
    }
}
