## MyStory 点对点迁移（方案 5）设计说明

### 1. 设计目标

- **场景**：用户更换新手机时，不经过服务器，仅通过两台设备直连完成数据迁移。
- **迁移内容**：
  - Core Data 中所有实体：`CategoryEntity`、`StoryEntity`、`MediaEntity`、`SettingEntity` 等。
  - 所有本地媒体文件：图片、视频及缩略图（由 `MediaStorageService` 管理）。
  - 媒体加密主密钥：Keychain 中的 `MyStory.MasterKey`。
- **关键要求**：
  - **安全**：端到端加密、身份确认、备份包二次加密。
  - **完整性**：哈希校验、分片校验、原子恢复和可选回滚。
  - **体验**：流程简单、操作引导清晰、支持中断恢复。

---

### 2. 模块划分

#### 2.1 角色

- **发送端（旧手机 / Source Device）**
  - 负责：
    - 与接收端建立 P2P 连接。
    - 生成本机快照（Core Data + 媒体 + MasterKey）。
    - 分片发送加密备份包。

- **接收端（新手机 / Target Device）**
  - 负责：
    - 建立连接并验证对端身份。
    - 接收并校验备份包。
    - 清空本地旧数据并恢复新数据。

#### 2.2 逻辑模块

- **`MigrationSessionManager`**
  - 职责：
    - 基于 `MultipeerConnectivity` 建立/管理会话。
    - 处理设备发现、连接、断线、重连等状态。
    - 负责控制消息、数据分片消息的发送与接收。

- **`MigrationBackupService`**
  - 职责：
    - 暂停写入或创建只读快照。
    - 导出 Core Data 实体数据为 JSON。
    - 收集媒体文件并计算哈希。
    - 导出 Keychain 中的 `MyStory.MasterKey`。
    - 生成备份目录结构与 `manifest.json`。
    - 压缩并加密备份包。

- **`MigrationRestoreService`**
  - 职责：
    - 接收并落地加密备份包。
    - 校验哈希并解密/解压。
    - 清空现有数据，并恢复 MasterKey、媒体文件和 Core Data 数据。
    - 保证恢复过程的原子性和可选回滚。

- **`MigrationCryptoService`**
  - 职责：
    - 基于用户设置的“迁移密码”派生对称密钥。
    - 使用 AES-GCM 对备份包进行加/解密。

- **`MigrationUIFlowController`**
  - 职责：
    - 引导用户选择角色（旧手机/新手机）。
    - 承载 PIN/验证码验证流程。
    - 展示迁移进度、错误状态和重试操作。

---

### 3. 通讯层与应用协议

#### 3.1 通讯技术

- **首选**：`MultipeerConnectivity` 框架。
  - 自动利用蓝牙、P2P Wi‑Fi、局域网等通道。
  - 自带 TLS 加密通道，可视为安全管道。
- 角色映射：
  - 发送端：`MCNearbyServiceAdvertiser`（广播服务）。
  - 接收端：`MCNearbyServiceBrowser`（发现并连接）。

#### 3.2 身份确认与 PIN 验证

- 连接建立后应用层执行二次身份确认：
  - **新手机生成 6 位随机 PIN**，显示在界面上。
  - 旧手机由用户手动输入该 PIN，发送给新手机。
  - 新手机校验通过后，才允许进入备份/传输阶段。

#### 3.3 应用层消息协议

- 所有控制消息统一为 JSON：
  - 外层结构：
    ```json
    {
      "type": "MessageType",
      "payload": { ... }
    }
    ```

- **控制消息类型示例**：
  - `Handshake`
    - 发送：App 版本、schema 版本、设备信息、会话 ID 等。
  - `AuthPIN`
    - 发送：PIN 验证请求和结果。
  - `StartBackup`
    - 发送端通知即将开始生成备份。
  - `BackupMeta`
    - 发送端发送备份元数据（大小、分片大小、schema 版本等）。
  - `StartTransfer` / `PauseTransfer` / `ResumeTransfer` / `CancelTransfer`
    - 控制传输状态。
  - `ChunkAck`
    - 接收端对分片的确认或重传请求。
  - `Complete`
    - 发送端声明所有分片发送完毕。

- **数据消息类型**：
  - `BackupChunk`
    - 携带二进制分片数据及分片元信息（分片编号、偏移、长度、分片哈希等）。

---

### 4. 备份包目录结构 Schema

#### 4.1 顶层结构

备份过程在发送端生成如下目录（未加密前）：

