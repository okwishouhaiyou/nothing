import Cocoa
import Foundation
import ApplicationServices


// 自定义弹窗窗口
class PopClipStyleWindow: NSWindow {
    private var pid: Int32 = 0
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 100, height: 40),
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let contentView = PopClipStyleView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        self.contentView = contentView
    }
    
    func showAtLocation(_ point: NSPoint,pid: Int32) {
        let windowFrame = NSRect(x: point.x - 100, y: point.y + 10, width: 80, height: 40)
        self.setFrame(windowFrame, display: true)
        self.orderFrontRegardless()
        // 将 pid 传递给 contentView
        if let contentView = self.contentView as? PopClipStyleView {
            contentView.setPid(pid)
        }
        // 2秒后自动隐藏弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.orderOut(nil)
        }
    }
}

// 弹窗内容视图
class PopClipStyleView: NSView {
    private var pid: Int32 = 0
    // 添加方法来设置 pid
    func setPid(_ pid: Int32) {
        self.pid = pid
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        self.layer?.cornerRadius = 8
        
        let copyButton = NSButton(title: "复制", target: self, action: #selector(copyAction))
        copyButton.frame = NSRect(x: 10, y: 5, width: 60, height: 30)
        copyButton.bezelStyle = .rounded
        
//        let searchButton = NSButton(title: "搜索", target: self, action: #selector(searchAction))
//        searchButton.frame = NSRect(x: 80, y: 5, width: 60, height: 30)
//        searchButton.bezelStyle = .rounded
        
        self.addSubview(copyButton)
//        self.addSubview(searchButton)
    }
    
    @objc func copyAction() {
        self.window?.orderOut(nil)
        if let result = getSelectedTextByPID(self.pid) {
            writeToClipboard(result)
        } else {
            print("获取失败")
        }
        print("点击了复制")
    }
    
//    @objc func searchAction() {
//        print("点击了搜索")
//    }
}
let pasteboard = NSPasteboard.general

// 写入文字到粘贴板
func writeToClipboard(_ text: String) {
    // 清空粘贴板
    pasteboard.clearContents()
    // 写入字符串
    let success = pasteboard.setString(text, forType: .string)
}


func getSelectedTextByPID(_ pid: pid_t) -> String? {
    // 通过 PID 获取运行中的应用
    guard let app = NSRunningApplication(processIdentifier: pid) else {
        return "无法找到指定 PID 的应用"
    }
    
    // 创建应用的 Accessibility 元素
    let axApp = AXUIElementCreateApplication(pid)
    
    // 获取当前焦点元素
    var focusedElement: AnyObject?
    let focusedResult = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
    
    if focusedResult != .success || focusedElement == nil {
        return "无法获取焦点元素"
    }
    
    // 从焦点元素中获取选中文字
    var selectedText: AnyObject?
    let textResult = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
    
    if textResult != .success || selectedText == nil {
        return "无法获取选中文字"
    }
    
    // 将结果转换为字符串
    if let text = selectedText as? String {
        return text.isEmpty ? "未选中任何文字" : text
    }
    
    return "未选中任何文字"
}

// 主程序
func main() {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    
    let popClipWindow = PopClipStyleWindow()
    
    // 记录鼠标按下时的初始位置
    var startPoint: NSPoint?
    
    // 监听鼠标按下事件
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
        startPoint = NSEvent.mouseLocation
    }
    
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
            // 检查点击次数
            if event.clickCount == 2 { // 双击
                let point = NSEvent.mouseLocation
                // 获取当前进程的 PID
                if let frontApp = NSWorkspace.shared.frontmostApplication {
                    let currentPID = frontApp.processIdentifier
                    popClipWindow.showAtLocation(point,pid: currentPID)
                }
            } else if event.clickCount == 1 { // 单击
                print("鼠标单击位置: \(NSEvent.mouseLocation)")
                startPoint = NSEvent.mouseLocation
            }
        }
    
    
    // 监听鼠标拖动事件（可选，仅用于调试）
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
        let currentPoint = NSEvent.mouseLocation
    }
    
    // 监听鼠标释放事件
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { event in
        guard let start = startPoint else { return }
        let endPoint = NSEvent.mouseLocation
        // 计算位移
        let deltaX = abs(endPoint.x - start.x)
        let deltaY = abs(endPoint.y - start.y)
        let dragThreshold: CGFloat = 8.0 // 设置拖动阈值（像素）

        
        // 如果位移超过阈值，认为是拖动，显示弹窗
        if deltaX > dragThreshold || deltaY > dragThreshold {
            // 获取当前进程的 PID
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                let currentPID = frontApp.processIdentifier
                popClipWindow.showAtLocation(endPoint,pid: currentPID)
            }
        } else {
            print("仅为点击，未显示弹窗")
        }
        
        // 重置初始位置
        startPoint = nil
    }
    
    // 运行事件循环
    app.run()
}

// 执行主程序
main()
