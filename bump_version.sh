#!/bin/bash
# Moodiary 版本管理脚本
# 自动递增版本号、更新 CHANGELOG、创建 Git 提交和标签

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 文件路径
PUBSPEC_FILE="pubspec.yaml"
CHANGELOG_FILE="CHANGELOG.md"

# 显示帮助信息
show_help() {
    echo -e "${CYAN}用法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${CYAN}选项:${NC}"
    echo "  hotfix    递增 hotfix 版本 (2.7.3-3 → 2.7.3-4)"
    echo "  patch     递增 patch 版本 (2.7.3 → 2.7.4)"
    echo "  minor     递增 minor 版本 (2.7.3 → 2.8.0)"
    echo "  major     递增 major 版本 (2.7.3 → 3.0.0)"
    echo "  -h, --help 显示此帮助信息"
    echo ""
    echo -e "${CYAN}示例:${NC}"
    echo "  $0              # 交互式选择"
    echo "  $0 hotfix       # 直接递增 hotfix"
    exit 0
}

# 获取当前版本号
get_current_version() {
    grep "^version:" "$PUBSPEC_FILE" | awk '{print $2}'
}

# 解析版本号
# 格式: x.y.z-hotfix+build
parse_version() {
    local version=$1

    # 提取 x.y.z 和 hotfix
    if [[ $version =~ ^([0-9]+\.[0-9]+\.[0-9]+)(-([0-9]+))?(\+([0-9]+))?$ ]]; then
        BASE_VERSION="${BASH_REMATCH[1]}"
        HOTFIX="${BASH_REMATCH[3]:-0}"
        BUILD="${BASH_REMATCH[5]:-0}"

        # 解析 base version 的各部分
        IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
    else
        echo -e "${RED}错误: 无法解析版本号 '$version'${NC}"
        exit 1
    fi
}

# 递增版本号
bump_version() {
    local type=$1

    case $type in
        hotfix)
            HOTFIX=$((HOTFIX + 1))
            BUILD=$((BUILD + 1))
            ;;
        patch)
            PATCH=$((PATCH + 1))
            HOTFIX=0
            BUILD=$((BUILD + 1))
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            HOTFIX=0
            BUILD=$((BUILD + 1))
            ;;
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            HOTFIX=0
            BUILD=$((BUILD + 1))
            ;;
        *)
            echo -e "${RED}错误: 未知的版本类型 '$type'${NC}"
            exit 1
    esac
}

# 生成新版本号
format_version() {
    if [ "$HOTFIX" -eq 0 ]; then
        echo "${MAJOR}.${MINOR}.${PATCH}+${BUILD}"
    else
        echo "${MAJOR}.${MINOR}.${PATCH}-${HOTFIX}+${BUILD}"
    fi
}

# 更新 pubspec.yaml
update_pubspec() {
    local new_version=$1
    local current=$2

    # macOS 和 Linux 兼容的 sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version: $current/version: $new_version/" "$PUBSPEC_FILE"
    else
        sed -i "s/^version: $current/version: $new_version/" "$PUBSPEC_FILE"
    fi

    echo -e "${GREEN}✓${NC} pubspec.yaml: $current → ${CYAN}$new_version${NC}"
}

# 更新 CHANGELOG.md
update_changelog() {
    local version=$1
    local today=$(date +%Y-%m-%d)

    # 提取版本显示名（去掉 build 号）
    local display_version="${version%+*}"

    # 检查 CHANGELOG 是否存在
    if [ ! -f "$CHANGELOG_FILE" ]; then
        echo -e "${YELLOW}创建 CHANGELOG.md${NC}"
        cat > "$CHANGELOG_FILE" << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

EOF
    fi

    # 生成新的版本条目到临时文件
    local tmp_file=$(mktemp)
    cat > "$tmp_file" << EOF
## [$display_version] - $today

### Added
-

### Changed
-

### Fixed
-

EOF

    # 将原内容追加到临时文件
    cat "$CHANGELOG_FILE" >> "$tmp_file"

    # 替换原文件
    mv "$tmp_file" "$CHANGELOG_FILE"

    echo -e "${GREEN}✓${NC} CHANGELOG.md: 已添加版本 $display_version 条目"
}

