# Simple Pomodoro

一个极简番茄钟应用。界面仿照机械腕表表盘设计，不使用传统开始按钮、结束按钮或数字输入，主要通过分针完成时间选择、启动和停止。

## 当前版本

- 应用版本：`1.0.0+1`
- 包名：`com.bollks.simple_pomodoro`
- 技术栈：Flutter + Android 原生反馈通道

## 功能

- 初始状态停在 12 点方向，代表 `0` 分钟。
- 拖动分针选择计时时长，范围为 `0-60` 分钟。
- 松开分针后，如果选择时间大于 `0`，立即开始倒计时。
- 倒计时过程中，分针会随剩余时间回转。
- 运行状态下长按分针约 `700ms` 可停止并重置计时。
- 计时开始和结束时有背景明暗过渡。
- 倒计时完成时播放系统提示音，并触发加强震动反馈。

## 视觉资源

表盘主要视觉元素来自实际图片资源：

- `assets/dials/fritillaria.webp`：表盘底纹
- `assets/cases/case_01.webp`：表壳
- `assets/scale.webp`：刻度
- `assets/pointer.webp`：分针
- `assets/hat.webp`：中心轴帽

## 交互说明

1. 在空闲状态下，按住分针或中心轴附近。
2. 将分针拖到目标分钟位置。
3. 松手后开始倒计时。
4. 运行中长按分针可停止计时并回到 `0` 分钟。

应用没有独立的开始/结束按钮，也没有第二圈计时；一次计时只支持 `60` 分钟以内。

## 开发

安装依赖：

```sh
flutter pub get
```

运行测试：

```sh
flutter test
```

静态分析：

```sh
flutter analyze
```

连接设备运行：

```sh
flutter run
```

## 构建 APK

构建通用 Release APK：

```sh
flutter build apk --release
```

构建按 CPU 架构拆分的 Release APK：

```sh
flutter build apk --release --split-per-abi
```

输出位置：

```text
build/app/outputs/flutter-apk/
```

常用 APK：

- `app-arm64-v8a-release.apk`：现代 Android 手机
- `app-armeabi-v7a-release.apk`：旧 32 位 Android 设备
- `app-x86_64-release.apk`：x86_64 模拟器或设备

## 测试与验证

项目包含针对表盘几何、计时控制、背景过渡、资源渲染和完成反馈的测试。提交前建议至少运行：

```sh
flutter test
flutter analyze
flutter build apk --debug
```

涉及震动反馈的改动需要真机验证，因为模拟器和日志无法准确反映手持震感。

## License

MIT
