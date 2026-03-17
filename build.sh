#!/bin/bash
#
# NowenReader 懒猫应用构建脚本
# LazyCat App Build Script
#
# Usage: ./build.sh
#

set -e

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==================== 应用信息 ====================
APP_NAME="NowenReader"
APP_PACKAGE="cloud.lazycat.app.nowen-reader"
APP_VERSION=$(grep "^version:" lzc-manifest.yml | awk '{print $2}')
IMAGE_ORIGINAL="cropflre/nowen-reader:latest"
IMAGE_PREFIX="registry.lazycat.cloud/czyt"

# ==================== 工具函数 ====================

print_header() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  NowenReader 懒猫应用构建工具                                  ║${NC}"
    echo -e "${CYAN}║  LazyCat App Build Script                                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 lzc-cli"
        echo "安装文档: https://developer.lazycat.cloud/docs/lzc-cli.html"
        exit 1
    fi
}

check_files() {
    print_info "检查必要文件..."

    local missing_files=()

    if [ ! -f "lzc-manifest.yml" ]; then
        missing_files+=("lzc-manifest.yml")
    fi

    if [ ! -f "lzc-build.yml" ]; then
        missing_files+=("lzc-build.yml")
    fi

    if [ ! -f "icon.png" ]; then
        print_warning "icon.png 不存在，请提供 512x512 PNG 图标"
        missing_files+=("icon.png")
    fi

    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "缺少以下文件:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    print_success "所有必要文件检查通过"
    return 0
}

validate_config() {
    print_info "验证配置文件..."

    # 检查 YAML 语法
    if command -v yq &> /dev/null; then
        if yq eval '.' lzc-manifest.yml > /dev/null 2>&1; then
            print_success "lzc-manifest.yml 语法正确"
        else
            print_error "lzc-manifest.yml 语法错误"
            return 1
        fi
    else
        print_warning "yq 未安装，跳过 YAML 语法检查"
    fi

    # 检查必要字段
    if grep -q "^name:" lzc-manifest.yml && \
       grep -q "^package:" lzc-manifest.yml && \
       grep -q "^version:" lzc-manifest.yml; then
        print_success "必要字段检查通过"
    else
        print_error "缺少必要字段 (name, package, version)"
        return 1
    fi

    return 0
}

show_info() {
    print_header
    echo -e "${CYAN}应用信息 / Application Info:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  名称:     ${GREEN}${APP_NAME}${NC}"
    echo -e "  包名:     ${GREEN}${APP_PACKAGE}${NC}"
    echo -e "  版本:     ${GREEN}${APP_VERSION}${NC}"
    echo -e "  镜像:     ${YELLOW}${IMAGE_ORIGINAL}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${CYAN}存储路径 / Storage Paths:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  数据库:   /lzcapp/var/data"
    echo "  缓存:     /lzcapp/cache/app"
    echo "  漫画:     /lzcapp/var/comics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${CYAN}注意事项 / Notes:${NC}"
    echo "  1. 漫画目录默认映射到 /lzcapp/var/comics"
    echo "  2. 如需使用 NAS 上的现有漫画，请参考 README.md"
    echo "  3. 图标需要手动准备 (icon.png, 512x512)"
    echo ""
}

build_app() {
    print_info "开始构建应用..."

    check_files || return 1
    validate_config || return 1

    local output_file="${APP_NAME}-${APP_VERSION}.lpk"

    print_info "构建 LPK 包: $output_file"

    if lzc-cli project build -o "$output_file"; then
        print_success "构建成功: $output_file"
        echo ""
        echo -e "${GREEN}✅ 安装命令: lzc-cli app install $output_file${NC}"
        return 0
    else
        print_error "构建失败"
        return 1
    fi
}

check_login() {
    print_info "检查登录状态..."

    if lzc-cli appstore my-images &> /dev/null 2>&1; then
        print_success "已登录懒猫应用商店"
        return 0
    else
        print_warning "未登录懒猫应用商店"
        print_info "请先执行: lzc-cli appstore login"
        return 1
    fi
}

