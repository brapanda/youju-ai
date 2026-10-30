# 验证记录

## 已执行

- 阅读两段参考视频并提取联系表；图片裁切来自用户素材。
- Dart 源码和测试通过 tree-sitter Dart 语法解析；这仅能验证语法树，不替代 Dart 编译、类型检查或 Flutter 测试。
- 根据 pub.dev 官方 3.34.1 源码核对 Mapbox 的跨端导出接口；使用 GeoJSON Source、CircleLayer、TapInteraction，避免 Web 不支持的 annotation manager。
- `bash -n tool/bootstrap.sh` 通过；此结果不代表安装脚本已完整运行。
- VS Code JSON 配置解析通过。
- `node --check design/preview.js` 通过。
- Playwright + Chromium 对浏览器设计稿的实际交互验证通过：主题／收藏持久化、搜索、卧室过滤空结果及清除、地图选点、图库、地图／列表、AI／个人入口。320、390、430、768、1440 宽度未见横向溢出或 JS 页面错误。

浏览器重放：先从工程根目录启动 `python3 -m http.server 8765`，另一个终端安装本机 Playwright 后运行 `node tool/preview_smoke.cjs`。可通过 `PREVIEW_URL` 和 `CHROMIUM_EXECUTABLE` 指定本机 URL／浏览器；这是内部验证操作，不是公开云端预览链接。本轮共 25 项检查通过。

## 未执行／阻塞

- Flutter SDK 源码成功获取；Dart 二进制从 `storage.googleapis.com` 下载被网络代理返回 403。
- 因此 **Flutter 依赖安装、锁文件生成、formatter、analyze、11 项 Flutter 测试、Web 构建、Android/iOS 编译均未执行**。
- 未验证真实 Mapbox Token、在线地图或移动端 SDK 生命周期。Tokenless 浏览器图为示意图。
- iOS 需要 macOS/Xcode，当前 Linux 环境无法完成。
- PowerShell bootstrap 尚未在 Windows 执行。

## 下一轮验证

在允许 SDK 下载的环境运行首次初始化，之后执行 `dart format lib test`、`flutter analyze`、`flutter test`、`flutter build web`，处理实际报告。再在 Android 模拟器／iOS 模拟器检查页面、键盘、安全区和 Mapbox，才可以声明移动端可运行。

当前截图均来自 **HTML 浏览器设计稿**，不是 Flutter 或原生 App 截图。
