// 安全帽佩戴检测 APP 主页面（HarmonyOS，ArkTS）
// 功能：相册选图 → 上传后端推理 → 显示检测框与类别
// 使用说明见：鸿蒙APP开发说明.md

import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fileIo from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BusinessError } from '@ohos.base';

// ========== 服务器地址配置 ==========
// 模拟器：10.0.2.2 指向电脑本机；真机调试请改成电脑的局域网 IP（电脑上 ipconfig 查询，如 192.168.1.100）
const SERVER = 'http://10.0.2.2:5000/v1/object-detection/helmet';

interface DetectBox {
  xmin: number;
  ymin: number;
  xmax: number;
  ymax: number;
  confidence: number;
  name: string;
}

@Entry
@Component
struct Index {
  @State imgUri: string = '';
  @State imgW: number = 0;      // 图片原始宽（px）
  @State imgH: number = 0;      // 图片原始高（px）
  @State boxes: DetectBox[] = []; // 检测结果
  @State loading: boolean = false;
  @State status: string = '请先从相册选择一张工地图片';
  @State containerW: number = 0;
  @State containerH: number = 400;

  // ---------- 相册选图 ----------
  async pickImage(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris.length > 0) {
        this.imgUri = result.photoUris[0];
        this.boxes = [];
        this.status = '图片已选择，点击"开始检测"';
        await this.getImageSize(this.imgUri);
      }
    } catch (e) {
      const err = e as BusinessError;
      this.status = '选择图片失败: ' + err.message;
    }
  }

  // ---------- 读取图片原始尺寸 ----------
  async getImageSize(uri: string): Promise<void> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const imgSource = image.createImageSource(file.fd);
      const info = await imgSource.getImageInfo();
      this.imgW = info.size.width;
      this.imgH = info.size.height;
      imgSource.release();
      fileIo.closeSync(file);
    } catch (e) {
      const err = e as BusinessError;
      console.error('getImageSize failed: ' + err.message);
    }
  }

  // ---------- 上传检测 ----------
  async detect(): Promise<void> {
    if (this.imgUri === '') {
      this.status = '请先选择图片';
      return;
    }
    this.loading = true;
    this.status = '正在上传并检测...';
    try {
      // 1. 读取图片字节
      const file = fileIo.openSync(this.imgUri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buf);
      fileIo.closeSync(file);
      const imgBytes = new Uint8Array(buf);

      // 2. 构造 multipart/form-data 报文（字段名 image，与后端 restapi.py 一致）
      const boundary = '----HarmonyBoundary' + Date.now();
      const headStr = '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="image"; filename="photo.jpg"\r\n' +
        'Content-Type: image/jpeg\r\n\r\n';
      const tailStr = '\r\n--' + boundary + '--\r\n';
      const encoder = new util.TextEncoder();
      const head = encoder.encodeInto(headStr);
      const tail = encoder.encodeInto(tailStr);
      const body = new Uint8Array(head.byteLength + imgBytes.byteLength + tail.byteLength);
      body.set(head, 0);
      body.set(imgBytes, head.byteLength);
      body.set(tail, head.byteLength + imgBytes.byteLength);

      // 3. 发送 POST 请求
      const httpRequest = http.createHttp();
      const resp = await httpRequest.request(SERVER, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'multipart/form-data; boundary=' + boundary },
        extraData: body.buffer,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 60000
      });
      httpRequest.destroy();

      // 4. 解析结果
      const data = JSON.parse(resp.result as string) as DetectBox[];
      this.boxes = data;
      const helmetCnt = data.filter((b: DetectBox) => b.name === 'helmet').length;
      const headCnt = data.filter((b: DetectBox) => b.name === 'head').length;
      this.status = '检测完成：共 ' + data.length + ' 个目标（helmet ' + helmetCnt + ' / head ' + headCnt + '）';
    } catch (e) {
      const err = e as BusinessError;
      this.status = '检测失败: ' + err.message + '（请确认电脑端后端服务已启动）';
    }
    this.loading = false;
  }

  // ---------- 坐标换算：像素 -> 显示尺寸 ----------
  calcScale(): number {
    if (this.imgW === 0 || this.imgH === 0) {
      return 0;
    }
    return Math.min(this.containerW / this.imgW, this.containerH / this.imgH);
  }

  offsetX(): number {
    return (this.containerW - this.imgW * this.calcScale()) / 2;
  }

  offsetY(): number {
    return (this.containerH - this.imgH * this.calcScale()) / 2;
  }

  // ---------- 页面 ----------
  build() {
    Column() {
      Text('安全帽佩戴检测')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 12 })

      // 图片显示区 + 检测框叠加层
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.imgUri !== '') {
          Image(this.imgUri)
            .width('100%')
            .height(this.containerH)
            .objectFit(ImageFit.Contain)
        } else {
          Column() {
            Text('👷 请选择图片')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height(this.containerH)
          .justifyContent(FlexAlign.Center)
        }

        // 检测框
        ForEach(this.boxes, (b: DetectBox, index: number) => {
          Column() {
            Text(b.name + ' ' + (b.confidence * 100).toFixed(0) + '%')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor(b.name === 'helmet' ? '#2E7D32' : '#C62828')
              .padding({ left: 3, right: 3 })
          }
          .position({
            x: b.xmin * this.calcScale() + this.offsetX(),
            y: b.ymin * this.calcScale() + this.offsetY()
          })
          .width((b.xmax - b.xmin) * this.calcScale())
          .height((b.ymax - b.ymin) * this.calcScale())
          .border({
            width: 2,
            color: b.name === 'helmet' ? '#00C853' : '#FF1744'
          })
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
        }, (b: DetectBox, index: number) => {
          return b.xmin + '_' + b.ymin + '_' + index;
        })
      }
      .width('100%')
      .height(this.containerH)
      .backgroundColor('#FFFFFF')
      .onAreaChange((oldArea: Area, newArea: Area) => {
        this.containerW = newArea.width as number;
        this.containerH = newArea.height as number;
      })

      // 按钮区
      Row({ space: 16 }) {
        Button('从相册选择')
          .onClick(() => this.pickImage())
        Button(this.loading ? '检测中...' : '开始检测')
          .enabled(!this.loading)
          .onClick(() => this.detect())
      }
      .margin({ top: 20, bottom: 12 })

      // 状态栏
      Text(this.status)
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .margin({ left: 16, right: 16 })

      Text('绿色框 = helmet（戴安全帽）  红色框 = head（未戴）')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
