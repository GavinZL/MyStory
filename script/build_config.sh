#!/bin/bash

################################################################################
# iOS 自动打包配置文件
# 说明: 在此文件中配置你的构建参数，避免每次都手动指定
# 使用: source build_config.sh 或在脚本中引用此配置
################################################################################

# ============================================================================
# 项目基本信息
# ============================================================================

# 项目名称
export BUILD_PROJECT_NAME="MyStory"

# Scheme 名称 (通常与项目名称相同)
export BUILD_SCHEME_NAME="MyStory"

# Bundle Identifier (Release 配置)
export BUILD_BUNDLE_IDENTIFIER="com.lgogo.story"

# ============================================================================
# 构建配置
# ============================================================================

# 构建配置 (Debug, Release)
export BUILD_CONFIGURATION="Release"

# 导出方法
# - app-store: App Store 分发
# - ad-hoc: Ad Hoc 分发 (内部测试)
# - enterprise: 企业分发
# - development: 开发分发
export BUILD_EXPORT_METHOD="app-store"

# ============================================================================
# 证书和签名配置
# ============================================================================

# 开发者团队 ID
# 可在 Apple Developer 账号设置或 Xcode 项目设置中查看
export BUILD_TEAM_ID="HY652QKG7G"

# 签名方式 (automatic 或 manual)
# - automatic: Xcode 自动管理证书和描述文件 (推荐)
# - manual: 手动指定证书和描述文件
export BUILD_SIGNING_STYLE="automatic"

# 描述文件名称 (仅在 manual 签名时需要)
# 留空表示自动选择
export BUILD_PROVISIONING_PROFILE=""

# 证书名称 (仅在 manual 签名时需要)
# 例如: "Apple Distribution: Your Company Name (TEAM_ID)"
export BUILD_CERTIFICATE_NAME=""

# ============================================================================
# 路径配置
# ============================================================================

# 项目文件路径 (相对于 script 目录)
# 如果使用 .xcworkspace，请填写 workspace 路径
export BUILD_WORKSPACE_PATH=""

# 项目文件路径 (相对于 script 目录)
export BUILD_PROJECT_PATH="../MyStory.xcodeproj"

# 输出目录 (相对于项目根目录)
export BUILD_OUTPUT_DIR="build"

# ============================================================================
# 其他选项
# ============================================================================

# 是否在构建前清理缓存 (true 或 false)
export BUILD_CLEAN_BEFORE="false"

# 是否显示详细构建日志 (true 或 false)
export BUILD_VERBOSE="false"

# 是否上传符号表 (true 或 false)
export BUILD_UPLOAD_SYMBOLS="true"

# 是否编译 Bitcode (true 或 false)
# 注意: Apple 已在 Xcode 14 中移除 Bitcode 支持
export BUILD_COMPILE_BITCODE="false"

# ============================================================================
# App Store Connect 配置 (用于自动上传)
# ============================================================================

# Apple ID (用于上传到 App Store)
export APPSTORE_USERNAME=""

# App 专用密码 (在 appleid.apple.com 生成)
export APPSTORE_PASSWORD=""

# App Store Connect API Key ID (可选，用于 API 认证)
export APPSTORE_API_KEY_ID=""

# App Store Connect API Issuer ID (可选)
export APPSTORE_API_ISSUER_ID=""

# API Key 文件路径 (可选)
export APPSTORE_API_KEY_PATH=""

# ============================================================================
# 通知配置 (可选)
# ============================================================================

# 构建完成后是否发送通知 (true 或 false)
export BUILD_NOTIFY="false"

# 通知邮箱地址
export BUILD_NOTIFY_EMAIL=""

# Slack Webhook URL (如果使用 Slack 通知)
export BUILD_SLACK_WEBHOOK=""

# ============================================================================
# 使用说明
# ============================================================================
# 
# 1. 复制此文件为 build_config.local.sh 进行个人配置
#    cp build_config.sh build_config.local.sh
# 
# 2. 编辑 build_config.local.sh 填入你的配置
# 
# 3. 在构建脚本中引用配置:
#    source build_config.local.sh
#    ./build_appstore.sh
# 
# 4. 或直接使用环境变量:
#    export BUILD_TEAM_ID="YOUR_TEAM_ID"
#    ./build_appstore.sh
# 
# ============================================================================

echo "配置文件已加载: build_config.sh"
echo "项目: ${BUILD_PROJECT_NAME}"
echo "Team ID: ${BUILD_TEAM_ID}"
echo "导出方法: ${BUILD_EXPORT_METHOD}"
