# 健康同步 v1 方案

2026-10-14 · Duncan

## v1 范围

v1 只做一件事：把 Apple 健康数据自动、增量、可靠地 POST 到用户填写的 Webhook，免费、开源、上中国区 App Store。这对应 Health Webhook 的全部功能和 Health Auto Export（下称 HAE）付费版里「REST API 自动导出」这一项；HAE 其余功能放 v2+。

**做：**

- 多个 Webhook 地址，每个可设自定义 Header（如 `Authorization: Bearer xxx`），可单独启停
- 勾选要同步的数据类型（v1 约 20 种，睡眠优先）
- 三种触发：HealthKit 后台推送、手动「立即同步」、快捷指令动作「同步健康数据」
- 历史回填：选日期范围，分批上传
- 失败指数退避重试；服务端返回 2xx 才推进进度
- 同步日志：时间、结果、条数、状态码
- 仓库内附一个最小接收端（FastAPI + SQLite），部署到你的 ECS

**不做（v1）：** MQTT、Home Assistant、iCloud Drive 文件导出、CSV/GPX、小组件、日历、内置 TCP 服务器、Mac 端、运动轨迹、ECG、账号体系、任何云端中转。Google Drive / Dropbox 已永久砍掉。

**成功标准：** iPhone（iOS 26）+ Apple Watch 连续 7 天不打开 App，每天早上起床解锁后 1 小时内，前一晚睡眠数据已到服务器，无重复、无丢失；中国区上架。

## 功能对照

| 功能 | 来自 | 版本 |
| --- | --- | --- |
| JSON POST 到多个 URL，新数据到达即推 | Health Webhook / HAE | v1 |
| 手动同步 + 快捷指令「同步健康数据」 | 两者 | v1 |
| 指数退避重试 | Health Webhook | v1 |
| 同步日志（时间/状态/摘要） | Health Webhook | v1 |
| 健康指标 + 睡眠分期 + 运动摘要 | 两者 | v1 |
| 活动圆环（移动/锻炼/站立 + 目标） | Health Webhook | v1.1 |
| 运动 GPS 轨迹 | 两者 | v1.1 |
| 按分钟/小时/天聚合输出 | HAE | v2 |
| CSV / GPX 格式、一键导出文件 | HAE | v2 |
| ECG、情绪状态、用药、经期、心率提醒 | HAE | v2 |
| MQTT、Home Assistant、iCloud Drive、日历 | HAE | v2 |
| 桌面小组件 | HAE 免费版 | v2 |
| 内置 TCP 服务器、Mac 同步端 | HAE | v3 或不做 |
| Google Drive / Dropbox | HAE | 不做 |

## 技术架构

核心是「每个数据类型一个 HKAnchoredObjectQuery 锚点 + 只有上传成功才保存新锚点」，这一条决定了不重不漏。

**技术栈：** Swift 6 + SwiftUI，最低 iOS 17（自测用 iOS 26），无第三方依赖。State of Mind 等新类型用 `#available` 分支。

**模块：**

1. `HealthStore`：权限申请、类型清单、单位换算（公制，心率 count/min）。
2. `AnchorStore`：每个类型一个 `HKQueryAnchor`，NSKeyedArchiver 存到 App Group 容器。
3. `SyncEngine`（actor，串行）：读锚点 → 取新增 + 已删除样本 → 编码 → 发往所有启用的目标 → 全部 2xx 才写新锚点。同一时刻只跑一个同步。
4. `Destination` 协议：v1 只实现 `WebhookDestination`；以后 MQTT/HA/文件都是新的实现，引擎不用改。
5. `Uploader`：URLSession，单批最多 5000 条样本或 2 MB，超出分批；重试 3 次，间隔 2s/8s/30s；4xx 不重试。gzip 压缩可选，默认关。
6. `SyncLog`：SwiftData，保留最近 500 条。
7. 配置：Webhook 列表存 SwiftData，Header 里的密钥存 Keychain。

**触发方式：**

