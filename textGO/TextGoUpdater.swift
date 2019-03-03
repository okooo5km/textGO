//
//  TextGoUpdater.swift
//  textGO
//
//  Created by 5km on 2019/3/2.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa


class TextGoUpdater {
    
    private let url: URL?
    private let user: String
    
    init(user: String) {
        self.user = user
        let proName = Bundle.main.infoDictionary!["CFBundleExecutable"]!
        self.url = URL(string: "https://raw.githubusercontent.com/\(user)/\(proName)/master/\(proName)/Info.plist")
    }
    
    func check(callback: @escaping (()->Void)) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: self.url!) { (data, response, error) in
            self.checkUpdateRequestSuccess(data: data, response: response, error: error, callback: callback)
        }
        task.resume()
    }
    
    private func checkUpdateRequestSuccess(data:Data?, response:URLResponse?, error:Error?, callback: @escaping (()->Void)) -> Void {
        DispatchQueue.main.async {
            callback()
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // :TODO 加日志
                    tipInfo(withTitle: NSLocalizedString("check-update-tip.title", comment: "检查更新"),
                            withMessage: NSLocalizedString("check-update-tip-network.message", comment: "网络异常！"))
                    return
                }
                var propertyListForamt = PropertyListSerialization.PropertyListFormat.xml
                do {
                    let infoPlist = try PropertyListSerialization.propertyList(from: data!, options: PropertyListSerialization.ReadOptions.mutableContainersAndLeaves, format: &propertyListForamt) as! [String: AnyObject]
                    let latestVersion = infoPlist["CFBundleShortVersionString"] as! String
                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                    if latestVersion == appVersion {
                        tipInfo(withTitle: NSLocalizedString("check-update-tip.title", comment: "检查更新"),
                                withMessage: NSLocalizedString("check-update-tip-none.message", comment: "没有更新！"))
                        return
                    }
                    
                    tipInfo(withTitle: NSLocalizedString("check-update-tip.title", comment: "检查更新"),
                            withMessage: NSLocalizedString("check-update-tip-get.message", comment: "发现新版本") + " v\(latestVersion)",
                        oKButtonTitle: NSLocalizedString("check-update-tip-get-gobutton.title", comment: "前往下载"),
                        cancelButtonTitle: NSLocalizedString("check-update-tip-get-ignorebutton.title", comment: "忽略")) {
                            if let url = URL(string: "https://github.com/\(self.user)/\(Bundle.main.infoDictionary!["CFBundleExecutable"]!)/releases/tag/v" + latestVersion) {
                                NSWorkspace.shared.open(url)
                            }
                    }
                } catch {
                    // :TODO 加日志
                    print("Error reading plist: \(error), format: \(propertyListForamt)")
                }
            }
        }
    }
}
