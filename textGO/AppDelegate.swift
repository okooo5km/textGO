//
//  AppDelegate.swift
//  textGO
//
//  Created by 5km on 2019/1/18.
//  Copyright © 2019 5km. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    var settings: TextGoSettings?
    var ocrImage: NSImage?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named: "statusIcon")
            button.window?.delegate = self
            button.window?.registerForDraggedTypes([NSPasteboard.PasteboardType("NSFilenamesPboardType")])
        }
        
        // 加载设置，必须放在 Menu 构建前面
        if let data = UserDefaults.standard.value(forKey: "TextGoSettings") as? Data {
            settings = try? JSONDecoder().decode(TextGoSettings.self, from: data)
        } else {
            settings = TextGoSettings(service: .baidu)
            settings?.save()
        }
        
        constructMenu()
        if settings?.service == OCRService.baidu {
            BaiduAccessToken.shared.update()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func constructMenu() {
        let menu = NSMenu()
        let helpMenu = NSMenu()
        let serviceMenu = NSMenu()
        let helpDropdown = NSMenuItem(title: NSLocalizedString("menu-item-help.title", comment: "菜单栏帮助选项按钮标题：帮助选项"), action: nil, keyEquivalent: "")
        let serviceDropdown = NSMenuItem(title: NSLocalizedString("menu-item-service.title", comment: "菜单栏OCR服务选择按钮标题：识别服务"), action: nil, keyEquivalent: "")
        
        helpMenu.addItem(withTitle: NSLocalizedString("menu-item-help-tutorial.title", comment: "菜单栏帮助选项按钮标题：教程"), action: #selector(howToUse), keyEquivalent: "")
        helpMenu.addItem(withTitle: NSLocalizedString("menu-item-help-feedback.title", comment: "菜单栏帮助选项按钮标题：反馈"), action: #selector(feedbackApp), keyEquivalent: "")
        helpMenu.addItem(withTitle: NSLocalizedString("menu-item-help-about.title", comment: "菜单栏帮助选项按钮标题：关于"), action: #selector(showAboutMe), keyEquivalent: "")
        
        for item in OCRService.allCases {
            let menuItem = NSMenuItem(title: item.title, action: #selector(selectService(sender:)), keyEquivalent: "")
            if item == settings?.service {
                menuItem.state = .on
            }
            serviceMenu.addItem(menuItem)
        }
        
        menu.addItem(withTitle: NSLocalizedString("menu-item-capture-ocr.title", comment: "菜单栏截图识别按钮标题：截图识别"), action: #selector(screenshotAndOCR), keyEquivalent: "c")
        menu.addItem(.separator())
        menu.addItem(serviceDropdown)
        menu.setSubmenu(serviceMenu, for: serviceDropdown)
        menu.addItem(.separator())
        menu.addItem(helpDropdown)
        menu.setSubmenu(helpMenu, for: helpDropdown)
        menu.addItem(withTitle: NSLocalizedString("menu-item-check-update.title", comment: "菜单栏检查更新按钮标题：检查更新"), action: #selector(checkUpdate), keyEquivalent: "u")
        menu.addItem(.separator())
        menu.addItem(withTitle: NSLocalizedString("menu-item-quit.title", comment: "菜单栏退出按钮标题：退出 文析"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }
    
    @objc func screenshotAndOCR() {

        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        task.launch()
        task.waitUntilExit()
        
        if (NSPasteboard.general.types?.contains(NSPasteboard.PasteboardType.png))! {
            let imgData = NSPasteboard.general.data(forType: NSPasteboard.PasteboardType.png)
            self.ocrImage = NSImage(data: imgData!)
            
            if let service = settings?.service {
                switch service {
                case OCRService.baidu:
                    BaiduAI.share.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
                case OCRService.youtu:
                    YoutuOCR.shared.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
                }
            } else {
                BaiduAI.share.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
            }
        }
    }
    
    @objc func selectService(sender: NSMenuItem) {
        settings?.service = .init(name: sender.title)
        settings?.save()
        
        if let menu = sender.parent!.submenu {
            for item in menu.items {
                if item.title == sender.title {
                    item.state = .on
                } else {
                    item.state = .off
                }
            }
        }
    }
    
    @objc func showAboutMe() {
        tipInfo(withTitle: NSLocalizedString("about-window.title", comment: "关于窗口的标题：关于"), withMessage: "\(getAppInfo()) \(NSLocalizedString("about-window.message", comment: "关于窗口的消息：帮助您提取图片中的文字。"))")
    }
    
    @objc func feedbackApp() {
        let emailBody           = ""
        let emailService        =  NSSharingService.init(named: NSSharingService.Name.composeEmail)!
        emailService.recipients = ["5km@smslit.cn"]
        emailService.subject    = NSLocalizedString("feedback-email.subject", comment: "反馈邮件的标题：textGO 反馈")
        
        if emailService.canPerform(withItems: [emailBody]) {
            emailService.perform(withItems: [emailBody])
        } else {
            tipInfo(withTitle: NSLocalizedString("feedback-warning-window.title", comment: "反馈出错窗口的标题：问题反馈"), withMessage: NSLocalizedString("feedback-warning-window.message", comment: "反馈出错窗口的消息：您有什么问题向 5km@smslit.cn 发送邮件反馈即可！感谢您的支持！"))
        }
    }
    
    @objc func howToUse() {
        NSWorkspace.shared.open(URL(string: "https://app.smslit.cn/textgo/")!)
    }
    
    @objc func checkUpdate() {
        TextGoUpdater.share.check() {}
    }
    
    private func ocrCallBack(result: String?, error: String?) {
        if let error = error {
            print(error)
            return
        }
        
        if let result = result {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(result, forType: .string)
        }
    }
    
}

extension AppDelegate: NSWindowDelegate, NSDraggingDestination {
    
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.isImageFile {
            if let button = statusItem.button {
                button.image = NSImage(named: "uploadIcon")
            }
            return .copy
        }
        return .generic
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if sender.isImageFile {
            let imgurl = sender.draggedFileURL!.absoluteURL
            let imgData = NSData(contentsOf: imgurl!)
            self.ocrImage = NSImage(data: imgData! as Data)
            
            if let service = settings?.service {
                switch service {
                case OCRService.baidu:
                    BaiduAI.share.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
                case OCRService.youtu:
                    YoutuOCR.shared.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
                }
            } else {
                BaiduAI.share.ocr(imgData! as NSData, callback: self.ocrCallBack(result:error:))
            }

            return true
        }
        return false
    }
    
    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    func draggingExited(_ sender: NSDraggingInfo?) {
        if let button = statusItem.button {
            button.image = NSImage(named: "statusIcon")
        }
    }
    
    func draggingEnded(_ sender: NSDraggingInfo) {
        if let button = statusItem.button {
            button.image = NSImage(named: "statusIcon")
        }
    }

}
