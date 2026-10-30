# 在模拟器或手机测试 Youju App

`design/index.html` 是独立网页设计稿。真正的 Flutter 应用入口是 `lib/main.dart`。Live Server、Chrome 和 `flutter run -d chrome` 都不是原生 App 测试。

当前仓库尚未提供 APK、IPA 或 TestFlight 安装包。Flutter 源码尚未完成依赖安装、类型检查、Flutter 测试或原生构建验证，以下是首次在本机初始化和运行的步骤，不能视为已验证可编译。

## 所有平台先做

安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)，将 `flutter/bin` 加入 PATH，并在 VS Code 安装 Flutter、Dart 扩展。工程参考版本为 `.flutter-version` 中的 3.47.9。

克隆界面分支，或解压该分支的 ZIP 后，在包含 `pubspec.yaml` 的目录打开终端：

```sh
git clone -b codex/youju-ui-preview https://github.com/brapanda/youju-ai.git
cd youju-ai
flutter --version
flutter doctor -v
flutter create --no-pub --platforms=android,ios,web --org ca.youju --project-name youju_ai .
dart tool/configure_android.dart
flutter pub get
flutter analyze
flutter test
```

已下载 ZIP 的用户从 `flutter --version` 开始，不需要再次克隆。不要添加 `--overwrite`。上述 `create` 命令只为此新项目补充缺失的平台工程；不要在旧 Swift 项目目录执行。

解决当前目标平台对应的 doctor 报告后再运行。仅测试 Android 不需要为 Xcode 报告阻塞；仅测试 iOS 不需要先装 Android SDK。

## Android：Windows、Mac、Linux 都可以

1. 安装 Android Studio，通过 SDK Manager 安装 Flutter doctor 所需 SDK、Command-line Tools 及构建组件。优先使用 Android Studio 附带并被 Flutter 检测到的 JDK。
2. 阅读并接受 Android SDK 许可：

```sh
flutter doctor --android-licenses
```

3. Android Studio → Device Manager → 创建并启动一个 Android 模拟器。或者把 Android 手机打开开发者选项及 USB 调试，用 USB 连接电脑，并在手机确认调试授权；部分 Windows 手机需要厂商 USB 驱动。
4. 检查实际设备列表：

```sh
flutter devices
```

5. 在 VS Code 底部设备选择器选择 Android 设备，运行配置选择 `Youju · Android/iOS App（先选设备）`，按 F5。终端方式则用上一步显示的真实 ID 替换下面的示例：

```sh
flutter run -d emulator-5554
```

不要把示例 `emulator-5554` 当作你电脑的固定 ID；真机 ID 通常不同。

首次编译需要下载 Flutter 引擎、Gradle、Android 和 Mapbox 原生依赖，可能明显慢于以后启动。VS Code 提供编辑和调试，不会代替这些 SDK。

### 生成 Android 测试安装包

在本机先成功运行并完成检查，再执行：

```sh
flutter build apk --debug
```

输出通常为 `build/app/outputs/flutter-apk/app-debug.apk`。这是调试安装包，可以安装到 Android 测试手机，不是可直接提交商店的正式签名包。也可在连接手机后使用 `flutter install --debug -d YOUR_DEVICE_ID`。

## iOS：需要 Mac 和 Xcode

1. 安装并启动 Xcode，完成首次组件安装，安装需要的 iOS Simulator 运行时，并按 Flutter doctor 提示配置 Xcode 工具链与依赖管理。
2. 在 Xcode → Open Developer Tool → Simulator 启动模拟器。Mac 终端也可执行：

```sh
open -a Simulator
flutter devices
```

3. 在 VS Code 选择该 iPhone 模拟器和 `Youju · Android/iOS App（先选设备）`，按 F5。或执行 `flutter run -d YOUR_SIMULATOR_ID`，替换为 `flutter devices` 列出的 ID。
4. 模拟器通常不需要付费开发者账号或分发签名。真机则需要 Developer Mode、Xcode 中的 Team 和有效签名／Provisioning 配置，必要时使用唯一的 Bundle ID；个人 Team 有使用限制。
5. Flutter 生成工程使用哪个依赖管理方案，就按其 doctor／构建提示配置；不要为排错盲目强制切换 CocoaPods 与 Swift Package Manager。

Mapbox 包最低要求 iOS 14，但所选 Flutter 版本生成模板是 iOS 15，请保留 Flutter 的较高默认部署目标。Android 也保留 Flutter 的较高默认 SDK；不要为了满足 Mapbox 的较低底线而降级。

## Windows + iPhone

Windows 可以编辑 Flutter 源码，不能本地编译、签名或运行 iOS 模拟器。需要 Mac，或已经配置 macOS 构建、签名与分发的云服务。通过 TestFlight 测试通常需要 Apple Developer Program 和 App Store Connect 配置；当前项目尚未配置这些，也没有可用 TestFlight 邀请。

## 先测试什么

- 首页滚动、搜索与筛选空结果。
- 绿色浅色／深色主题。
- 悬浮底栏、安全区、键盘和返回行为。
- 地图示意选点、地图／列表、底部房源预览。
- 房源图片翻页、全屏图片、收藏和取消收藏。

无 Token 可走离线示意地图界面，但因为工程包含 Mapbox 插件，首次构建仍需要下载其原生依赖。实际 Mapbox 公共样式需公开 access token；当前使用的发布版 SDK 不要求额外的 secret download token。不要把 AMPRE 或其他服务密钥放入 Flutter 客户端。

Flutter 的本次会话收藏在重启后会清空；AI、账号、AMPRE、数据库及真实定位尚未接入。网页设计稿与 Flutter 页面的部分排版不同，网页截图不代表 App 实测结果。

## Mapbox 构建报 Could not find method kotlin()

Flutter 3.47.9 生成的 Android 工程使用 AGP 9，但默认设置 `android.builtInKotlin=false`。Mapbox 3.34.1 在 AGP 9 下跳过传统 Kotlin 插件，需要开启内置 Kotlin，否则其 `kotlin {}` 配置找不到对应扩展。

在当前生成模板下，只需编辑 **项目目录内**的 `android/gradle.properties`：

```properties
android.builtInKotlin=true
android.newDsl=false
```

把原有 `android.builtInKotlin=false` 改成 `true`，不要额外添加矛盾的重复项，其他属性保留。`dart tool/configure_android.dart` 自动完成此项，并拒绝直接迁移显式应用旧 Kotlin 插件的自定义工程。bootstrap 已包含此步骤。

若 `android/app/build.gradle.kts` 的 `plugins` 中显式应用了 `id("org.jetbrains.kotlin.android")` 或 `id("kotlin-android")`，需要先审查并移除该旧插件应用，再启用内置 Kotlin。`settings.gradle.kts` 中仅声明 `apply false` 的版本项可以保留。

修改后在项目根目录重试：

```sh
flutter run -d emulator-5554
```

这里的设备 ID 来自当前测试机输出；其他机器以 `flutter devices` 为准。不需要修改 Pub Cache 内的 Mapbox 源码，也无需因本错误降级 Gradle。这是依据官方源码确定的配置修正；完整 Android 构建仍需在有 SDK 的机器上验证。
