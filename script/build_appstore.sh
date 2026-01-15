#!/bin/bash

################################################################################
# iOS App Store 自动打包脚本
# 用途: 自动化构建、签名和打包 iOS 应用，生成可上传 App Store 的 .ipa 文件
# 使用方式: ./build_appstore.sh [选项]
################################################################################

set -e  # 遇到错误立即退出
set -o pipefail  # 管道命令出错时退出

# ============================================================================
# 配置区域 - 根据项目实际情况修改
# ============================================================================

# 项目配置
PROJECT_NAME="MyStory"
SCHEME_NAME="MyStory"
WORKSPACE_PATH=""  # 如果使用 .xcworkspace，请填写路径
PROJECT_PATH="MyStory.xcodeproj"  # 相对于项目根目录的路径

# Bundle Identifier (Release 配置)
BUNDLE_IDENTIFIER="com.lgogo.story"

# 构建配置
CONFIGURATION="Release"

# 导出方法 (app-store, ad-hoc, enterprise, development)
EXPORT_METHOD="app-store"

# 输出路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
IPA_OUTPUT_PATH="${BUILD_DIR}"

# 颜色输出配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# 辅助函数
# ============================================================================

# 日志输出函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 错误处理函数
error_exit() {
    log_error "$1"
    exit 1
}

# 显示帮助信息
show_help() {
    cat << EOF
使用方式: $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -c, --clean             构建前清理缓存
    -t, --team TEAM_ID      指定开发者团队 ID
    -p, --profile PROFILE   指定描述文件名称
    -v, --verbose           显示详细构建日志
    
示例:
    $0                      # 使用默认配置构建
    $0 --clean              # 清理后构建
    $0 -t HY652QKG7G        # 指定团队 ID 构建
    
EOF
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error_exit "未找到命令: $1，请确保已安装 Xcode 命令行工具"
    fi
}

# 清理构建目录
clean_build() {
    log_info "清理构建目录..."
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
        log_success "构建目录已清理"
    fi
}

# 创建导出选项 plist 文件
create_export_options() {
    local export_options_path="${BUILD_DIR}/ExportOptions.plist"
    
    log_info "创建导出配置文件..."
    
    cat > "${export_options_path}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>${SIGNING_STYLE}</string>
EOF

    # 如果指定了描述文件，添加到配置中
    if [ -n "${PROVISIONING_PROFILE}" ]; then
        cat >> "${export_options_path}" << EOF
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_IDENTIFIER}</key>
        <string>${PROVISIONING_PROFILE}</string>
    </dict>
EOF
    fi

    cat >> "${export_options_path}" << EOF
</dict>
</plist>
EOF
    
    log_success "导出配置文件创建完成: ${export_options_path}"
    echo "${export_options_path}"
}

# 解析命令行参数
parse_arguments() {
    CLEAN_BUILD=false
    VERBOSE_MODE=false
    TEAM_ID="${TEAM_ID:-HY652QKG7G}"  # 默认值从 Xcode Signing Certificate 获取
    PROVISIONING_PROFILE=""
    SIGNING_STYLE="automatic"  # automatic 或 manual
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -t|--team)
                TEAM_ID="$2"
                shift 2
                ;;
            -p|--profile)
                PROVISIONING_PROFILE="$2"
                SIGNING_STYLE="manual"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 验证环境
validate_environment() {
    log_info "验证构建环境..."
    
    # 检查必需的命令
    check_command "xcodebuild"
    check_command "xcrun"
    
    # 检查项目文件是否存在
    local project_file="${PROJECT_ROOT}/${PROJECT_PATH}"
    if [ ! -d "${project_file}" ]; then
        error_exit "项目文件不存在: ${project_file}"
    fi
    
    # 检查 Scheme 是否存在
    if [ -z "${WORKSPACE_PATH}" ]; then
        xcodebuild -list -project "${project_file}" | grep -q "${SCHEME_NAME}" || \
            error_exit "Scheme '${SCHEME_NAME}' 不存在"
    else
        local workspace_file="${PROJECT_ROOT}/${WORKSPACE_PATH}"
        xcodebuild -list -workspace "${workspace_file}" | grep -q "${SCHEME_NAME}" || \
            error_exit "Scheme '${SCHEME_NAME}' 不存在"
    fi
    
    log_success "环境验证通过"
}

# 显示构建信息
show_build_info() {
    log_info "================================"
    log_info "构建配置信息"
    log_info "================================"
    log_info "项目名称: ${PROJECT_NAME}"
    log_info "Scheme: ${SCHEME_NAME}"
    log_info "配置: ${CONFIGURATION}"
    log_info "Bundle ID: ${BUNDLE_IDENTIFIER}"
    log_info "导出方法: ${EXPORT_METHOD}"
    log_info "团队 ID: ${TEAM_ID}"
    log_info "签名方式: ${SIGNING_STYLE}"
    [ -n "${PROVISIONING_PROFILE}" ] && log_info "描述文件: ${PROVISIONING_PROFILE}"
    log_info "输出目录: ${IPA_OUTPUT_PATH}"
    log_info "================================"
}

