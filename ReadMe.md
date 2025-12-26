# MyStory - 个人故事记录应用

## 项目概述
MyStory是一款面向iOS平台的个人故事记录应用，采用时间轴叙事方式，集成AI内容增强能力。

## 技术栈
- **开发语言**: Swift 5.9+
- **UI框架**: SwiftUI + UIKit混合开发
- **架构模式**: MVVM + 路由架构
- **本地存储**: Core Data
- **AI服务**: 阿里通义千问API
- **最低支持版本**: iOS 16.0+

## 项目结构

```
MyStory/
├── MyStoryApp.swift              # 应用入口
├── Info.plist                    # 应用配置
├── App/                          # 应用层
├── Core/                         # 核心层
│   ├── Router/                   # 路由
│   │   └── AppRouter.swift       # 路由管理器
│   ├── Network/                  # 网络层
│   └── Storage/                  # 存储层
│       └── PersistenceController.swift  # Core Data控制器
├── Models/                       # 数据模型
│   ├── Entities/                 # Core Data实体
│   │   ├── StoryEntity+CoreDataClass.swift
│   │   ├── StoryEntity+CoreDataProperties.swift
│   │   ├── CategoryEntity+CoreDataClass.swift
│   │   ├── CategoryEntity+CoreDataProperties.swift
│   │   ├── MediaEntity+CoreDataClass.swift
│   │   ├── MediaEntity+CoreDataProperties.swift
│   │   ├── SettingEntity+CoreDataClass.swift
│   │   └── SettingEntity+CoreDataProperties.swift
│   ├── ViewModels/               # 业务模型
│   │   ├── StoryModel.swift
│   │   ├── LocationInfo.swift
│   │   └── SearchHistoryItem.swift
│   └── MyStory.xcdatamodeld/     # Core Data模型定义
├── Services/                     # 业务服务
│   ├── AIService/
│   ├── MediaService/
│   ├── LocationService/
│   ├── SearchService/
│   └── CategoryService/
├── Views/                        # 视图层
│   ├── RootView.swift            # 根视图
│   ├── Timeline/                 # 时间轴
│   │   └── TimelineView.swift
│   ├── Search/                   # 搜索
│   ├── Editor/                   # 编辑器
│   ├── Category/                 # 分类
│   │   └── CategoryListView.swift
│   └── Settings/                 # 设置
│       └── SettingsView.swift
├── Components/                   # 通用组件
│   └── Theme/
│       └── AppTheme.swift        # 主题配置
├── Resources/                    # 资源文件
│   ├── Assets.xcassets/          # 资源目录
│   ├── Localizable/              # 多语言
│   └── Fonts/                    # 字体
└── Utils/                        # 工具类
```

## 已完成功能（第一阶段）

### ✅ 核心框架搭建
1. **Xcode工程初始化**
   - 创建iOS App项目
   - 配置最低支持版本iOS 16.0
   - 设置项目目录结构

2. **Core Data数据模型**
   - StoryEntity: 故事主体数据（包含位置信息字段）
   - CategoryEntity: 分类数据（支持三级层级）
   - MediaEntity: 媒体文件元数据
   - SettingEntity: 用户设置

3. **路由框架**
   - AppRouter: 统一路由管理
   - 支持NavigationStack导航
   - 支持Sheet和FullScreen模态展示

4. **基础UI组件库**
   - 颜色系统（支持深色模式）
   - 字体系统（层级化定义）
   - 间距和圆角规范
   - 阴影效果定义

5. **主要视图框架**
   - RootView: TabView主导航
   - TimelineView: 时间轴页面（带搜索栏）
   - CategoryListView: 分类列表页面
   - SettingsView: 设置页面

## 核心数据模型详情

### StoryEntity（故事实体）
- id: UUID（主键）
- title: 故事标题
- content: 故事正文（支持Markdown）
- plainTextContent: 纯文本内容（用于搜索）
- timestamp: 故事发生时间
- locationName: 地点名称
- locationAddress: 详细地址
- locationCity: 城市（带索引，用于搜索）
- latitude/longitude: 经纬度
- categories: 关联分类（多对多关系）
- media: 关联媒体（一对多关系）

### CategoryEntity（分类实体）
- id: UUID（主键）
- name: 分类名称
- nameEn: 英文名称
- iconName: SF Symbols图标名
- level: 分类层级（1-3）
- parent/children: 树形结构关系
- stories: 关联故事（多对多关系）

## 开发规范

### 命名规范
- 文件名: PascalCase（如 `TimelineView.swift`）
- 类名: PascalCase（如 `StoryViewModel`）
- 变量名: camelCase（如 `storyList`）
- 常量: camelCase（如 `maxCacheSize`）

### 代码风格
- 使用SwiftUI声明式编程
- MVVM架构分离关注点
- 使用环境对象传递依赖
- 优先使用`@Published`属性包装器

## 下一步计划（第二阶段）

1. 实现瀑布流时间轴布局
2. 开发故事编辑器（含位置选择功能）
3. 集成媒体选择和展示
4. 实现本地存储和加密
5. 添加草稿自动保存

## 隐私权限说明
应用需要以下权限：
- 📸 相册访问权限：用于选择和保存照片
- 📷 相机权限：用于拍摄照片
- 📍 位置权限：用于记录故事发生地点（可选）

所有数据均存储在本地，不会上传到第三方服务器。

## 版本信息
- 当前版本: 1.0.0
- 构建日期: 2025-11-21