```text
Backup-{backupId}/
├── manifest.json
├── coredata/
│   ├── categories.json
│   ├── stories.json
│   ├── media.json
│   ├── settings.json
│   └── relations_story_categories.json
├── media/
│   ├── Images/
│   │   ├── YYYY/
│   │   │   ├── MM/
│   │   │   │   └── *.heic / *.jpg（加密文件原样拷贝）
│   └── Videos/
│       ├── YYYY/
│       │   ├── MM/
│       │   │   └── *.mov / 缩略图（加密文件原样拷贝）
└── security/
    └── master_key.bin
```

随后：

1. 将 `Backup-{backupId}/` 压缩为 `backup-{backupId}.zip`。
2. 使用迁移密码派生密钥，对 `backup-{backupId}.zip` 做 AES-GCM 加密，得到最终传输文件：

```text
backup-{backupId}.enc
```

#### 4.2 文件说明

- **`manifest.json`**
  - 备份元数据和完整性信息，详细字段见第 5 节。

- **`coredata/`**
  - 存放各实体导出的 JSON 数据和关系表：
    - `categories.json`：`CategoryEntity` 实例列表。
    - `stories.json`：`StoryEntity` 实例列表。
    - `media.json`：`MediaEntity` 实例列表。
    - `settings.json`：`SettingEntity` 实例列表。
    - `relations_story_categories.json`：Story ↔ Category 多对多关系表。

- **`media/`**
  - 按现有 `MediaStorageService` 目录结构（`Documents/Media/Images/YYYY/MM`，`Documents/Media/Videos/YYYY/MM`）原样复制加密文件。
  - 恢复时按相同结构写回。

- **`security/master_key.bin`**
  - 存放 Keychain 中的 `MyStory.MasterKey` 原始二进制数据。
  - 该文件本身属于 `backup.zip` 的一部分，且外层还有迁移密码加密。

---

### 5. `manifest.json` Schema 设计

#### 5.1 顶层结构

```json
{
  "backupId": "string",
  "appVersion": "string",
  "schemaVersion": 1,
  "createdAt": 1736240000,
  "entityStats": {
    "CategoryEntity": { "count": 0 },
    "StoryEntity": { "count": 0 },
    "MediaEntity": { "count": 0 },
    "SettingEntity": { "count": 0 }
  },
  "mediaStats": {
    "totalFiles": 0,
    "totalBytes": 0
  },
  "integrity": {
    "zipSize": 0,
    "zipSHA256": "hex-string",
    "hashAlgorithm": "SHA256"
  },
  "options": {
    "hasBrokenMedia": false,
    "brokenMediaCount": 0
  },
  "brokenMedia": [
    {
      "mediaId": "string",
      "fileName": "string",
      "reason": "FILE_NOT_FOUND"
    }
  ]
}
```

#### 5.2 字段说明

- **`backupId: string`**
  - 备份唯一标识，建议为 UUID 字符串。

- **`appVersion: string`**
  - 生成备份的 App 版本号，如 `"1.2.0"`。

- **`schemaVersion: number`**
  - 自定义数据 schema 版本，随 Core Data 模型演进而递增。
  - 用于接收端判定是否需要升级 App 才能恢复。

- **`createdAt: number`**
  - 备份创建时间，Unix 时间戳（秒）。

- **`entityStats: object`**
  - 各实体统计信息，键为实体名：
    - `CategoryEntity.count: number`：分类数量。
    - `StoryEntity.count: number`：故事数量。
    - `MediaEntity.count: number`：媒体记录数量。
    - `SettingEntity.count: number`：设置条目数量。

- **`mediaStats: object`**
  - 媒体文件整体统计：
    - `totalFiles: number`：媒体文件总数（图片 + 视频 + 缩略图）。
    - `totalBytes: number`：媒体文件总字节数（加密后）。

- **`integrity: object`**
  - 用于完整性校验的参数：
    - `zipSize: number`：`backup-{backupId}.zip` 的文件大小（字节）。
    - `zipSHA256: string`：`backup-{backupId}.zip` 的 SHA-256 哈希（十六进制字符串）。
    - `hashAlgorithm: string`：当前使用的哈希算法，默认为 `"SHA256"`。

- **`options: object`**
  - 一些可选标记位：
    - `hasBrokenMedia: boolean`：导出时是否存在缺失媒体文件。
    - `brokenMediaCount: number`：缺失媒体文件数量。

- **`brokenMedia: array`**
  - 记录导出时发现的异常媒体记录（可选）：
    - `mediaId: string`：`MediaEntity.id`。
    - `fileName: string`：`MediaEntity.fileName`。
    - `reason: string`：例如 `"FILE_NOT_FOUND"`、`"READ_ERROR"` 等。

---

### 6. Core Data JSON 导出 Schema

