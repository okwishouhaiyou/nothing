from pynput import mouse
import tkinter as tk
from threading import Thread
import queue
import pyautogui
from Foundation import NSString
from AppKit import NSWorkspace,NSPasteboard, NSStringPboardType
from ApplicationServices import (
    AXUIElementCreateApplication,
    AXUIElementCopyAttributeValue,
    kAXFocusedUIElementAttribute,
)

class DragListener:
    def __init__(self):
        self.status_label = None
        self.drag_threshold = 10  # 像素阈值
        self.dragging = False
        self.start_x = 0
        self.start_y = 0
        self.queue = queue.Queue()
        self.root = tk.Tk()
        self.root.title("牛子小能手")
        self.has_dragged = False  # 新增：标记是否发生拖动
        self.root.withdraw()  # 隐藏主窗口
        self.tooltip = None  # 提示窗口

        # 设置 pyautogui 的安全暂停时间
        pyautogui.PAUSE = 0.5

    def on_click(self, x, y, button, pressed):
        if button == mouse.Button.left:
            if pressed:
                self.has_dragged = False
                self.dragging = True
                self.start_x = x
                self.start_y = y
            else:
                self.dragging = False
                self.queue.put((x, y))  # 将坐标放入队列
                if self.has_dragged:
                    pid = getCruntPid()
                    mouse_x, mouse_y = pyautogui.position()
                    self._show_button(mouse_x, mouse_y,pid)

    def on_move(self, x, y):
        if self.dragging and not self.has_dragged:
            distance = ((x - self.start_x) ** 2 + (y - self.start_y) ** 2) ** 0.5
            if distance > self.drag_threshold:
                self.has_dragged = True

    def start_listening(self):
        # 启动鼠标监听线程
        listener_thread = Thread(target=self._listen_mouse)
        listener_thread.daemon = True
        listener_thread.start()
        # 在主线程处理 Tkinter 事件
        self.root.mainloop()

    def _listen_mouse(self):
        with mouse.Listener(on_click=self.on_click, on_move=self.on_move) as listener:
            listener.join()

    def _on_action_button_click_copy(self, top_window,pid):
        selectTex =get_select_text_bypid(pid)
        if selectTex ==None:
            selectTex ="something wrong"
        # 获取通用粘贴板
        pasteboard = NSPasteboard.generalPasteboard()
        # 清空当前内容
        pasteboard.clearContents()
        # 设置文本内容
        ns_string = NSString.stringWithString_(selectTex)
        success = pasteboard.setString_forType_(ns_string, NSStringPboardType)
        self.has_dragged = False  # 重置拖动状态标记
        top_window.destroy()  # 销毁按钮窗口

    def _show_button(self, x, y,pid):
        top = tk.Toplevel(self.root)
        top.geometry(f"+{x}+{y}")  # 定位到鼠标释放位置

        # 创建按钮容器（水平排列两个按钮）
        button_frame = tk.Frame(top)
        button_frame.pack(padx=6, pady=5)

        # 功能按钮（原"点击我"按钮）
        action_btn = tk.Button(
            button_frame,
            text="复制",
            command=lambda: self._on_action_button_click_copy(top,pid),
        )
        action_btn.pack(side="left", padx=2)

        # 关闭按钮（新增功能）
        close_btn = tk.Button(
            button_frame,
            text="删除",
            command=lambda :self._on_action_button_click_copy(top),
            bg="#ff9999",  # 红色背景更显眼
            activebackground="#ff6666"
        )
        close_btn.pack(side="left", padx=2)


        # 关闭按钮（新增功能）
        cut_btn = tk.Button(
            button_frame,
            text="剪切",
            command=lambda :self._on_action_button_click_copy(top),
            bg="#ff9999",  # 红色背景更显眼
            activebackground="#ff6666"
        )
        cut_btn.pack(side="left", padx=2)

        # 窗口样式优化
        top.attributes("-topmost", True)  # 确保窗口在最前
        top.resizable(False, False)  # 禁止调整大小



def get_select_text_bypid(pid):
    # 创建 AXUIElementRef 对象
    app_ref = AXUIElementCreateApplication(pid)

    # 获取当前聚焦的 UI 元素
    result = AXUIElementCopyAttributeValue(app_ref, kAXFocusedUIElementAttribute, None)

    # 解包并调整返回值
    first, second = result
    if isinstance(first, int):
        error, focused_element = first, second
    elif isinstance(second, int):
        focused_element, error = first, second
    else:
        print("无法解析返回值")
        exit(1)
    print(focused_element)
    # 从聚焦元素中获取选中文本 (AXSelectedText)
    text_result = AXUIElementCopyAttributeValue(focused_element, "AXSelectedText", None)

    text_value, text_error = text_result
    return text_error



def getCruntPid():
    # 获取当前活动应用程序的 PID
    try:
        active_app = NSWorkspace.sharedWorkspace().activeApplication()
        if not active_app:
            print("无法获取当前活动应用程序")
            exit(1)
        pid = active_app['NSApplicationProcessIdentifier']
        app_name = active_app['NSApplicationName']
        print(app_name)
    except Exception as e:
        print(f"获取活动应用程序时出错: {e}")
        exit(1)

    return pid
if __name__ == "__main__":
    listener = DragListener()
    listener.start_listening()