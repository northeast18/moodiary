#!/bin/bash
# 此脚本需要 sudo 权限来配置 Android SDK

echo "正在配置 Android SDK 许可证..."

# 创建许可证目录
sudo mkdir -p /usr/lib/android-sdk/licenses

# 复制许可证文件
sudo cp ~/.android/licenses/* /usr/lib/android-sdk/licenses/

# 设置正确的权限
sudo chown -R root:root /usr/lib/android-sdk/licenses
sudo chmod 644 /usr/lib/android-sdk/licenses/*

echo "✓ 许可证文件已复制到系统 SDK 目录"
echo ""
echo "许可证文件列表："
ls -la /usr/lib/android-sdk/licenses/
