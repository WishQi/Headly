# Headly 轻记验证记录

验证日期：2026 年 10 月 3 日。本记录包含 PRD 交付及合入 main 后的代码审查结果。模型、DOM 与构建日志已更新为清理后的源码；先前界面和 PDF 的视觉检查单独保留，正式 App 发布检查仍需按 PRD 完成。

## 结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 实际 Swift 数据模型与草稿 | 38 项通过 | [模型日志](../output/verification/model-checks.log) |
| HTML 原型 DOM 集成 | 33 项通过 | [交互日志](../output/verification/browser-checks.log) |
| 原生 iOS 模拟器构建 | 清理后的 Debug 构建 BUILD SUCCEEDED | [当前构建](../output/verification/native-build.log) |
| 当前原生安装与启动 | 独立 QA 进程启动及演示文件读取通过；本次点击复测受阻 | [启动记录](../output/verification/code-review/native-startup.json)、[待复测项](Code-Review.md) |
| 原生界面设计（先前交付） | 今日、回顾、记录浮层已检查 | [今日](screens/ios-today.png)、[回顾](screens/ios-review.png)、[记录](screens/ios-record.png) |
| Chrome 实际交互 | 清理后新增、刷新保留、编辑、取消放弃、结束与回顾通过 | [本次测试数据截图](../output/verification/code-review/browser-review.png) |
| 小屏布局（先前交付） | 375 × 812、393 × 852，无横向溢出 | [最终页面截图](screens/) |
| 文档视觉检查（先前交付） | 14 页 PDF 已逐页渲染检查 | [PRD PDF](../output/pdf/Headly-PRD.pdf) |
| 本地与登录边界 | 无账号流程、网络接口、CloudKit 或推送 | Swift 源码、HTML、Info.plist 与 entitlements 检查 |
| 文件一致性 | 各项检查的相关源码哈希一致，PDF 保留先前视觉检查结果 | [文件清单](../output/verification/final-manifest.json) |

## 验证范围

Swift 检查直接编译 HeadacheRecord.swift 和 RecordDraft.swift 中的真实数据模型、存储与草稿实现。覆盖保存后重载与 ID 保留、单条进行中限制、已结束的过去记录、结束时长、编辑、删除与清空持久化、跨日和跨月边界、午夜结束的半开区间、同日去重、平均强度和时长、因素去重、空数据、演示不覆盖、中文 CSV / BOM / 引号 / 换行 / 公式前缀、未来时间、非法结束时间、备注长度、损坏文件与未知版本保护、写入失败不改变内存。新增 9 项检查覆盖草稿初始化、修改比较、恢复原值、隐藏结束时间、编辑时的身份保留，以及夏令时补记和演示时间。

DOM 集成检查在独立 jsdom 内存环境执行原型 JavaScript，覆盖新增、编辑、结束、删除与清空确认、重新加载、日历及列表、强度必选、日期校验、导出、明确加载演示、储存容量错误保留草稿、损坏数据保留原字节，以及两个窗口编辑冲突提示。不操作用户浏览器的既有数据。新增 10 项检查覆盖演示确认期间新增记录、事件延迟时的保存与编辑冲突、详情外部删除、clear() 事件、清空与删除确认期间更新，以及确认框重绘后的交互和辅助功能状态。33 项是 DOM 集成结果，不等同于原生 UI 自动化测试。

先前交付时在 Chrome 中实际点击记录流程，刷新后记录仍在，再结束并修改部位，在回顾查看记录。设计截图使用明确标记的虚构演示数据；本次回归截图使用隔离存储来源中的手动测试记录。393 宽度下强度按钮为约 63 × 44，保存按钮为 349 × 52，默认记录浮层的保存操作在可见范围内；展开可选细节后可滚动。375 和 393 宽度的页面内容宽度与视口一致。

主要颜色对比度计算：墨绿按钮与暖白文字约 12.16:1，正文与背景约 10.94:1，辅助文字 #616E66 与背景约 4.89:1。这些数值不能代替完整辅助功能体验检查。

本次原生构建使用 Xcode 26.6、iOS 26.5 Simulator、Debug、关闭签名的独立 QA bundle `com.maoqi.Headly.CodeReviewQA`。安装和启动在「Headly Product QA」iPhone 17 模拟器完成，没有覆盖用户 App 的数据。最低部署目标为 iOS 17。先前界面截图使用 `com.maoqi.Headly.ProductPrototypeQA`；当前控制工具返回过期菜单且无法截图，本次原生详情转编辑、保存和放弃操作尚未实际点击复测。

PDF 使用 ReportLab 生成，pypdfium2 渲染为页面 PNG 后检查。最终修正了界面图缩放导致的裁切；三张界面截图、表格、中文段落、分页和页码均已复核。完整源稿为 Product/PRD.md，包含 16 个章节及 A01–A22 验收条件。

## 尚未完成的发布检查

- iOS 17 真机及目标机型适配，断网和卸载行为的真机复测。
- 最大动态字号、完整 VoiceOver 顺序、粗体文字、高对比度及色觉差异设备体验。
- 大数据量性能、文件迁移、系统备份排除的实机验证和导出临时文件生命周期。
- App Store 隐私申报、中文健康提示的专业审核与目标地区适用性。
- 数据导入、Face ID、暗色主题和自动恢复属于后续版本，当前原型未实现。

性能数字在 PRD 中标明为发布前目标，未作为已测量结果报告。原生与浏览器各自保存数据，未实现互通。

## 工作区保护与复现

先前图标设计使用 ImageGen 生成圆润 h 标记，输出 1024 × 1024 RGB 不透明 PNG，接入 AppIcon，60 px 与 29 px 的实际缩小图已检查。图标更新后的模拟器构建通过。旧图标保留于 Product/Icon/archive/，设计和提示词见 [图标说明](Icon/README.md)；本次审查继续使用该图标。

新 PRD 位于 Product/，产品原型、图标与交付资料已合入 main。本次代码清理使用独立分支 `codex/headly-code-cleanup`；开始前已有的 docs/PRD.md 删除改动保留在本地工作区。尚未发布网站或 App，没有云端文档写入。

复现命令和启动方式见 [交付说明](README.md)。完整检查点及逐页 PDF 渲染位于 `/Users/maoqi/.codex/long-tasks/headly-product-20261003/`；原始验证输入哈希保存于 `evidence/inputs-before.json`。当前代码审查检查点位于 `/Users/maoqi/.codex/long-tasks/headly-code-review-20261003/STATE.md`，相关检查分别绑定模型、浏览器和最终构建的输入快照。当前交付哈希保存在文件清单；先前 PDF 和图标检查按历史证据列出。