- 后台：对每个勾选类型 `enableBackgroundDelivery`（多数类型系统上限为每小时），在 App 启动时（`didFinishLaunching`）注册 `HKObserverQuery`，回调里跑增量同步并务必调用 completionHandler。加一个 `BGAppRefreshTask` 兜底。
- 手动：首页「立即同步」。
- 快捷指令：App Intents 提供「同步健康数据」，用户可配「每天 8:00」自动化。

**锁屏问题：** 手机锁屏时健康库加密不可读，读取会报 `errorDatabaseInaccessible`。引擎遇到这个错误直接跳过，不动锚点，等下次解锁后的触发。所以「起床解锁后 1 小时内到达」是合理目标，「睡着时实时到达」做不到。

**数据流向：** iPhone → 用户的 URL，中间无任何开发者服务器。你自己的接收端只是「你自己填的一个 URL」，和 App 本身无关。这对审核和隐私政策都最省事。

## Webhook 数据格式 v1

发原始样本、不做聚合，每条带 HealthKit UUID；接收端用 UUID 去重，重发也不会重复入库。时间一律 ISO 8601 带时区。

```json
{
  "schema": "healthsync.v1",
  "batch_id": "8E1F…",
  "device": { "model": "iPhone17,1", "os": "26.0", "app": "1.0.0" },
  "sent_at": "2026-10-15T07:42:10+08:00",
  "samples": [
    {
      "uuid": "A1B2…",
      "type": "heart_rate",
      "value": 62,
      "unit": "count/min",
      "start": "2026-10-15T03:10:00+08:00",
      "end": "2026-10-15T03:10:00+08:00",
      "source": { "name": "Duncan的Apple Watch", "bundle_id": "com.apple.health.…" },
      "metadata": {}
    },
    {
      "uuid": "C3D4…",
      "type": "sleep",
      "value": "asleep_deep",
      "start": "2026-10-15T01:20:00+08:00",
      "end": "2026-10-15T01:55:00+08:00",
      "source": { "name": "小米运动健康", "bundle_id": "…" }
    }
  ],
  "workouts": [
    { "uuid": "…", "activity": "running", "start": "…", "end": "…",
      "duration_s": 1820, "energy_kcal": 310, "distance_m": 5020, "source": {} }
  ],
  "deleted": [ { "uuid": "…", "type": "heart_rate" } ]
}
```

**v1 数据类型（20 种）：** 睡眠（含入床/浅/深/REM/清醒）、心率、静息心率、步行平均心率、HRV（SDNN）、血氧、呼吸频率、睡眠手腕温度、步数、步行+跑步距离、爬楼层数、活动能量、静息能量、锻炼时长、站立时长、体重、体脂率、血压（收缩/舒张）、最大摄氧量、运动（摘要，不含轨迹）。

保留 `source` 很重要：小米手环和 Apple Watch 都会写睡眠，去重/取优先级放在服务端做，App 不替用户选。

## 分阶段任务

共 6 个阶段，全部由 Claude Code 在 Mac 上开发，每个阶段一次会话，验收通过再进下一阶段。P0 的备案今天就该启动，它和开发并行，是上架的最长链路。

**P0 准备（Duncan 亲自做）**

- [ ] 定 App 名字和 Bundle ID（备案后改名要重新备案）
- [ ] GitHub 建仓库 a78c7/<repo>，MIT 协议
- [ ] Apple Developer 创建 App ID，勾选 HealthKit（含 Background Delivery）、App Groups
- [ ] 阿里云发起 App 备案（见「备案与上架」）

**P1 骨架 + 读数据**

- [ ] Xcode 工程、目录结构、SwiftLint、单元测试 target
- [ ] HealthKit 权限页，20 种类型可勾选
- [ ] 调试页：列出每种类型最近 24 小时条数
- 验收：真机上看到昨晚睡眠分期，和「健康」App 一致

**P2 Webhook + 手动同步**

- [ ] Webhook 增删改、自定义 Header、「发送测试请求」按钮
- [ ] JSON 编码器（按上一节格式）+ 编码单元测试
- [ ] 锚点增量 + 分批 + 重试，成功才存锚点
- [ ] 历史回填（选日期范围）
- 验收：用 webhook.site 收到数据；连按两次同步，第二次 0 条；断网同步失败后恢复网络再同步，数据完整

