#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片尺寸调整工具
将输入图片按照 fit 模式调整到目标尺寸
保持纵横比，不变形，居中放置，空白区域填充指定颜色
"""

import sys
import os
from PIL import Image, ImageOps
import argparse


def resize_image_fit(input_path, output_path, target_width, target_height, bg_color='white'):
    """
    调整图片尺寸，使用 fit 模式
    
    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径
        target_width: 目标宽度
        target_height: 目标高度
        bg_color: 背景填充颜色 (默认: white)
    """
    try:
        # 打开图片
        img = Image.open(input_path)
        original_width, original_height = img.size
        
        print(f"原始尺寸: {original_width} x {original_height}")
        print(f"目标尺寸: {target_width} x {target_height}")
        
        # 计算缩放比例，保持纵横比
        width_ratio = target_width / original_width
        height_ratio = target_height / original_height
        scale_ratio = min(width_ratio, height_ratio)  # 使用较小的比例，确保图片完全适配
        
        # 计算缩放后的尺寸
        new_width = int(original_width * scale_ratio)
        new_height = int(original_height * scale_ratio)
        
        print(f"缩放比例: {scale_ratio:.4f}")
        print(f"缩放后尺寸: {new_width} x {new_height}")
        
        # 缩放图片（使用高质量的 LANCZOS 重采样）
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # 创建目标尺寸的背景画布
        if img.mode == 'RGBA':
            # 如果原图有透明通道，保持透明背景
            canvas = Image.new('RGBA', (target_width, target_height), (255, 255, 255, 0))
        else:
            # 否则使用指定颜色填充
            canvas = Image.new('RGB', (target_width, target_height), bg_color)
        
        # 计算居中位置
        x = (target_width - new_width) // 2
        y = (target_height - new_height) // 2
        
        print(f"居中位置: ({x}, {y})")
        
        # 将缩放后的图片粘贴到画布中央
        if img_resized.mode == 'RGBA':
            canvas.paste(img_resized, (x, y), img_resized)
        else:
            canvas.paste(img_resized, (x, y))
        
        # 保存输出图片
        # 如果输出路径是 PNG 且原图有透明通道，保存为 RGBA
        if output_path.lower().endswith('.png') and canvas.mode == 'RGBA':
            canvas.save(output_path, 'PNG', quality=100)
        else:
            # 转换为 RGB 保存 (JPG 不支持透明通道)
            if canvas.mode == 'RGBA':
                # 将透明背景转为白色
                rgb_canvas = Image.new('RGB', canvas.size, bg_color)
                rgb_canvas.paste(canvas, mask=canvas.split()[3] if len(canvas.split()) == 4 else None)
                rgb_canvas.save(output_path, quality=95)
            else:
                canvas.save(output_path, quality=95)
        
        print(f"✓ 图片已保存到: {output_path}")
        return True
        
    except FileNotFoundError:
        print(f"✗ 错误: 找不到输入文件 '{input_path}'", file=sys.stderr)
        return False
    except Exception as e:
        print(f"✗ 错误: {str(e)}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description='图片尺寸调整工具 - 按 fit 模式调整到目标尺寸',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 调整到 1242x2688
  %(prog)s input.png -o output.png -w 1242 --height 2688
  
  # 指定背景颜色
  %(prog)s input.jpg -o output.jpg -w 1242 --height 2688 --bg-color "#F0F0F0"
  
  # 批量处理
  %(prog)s *.png -w 1242 --height 2688
        """
    )
    
    parser.add_argument('input', nargs='+', help='输入图片路径（支持多个文件或通配符）')
    parser.add_argument('-o', '--output', help='输出图片路径（单个文件时使用）')
    parser.add_argument('-w', '--width', type=int, required=True, help='目标宽度（像素）')
    parser.add_argument('--height', type=int, required=True, help='目标高度（像素）', dest='target_height')
    parser.add_argument('--bg-color', default='white', help='背景填充颜色（默认: white）')
    parser.add_argument('--suffix', default='_resized', help='批量处理时的文件名后缀（默认: _resized）')
    
    args = parser.parse_args()
    
    # 检查 Pillow 是否安装
    try:
        import PIL
    except ImportError:
        print("✗ 错误: 需要安装 Pillow 库", file=sys.stderr)
        print("请运行: pip3 install Pillow", file=sys.stderr)
        sys.exit(1)
    
    input_files = args.input
    
    # 单文件处理
    if len(input_files) == 1 and args.output:
        input_file = input_files[0]
        if not os.path.exists(input_file):
            print(f"✗ 错误: 文件不存在 '{input_file}'", file=sys.stderr)
            sys.exit(1)
        
        success = resize_image_fit(
            input_file,
            args.output,
            args.width,
            args.target_height,
            args.bg_color
        )
        sys.exit(0 if success else 1)
    
    # 批量处理
    print(f"批量处理 {len(input_files)} 个文件...\n")
    success_count = 0
    
    for input_file in input_files:
        if not os.path.exists(input_file):
            print(f"⊘ 跳过: 文件不存在 '{input_file}'")
            continue
        
        # 生成输出文件名
        name, ext = os.path.splitext(input_file)
        output_file = f"{name}{args.suffix}{ext}"
        
        print(f"\n处理: {input_file}")
        if resize_image_fit(input_file, output_file, args.width, args.target_height, args.bg_color):
            success_count += 1
    
    print(f"\n{'='*50}")
    print(f"完成! 成功处理 {success_count}/{len(input_files)} 个文件")


if __name__ == '__main__':
    main()
