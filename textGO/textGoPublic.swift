//
//  public.swift
//  timeGO
//
//  Created by 5km on 2019/1/7.
//  Copyright © 2019 5km. All rights reserved.
//
import Cocoa

func getAppInfo() -> String {
    let infoDic = Bundle.main.infoDictionary
    let appNameStr = NSLocalizedString("app-info-name", comment: "app display name: Text Go")
    let versionStr = infoDic?["CFBundleShortVersionString"] as! String
    return appNameStr + " v" + versionStr
}

func tipInfo(withTitle: String, withMessage: String) {
    let alert = NSAlert()
    alert.messageText = withTitle
    alert.informativeText = withMessage
    alert.addButton(withTitle: NSLocalizedString("tip-info-button.titile", comment: "提示窗口确定按钮的标题：确定"))
    alert.window.titlebarAppearsTransparent = true
    alert.runModal()
}

func tipInfo(withTitle title: String, withMessage message: String, oKButtonTitle: String, cancelButtonTitle: String, okHandler:(()-> Void)) {
    let alert = NSAlert()
    alert.alertStyle = NSAlert.Style.informational
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: oKButtonTitle)
    alert.addButton(withTitle: cancelButtonTitle)
    alert.window.titlebarAppearsTransparent = true
    if alert.runModal() == .alertFirstButtonReturn {
        okHandler()
    }
}

// NSTextField 支持快捷键
extension NSTextField {
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.isDisjoint(with: .command) {
            return super.performKeyEquivalent(with: event)
        }
       
        switch event.charactersIgnoringModifiers {
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: self.window?.firstResponder, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: self.window?.firstResponder, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: self.window?.firstResponder, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: self.window?.firstResponder, from: self)
        case "z":
            self.window?.firstResponder?.undoManager?.undo()
            return true
        case "Z":
            self.window?.firstResponder?.undoManager?.redo()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

// 垂直居中
class VATextFieldCell: NSTextFieldCell {
    
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var titleFrame = super.titleRect(forBounds: rect)
        let titleSize = self.attributedStringValue.size()
        var lineCount = CGFloat(1)
        if !usesSingleLineMode {
            lineCount = CGFloat(Int(titleSize.width / rect.size.width) + 1)
        } else {
            titleFrame.size.height = titleSize.height
        }
        // 自适应水平居中
        if titleFrame.width - titleSize.width > 22 {
            titleFrame.origin.x = rect.origin.x + (rect.size.width - titleSize.width) / 2.0
        }
        // 垂直居中
        titleFrame.origin.y = rect.origin.y + (rect.size.height - titleSize.height * lineCount) / 2.0
        return titleFrame
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let titleRect = self.titleRect(forBounds: cellFrame)
        self.attributedStringValue.draw(in: titleRect)
    }
}
