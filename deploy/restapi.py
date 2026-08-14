# -*- coding: utf-8 -*-
"""
安全帽检测后端推理服务（作业三(一)）
参照 yolov5/utils/flask_rest_api/restapi.py 实现，
改进点：加载本地训练的自定义模型 best.pt（原示例通过 torch.hub 从 GitHub 拉取，无法用自定义权重）
启动：python restapi.py --weights <best.pt路径> [--port 5000] [--model-name helmet]
"""
import argparse
import io
import os

from flask import Flask, request
from PIL import Image
from werkzeug.exceptions import RequestEntityTooLarge

DETECTION_URL = "/v1/object-detection/<model>"
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"}
MAX_IMAGE_SIZE = 16 * 1024 * 1024  # 16 MB

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_IMAGE_SIZE
models = {}


@app.errorhandler(RequestEntityTooLarge)
def handle_large_upload(_):
    """Return a JSON error for uploads rejected by Flask before request parsing."""
    return {"error": "File too large. Maximum size is 16 MB."}, 413


@app.route(DETECTION_URL, methods=["POST"])
def predict(model):
    """接收图片并返回检测结果 JSON"""
    if not request.files.get("image"):
        return {"error": "No image file provided"}, 400
    im_file = request.files["image"]

    # 校验文件扩展名
    filename = im_file.filename or ""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    if ext not in ALLOWED_EXTENSIONS:
        return {"error": "Invalid file type. Allowed types: " + ", ".join(sorted(ALLOWED_EXTENSIONS))}, 400

    # 大小限制
    im_bytes = im_file.read(MAX_IMAGE_SIZE + 1)
    if len(im_bytes) > MAX_IMAGE_SIZE:
        return {"error": "File too large. Maximum size is 16 MB."}, 413

    # 校验图片有效性
    try:
        with Image.open(io.BytesIO(im_bytes)) as im:
            im.verify()
    except Exception:
        return {"error": "Invalid image file"}, 400
    im = Image.open(io.BytesIO(im_bytes))

    if model not in models:
        return {"error": "Model not found. Available models: " + ", ".join(sorted(models))}, 404

    # 推理（size=640；若需更快可改 320）
    results = models[model](im, size=640)
    return results.pandas().xyxy[0].to_json(orient="records")


if __name__ == "__main__":
    import torch

    parser = argparse.ArgumentParser(description="Flask API exposing local YOLOv5 model")
    parser.add_argument("--port", default=5000, type=int, help="port number")
    parser.add_argument("--weights", default=r"D:\智能制造\yolov5\runs\train\exp5\weights\best.pt",
                        help="path to trained best.pt")
    parser.add_argument("--model-name", default="helmet", help="model name in URL, i.e. /v1/object-detection/helmet")
    parser.add_argument("--conf", default=0.25, type=float, help="confidence threshold")
    opt = parser.parse_args()

    if not os.path.exists(opt.weights):
        raise FileNotFoundError("weights not found: %s" % opt.weights)

    # 加载本地自定义模型（source='local'，无需联网从 GitHub 拉取）
    print("Loading model %s from %s ..." % (opt.model_name, opt.weights))
    models[opt.model_name] = torch.hub.load(
        r"D:\智能制造\yolov5", "custom", path=opt.weights, source="local",
        force_reload=True, skip_validation=True,
    )
    models[opt.model_name].conf = opt.conf
    print("Model loaded. Serving on http://127.0.0.1:%d/v1/object-detection/%s" % (opt.port, opt.model_name))

    app.run(host="127.0.0.1", port=opt.port)
