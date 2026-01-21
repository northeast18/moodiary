#!/bin/bash
# Moodiary 环境设置脚本
# 此脚本配置 Rust 和 Flutter 所需的环境变量

# 加载 Rust 环境
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
    echo "✓ Rust environment loaded"
fi

# 添加 FVM 到 PATH
if [ -d "$HOME/.pub-cache/bin" ]; then
    export PATH="$PATH:$HOME/.pub-cache/bin"
    echo "✓ FVM added to PATH"
fi

# 配置 Android SDK
export ANDROID_HOME=$HOME/projects/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0"
echo "✓ Android SDK configured"

# 显示版本信息
echo ""
echo "当前环境版本："
echo "=============="
if command -v rustc &> /dev/null; then
    echo "Rust: $(rustc --version)"
else
    echo "✗ Rust 未安装"
fi

if command -v cargo &> /dev/null; then
    echo "Cargo: $(cargo --version)"
else
    echo "✗ Cargo 未安装"
fi

if command -v flutter &> /dev/null; then
    echo "Flutter: $(flutter --version | head -n 1)"
else
    echo "✗ Flutter 未安装"
fi

if command -v fvm &> /dev/null; then
    echo "FVM: $(fvm --version)"
else
    echo "✗ FVM 未安装"
fi

echo ""
echo "环境配置完成！"
echo "使用说明："
echo "  - 运行 'flutter pub get' 安装依赖"
echo "  - 运行 'flutter run' 启动应用"
echo "  - 运行 'cd rust && cargo build --release' 构建 Rust 组件"
