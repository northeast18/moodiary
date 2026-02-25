<picture>
  <source media="(prefers-color-scheme: dark)" srcset="res/banner/dark_zh.svg">
  <source media="(prefers-color-scheme: light)" srcset="res/banner/light_zh.svg">
  <img alt="The preview for moodiary." src="res/banner/light_zh.svg">
</picture>
<p align="center">简体中文</p>

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41.0-blue?style=for-the-badge">
  <img src="https://img.shields.io/github/repo-size/northeast18/moodiary?style=for-the-badge&color=ff7070">
  <img src="https://img.shields.io/github/stars/northeast18/moodiary?style=for-the-badge&color=965f8a">
  <img src="https://img.shields.io/github/v/release/northeast18/moodiary?style=for-the-badge&color=4f5e7f">
  <img src="https://img.shields.io/github/license/northeast18/moodiary?style=for-the-badge&color=4ac6b7">
</div>

> 本项目基于 [ZhuJHua/moodiary](https://github.com/ZhuJHua/moodiary) 进行维护和修复。原作者项目已停止更新很长时间，本 fork 版本主要修复了使用中发现的 bug，并实现了一些新功能。

## 🛠️ 本版本修复与新增内容

### Bug 修复

- **修复 WebDAV 同步加密上传功能**：修复webdav加密同步功能中只加密文字，不加密照片、视频等富文本的bug，加密同步功能可以正常工作
- **修复日记数据兼容性**：修复了旧版日记数据缺少 `show` 字段导致的加载失败问题
- **修复 Rust 库打包问题**：修复了 Rust 动态库未正确打包到 APK 的问题
- **移除了日记内容封面显示大图的问题**：移除了在日记详情页面使用日记里面图片当做封面图的问题，界面更简洁美观
- **增强智能助手和多AI提供商支持**：智能助手支持常见各类大模型厂商，提供自定义OpenAI兼容格式自定义支持；
- **分析统计功能完善**：支持调用大模型进行日记分析统计功能

### 依赖更新

- **flutter_rust_bridge**: 2.9.0 → 2.11.1
- **Flutter SDK**: 更新至 3.41.0

## 🔧 主要技术栈

- [Flutter](https://github.com/flutter/flutter)（跨平台 UI 框架）
- [Isar](https://github.com/isar/isar)（高性能本地数据库）
- [GetX](https://github.com/jonataslaw/getx)（状态管理框架）
- [flutter_rust_bridge](https://github.com/Deskhun/flutter_rust_bridge)（Rust FFI 桥接）
- [Rust](https://www.rust-lang.org/)（加密等高性能本地处理）

## 📸 应用截图

> 应用持续更新中，新版本界面可能稍有变化

### 移动端

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="res/screenshot/mobile_dark_zh.webp">
  <source media="(prefers-color-scheme: light)" srcset="res/screenshot/mobile_light_zh.webp">
  <img alt="The mobile screenshot for moodiary." src="res/screenshot/mobile_light_zh.webp">
</picture>

### 桌面端

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="res/screenshot/desktop_dark_zh.webp">
  <source media="(prefers-color-scheme: light)" srcset="res/screenshot/desktop_light_zh.webp">
  <img alt="The desktop screenshot for moodiary." src="res/screenshot/desktop_light_zh.webp">
</picture>

## 🚀 安装指南

### 直接安装

通过下载 Release 中已编译好的安装包来使用，如果没有你所需要的平台，请使用手动编译。

### 手动编译

#### 环境要求

- Flutter SDK (>= 3.41.0 Stable)
- Dart (>= 3.7.0)
- Rust 工具链（Nightly）
- Clang/LLVM
- 兼容的 IDE（如 Android Studio、Visual Studio Code）

#### 安装步骤

1. **克隆仓库**：

```bash
git clone https://github.com/northeast18/moodiary.git
cd moodiary
```

2. **安装依赖**：

```bash
flutter pub get
```

3. **运行应用**：

```bash
flutter run
```

4. **打包发布**：

- Android: `flutter build apk --split-per-abi`
- iOS: `flutter build ipa`
- Windows: `flutter build windows`
- MacOS: `flutter build macos`

## 📝 更多说明

### 自然语言处理（NLP）

> 处于实验阶段

如今，越来越多的行业产品开始融入 AI 技术，这无疑极大地提升了我们的使用体验。然而，对于日记应用来说，将数据交给大型模型处理并不可接受，因为无法确定这些数据是否会被用于训练。因此，更好的方法是采用本地模型。虽然由于体积限制，本地模型的能力可能不如大型模型强大，但在一定程度上仍能为我们提供必要的帮助。

目前，源码中集成了以下任务：

#### 基于 Bert 预训练模型的 SQuAD 任务

采用了 MobileBert 来处理 SQuAD 任务，这是一个简单的机器阅读理解任务。你可以向它提出问题，它会返回你需要的答案。模型文件采用 TensorFlow Lite 所需的 `.tflite` 格式，所以你可以添加自己的模型文件到 `assets/tflite` 目录下。

感谢以下开源项目：

- [Chinese MobileBERT](https://github.com/ymcui/Chinese-MobileBERT)
- [Mobilebert](https://github.com/google-research/google-research/tree/master/mobilebert)
- [ChineseSquad](https://github.com/junzeng-pluto/ChineseSquad)

## 🤝 贡献指南

欢迎贡献！请按照以下步骤进行贡献：

1. Fork 本仓库。
2. 创建一个新分支（`git checkout -b feature-branch-name`）。
3. 提交你的修改（`git commit -am 'Add some feature'`）。
4. 推送到分支（`git push origin feature-branch-name`）。
5. 创建一个 Pull Request。

请确保你的代码遵循 [Flutter 风格指南](https://flutter.dev/docs/development/tools/formatting) 并包含适当的测试。

## 📄 许可证

此项目基于 AGPL-3.0 许可证进行许可，详情请参阅 [LICENSE](LICENSE) 文件。

## 💖 鸣谢

- 感谢原作者 [ZhuJHua](https://github.com/ZhuJHua/moodiary) 提供的优秀项目基础
- 感谢 Flutter 团队提供出色的框架
- 感谢开源社区的宝贵贡献