# 构建 Archive
build_archive() {
    log_info "开始构建 Archive..."
    
    # 创建构建目录
    mkdir -p "${BUILD_DIR}"
    
    # 构建参数
    local signing_style_capitalized=$(echo "${SIGNING_STYLE}" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    local build_args=(
        -scheme "${SCHEME_NAME}"
        -configuration "${CONFIGURATION}"
        -sdk iphoneos
        -archivePath "${ARCHIVE_PATH}"
        -destination 'generic/platform=iOS'
        -allowProvisioningUpdates
        DEVELOPMENT_TEAM="${TEAM_ID}"
        CODE_SIGN_STYLE="${signing_style_capitalized}"  # Automatic 或 Manual
    )
    
    # 根据是否使用 workspace 添加相应参数
    if [ -n "${WORKSPACE_PATH}" ]; then
        build_args=(-workspace "${PROJECT_ROOT}/${WORKSPACE_PATH}" "${build_args[@]}")
    else
        build_args=(-project "${PROJECT_ROOT}/${PROJECT_PATH}" "${build_args[@]}")
    fi
    
    # 如果启用详细模式，不隐藏输出
    if [ "${VERBOSE_MODE}" = true ]; then
        xcodebuild archive "${build_args[@]}"
    else
        log_info "正在编译项目 (可能需要几分钟)..."
        xcodebuild archive "${build_args[@]}" | xcpretty || xcodebuild archive "${build_args[@]}"
    fi
    
    # 检查 Archive 是否成功
    if [ ! -d "${ARCHIVE_PATH}" ]; then
        error_exit "Archive 构建失败"
    fi
    
    log_success "Archive 构建成功: ${ARCHIVE_PATH}"
}

# 导出 IPA
export_ipa() {
    log_info "开始导出 IPA..."
    
    # 创建导出选项文件
    local export_options_path=$(create_export_options)
    
    # 导出参数
    local export_args=(
        -archivePath "${ARCHIVE_PATH}"
        -exportPath "${EXPORT_PATH}"
        -exportOptionsPlist "${export_options_path}"
        -allowProvisioningUpdates
    )
    
    # 执行导出
    if [ "${VERBOSE_MODE}" = true ]; then
        xcodebuild -exportArchive "${export_args[@]}"
    else
        log_info "正在导出 IPA 文件..."
        xcodebuild -exportArchive "${export_args[@]}" | xcpretty || xcodebuild -exportArchive "${export_args[@]}"
    fi
    
    # 检查导出是否成功
    local ipa_file="${EXPORT_PATH}/${PROJECT_NAME}.ipa"
    if [ ! -f "${ipa_file}" ]; then
        error_exit "IPA 导出失败"
    fi
    
    # 移动 IPA 到输出目录
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local final_ipa="${IPA_OUTPUT_PATH}/${PROJECT_NAME}_${timestamp}.ipa"
    mv "${ipa_file}" "${final_ipa}"
    
    log_success "IPA 导出成功: ${final_ipa}"
    
    # 显示 IPA 文件信息
    local ipa_size=$(du -h "${final_ipa}" | awk '{print $1}')
    log_info "IPA 文件大小: ${ipa_size}"
    
    echo "${final_ipa}"
}

# 主函数
main() {
    log_info "开始 iOS App Store 自动打包流程..."
    echo ""
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 显示构建信息
    show_build_info
    echo ""
    
    # 验证环境
    validate_environment
    echo ""
    
    # 清理构建 (如果需要)
    if [ "${CLEAN_BUILD}" = true ]; then
        clean_build
        echo ""
    fi
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 构建 Archive
    build_archive
    echo ""
    
    # 导出 IPA
    local ipa_path=$(export_ipa)
    echo ""
    
    # 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # 显示成功信息
    log_success "================================"
    log_success "打包完成!"
    log_success "================================"
    log_success "IPA 文件位置: ${ipa_path}"
    log_success "耗时: ${minutes} 分 ${seconds} 秒"
    log_success "================================"
    echo ""
    log_info "下一步操作:"
    log_info "1. 使用 Transporter 应用上传 IPA 到 App Store Connect"
    log_info "2. 或使用命令: xcrun altool --upload-app --file \"${ipa_path}\" --type ios --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD"
    
    # 清理临时文件 (保留 Archive 以便调试)
    if [ -d "${EXPORT_PATH}" ]; then
        rm -rf "${EXPORT_PATH}"
    fi
}

# ============================================================================
# 脚本入口
# ============================================================================

# 执行主函数
main "$@"
