//
//  models.swift
//  textGO
//
//  Created by 5km on 2019/8/28.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

struct YouTuCoordinate: Codable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
}

struct YouTuWord: Codable {
    var character: String
    var confidence: Double
}

struct YouTuParagraph: Codable {
    var word_size: Int
    var parag_no: Int
}

struct YouTuCoordPoint: Codable {
    var x: [Int]
}

struct YouTuItem: Codable {
    var itemcoord: YouTuCoordinate
    var itemconf: Double
    var itemstring: String
    var coords: [YouTuCoordinate]
    var words: [YouTuWord]
    var candword: [YouTuWord]
    var parag: YouTuParagraph
    var coordpoint: YouTuCoordPoint
    var wordcoordpoint: [YouTuCoordPoint]
}

struct YouTuResult: Codable {
    var errorcode: Int
    var errormsg: String
    var items: [YouTuItem]
    var session_id: String
    var angle: Double
}