copy_image() {
    print_info "复制镜像到懒猫仓库..."

    check_login || return 1

    print_info "原始镜像: $IMAGE_ORIGINAL"
    print_info "正在复制镜像，请耐心等待..."
    echo ""

    local result
    result=$(lzc-cli appstore copy-image "$IMAGE_ORIGINAL" 2>&1)

    if echo "$result" | grep -q "uploaded:"; then
        local new_image
        new_image=$(echo "$result" | grep "^uploaded:" | awk '{print $2}')

        print_success "镜像复制成功"
        echo ""
        echo -e "  原始镜像: ${YELLOW}${IMAGE_ORIGINAL}${NC}"
        echo -e "  新镜像:   ${GREEN}${new_image}${NC}"
        echo ""

        # 更新 manifest
        update_manifest_image "$new_image"

        return 0
    else
        print_error "镜像复制失败"
        echo "$result"
        return 1
    fi
}

update_manifest_image() {
    local new_image="$1"

    print_info "更新 manifest 文件..."

    # 备份原文件
    cp lzc-manifest.yml lzc-manifest.yml.bak

    # 更新镜像并保留原镜像作为注释
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|image: ${IMAGE_ORIGINAL}|    # ${IMAGE_ORIGINAL}\n    image: ${new_image}|" lzc-manifest.yml
    else
        # Linux
        sed -i "s|image: ${IMAGE_ORIGINAL}|    # ${IMAGE_ORIGINAL}\n    image: ${new_image}|" lzc-manifest.yml
    fi

    print_success "manifest 文件已更新"
    print_info "原镜像已注释保留，方便版本追溯"
}

publish_app() {
    print_info "发布应用到应用商店..."

    check_login || return 1

    local lpk_file="${APP_NAME}-${APP_VERSION}.lpk"

    if [ ! -f "$lpk_file" ]; then
        print_error "LPK 文件不存在: $lpk_file"
        print_info "请先执行构建"
        return 1
    fi

    print_info "发布文件: $lpk_file"
    print_warning "首次发布将创建新应用，更新将提交审核"
    echo ""

    if lzc-cli appstore publish "$lpk_file"; then
        print_success "发布成功"
        echo ""
        echo -e "${GREEN}✅ 请等待审核 (通常 1-3 天)${NC}"
        return 0
    else
        print_error "发布失败"
        return 1
    fi
}

one_click_publish() {
    print_header
    print_info "🚀 一键构建+镜像复制+发布"
    echo ""

    # Stage 1: Initial Build
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}阶段 1/4: 初始构建（原始镜像）${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    build_app || return 1
    echo ""

    # Stage 2: Image Copy
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}阶段 2/4: 镜像复制（自动更新 manifest）${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    copy_image || return 1
    echo ""

    # Stage 3: Rebuild
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}阶段 3/4: 重新构建（新镜像）${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    build_app || return 1
    echo ""

    # Stage 4: Publish
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}阶段 4/4: 发布审核${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    publish_app || return 1
    echo ""

    print_success "🎉 一键发布流程完成！"
}

# ==================== 主菜单 ====================

show_menu() {
    print_header
    echo -e "${CYAN}请选择操作 / Select Operation:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  1. 📦 构建应用 (Build)"
    echo "  2. 🔧 镜像复制到懒猫仓库 (Copy Image)"
    echo "  3. 📤 发布到应用商店 (Publish)"
    echo "  4. 🚀 一键构建+镜像复制+发布 (One-Click)"
    echo "  5. 📋 查看应用信息 (Info)"
    echo "  6. ❌ 退出"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

main() {
    check_command lzc-cli

    if [ $# -gt 0 ]; then
        case "$1" in
            build)
                build_app
                ;;
            copy)
                copy_image
                ;;
            publish)
                publish_app
                ;;
            one-click)
                one_click_publish
                ;;
            info)
                show_info
                ;;
            *)
                print_error "未知命令: $1"
                echo "用法: $0 [build|copy|publish|one-click|info]"
                exit 1
                ;;
        esac
        exit $?
    fi

    # 交互式菜单
    while true; do
        show_menu
        read -p "请输入选项 (1-6): " choice
        echo ""

        case $choice in
            1)
                build_app
                ;;
            2)
                copy_image
                ;;
            3)
                publish_app
                ;;
            4)
                one_click_publish
                ;;
            5)
                show_info
                ;;
            6)
                print_info "再见！"
                exit 0
                ;;
            *)
                print_error "无效选项，请输入 1-6"
                ;;
        esac

        echo ""
        read -p "按回车继续..."
        echo ""
    done
}

main "$@"