# Git 提交和标签
git_commit_and_tag() {
    local version=$1
    local display_version="${version%+*}"
    local tag_name="v$display_version"

    # 检查是否有 git 仓库
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}⚠${NC} 不是 Git 仓库，跳过提交和标签"
        return
    fi

    # 检查是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠${NC} 工作区有未提交的更改，建议先提交或暂存"
        local reply
        read -p "是否继续？(y/N) " reply
        reply=$(echo "$reply" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        if [[ $reply != "y" ]]; then
            exit 0
        fi
    fi

    # 提交版本变更
    echo -e "${YELLOW}创建 Git 提交...${NC}"
    git add "$PUBSPEC_FILE" "$CHANGELOG_FILE"

    local commit_msg="chore: bump version to $display_version"
    git commit -m "$commit_msg"

    echo -e "${GREEN}✓${NC} Git 提交: $commit_msg"

    # 创建标签
    echo -e "${YELLOW}创建 Git 标签...${NC}"
    local tag_msg="Release $display_version"

    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} 标签 $tag_name 已存在"
        local reply
        read -p "是否删除并重新创建？(y/N) " reply
        reply=$(echo "$reply" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        if [[ $reply == "y" ]]; then
            git tag -d "$tag_name"
            git tag -a "$tag_name" -m "$tag_msg"
            echo -e "${GREEN}✓${NC} 标签已更新: $tag_name"
        fi
    else
        git tag -a "$tag_name" -m "$tag_msg"
        echo -e "${GREEN}✓${NC} 标签已创建: $tag_name"
    fi

    echo ""
    echo -e "${YELLOW}提示: 使用 'git push --follow-tags' 推送提交和标签${NC}"
}

# 显示版本预览
show_preview() {
    local current=$1
    local new=$2
    local type=$3

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}   版本预览${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "${CYAN}当前版本:${NC} $current"
    echo -e "${CYAN}递增类型:${NC} $type"
    echo -e "${CYAN}新版本号:${NC} ${YELLOW}$new${NC}"
    echo ""
}

# 交互式菜单
interactive_menu() {
    local current_version=$1

    echo "" >&2
    echo -e "${GREEN}======================================${NC}" >&2
    echo -e "${GREEN}   Moodiary 版本管理${NC}" >&2
    echo -e "${GREEN}======================================${NC}" >&2
    echo "" >&2
    echo -e "${CYAN}当前版本:${NC} $current_version" >&2
    echo "" >&2

    parse_version "$current_version"

    echo -e "${YELLOW}选择要递增的版本部分:${NC}" >&2
    echo "" >&2
    echo "  ${GREEN}[H]${NC} hotfix  ${CYAN}(2.7.3-$HOTFIX → 2.7.3-$((HOTFIX + 1)))${NC} ${YELLOW}← 默认${NC}" >&2
    echo "  ${GREEN}[P]${NC} patch   ${CYAN}($PATCH → $((PATCH + 1)))${NC}" >&2
    echo "  ${GREEN}[N]${NC} minor   ${CYAN}($MINOR → $((MINOR + 1)))${NC}" >&2
    echo "  ${GREEN}[M]${NC} major   ${CYAN}($MAJOR → $((MAJOR + 1)))${NC}" >&2
    echo "  ${GREEN}[Q]${NC} quit    取消" >&2
    echo "" >&2

    # 使用 select 更可靠
    local choice
    while true; do
        read -p "请选择 [H/p/n/M/q] " choice
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

        case $choice in
            h|"")
                echo "hotfix"
                return
                ;;
            p)
                echo "patch"
                return
                ;;
            n)
                echo "minor"
                return
                ;;
            m)
                echo "major"
                return
                ;;
            q)
                echo -e "${YELLOW}已取消${NC}" >&2
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}" >&2
                ;;
        esac
    done
}

# 主流程
main() {
    # 解析命令行参数
    local bump_type=""

    for arg in "$@"; do
        case $arg in
            hotfix|patch|minor|major)
                bump_type="$arg"
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo -e "${RED}错误: 未知参数 '$arg'${NC}"
                echo "使用 -h 查看帮助"
                exit 1
                ;;
        esac
    done

    # 获取当前版本
    local current_version=$(get_current_version)
    if [ -z "$current_version" ]; then
        echo -e "${RED}错误: 无法从 $PUBSPEC_FILE 读取版本号${NC}"
        exit 1
    fi

    # 确定递增类型
    if [ -z "$bump_type" ]; then
        bump_type=$(interactive_menu "$current_version")
    fi

    # 解析并递增版本
    parse_version "$current_version"
    bump_version "$bump_type"
    local new_version=$(format_version)

    # 显示预览并确认
    show_preview "$current_version" "$new_version" "$bump_type"

    local confirm
    read -p "确认更新？(Y/n) " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    if [[ $confirm == "n" ]]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 0
    fi

    echo ""
    echo -e "${YELLOW}正在更新...${NC}"
    echo ""

    # 执行更新
    update_pubspec "$new_version" "$current_version"
    echo ""
    update_changelog "$new_version"
    echo ""
    git_commit_and_tag "$new_version"

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}   版本更新完成！${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "${CYAN}新版本:${NC} $new_version"
    echo -e "${CYAN}下一步:${NC} ./build_apk.sh"
    echo ""
}

main "$@"
