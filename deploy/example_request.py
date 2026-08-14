# -*- coding: utf-8 -*-
"""
客户端请求测试脚本（作业三(二)）
参照 yolov5/utils/flask_rest_api/example_request.py
用法：先启动 restapi.py，再运行本脚本
"""
import pprint

import requests

DETECTION_URL = "http://localhost:5000/v1/object-detection/helmet"
IMAGE = r"D:\智能制造\helmet_dataset\images\val\hard_hat_workers0.jpg"

# 读取测试图片
with open(IMAGE, "rb") as f:
    image_data = f.read()

# 发送请求（文件名用于服务端扩展名校验）
response = requests.post(DETECTION_URL, files={"image": ("test.jpg", image_data, "image/jpeg")}).json()

pprint.pprint(response)
print("\n检测到 %d 个目标" % len(response))
