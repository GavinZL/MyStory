#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
iOS App Store 自动打包脚本 (Python 版本)
用途: 自动化构建、签名和打包 iOS 应用，生成可上传 App Store 的 .ipa 文件
使用方式: python3 build_appstore.py [选项]
"""

import os
import sys
import subprocess
import argparse
import shutil
from datetime import datetime
from pathlib import Path

# ============================================================================
# 配置区域 - 根据项目实际情况修改
# ============================================================================

PROJECT_NAME = "MyStory"
SCHEME_NAME = "MyStory"
WORKSPACE_PATH = ""  # 如果使用 .xcworkspace，请填写路径
PROJECT_PATH = "MyStory.xcodeproj"  # 相对于项目根目录的路径

# Bundle Identifier (Release 配置)
BUNDLE_IDENTIFIER = "com.lgogo.story"

# 构建配置
CONFIGURATION = "Release"

# 导出方法 (app-store, ad-hoc, enterprise, development)
EXPORT_METHOD = "app-store"

# 默认团队 ID
DEFAULT_TEAM_ID = "HY652QKG7G"

# ============================================================================
# 颜色输出类
# ============================================================================

class Colors:
    """终端颜色输出"""
    BLUE = '\033[0;34m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color
    
    @staticmethod
    def info(msg):
        print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")
    
    @staticmethod
    def success(msg):
        print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {msg}")
    
    @staticmethod
    def warning(msg):
        print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {msg}")
    
    @staticmethod
    def error(msg):
        print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}", file=sys.stderr)

# ============================================================================
# 主构建类
# ============================================================================

class AppStoreBuilder:
    """App Store 自动打包构建器"""
    
    def __init__(self, args):
        """初始化构建器"""
        self.args = args
        self.script_dir = Path(__file__).parent.resolve()
        self.project_root = self.script_dir.parent
        self.build_dir = self.project_root / "build"
        self.archive_path = self.build_dir / f"{PROJECT_NAME}.xcarchive"
        self.export_path = self.build_dir / "export"
        self.ipa_output_path = self.build_dir
        
        # 签名配置
        self.team_id = args.team_id or DEFAULT_TEAM_ID
        self.provisioning_profile = args.provisioning_profile or ""
        self.signing_style = "manual" if self.provisioning_profile else "automatic"
    
    def check_command(self, command):
        """检查命令是否存在"""
        if shutil.which(command) is None:
            Colors.error(f"未找到命令: {command}，请确保已安装 Xcode 命令行工具")
            sys.exit(1)
    
    def run_command(self, cmd, description="", check=True):
        """执行命令"""
        if description:
            Colors.info(description)
        
        try:
            if self.args.verbose:
                result = subprocess.run(cmd, check=check)
            else:
                result = subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=check
                )
            return result
        except subprocess.CalledProcessError as e:
            Colors.error(f"命令执行失败: {' '.join(cmd)}")
            if not self.args.verbose and e.stderr:
                Colors.error(e.stderr.decode('utf-8'))
            sys.exit(1)
    
    def validate_environment(self):
        """验证构建环境"""
        Colors.info("验证构建环境...")
        
        # 检查必需的命令
        self.check_command("xcodebuild")
        self.check_command("xcrun")
        
        # 检查项目文件
        project_file = self.project_root / PROJECT_PATH
        if not project_file.exists():
            Colors.error(f"项目文件不存在: {project_file}")
            sys.exit(1)
        
        # 检查 Scheme
        if WORKSPACE_PATH:
            workspace_file = self.project_root / WORKSPACE_PATH
            cmd = ["xcodebuild", "-list", "-workspace", str(workspace_file)]
        else:
            cmd = ["xcodebuild", "-list", "-project", str(project_file)]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if SCHEME_NAME not in result.stdout:
            Colors.error(f"Scheme '{SCHEME_NAME}' 不存在")
            sys.exit(1)
        
        Colors.success("环境验证通过")
    
    def clean_build(self):
        """清理构建目录"""
        if self.build_dir.exists():
            Colors.info("清理构建目录...")
            shutil.rmtree(self.build_dir)
            Colors.success("构建目录已清理")
    
    def show_build_info(self):
        """显示构建信息"""
        Colors.info("=" * 50)
        Colors.info("构建配置信息")
        Colors.info("=" * 50)
        Colors.info(f"项目名称: {PROJECT_NAME}")
        Colors.info(f"Scheme: {SCHEME_NAME}")
        Colors.info(f"配置: {CONFIGURATION}")
        Colors.info(f"Bundle ID: {BUNDLE_IDENTIFIER}")
        Colors.info(f"导出方法: {EXPORT_METHOD}")
        Colors.info(f"团队 ID: {self.team_id}")
        Colors.info(f"签名方式: {self.signing_style}")
        if self.provisioning_profile:
            Colors.info(f"描述文件: {self.provisioning_profile}")
        Colors.info(f"输出目录: {self.ipa_output_path}")
        Colors.info("=" * 50)
    
    def create_export_options(self):
        """创建导出选项 plist 文件"""
        export_options_path = self.build_dir / "ExportOptions.plist"
        
        Colors.info("创建导出配置文件...")
        
        content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>{EXPORT_METHOD}</string>
    <key>teamID</key>
    <string>{self.team_id}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>{self.signing_style}</string>
"""
        
        # 如果指定了描述文件，添加到配置中
        if self.provisioning_profile:
            content += f"""    <key>provisioningProfiles</key>
    <dict>
        <key>{BUNDLE_IDENTIFIER}</key>
        <string>{self.provisioning_profile}</string>
    </dict>
"""
        
        content += """</dict>
</plist>
"""
        
        export_options_path.write_text(content)
        Colors.success(f"导出配置文件创建完成: {export_options_path}")
        
        return export_options_path
    
    def build_archive(self):
        """构建 Archive"""
        Colors.info("开始构建 Archive...")
        
        # 创建构建目录
        self.build_dir.mkdir(parents=True, exist_ok=True)
        
        # 构建参数
        project_file = self.project_root / PROJECT_PATH
        
        cmd = [
            "xcodebuild",
            "archive",
            "-scheme", SCHEME_NAME,
            "-configuration", CONFIGURATION,
            "-sdk", "iphoneos",
            "-archivePath", str(self.archive_path),
            "-destination", "generic/platform=iOS",
            "-allowProvisioningUpdates",
            f"DEVELOPMENT_TEAM={self.team_id}",
            f"CODE_SIGN_STYLE={self.signing_style.capitalize()}",
        ]
        
        # 根据是否使用 workspace 添加相应参数
        if WORKSPACE_PATH:
            workspace_file = self.project_root / WORKSPACE_PATH
            cmd.extend(["-workspace", str(workspace_file)])
        else:
            cmd.extend(["-project", str(project_file)])
        
        # 执行构建
        if not self.args.verbose:
            Colors.info("正在编译项目 (可能需要几分钟)...")
        
        self.run_command(cmd)
        
        # 检查 Archive 是否成功
        if not self.archive_path.exists():
            Colors.error("Archive 构建失败")
            sys.exit(1)
        
        Colors.success(f"Archive 构建成功: {self.archive_path}")
    
    def export_ipa(self):
        """导出 IPA"""
        Colors.info("开始导出 IPA...")
        
        # 创建导出选项文件
        export_options_path = self.create_export_options()
        
        # 导出参数
        cmd = [
            "xcodebuild",
            "-exportArchive",
            "-archivePath", str(self.archive_path),
            "-exportPath", str(self.export_path),
            "-exportOptionsPlist", str(export_options_path),
            "-allowProvisioningUpdates",
        ]
        
        # 执行导出
        if not self.args.verbose:
            Colors.info("正在导出 IPA 文件...")
        
        self.run_command(cmd)
        
        # 检查导出是否成功
        ipa_file = self.export_path / f"{PROJECT_NAME}.ipa"
        if not ipa_file.exists():
            Colors.error("IPA 导出失败")
            sys.exit(1)
        
        # 移动 IPA 到输出目录
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        final_ipa = self.ipa_output_path / f"{PROJECT_NAME}_{timestamp}.ipa"
        shutil.move(str(ipa_file), str(final_ipa))
        
        Colors.success(f"IPA 导出成功: {final_ipa}")
        
        # 显示 IPA 文件信息
        ipa_size = final_ipa.stat().st_size / (1024 * 1024)
        Colors.info(f"IPA 文件大小: {ipa_size:.2f} MB")
        
        return final_ipa
    
    def cleanup(self):
        """清理临时文件"""
        if self.export_path.exists():
            shutil.rmtree(self.export_path)
    
    def build(self):
        """执行完整的构建流程"""
        Colors.info("开始 iOS App Store 自动打包流程...")
        print()
        
        # 显示构建信息
        self.show_build_info()
        print()
        
        # 验证环境
        self.validate_environment()
        print()
        
        # 清理构建 (如果需要)
        if self.args.clean:
            self.clean_build()
            print()
        
        # 记录开始时间
        start_time = datetime.now()
        
        # 构建 Archive
        self.build_archive()
        print()
        
        # 导出 IPA
        ipa_path = self.export_ipa()
        print()
        
        # 清理临时文件
        self.cleanup()
        
        # 计算耗时
        duration = (datetime.now() - start_time).total_seconds()
        minutes = int(duration // 60)
        seconds = int(duration % 60)
        
        # 显示成功信息
        Colors.success("=" * 50)
        Colors.success("打包完成!")
        Colors.success("=" * 50)
        Colors.success(f"IPA 文件位置: {ipa_path}")
        Colors.success(f"耗时: {minutes} 分 {seconds} 秒")
        Colors.success("=" * 50)
        print()
        Colors.info("下一步操作:")
        Colors.info("1. 使用 Transporter 应用上传 IPA 到 App Store Connect")
        Colors.info(f"2. 或使用命令: xcrun altool --upload-app --file \"{ipa_path}\" --type ios --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD")

# ============================================================================
# 命令行参数解析
# ============================================================================

def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="iOS App Store 自动打包脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python3 build_appstore.py                    # 使用默认配置构建
  python3 build_appstore.py --clean            # 清理后构建
  python3 build_appstore.py -t HY652QKG7G      # 指定团队 ID 构建
  python3 build_appstore.py -v                 # 显示详细构建日志
        """
    )
    
    parser.add_argument(
        '-c', '--clean',
        action='store_true',
        help='构建前清理缓存'
    )
    
    parser.add_argument(
        '-t', '--team-id',
        help='指定开发者团队 ID'
    )
    
    parser.add_argument(
        '-p', '--provisioning-profile',
        help='指定描述文件名称'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='显示详细构建日志'
    )
    
    return parser.parse_args()

# ============================================================================
# 主函数
# ============================================================================

def main():
    """主函数"""
    try:
        args = parse_arguments()
        builder = AppStoreBuilder(args)
        builder.build()
    except KeyboardInterrupt:
        Colors.warning("\n用户中断构建")
        sys.exit(1)
    except Exception as e:
        Colors.error(f"构建过程发生错误: {str(e)}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
