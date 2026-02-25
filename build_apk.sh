#!/bin/bash
# Moodiary APK 构建脚本
# 生成按规范命名的APK文件: moodiary-{version}-{abi}-release.apk

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   Moodiary APK 构建脚本${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 获取版本号
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
echo -e "${YELLOW}版本号: ${VERSION}${NC}"
echo ""

# 清理旧的构建文件
echo -e "${YELLOW}[1/4] 清理旧的构建文件...${NC}"
flutter clean
echo ""

# 构建APK（分架构）
echo -e "${YELLOW}[2/4] 构建APK（分架构）...${NC}"
flutter build apk --release --split-per-abi
echo ""

# 重命名APK
echo -e "${YELLOW}[3/4] 重命名APK文件...${NC}"
cd android
./gradlew renameApk -q
cd ..
echo ""

# 显示构建结果
echo -e "${YELLOW}[4/4] 构建完成！${NC}"
echo ""
echo -e "${GREEN}生成的APK文件:${NC}"
ls -lh build/app/outputs/flutter-apk/moodiary-*-release.apk | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   构建成功！APK位于 build/app/outputs/flutter-apk/${NC}"
echo -e "${GREEN}======================================${NC}"
