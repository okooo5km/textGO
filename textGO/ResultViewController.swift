//
//  ResultViewController.swift
//  textGO
//
//  Created by 5km on 2019/3/8.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

class ResultViewController: NSViewController {

    var resultText: String?
    @IBOutlet weak var targetImageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openResultHandleWindow(_ sender: Any) {
        // 添加结果处理窗口的弹出
        print("handle here")
    }
}
