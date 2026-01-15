# 快速开始指南

这是一个超简洁的快速上手指南，让你在 5 分钟内完成第一次打包。

## 📋 准备工作（首次使用）

### 1. 确保环境就绪

```bash
# 检查 Xcode 命令行工具
xcodebuild -version

# 如果没有安装，执行以下命令
xcode-select --install
```

### 2. 配置 Apple Developer 账号

- 在 Xcode 中登录你的 Apple Developer 账号
- 确保你的账号已加入 Apple Developer Program
- 路径: Xcode → Settings → Accounts → 添加 Apple ID

### 3. 确认证书和描述文件

- 打开项目: `/Users/master/Documents/AI-Project/MyStory/MyStory.xcodeproj`
- 选择 Target: MyStory
- 切换到 "Signing & Capabilities" 标签
- 确保 "Automatically manage signing" 已勾选
- 确认 Team 已选择（团队 ID: HY652QKG7G）

## 🚀 开始打包（三步走）

### 方式一：使用 Shell 脚本（推荐）

```bash
# 1. 进入 script 目录
cd /Users/master/Documents/AI-Project/MyStory/script

# 2. 赋予执行权限（仅首次需要）
chmod +x build_appstore.sh

# 3. 运行脚本
./build_appstore.sh
```

### 方式二：使用 Python 脚本

```bash
# 1. 进入 script 目录
cd /Users/master/Documents/AI-Project/MyStory/script

# 2. 运行脚本
python3 build_appstore.py
```

## ⏱️ 等待构建完成

- 首次构建大约需要 3-5 分钟
- 脚本会显示构建进度
- 完成后会显示 IPA 文件的位置

## 📦 找到你的 IPA 文件

构建完成后，IPA 文件位于：

```
/Users/master/Documents/AI-Project/MyStory/build/MyStory_YYYYMMDD_HHMMSS.ipa
```

例如: `MyStory_20260115_143052.ipa`

## 📤 上传到 App Store

### 使用 Transporter（最简单）

1. 打开 Mac App Store，搜索并安装 **Transporter**
2. 打开 Transporter，登录你的 Apple ID
3. 将生成的 `.ipa` 文件拖入 Transporter 窗口
4. 点击"交付"按钮，等待上传完成

### 上传完成后

1. 访问 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择你的应用
3. 在"TestFlight"或"App Store"标签中可以看到刚上传的构建版本
4. 提交审核或分发给测试人员

## ⚠️ 常见问题

### Q1: 提示"xcodebuild: command not found"

**解决方案:**
```bash
xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### Q2: 提示签名错误

**解决方案:**
1. 打开 Xcode 项目
2. 选择 MyStory Target
3. 在 "Signing & Capabilities" 中点击 "Try Again"
4. 确保 Team 已选择
5. 如果还有问题，尝试在 Xcode 中手动构建一次（Product → Archive）

### Q3: 构建失败，提示依赖错误

**解决方案:**
```bash
# 先在 Xcode 中打开项目，让它自动下载依赖
# 或者使用 --clean 选项重新构建
./build_appstore.sh --clean
```

### Q4: 想看详细的构建日志

**解决方案:**
```bash
./build_appstore.sh -v
```

## 🔧 高级选项

### 清理后重新构建
```bash
./build_appstore.sh --clean
```

### 指定其他团队 ID
```bash
./build_appstore.sh -t YOUR_TEAM_ID
```

### 查看所有选项
```bash
./build_appstore.sh --help
```

## 📝 下次构建

下次构建时，只需要一行命令：

```bash
cd /Users/master/Documents/AI-Project/MyStory/script && ./build_appstore.sh
```

或者更简单，创建一个别名（添加到 `~/.zshrc` 或 `~/.bashrc`）：

```bash
alias build-mystory='cd /Users/master/Documents/AI-Project/MyStory/script && ./build_appstore.sh'
```

之后只需要输入：
```bash
build-mystory
```

## 🎉 完成！

现在你已经成功完成了第一次自动化打包。后续的打包流程都会非常简单快速。

如需更详细的信息，请查看 [README.md](README.md)。
