# MyStory 存储系统设计文档

## 一、整体架构

### 1.1 存储层级关系

```
分类体系（CategoryEntity）
├── 一级分类（Level 1）如：生活、工作、旅行
│   ├── 二级分类（Level 2）如：育儿、美食、健康
│   │   ├── 三级分类（Level 3）如：大宝故事、二宝日常
│   │   │   └── 故事节点（StoryEntity）
│   │   │       └── 媒体文件（MediaEntity）
```

### 1.2 核心概念说明

1. **三级分类体系**
   - **Level 1（主分类）**：如"生活"、"工作"、"旅行"，最多10个
   - **Level 2（子分类）**：如"育儿"、"美食"、"健康"，每个主分类最多20个
   - **Level 3（细分类/故事线）**：如"大宝故事"、"二宝日常"，每个子分类最多30个

2. **故事线（Timeline）**
   - 第三级分类即为一个故事线
   - `TimelineView` 负责展示第三级分类下的所有故事节点
   - 故事节点按时间顺序排列，形成时间轴

3. **故事节点（StoryEntity）**
   - 每个故事节点是时间轴上的一个节点
   - 可以属于多个分类（通过多对多关系）
   - 包含文本内容、媒体文件、位置信息等

## 二、Core Data 实体设计

### 2.1 CategoryEntity（分类实体）

```swift
entity CategoryEntity {
    // 基础字段
    id: UUID           // 主键
    name: String       // 分类名称，如"大宝故事"
    nameEn: String?    // 英文名称（可选）
    iconName: String   // SF Symbols图标名
    colorHex: String   // 主题色，默认"#007AFF"
    level: Int16       // 分类层级：1-3
    sortOrder: Int32   // 排序权重
    createdAt: Date    // 创建时间
    
    // 关系
    parent: CategoryEntity?           // 父分类（to-one）
    children: Set<CategoryEntity>     // 子分类集合（to-many）
    stories: Set<StoryEntity>         // 关联故事（to-many）
}
```

**层级规则**：
- Level 1: `parent = nil`，最多10个
- Level 2: `parent.level = 1`，每个父分类最多20个
- Level 3: `parent.level = 2`，每个父分类最多30个

**删除规则**：
- `parent -> children`: Cascade（删除父分类时级联删除子分类）
- `children -> parent`: Nullify（删除子分类时不影响父分类）
- `stories <-> categories`: Nullify（解除关联，不删除故事）

### 2.2 StoryEntity（故事实体）

```swift
entity StoryEntity {
    // 基础字段
    id: UUID                    // 主键
    title: String?              // 故事标题
    content: String?            // 故事正文（支持Markdown）
    plainTextContent: String?   // 纯文本内容（用于搜索）
    timestamp: Date             // 故事发生时间
    createdAt: Date             // 创建时间
    updatedAt: Date             // 最后修改时间
    
    // 位置信息
    locationName: String?       // 地点名称
    locationAddress: String?    // 详细地址
    locationCity: String?       // 城市（带索引）
    latitude: Double            // 纬度
    longitude: Double           // 经度
    
    // 其他
    mood: String?               // 心情标签（预留）
    syncStatus: Int16           // 同步状态：0-未同步，1-已同步，2-冲突
    isDeleted: Bool             // 软删除标记
    
    // 关系
    categories: Set<CategoryEntity>  // 所属分类（to-many）
    media: Set<MediaEntity>          // 媒体文件（to-many）
}
```

**多对多关系说明**：
- 一个故事可以属于多个分类
- 一个分类下可以有多个故事
- 中间表由Core Data自动管理

### 2.3 MediaEntity（媒体实体）

```swift
entity MediaEntity {
    // 基础字段
    id: UUID                      // 主键
    type: String                  // 类型："image" 或 "video"
    fileName: String              // 加密后的文件名
    originalFileName: String?     // 原始文件名
    fileSize: Int64               // 文件大小（字节）
    width: Int32                  // 宽度
    height: Int32                 // 高度
    duration: Double              // 时长（视频，秒）
    thumbnailFileName: String?    // 缩略图文件名
    encryptionKeyId: String       // 加密密钥ID
    createdAt: Date               // 创建时间
    
    // 关系
    story: StoryEntity?           // 所属故事（to-one）
}
```

**删除规则**：
- `story -> media`: Cascade（删除故事时级联删除媒体）
- `media -> story`: Nullify

## 三、业务模型（ViewModel层）

### 3.1 CategoryModel

```swift
struct CategoryModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var level: Int           // 1..3
    var parentId: UUID?
    var sortOrder: Int
    var createdAt: Date
}
```

### 3.2 CategoryTreeNode

```swift
struct CategoryTreeNode: Identifiable, Hashable {
    let id: UUID
    var category: CategoryModel
    var children: [CategoryTreeNode]
    var isExpanded: Bool
    var storyCount: Int      // 含子分类总数
}
```

用于分类树形展示：
- 递归构建树形结构
- `storyCount` 为该分类及所有子分类的故事总数
- `isExpanded` 控制列表模式下的展开/收起状态

## 四、数据访问层设计

### 4.1 CategoryService 协议

