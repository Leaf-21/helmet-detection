# 安全帽佩戴检测系统

基于 YOLOv5 的工地安全帽佩戴检测项目，覆盖"数据集制作 → 模型训练 → Flask 后端推理 → 鸿蒙 APP 端到端检测"完整流程。

- 检测类别（2 类）：`helmet`（戴安全帽）/ `head`（未戴安全帽的头部）
- 训练结果：YOLOv5s，mAP@0.5 = **0.93**（要求 ≥ 0.80）

---

## 一、目录结构

```
D:\智能制造\
├── yolov5\                  YOLOv5 官方仓库（训练 + 推理）
│   ├── data\helmet.yaml     数据集配置文件（类别、路径）
│   ├── runs\train\exp5\     最终训练结果
│   │   ├── weights\best.pt  训练好的模型权重（部署用）
│   │   ├── results.png      mAP 曲线
│   │   └── PR_curve.png     精确率-召回率曲线
│   └── utils\flask_rest_api\  官方 Flask 参考实现
├── deploy\                  部署目录（作业三）
│   ├── restapi.py           后端推理服务（加载本地 best.pt）
│   ├── example_request.py   接口测试脚本
│   ├── start_server.bat     一键启动后端服务
│   └── test_request.bat     一键发送测试请求
├── HarmonyApp\              鸿蒙 APP（作业三(三)）
│   ├── Index.ets            主页面代码（相册选图/上传/检测框显示）
│   └── 鸿蒙APP开发说明.md    建工程与联调步骤
├── start_labelimg.bat       启动 labelImg 标注工具
├── check_gpu.bat            验证 GPU 是否可用
├── set_mirror.bat           配置 pip 国内镜像（清华源）
├── 环境配置指南.md           环境重建详细步骤
├── 数据标注操作指南.md       自制数据标注流程
└── README.md                本文档
```

> 说明：为减小体积，本目录已移除 Python 运行环境（`python310`）、训练数据集（`helmet_dataset`）等大文件，按下文"环境重建"即可完整恢复。

---

## 二、功能与接口

### 后端推理服务（Flask）

```
POST http://127.0.0.1:5000/v1/object-detection/helmet
参数：表单字段 image（图片文件，jpg/png 等）
返回：JSON 数组，每项 {xmin, ymin, xmax, ymax, confidence, class, name}
      name: helmet 戴帽 / head 未戴帽；坐标为原图像素值
```

启动：双击 `deploy\start_server.bat`（或 `python deploy/restapi.py`），服务监听 5000 端口。

### 鸿蒙 APP

相册选图 → 上传至后端 → 返回结果在图片上叠加检测框（绿=helmet，红=head）+ 置信度。完整联调步骤见 `HarmonyApp\鸿蒙APP开发说明.md`。

---

## 三、环境重建（关键版本）

| 组件 | 版本要求 | 说明 |
|---|---|---|
| Python | 3.10.x | 可用官方 embeddable 精简版（免安装） |
| PyTorch | 2.3.1+cu121 | 必须从国内镜像下载（阿里云 pytorch-wheels），官方源国内极慢 |
| torchvision | 0.18.1+cu121 | 与 torch 配套 |
| numpy | **1.26.4（<2）** | numpy 2.x 与 torch 2.3.1 二进制不兼容，会崩溃 |
| opencv-python | **4.10.x** | 5.x 要求 numpy>=2，同样不兼容 |
| labelImg | 1.8.6 | 精简版 Python 下需配置 Qt 插件路径 |

### 重建步骤

```bash
# 1. 安装 Python 3.10（任意方式），配置 pip 清华源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 2. 安装 PyTorch GPU 版（下载 whl 后本地安装）
pip install torch-2.3.1+cu121-cp310-cp310-win_amd64.whl torchvision-0.18.1+cu121-cp310-cp310-win_amd64.whl

# 3. 安装 YOLOv5 依赖（注意 numpy/opencv 版本）
pip install -r yolov5/requirements.txt
pip install "numpy==1.26.4" "opencv-python==4.10.0.84" flask

# 4. 验证 GPU
python -c "import torch; print(torch.cuda.is_available())"   # 输出 True

# 5. 安装标注工具
pip install labelimg
```

---

## 四、训练与推理命令

```bash
# 训练（数据集需按 helmet.yaml 中的路径放置：images/train|val + labels/train|val）
cd yolov5
python train.py --img 416 --batch 16 --epochs 100 --data helmet.yaml --weights yolov5s.pt --workers 0 --cache disk --patience 30

# 单图推理
python detect.py --weights runs/train/exp5/weights/best.pt --source 图片路径 --img 416
```

训练产物：`runs\train\exp*\weights\best.pt`（最优权重）、`results.csv`（mAP 指标）、`results.png`（曲线图）。

---

## 五、数据集说明

训练数据集为工地安全帽图片（Helmet/head 两类，共 4000 张：train 3200 / val 800），来源为公开数据集转换（VOC → YOLO 格式），并进行了越界坐标规范化处理。目录结构：

```
helmet_dataset/
├── images/train|val/   图片
├── labels/train|val/   同名 txt 标注（class x_center y_center w h，归一化）
└── data.yaml           配置（位于 yolov5/data/helmet.yaml）
```

自制数据补充：按 `数据标注操作指南.md` 用 labelImg 标注后并入训练集即可。

---

## 六、常见问题

| 问题 | 解决 |
|---|---|
| 训练报 NumPy 相关崩溃 | 确认 numpy==1.26.4、opencv-python==4.10 |
| WinError 1455 页面文件太小 | 训练加 `--workers 0 --cache disk`，或调大系统虚拟内存 |
| APP 连不上后端 | 模拟器用 10.0.2.2，真机用电脑局域网 IP；确认后端已启动、防火墙放行 |
| labelImg 打不开（Qt 报错） | 设置 QT_QPA_PLATFORM_PLUGIN_PATH 指向 PyQt5\Qt5\plugins（见 start_labelimg.bat） |