#### 6.1 `coredata/categories.json`

- **类型**：JSON 数组。
- 每个元素对应一个 `CategoryEntity`。

**单条记录示例：**

```json
{
  "id": "UUID-string",
  "name": "string",
  "nameEn": "string or null",
  "colorHex": "string",          
  "level": 1,
  "parentId": "UUID-string or null",
  "iconName": "string",
  "iconType": "string",          
  "customIconData": "base64-string or null",
  "sortOrder": 0,
  "createdAt": 1736240000         
}
```

**字段说明（与 Core Data 模型对应）：**

- `id: string`：`UUID` 字符串，对应实体唯一约束。
- `name: string`：分类名称（本地语言）。
- `nameEn: string | null`：分类英文名称，可选。
- `colorHex: string`：颜色十六进制，如 `"#007AFF"`。
- `level: number`：层级深度（1 为顶级）。
- `parentId: string | null`：父分类 `id`，顶级分类为 `null`。
- `iconName: string`：图标名称（系统图标或资源名称）。
- `iconType: string`：图标类型，例如 `"system"` / `"custom"`。
- `customIconData: string | null`：自定义图标的二进制数据 Base64 编码。
- `sortOrder: number`：排序用字段。
- `createdAt: number`：创建时间，Unix 时间戳（秒）。

导入流程建议：

1. 第一轮：仅插入 Category，不设置 parent。
2. 第二轮：根据 `parentId` 设置 parent/children 关系（可按 `level` 升序处理）。

#### 6.2 `coredata/stories.json`

- **类型**：JSON 数组。
- 每个元素对应一个 `StoryEntity`。

**单条记录示例：**

```json
{
  "id": "UUID-string",
  "title": "string or null",
  "content": "string or null",          
  "plainTextContent": "string or null", 
  "createdAt": 1736240000,
  "updatedAt": 1736241234,
  "timestamp": 1736240000,
  "isDeleted": false,
  "syncStatus": 0,
  "mood": "string or null",
  "locationName": "string or null",
  "locationAddress": "string or null",
  "locationCity": "string or null",
  "latitude": 0.0,
  "longitude": 0.0,
  "horizontalAccuracy": -1.0,
  "verticalAccuracy": -1.0
}
```

**字段说明（与 Core Data 属性对应）：**

- `id: string`：`UUID` 字符串，唯一标识。
- `title: string | null`：标题。
- `content: string | null`：富文本或 Markdown 内容（原始内容）。
- `plainTextContent: string | null`：纯文本内容，用于搜索/索引。
- `createdAt: number`：创建时间戳。
- `updatedAt: number`：最近更新时间戳。
- `timestamp: number`：故事发生时间，可与创建时间不同。
- `isDeleted: boolean`：软删除标记。
- `syncStatus: number`：同步状态（本地使用），迁移后可复位或保留。
- `mood: string | null`：心情描述/编码。
- `locationName/locationAddress/locationCity: string | null`：位置信息。
- `latitude/longitude: number`：地理坐标。
- `horizontalAccuracy/verticalAccuracy: number`：定位精度，未测量时可能为 `-1`。

#### 6.3 `coredata/media.json`

- **类型**：JSON 数组。
- 每个元素对应一个 `MediaEntity`。

**单条记录示例：**

```json
{
  "id": "UUID-string",
  "type": "image",                
  "fileName": "string",          
  "thumbnailFileName": "string or null",
  "encryptionKeyId": "string",   
  "fileSize": 0,                  
  "width": 0,                     
  "height": 0,                    
  "duration": 0.0,                
  "createdAt": 1736240000,
  "storyId": "UUID-string or null"
}
```

**字段说明：**

- `id: string`：`UUID` 字符串，唯一标识。
- `type: string`：媒体类型，当前 `MediaEntity.type` 中存储的字符串（如 `"image"` / `"video"`）。
- `fileName: string`：主媒体文件名，例如 `"{uuid}.heic"` / `"{uuid}.mov"`。
- `thumbnailFileName: string | null`：缩略图文件名，例如 `"{uuid}_thumb.heic"` / `"{uuid}_thumb.jpg"`。
- `encryptionKeyId: string`：用于派生媒体对称密钥的 `keyId`（与 `KeyManager.key(for:)` 一致）。
- `fileSize: number`：文件大小（字节，密文大小）。
- `width/height: number`：图像或视频的分辨率（可为空时设为 0）。
- `duration: number`：视频时长（秒，非视频可为 0）。
- `createdAt: number`：媒体创建时间戳。
- `storyId: string | null`：关联的 `StoryEntity.id`，无关联时为 `null`。

