# iOS App Store 自动打包脚本

本目录包含用于自动化构建、签名和打包 MyStory iOS 应用的脚本，生成可上传到 App Store 的 .ipa 文件。

## 文件说明

- **build_appstore.sh** - Shell 脚本版本（推荐使用）
- **build_appstore.py** - Python 脚本版本（需要 Python 3.6+）
- **README.md** - 本说明文档

## 前置要求

### 必需工具

1. **Xcode** - 需要安装完整的 Xcode（不仅仅是命令行工具）
2. **Xcode 命令行工具** - 执行以下命令安装：
   ```bash
   xcode-select --install
   ```

3. **xcpretty**（可选，用于美化输出）- 安装命令：
   ```bash
   sudo gem install xcpretty
   ```

### 证书和描述文件准备

在运行脚本之前，请确保：

1. **Apple Developer 账号** - 已加入 Apple Developer Program
2. **证书** - 已在 Xcode 或 Apple Developer 网站创建 Distribution Certificate
3. **App ID** - 已注册 Bundle Identifier: `com.lgogo.story`
4. **描述文件** - 已创建 App Store Distribution 描述文件

#### 自动签名（推荐）

如果使用自动签名（默认），Xcode 会自动管理证书和描述文件：
- 确保在 Xcode 中登录了 Apple ID
- 团队 ID 已正确设置（默认: HY652QKG7G）

#### 手动签名

如果使用手动签名，需要：
- 手动下载并安装证书和描述文件
- 使用 `-p` 参数指定描述文件名称

## 使用方法

### Shell 脚本（推荐）

```bash
cd /Users/master/Documents/AI-Project/MyStory/script

# 1. 赋予执行权限
chmod +x build_appstore.sh

# 2. 执行脚本（使用默认配置）
./build_appstore.sh

# 3. 其他选项
./build_appstore.sh --clean              # 清理后构建
./build_appstore.sh -t YOUR_TEAM_ID      # 指定团队 ID
./build_appstore.sh -v                   # 显示详细日志
./build_appstore.sh --help               # 显示帮助信息
```

### Python 脚本

```bash
cd /Users/master/Documents/AI-Project/MyStory/script

# 1. 执行脚本（使用默认配置）
python3 build_appstore.py

# 2. 其他选项
python3 build_appstore.py --clean              # 清理后构建
python3 build_appstore.py -t YOUR_TEAM_ID      # 指定团队 ID
python3 build_appstore.py -v                   # 显示详细日志
python3 build_appstore.py --help               # 显示帮助信息
```

## 命令行参数说明

| 参数 | 长参数 | 说明 |
|------|--------|------|
| -h | --help | 显示帮助信息 |
| -c | --clean | 构建前清理构建缓存 |
| -t | --team | 指定开发者团队 ID |
| -p | --profile | 指定描述文件名称（使用手动签名时） |
| -v | --verbose | 显示详细的构建日志 |

## 构建流程说明

脚本会自动执行以下步骤：

1. **环境验证** - 检查 Xcode 工具和项目文件
2. **清理构建目录**（可选） - 删除旧的构建文件
3. **构建 Archive** - 编译项目并生成 .xcarchive 文件
4. **导出 IPA** - 从 Archive 导出 App Store 格式的 .ipa 文件
5. **生成时间戳文件名** - 输出文件如: `MyStory_20260115_143052.ipa`

## 输出位置

构建完成后，文件将保存在以下位置：

```
/Users/master/Documents/AI-Project/MyStory/build/
├── MyStory.xcarchive/              # Archive 文件
└── MyStory_YYYYMMDD_HHMMSS.ipa    # 最终的 IPA 文件
```

## 上传到 App Store

构建完成后，有两种方式上传 IPA 到 App Store Connect：

### 方式一：使用 Transporter 应用（推荐）

