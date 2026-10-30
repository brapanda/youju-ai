# 悠居 Youju · 第一版界面

独立 Flutter UI 工程与一份无需 Flutter 的浏览器交互设计稿。以旧版绿色为基调，使用悬浮胶囊底栏，支持浅色／深色。当前仅开发首页、地图／列表、简洁房源详情；AI、账号及完整个人服务均未接入。

## 最快看设计：不需要安装 Flutter

下载并解压整个项目。在项目根目录运行：

```sh
python3 -m http.server 8080
```

Windows 可使用 `py -m http.server 8080`。然后在自己电脑浏览器访问 `http://localhost:8080/design/`。这里的地址仅是本机操作说明，不是云端预览链接。

也可直接打开 `design/index.html`，但浏览器对本地文件／本地存储的限制可能影响主题和收藏保存，推荐本地 HTTP 服务。

浏览器设计稿是独立 HTML/CSS/JS 交互原型，用于评审视觉方向，**不是 Flutter 编译产物**，与 Flutter 页面的部分排版有所不同。

可测试：浅色／深色切换、五个导航入口、出售／出租、地址搜索、物业类型／卧室／价格筛选、空结果、地图标记与卡片联动、地图／列表切换、收藏、照片翻页和房源详情。浏览器收藏保存在当前浏览器；Flutter 收藏目前仅保存在当前会话。

## VS Code 运行 Flutter

1. 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)，将 `flutter/bin` 加到 PATH。工程参考稳定版 **3.47.9**；Mapbox 包至少需要 Flutter 3.38.1 / Dart 3.10。运行 `flutter doctor` 并按目标平台修复报告。
2. 在 VS Code 打开本项目根目录，安装推荐的 Flutter、Dart 扩展。
3. **首次使用需要生成平台工程**（当前交付未包含生成的 Android/iOS/Web runner）：

macOS / Linux：

```sh
bash tool/bootstrap.sh
```

Windows PowerShell：

```powershell
.\tool\bootstrap.ps1
```

如果系统策略不允许运行脚本，或不想运行脚本，可以在 VS Code 终端逐条执行：

```sh
flutter create --no-pub --platforms=android,ios,web --org ca.youju --project-name youju_ai .
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

不要给 `flutter create` 添加 `--overwrite`，以免覆盖已编写的文件。工程未来发布前需要确定正式 bundle ID 与签名。

4. VS Code 左侧「运行和调试」选择 `Youju · Chrome（演示）`，按 F5。Android 则先在 Android Studio 安装 SDK、启动模拟器，再在 VS Code 选择设备和 `Youju · 当前设备（演示）`。
5. iOS 必须使用 Mac/Xcode；完成 Flutter 与插件所需平台配置、签名及依赖安装后选择模拟器。Mapbox 最低 iOS 14；所选 Flutter 的生成模板为 iOS 15，应保留较高要求。Android 同样保留 Flutter 生成的最低 SDK。当前未验证 Android/iOS 构建。

### 接入真实 Mapbox

无 Token 时使用明确标注的离线示意地图；并不展示真实位置。

```sh
flutter run -d chrome --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_PUBLIC_MAPBOX_TOKEN
```

`MAPBOX_ACCESS_TOKEN` 只能使用允许放在客户端的公开 Mapbox Token；不要填 secret token 或 AMPRE 密钥。`--dart-define` 会编入客户端，不是秘密存储。正式发布请设置适当权限与 Web URL 限制。

配置后使用官方 `mapbox_maps_flutter` 3.34.1 的跨端地图、GeoJSON 点、点击交互和当前范围筛选。真实 Mapbox 网络、Token、原生 SDK 平台要求需另行验证。当前尚未实现服务端聚合、真实定位、卫星图和真实房源同步；数据始终是六套演示样例。

云环境需允许 Flutter SDK 下载域名 `storage.googleapis.com`；该域名已加入配置草稿，但草稿保存不等于运行时网络已更新。在线 Mapbox 还需要对应样式／瓦片域名访问。

## 数据和素材说明

- 地址、价格、位置、面积、交易状态是合成演示数据，不是可交易房源，不应据此判断真实物业。
- 图片从用户提供的旧 App 视频裁切，仅用于本次内部设计参考；不保证与样例地址或彼此属于同一物业。公开发布前替换为有许可且正确关联的图片。
- 本地 Noto Sans SC 字体许可证在 `assets/fonts/OFL.txt`。
- 未连接 AMPRE、后端、数据库、AI、登录、学校或新闻服务。
- 旧 MySQL 和旧 App 均未修改。

## 工程结构

```text
lib/main.dart                  应用状态、主题、导航
lib/core/catalog.dart          样例数据与筛选
lib/core/theme.dart            浅色／深色主题
lib/ui.dart                    首页、卡片、详情、筛选及基础入口
lib/features/map/property_map.dart  Mapbox 与离线示意地图
design/                        可交互浏览器设计稿
test/                          Flutter 单元与界面测试
docs/                          设计说明、验证结果和截图
```

## 当前验证边界

当前云端 Flutter/Dart SDK 下载被网络策略阻止，**尚未运行 `flutter pub get`、`flutter analyze`、`flutter test`、Flutter Web 编译或 Android/iOS 编译**。Dart 语法解析和 Mapbox API 源码核对不等于编译通过。浏览器设计稿另有实际交互验证，详见 `docs/VALIDATION.md`。
