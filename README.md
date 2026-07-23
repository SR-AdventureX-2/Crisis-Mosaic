# Crisis Mosaic

灾害现场信息协同 Flutter 原型，包含居民上报、指挥态势、定向问答、冲突研判和 AI 辅助功能。

## 运行多模态冲突分析演示

先启动本地演示 API：

```powershell
python tool/mock_ai_backend.py
```

再启动 Flutter Web，并将冲突分析指向该 API：

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 52123 `
  --no-web-resources-cdn `
  --dart-define=CRISIS_MOSAIC_API_BASE_URL=http://127.0.0.1:52125
```

也可以使用已配置好的启动脚本：

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_web.ps1
```

`--no-web-resources-cdn` 会把 CanvasKit、WASM 和 Web 字体改为本地资源，避免因 `www.gstatic.com` 或 `fonts.gstatic.com` 无法访问而白屏。

生产构建同样需要禁用外部 Web 资源 CDN：

```powershell
flutter build web --no-web-resources-cdn
```

未设置 `CRISIS_MOSAIC_API_BASE_URL` 时，应用会使用透明标注的本地多模态演示结果。生产环境应把该变量设置为真实后端地址，并通过安全会话提供 `CRISIS_MOSAIC_API_TOKEN`，不要把密钥写入仓库。

后端需求和接口契约见 `docs/backend_requirements.md`。

## 高德地图与定位

首页态势地图已替换为基于高德地图 SDK 的 Flutter 地图，并使用高德定位插件获取当前位置。为了避免泄露密钥，项目不会保存高德 Key，请通过运行参数注入。

1. 在[高德开放平台](https://console.amap.com/dev/key/app)分别创建 Android/iOS Key。
2. Android Key 绑定包名 `com.example.crisismosaic` 和对应签名 SHA1；iOS Key 绑定 Bundle ID `com.example.crisismosaic`。
3. 连接 Android 手机或模拟器后运行：

```powershell
flutter run -d <device-id> `
  --dart-define=AMAP_ANDROID_KEY=<android-key> `
  --dart-define=CRISIS_MOSAIC_API_BASE_URL=http://127.0.0.1:52125
```

iOS 使用相同方式传入 `--dart-define=AMAP_IOS_KEY=<ios-key>`。首次点击“启用地图定位”时，应用会展示高德地图与定位隐私说明；同意后才初始化 SDK 并申请前台定位权限。

当前高德地图 SDK Flutter 插件只支持 Android 和 iOS。Flutter Web/Windows/macOS/Linux 会显示兼容提示，不再绘制原来的模拟地图。
