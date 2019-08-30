//
//  TextGoSettings.swift
//  textGO
//
//  Created by 5km on 2019/8/29.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

enum OCRService: Int, Codable, CaseIterable {
    case baidu, youtu
    
    init(name: String) {
        switch name {
        case "腾讯优图 OCR":
            self = .youtu
        default:
            self = .baidu
        }
    }
    
    var title: String {
        var result = ""
        switch self {
        case .youtu:
            result = "腾讯优图 OCR"
        default:
            result = "百度 AI OCR"
        }
        return result
    }
}

struct TextGoSettings: Codable {
    var service: OCRService
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "TextGoSettings")
            UserDefaults.standard.synchronize()
        }
    }
}