1. 在 Mac 上打开 **Transporter** 应用（从 App Store 下载）
2. 登录你的 Apple ID
3. 将生成的 .ipa 文件拖入 Transporter
4. 点击"交付"按钮上传

### 方式二：使用命令行工具

```bash
xcrun altool --upload-app \
  --file "build/MyStory_20260115_143052.ipa" \
  --type ios \
  --username "your-apple-id@example.com" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

**注意**：密码需要使用 App 专用密码（App-Specific Password），而不是 Apple ID 密码。
- 在 [appleid.apple.com](https://appleid.apple.com) 的"安全"部分生成

## 常见问题排查

### 1. 签名错误

**错误信息**：`Code signing is required for product type 'Application'`

**解决方法**：
- 确保已在 Xcode 中登录 Apple ID
- 检查团队 ID 是否正确
- 尝试在 Xcode 中手动构建一次以确认证书配置

### 2. 描述文件错误

**错误信息**：`No profile for team 'XXX' matching 'YYY' found`

**解决方法**：
- 在 Apple Developer 网站创建 App Store Distribution 描述文件
- 下载并双击安装描述文件
- 或使用 `-p` 参数手动指定描述文件名称

### 3. Archive 构建失败

**错误信息**：各种编译错误

**解决方法**：
- 首先在 Xcode 中确保项目可以正常编译
- 使用 `-v` 参数查看详细的构建日志
- 检查项目依赖是否正确安装（如 RichTextKit）

### 4. 权限错误

**错误信息**：`Permission denied`

**解决方法**：
```bash
chmod +x build_appstore.sh
```

### 5. 命令未找到

**错误信息**：`xcodebuild: command not found`

**解决方法**：
```bash
# 安装 Xcode 命令行工具
xcode-select --install

# 设置 Xcode 路径
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## 脚本配置

如需修改默认配置，请编辑脚本开头的配置区域：

### Shell 脚本 (build_appstore.sh)

```bash
# 项目配置
PROJECT_NAME="MyStory"
SCHEME_NAME="MyStory"
BUNDLE_IDENTIFIER="com.lgogo.story"
CONFIGURATION="Release"
EXPORT_METHOD="app-store"
```

### Python 脚本 (build_appstore.py)

```python
# 配置区域
PROJECT_NAME = "MyStory"
SCHEME_NAME = "MyStory"
BUNDLE_IDENTIFIER = "com.lgogo.story"
CONFIGURATION = "Release"
EXPORT_METHOD = "app-store"
DEFAULT_TEAM_ID = "HY652QKG7G"
```

## 高级用法

### 构建其他分发方式

修改脚本中的 `EXPORT_METHOD` 变量：

- `app-store` - App Store 分发（默认）
- `ad-hoc` - Ad Hoc 分发（内部测试）
- `enterprise` - 企业分发（需要企业账号）
- `development` - 开发分发（开发测试）

### 集成到 CI/CD

脚本可以轻松集成到自动化构建流程中：

```bash
# 在 CI/CD 环境中使用
./build_appstore.sh --clean -t ${TEAM_ID} -v

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "构建成功"
    # 执行后续操作（如自动上传）
else
    echo "构建失败"
    exit 1
fi
```

## 版本信息

- **当前版本**: 1.0.0
- **创建日期**: 2026-01-15
- **最后更新**: 2026-01-15
- **支持的 iOS 版本**: 16.0+
- **支持的 Xcode 版本**: Xcode 14.0+

## 技术支持

如遇到问题，请检查：
1. Xcode 版本是否符合要求
2. 证书和描述文件是否正确配置
3. 网络连接是否正常（首次构建需要下载依赖）
4. 查看详细日志输出（使用 `-v` 参数）

## 许可证

本脚本为 MyStory 项目的一部分，仅供项目内部使用。

## 更新日志

### v1.0.0 (2026-01-15)
- 初始版本发布
- 支持自动和手动签名
- 支持 Shell 和 Python 两种实现
- 完整的错误处理机制
- 详细的构建日志输出
