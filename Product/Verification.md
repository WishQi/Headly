# Headly 轻记验证记录

验证日期：2026 年 10 月 3 日。此记录确认 PRD 与产品原型的交付质量，正式 App 发布检查仍需按 PRD 完成。

## 结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 实际 Swift 数据模型 | 29 项通过 | [模型日志](../output/verification/model-checks.log) |
| HTML 原型 DOM 集成 | 23 项通过 | [交互日志](../output/verification/browser-checks.log) |
| 原生 iOS 模拟器构建 | BUILD SUCCEEDED | [原型构建](../output/verification/native-build.log)、[图标更新构建](../output/verification/icon/native-build.log) |
| 原生真实启动与界面 | 今日、回顾、记录浮层已检查 | [今日](screens/ios-today.png)、[回顾](screens/ios-review.png)、[记录](screens/ios-record.png) |
| Chrome 实际交互 | 新增、刷新保留、结束、编辑、回顾已体验 | [浏览器界面](Preview.png) |
| 小屏布局 | 375 × 812、393 × 852，无横向溢出 | [最终页面截图](screens/) |
| 文档视觉检查 | 14 页 PDF 已逐页渲染检查 | [PRD PDF](../output/pdf/Headly-PRD.pdf) |
| 本地与登录边界 | 无账号流程、网络接口、CloudKit 或推送 | Swift 源码、HTML、Info.plist 与 entitlements 检查 |
| 文件一致性 | 验证后核心代码未变更，PDF 最终排版独立复核 | [文件清单](../output/verification/final-manifest.json) |

## 验证范围

Swift 检查直接编译 HeadacheRecord.swift 中的真实数据模型与存储实现。覆盖保存后重载与 ID 保留、单条进行中限制、已结束的过去记录、结束时长、编辑、删除与清空持久化、跨日和跨月边界、午夜结束的半开区间、同日去重、平均强度和时长、因素去重、空数据、演示不覆盖、中文 CSV / BOM / 引号 / 换行 / 公式前缀、未来时间、非法结束时间、备注长度、损坏文件与未知版本保护、写入失败不改变内存。

DOM 集成检查在独立 jsdom 内存环境执行原型 JavaScript，覆盖新增、编辑、结束、删除与清空确认、重新加载、日历及列表、强度必选、日期校验、导出、明确加载演示、储存容量错误保留草稿、损坏数据保留原字节，以及两个窗口编辑冲突提示。不操作用户浏览器的既有数据。23 项是 DOM 集成结果，不等同于原生 UI 自动化测试。

Chrome 中实际点击记录流程，刷新后记录仍在，再结束并修改部位，在回顾查看记录。交付截图使用明确标记的虚构演示数据。393 宽度下强度按钮为约 63 × 44，保存按钮为 349 × 52，默认记录浮层的保存操作在可见范围内；展开可选细节后可滚动。375 和 393 宽度的页面内容宽度与视口一致。

主要颜色对比度计算：墨绿按钮与暖白文字约 12.16:1，正文与背景约 10.94:1，辅助文字 #616E66 与背景约 4.89:1。这些数值不能代替完整辅助功能体验检查。

原生构建使用 Xcode 26.6、iOS 26.5 Simulator、Debug、关闭签名的 QA bundle `com.maoqi.Headly.ProductPrototypeQA`。界面检查在独立的「Headly Product QA」iPhone 17 模拟器进行；没有覆盖用户 App 的数据。最低部署目标为 iOS 17。

PDF 使用 ReportLab 生成，pypdfium2 渲染为页面 PNG 后检查。最终修正了界面图缩放导致的裁切；三张界面截图、表格、中文段落、分页和页码均已复核。完整源稿为 Product/PRD.md，包含 16 个章节及 A01–A22 验收条件。

## 尚未完成的发布检查

- iOS 17 真机及目标机型适配，断网和卸载行为的真机复测。
- 最大动态字号、完整 VoiceOver 顺序、粗体文字、高对比度及色觉差异设备体验。
- 大数据量性能、文件迁移、系统备份排除的实机验证和导出临时文件生命周期。
- App Store 隐私申报、中文健康提示的专业审核与目标地区适用性。
- 数据导入、Face ID、暗色主题和自动恢复属于后续版本，当前原型未实现。

性能数字在 PRD 中标明为发布前目标，未作为已测量结果报告。原生与浏览器各自保存数据，未实现互通。

## 工作区保护与复现

后续图标设计已完成：使用 ImageGen 生成圆润 h 标记，输出 1024 × 1024 RGB 不透明 PNG，接入 AppIcon，60 px 与 29 px 的实际缩小图已检查。图标更新后的模拟器构建再次通过；应用逻辑与浏览器原型未改动。旧图标保留于 Product/Icon/archive/，设计和提示词见 [图标说明](Icon/README.md)。文件清单已更新为此版本。

新 PRD 位于 Product/。用户已授权将产品原型、图标与交付资料提交至独立远端分支；开始前已有的 docs/PRD.md 删除改动保留在本地工作区。尚未发布网站或 App，没有云端文档写入。

复现命令和启动方式见 [交付说明](README.md)。完整检查点及逐页 PDF 渲染位于 `/Users/maoqi/.codex/long-tasks/headly-product-20261003/`；原始验证输入哈希保存于 `evidence/inputs-before.json`。最终交付哈希单独保存在文件清单，避免把后续文档排版修正错误地算作应用代码变更。
