#
import time
#
import pyautogui
import pytesseract
from PIL import Image


def cutScreen (x,y,x1,y1):
    img_path = '/Users/weishi/CANDELETE/python/SXNXCreateCodeTool/capp/picture.png'
    # # 每抓取一次屏幕需要的时间约为1s,如果图像尺寸小一些效率就会高一些
    # part of the screen
    screenshot = pyautogui.screenshot()
    width =x1 -x
    hight =y1 -y
    if hight>100:
        hight
    else:
        hight = 50
    rect = (1.9*x, 1.8*y, 10*x+width+140, 2*y+hight)
    # save to file
    cropped_screenshot = screenshot.crop(rect)
    # cropped_screenshot = screenshot.crop()
    cropped_screenshot.save(img_path)  # 保存为PNG以保持质量
    # cropped_screenshot.show()
    image = Image.open(img_path).convert('L')
    content = pytesseract.image_to_string(image, lang='chi_sim')
    return content



