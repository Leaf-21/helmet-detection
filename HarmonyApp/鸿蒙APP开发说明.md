# 鸿蒙安全帽检测 APP 开发说明（作业三(三)）

## 一、新建工程（DevEco Studio 中操作）

1. 打开 DevEco Studio → **Create Project** → 选 **Empty Ability** 模板；
2. Project Name: `HelmetDetect`，Language: **ArkTS**，Compatible SDK: **API 10 或以上**（新版默认）；
3. 点 Finish 等待工程同步完成（首次会下载 SDK，较慢）。

## 二、替换页面代码

把本目录的 **`Index.ets`** 内容，**全部替换**到：
```
entry/src/main/ets/pages/Index.ets
```
（原文件是模板自带的 Hello World 页面，直接覆盖即可）

> 本次版本已适配你的 SDK：`photoAccessHelper`/`fileIo` 用默认导入、`util.TextEncoder`、显式 catch 类型、避免 `scale` 方法名冲突、无 `any/unknown`。

## 三、添加网络权限

编辑 `entry/src/main/module.json5`，在 `module` 节点下加：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  }
]
```

## 四、⚠️ 运行方式（关键！）

**不要用右上角的"预览器 Previewer"**（它只做页面预览，不会安装到模拟器，模拟器里自然看不到 APP）。

正确方式：DevEco 顶部菜单 **Run → Run 'entry'**（或工具栏绿色三角 ▶），在弹出窗口里**选择模拟器设备**，等底部显示 `Launching ...` → `Install Finished` → APP 才会出现在模拟器里。构建时注意看 **Build** 面板（不是 Preview 面板）。

## 四、配置服务器地址（关键）

打开 `Index.ets` 顶部：
```typescript
const SERVER = 'http://10.0.2.2:5000/v1/object-detection/helmet';
```

| 调试方式 | SERVER 填什么 |
|---|---|
| **DevEco 模拟器** | `http://10.0.2.2:5000/v1/object-detection/helmet`（10.0.2.2 = 电脑本机，默认即可） |
| 真机 | 电脑上运行 `ipconfig` 查局域网 IP（如 192.168.1.100），改成 `http://192.168.1.100:5000/v1/object-detection/helmet`，且手机和电脑要在同一 WiFi |

## 五、运行流程（联调）

1. 电脑上双击 **`D:\智能制造\deploy\start_server.bat`** 启动后端（保持窗口开着）；
2. DevEco Studio 里启动**模拟器** → 点 Run 运行 APP；
3. APP 里点 **"从相册选择"** → 选一张工地/戴安全帽的图片（模拟器相册里需先有图，可拖图片进模拟器窗口）；
4. 点 **"开始检测"** → 等待返回 → 图片上显示绿色（helmet）/红色（head）检测框 + 置信度。

## 六、常见问题

| 现象 | 处理 |
|---|---|
| 请求超时/连接失败 | ① 后端窗口是否开着；② Windows 防火墙首次拦截 python 时点"允许访问"；③ 模拟器用 10.0.2.2、真机用电脑 IP（不是 127.0.0.1） |
| 模拟器相册没图 | 把电脑上的工地图片直接拖拽到模拟器窗口中即可导入 |
| 编译报错 | 确认工程 SDK 是 API 10+；本代码兼容 API 10/11/12 |
| 检测结果框位置不准 | 正常，坐标按 Contain 显示比例换算，长宽比接近时最准 |

## 七、加分项（可选）

相机拍照功能：作业要求"相机拍摄**或**相册访问"二选一，本版本已满足。想加拍照，可在页面加一个按钮调用 `@ohos.multimedia.camera` 的 CameraManager 流程（获取相机权限 → 创建相机输入/输出 → capture 保存到文件 → 拿 uri 复用现有上传逻辑）。