#### 6.4 `coredata/settings.json`

- **类型**：JSON 数组。
- 每个元素对应一个 `SettingEntity`。

**单条记录示例：**

```json
{
  "key": "string",
  "type": "string",
  "value": "string",
  "updatedAt": 1736240000
}
```

**字段说明：**

- `key: string`：设置键，唯一约束。
- `type: string`：值类型标识（例如 `"bool"`、`"int"`、`"string"`、`"json"` 等）。
- `value: string`：实际值的字符串形式。
- `updatedAt: number`：更新时间戳。

#### 6.5 `coredata/relations_story_categories.json`

- **类型**：JSON 数组。
- 每个元素表示 Story 与 Category 的一次关联。

**单条记录示例：**

```json
{
  "storyId": "UUID-string",
  "categoryId": "UUID-string"
}
```

导入时：

1. 确保 `stories.json` 和 `categories.json` 已全部导入。
2. 使用 `storyId` 和 `categoryId` 从 Core Data 查找对应对象并建立多对多关系。

---

### 7. 端到端迁移流程（概要）

#### 7.1 用户流程

- **接收端（新手机）**：
  1. 打开 App → 设置 → 数据迁移 → 选择“我是新手机”。
  2. 显示等待配对界面，并生成并展示 6 位 PIN。

- **发送端（旧手机）**：
  1. 打开 App → 设置 → 数据迁移 → 选择“我是旧手机”。
  2. 通过扫码或设备列表选择新手机。
  3. 输入新手机展示的 PIN 并确认。
  4. 设置/确认迁移密码。
  5. 点击“开始迁移”。

#### 7.2 发送端内部步骤

1. `MigrationSessionManager` 完成 P2P 会话与 PIN 验证。
2. `MigrationBackupService`：
   - 暂停写操作或开启只读快照。
   - 导出 Core Data 为 JSON（写入 `coredata/`）。
   - 遍历 `Documents/Media` 下所有媒体文件，复制到 `media/` 并计算哈希。
   - 导出 `MyStory.MasterKey` 到 `security/master_key.bin`。
   - 构建 `manifest.json`，写入统计与完整性信息。
   - 压缩为 `backup-{backupId}.zip`，计算 `zipSHA256`。
   - 使用迁移密码经 `MigrationCryptoService` 加密生成 `backup-{backupId}.enc`。
3. 通过 `MigrationSessionManager` 发送 `BackupMeta` 给接收端。
4. 按分片发送加密备份包，每片发送后等待 ACK，支持重试和暂停/恢复。

#### 7.3 接收端内部步骤

1. `MigrationSessionManager` 完成连接与 PIN 验证。
2. 接收 `BackupMeta`，评估磁盘空间与 schema 兼容性，提示用户确认清空本机数据。
3. 接收所有分片，写入临时文件 `backup-{backupId}.enc.tmp`，对每个分片进行哈希校验。
4. 收完后计算整文件哈希，与 `manifest.integrity.zipSHA256` 对比。
5. 用户输入迁移密码，通过 `MigrationCryptoService` 解密：
   - 生成 `backup-{backupId}.zip`。
6. 解压至临时目录 `Restore-{backupId}/`，读取并校验 `manifest.json` 与目录完整性。
7. `MigrationRestoreService` 执行恢复：
   - （可选）备份当前本地数据到 `BackupBeforeMigration/`。
   - 删除现有 Core Data store 和媒体目录。
   - 恢复 `security/master_key.bin` 到 Keychain。
   - 拷贝 `media/` 目录到 `Documents/Media` 并校验哈希。
   - 按顺序导入 `coredata/` 下 JSON：Settings → Categories（两轮）→ Stories → Media → Relations。
   - 迁移成功后，清理临时目录及旧数据备份（或保留一段时间）。

---

### 8. 安全与完整性要点总结

- **安全性**：
  - 传输层：`MultipeerConnectivity` 提供 TLS 级别加密。
  - 应用层：备份包使用用户迁移密码派生密钥进行 AES-GCM 加密。
  - MasterKey：只存在于加密的备份包中，恢复后写入 Keychain。
  - 身份验证：PIN 验证确保连接的是正确设备。

- **完整性**：
  - 备份生成时使用只读快照，避免导出期间数据变化。
  - 分片层级的 `chunkSHA256` 校验 + 整包 `zipSHA256` 校验。
  - 恢复时如有任何一步校验失败，应终止并（可选）回滚到迁移前状态。

- **用户体验**：
  - 全程有进度条和剩余时间估计。
  - 支持暂停/恢复和断线重连。
  - 对密码错误和版本不兼容提供明确提示和引导。