```swift
protocol CategoryService {
    // 查询
    func fetchTree() -> [CategoryTreeNode]
    func fetchCategory(id: UUID) -> CategoryEntity?
    func fetchCategories(level: Int) -> [CategoryEntity]
    func fetchChildren(parentId: UUID) -> [CategoryEntity]
    
    // 增删改
    func addCategory(name: String, level: Int, parentId: UUID?, 
                    iconName: String, colorHex: String) throws
    func updateCategory(id: UUID, name: String, iconName: String, 
                       colorHex: String) throws
    func deleteCategory(id: UUID) throws
    
    // 统计
    func storyCount(for id: UUID) -> Int
    func totalStoryCount(for id: UUID) -> Int  // 含子分类
}
```

### 4.2 CoreDataCategoryService 实现

基于 `NSManagedObjectContext` 实现真实的 Core Data 操作：

```swift
class CoreDataCategoryService: CategoryService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // 实现所有协议方法...
}
```

## 五、TimelineView 与分类的关系

### 5.1 使用场景

```
用户导航路径：
分类Tab -> CategoryView（卡片/列表模式）
    -> 点击"大宝故事"（Level 3分类）
        -> CategoryStoryListView（显示该分类下的所有故事）
            -> 点击某个故事
                -> FullScreenStoryView（全屏查看）
```

### 5.2 数据过滤

```swift
// CategoryStoryListView 初始化时，根据分类ID过滤故事
init(category: CategoryTreeNode) {
    self.category = category
    
    // 构建 FetchRequest，过滤出该分类及其子分类的所有故事
    let predicate = NSPredicate(
        format: "ANY categories.id IN %@", 
        collectCategoryIds(category)
    )
    
    _stories = FetchRequest<StoryEntity>(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.timestamp, ascending: false)],
        predicate: predicate,
        animation: .default
    )
}

// 递归收集分类及其所有子分类的ID
func collectCategoryIds(_ node: CategoryTreeNode) -> [UUID] {
    var ids = [node.id]
    for child in node.children {
        ids.append(contentsOf: collectCategoryIds(child))
    }
    return ids
}
```

### 5.3 TimelineView 的角色

- **主时间轴**：显示所有故事（不过滤分类）
- **分类时间轴**：`CategoryStoryListView` 显示特定分类下的故事
- 两者使用相同的 `StoryCardView` 组件展示故事卡片

## 六、分类选择器设计

### 6.1 在故事编辑器中选择分类

```swift
struct CategorySelectorView: View {
    @Binding var selectedCategories: Set<UUID>
    @FetchRequest var allCategories: FetchedResults<CategoryEntity>
    
    var body: some View {
        NavigationView {
            List {
                // 展示三级分类树
                // 支持多选
                // 显示当前选中状态
            }
        }
    }
}
```

### 6.2 推荐的分类选择策略

1. **优先选择第三级分类**（故事线）
   - 如："生活 > 育儿 > 大宝故事"
   
2. **支持多个第三级分类**
   - 一个故事可以同时属于"大宝故事"和"家庭活动"

3. **面包屑导航**
   - 显示完整路径："生活 > 育儿 > 大宝故事"

## 七、数据迁移与版本管理

### 7.1 Core Data 版本策略

- 使用轻量级迁移（Lightweight Migration）
- 每次模型变更创建新版本
- 迁移前自动备份数据库

### 7.2 索引优化

为提高查询性能，建议为以下字段添加索引：

**CategoryEntity**:
- `level` (用于按层级查询)
- `sortOrder` (用于排序)

**StoryEntity**:
- `timestamp` (用于时间排序)
- `locationCity` (用于位置搜索)
- `isDeleted` (用于过滤已删除项)

## 八、最佳实践

### 8.1 创建分类示例

```swift
// Level 1: 生活
let life = try service.addCategory(
    name: "生活", 
    level: 1, 
    parentId: nil,
    iconName: "house.fill",
    colorHex: "#34C759"
)

// Level 2: 育儿
let parenting = try service.addCategory(
    name: "育儿",
    level: 2,
    parentId: life.id,
    iconName: "figure.2.and.child.holdinghands",
    colorHex: "#FF9F0A"
)

// Level 3: 大宝故事（故事线）
let babyStories = try service.addCategory(
    name: "大宝故事",
    level: 3,
    parentId: parenting.id,
    iconName: "sparkles",
    colorHex: "#FF375F"
)
```

### 8.2 创建故事并关联分类

```swift
let story = StoryEntity(context: context)
story.id = UUID()
story.title = "第一次叫妈妈"
story.content = "今天宝宝第一次清晰地叫出了妈妈..."
story.timestamp = Date()

// 关联到"大宝故事"分类
story.addToCategories(babyStories)

try context.save()
```

## 九、常见问题

### Q1: 为什么第三级分类是故事线？

A: 设计上，第三级分类足够具体，代表一个主题下的连续故事集合。例如"大宝故事"记录了关于大宝的所有成长瞬间，这些故事按时间排列形成时间轴。

### Q2: 一个故事可以属于多个分类吗？

A: 可以。通过多对多关系，一个故事可以同时属于多个分类。例如"第一次叫妈妈"可以同时属于"大宝故事"和"家庭纪念日"。

### Q3: 如何处理分类删除时的故事？

A: 删除分类时，不会删除故事本身，只是解除关联关系（Nullify）。故事仍然存在，可以重新分配到其他分类。

### Q4: 分类数量限制的原因？

A: 限制数量是为了保持UI简洁、提高性能，并鼓励用户合理规划分类结构。实际使用中，这些限制已经足够覆盖大多数场景。

---

**文档版本**: 1.0  
**最后更新**: 2025-11-29  
**维护者**: MyStory开发团队

