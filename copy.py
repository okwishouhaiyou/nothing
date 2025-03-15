from pynput import mouse
import tkinter as tk
from threading import Thread
import queue
import pyautogui

class DragListener:

    def __init__(self):
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
                    mouse_x, mouse_y = pyautogui.position()
                    self._show_button(mouse_x, mouse_y)

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

    def _on_action_button_click(self, top_window):
        """ 操作按钮点击回调 """
        self.has_dragged = False  # 重置拖动状态标记
        top_window.destroy()  # 销毁按钮窗口

    def _show_button(self, x, y):
        top = tk.Toplevel(self.root)
        top.geometry(f"+{x}+{y}")  # 定位到鼠标释放位置

        # 创建按钮容器（水平排列两个按钮）
        button_frame = tk.Frame(top)
        button_frame.pack(padx=6, pady=5)

        # 功能按钮（原"点击我"按钮）
        action_btn = tk.Button(
            button_frame,
            text="复制",
            command=lambda: self._on_action_button_click(top),
        )
        action_btn.pack(side="left", padx=2)

        # 关闭按钮（新增功能）
        close_btn = tk.Button(
            button_frame,
            text="删除",
            command=lambda :self._on_action_button_click(top),
            bg="#ff9999",  # 红色背景更显眼
            activebackground="#ff6666"
        )
        close_btn.pack(side="left", padx=2)


        # 关闭按钮（新增功能）
        cut_btn = tk.Button(
            button_frame,
            text="剪切",
            command=lambda :self._on_action_button_click(top),
            bg="#ff9999",  # 红色背景更显眼
            activebackground="#ff6666"
        )
        cut_btn.pack(side="left", padx=2)

        # 窗口样式优化
        top.attributes("-topmost", True)  # 确保窗口在最前
        top.resizable(False, False)  # 禁止调整大小


if __name__ == "__main__":
    listener = DragListener()
    listener.start_listening()