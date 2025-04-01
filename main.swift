import Cocoa

// 自定义弹窗窗口
class PopClipStyleWindow: NSWindow {
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
    
    func showAtLocation(_ point: NSPoint) {
        let windowFrame = NSRect(x: point.x - 100, y: point.y + 10, width: 200, height: 40)
        self.setFrame(windowFrame, display: true)
        self.orderFrontRegardless()
        
        // 2秒后自动隐藏弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.orderOut(nil)
        }
    }
}

// 弹窗内容视图
class PopClipStyleView: NSView {
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
        print("点击了复制")
    }
    
//    @objc func searchAction() {
//        print("点击了搜索")
//    }
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
        print("鼠标按下 - 时间: \(Date()), 位置: x: \(startPoint!.x), y: \(startPoint!.y)")
    }
    
    // 监听鼠标拖动事件（可选，仅用于调试）
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
        let currentPoint = NSEvent.mouseLocation
        print("鼠标拖动 - 时间: \(Date()), 位置: x: \(currentPoint.x), y: \(currentPoint.y)")
    }
    
    // 监听鼠标释放事件
    NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { event in
        guard let start = startPoint else { return }
        let endPoint = NSEvent.mouseLocation
        print("鼠标释放 - 时间: \(Date()), 位置: x: \(endPoint.x), y: \(endPoint.y)")
        
        // 计算位移
        let deltaX = abs(endPoint.x - start.x)
        let deltaY = abs(endPoint.y - start.y)
        let dragThreshold: CGFloat = 8.0 // 设置拖动阈值（像素）
        
        // 如果位移超过阈值，认为是拖动，显示弹窗
        if deltaX > dragThreshold || deltaY > dragThreshold {
            print("检测到拖动，显示弹窗")
            popClipWindow.showAtLocation(endPoint)
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