**P3 接收端（放同一仓库 /server）**

- [ ] FastAPI 单文件：`POST /ingest`，Bearer token 校验，原始 JSON 存档 + SQLite 按 uuid upsert，处理 deleted
- [ ] 部署到 ECS：api.a78c7.com/health/ingest，HTTPS，systemd
- [ ] 给 Claude 用的导出：`GET /export?from=&to=` 输出按天汇总的 CSV/Markdown（睡眠时长、各分期、静息心率、HRV）
- 验收：同一批数据发 3 次，库里不重复

**P4 后台同步 + 快捷指令 + 日志**

- [ ] Observer query + background delivery + BGAppRefreshTask
- [ ] App Intent「同步健康数据」
- [ ] 同步日志页；锁屏错误不计入失败
- 验收：「v1 范围」里的「连续 7 天不开 App」标准

**P5 打磨 + 上架**

- [ ] 中英双语、空状态、权限被拒的引导、App 图标
- [ ] 隐私政策页放 [www.a78c7.com](https://www.a78c7.com)
- [ ] TestFlight 自测 1 周 → 提审（中国区填备案号）
- [ ] README：功能、数据格式、接收端部署说明

## 备案与上架

备案在阿里云做，和 a78c7.com 用同一个个人主体，可以复用已审核的资料。流程是：填表 → 阿里云初审 → 工信部短信核验 → 管局审核 → 拿到备案号。

**备案要填的 iOS 特征信息：**

- Bundle ID（P0 定下的）
- 平台公钥和证书 SHA-1 指纹：用 Apple Distribution 证书，在 Mac「钥匙串访问」里双击证书即可看到
- 后台域名：App 没有自己的后台，填 a78c7.com（隐私政策页所在）
- 服务类型：建议选「工具」类，不要选医疗健康类（未核实：医疗类可能触发前置审批，提交前问阿里云备案客服）

**App Store 上架要点：**

- App Store Connect 中国大陆地区填入备案号，否则不能在中国区上架
- 隐私标签选「不收集数据」：数据只发到用户自己填的 URL，开发者不接触
- 健康数据不得用于广告、不得存 iCloud；App 内无广告、无统计 SDK
- 审核备注：说明用途、给一个可用的测试 Webhook 地址、附一段录屏
- 权限弹窗文案（NSHealthShareUsageDescription）写清数据去向

## 风险与限制

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| 后台推送时机由系统决定，不能「每 15 分钟」 | 用户会抱怨不及时 | 设置页写明；推荐加快捷指令定时自动化兜底 |
| 用户划掉 App、关闭后台 App 刷新、重启后未打开 | 后台同步停止 | 首页显示「最后成功同步时间」，超 24h 标红 |
| 历史回填数据量大（心率一年可达百万条） | 内存暴涨、请求超时 | 按 7 天窗口分段读，每批 ≤ 5000 条，只在前台运行 |
| 小米手环睡眠经 Mi Fitness 同步会延迟，且与 Apple Watch 重叠 | 睡眠数据重复或晚到 | 保留 source，服务端按来源优先级去重 |
| 审核以「功能太少 / 看不懂」拒审（4.2） | 上架延迟 | 审核备注 + 录屏 + 可用测试地址 |
| 备案被退回或归类需前置审批 | 中国区无法上架 | P0 就启动；先上其他地区不受影响 |
| 用户填 HTTP 明文地址 | ATS 拦截 | v1 只支持 HTTPS，局域网 HTTP 放 v2 |

## 待决定

- [ ] App 名字（中/英）和 Bundle ID
- [ ] 最低系统：iOS 17（覆盖广，建议）还是 iOS 26
- [ ] 是否加「HAE 兼容格式」开关（建议 v1.1）
- [ ] 接收端独立还是并入现有 life-log 服务
- [ ] 「给 Claude 分析」的方式：导出文件手动发，还是以后做成 MCP 服务
