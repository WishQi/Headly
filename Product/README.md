# Headly 轻记交付说明

本次交付包含完整 PRD、视觉规范、可交互浏览器原型，以及现有 Xcode 工程中的可运行 SwiftUI 原型。产品采用今日和回顾两个主页面，记录、详情和隐私操作以浮层完成。

## 交付文件

| 交付 | 位置 | 内容 |
| --- | --- | --- |
| PRD 源稿 | Product/PRD.md | 用户场景、功能、交互、字段、统计、隐私、验收与路线 |
| PRD PDF | output/pdf/Headly-PRD.pdf | 可分享的排版文档和核心界面图 |
| 交互原型 | Prototype/index.html | 零外部依赖的浏览器版，中文界面 |
| 原生原型 | Headly.xcodeproj 与 Headly/ | SwiftUI 界面、原子本地 JSON 存储 |
| 视觉规范 | Product/Design-Spec.md | 色彩、字体、组件与交互规则 |
| App 图标 | Product/Icon/Headly-AppIcon.png 与 Product/Icon/README.md | 1024 × 1024 图标、设计说明及生成提示词 |
| 界面预览 | Product/Preview.png 与 Product/screens/ | 三页概览及实际浏览器截图 |
| 验证说明 | Product/Verification.md | 检查范围、结果与发布前边界 |

## 打开浏览器原型

直接打开 Prototype/index.html 即可。为了保持稳定的存储来源，推荐在工作区执行：

```sh
python3 -m http.server 8769 --bind 127.0.0.1
```

访问 <http://localhost:8769/Prototype/>。localhost 与 127.0.0.1 是不同的浏览器存储来源，固定使用一种地址。原型不加载外部字体、图片、库或统计服务。开始为空白；右上角「记录与隐私」可在没有记录时加载演示数据。桌面画布也有演示按钮。

建议体验：记录此刻的头痛 → 选强度 → 保存 → 查看并结束；回顾 → 选过去日期 → 补记；任意记录 → 编辑或删除；右上角 → 导出 CSV。浏览器的虚构演示记录带明确标识，不覆盖现有记录。

## 运行原生 iOS 原型

用 Xcode 打开 Headly.xcodeproj，选择 Headly scheme 和 iPhone 模拟器运行。最低部署目标为 iOS 17；本次构建与界面检查使用 Xcode 26.6 及 iOS 26.5。真机运行需要配置自己的签名。原生版本没有登录、CloudKit、推送或网络接口。

应用数据位于沙箱 Application Support/Headly/records-v1.json，排除设备备份。新用户没有预置记录。右上角隐私浮层可加载演示数据和主动导出 CSV，系统分享的目的地由用户选择。原生与浏览器数据不互通。

QA 启动参数仅用于可复现的界面检查：`--demo` 在空数据库中加载虚构记录，`--review` 打开回顾，`--record` 打开新记录浮层。不会覆盖非空数据库。

## 复现检查

本地模型检查直接编译真实数据模型，不依赖浏览器或 Xcode 测试 target：

```sh
xcrun swiftc Headly/HeadacheRecord.swift tools/product/ModelChecks.swift -o /tmp/headly-model-checks
/tmp/headly-model-checks
```

DOM 集成检查使用 jsdom，只在测试内存中运行 HTML，不控制或清除用户浏览器：

```sh
npm install --prefix /tmp/headly-check-deps jsdom
HEADLY_JSDOM=/tmp/headly-check-deps/node_modules/jsdom node tools/product/browser-checks.cjs
```

PRD PDF 的生成脚本为 tools/product/render_prd.py，需要 Python 的 reportlab，并使用 macOS 系统 Arial Unicode 与 Georgia 字体。检查 PDF 时使用 pypdfium2 逐页渲染；本次环境依赖放在独立任务目录，没有添加应用运行依赖。

## 当前边界

这是用于评审与实现参考的产品原型。尚未进行 iOS 17 实机、最大动态字号和完整 VoiceOver 测试；未实现数据导入、自动恢复、Face ID 和暗色主题。原型满足核心记录与回顾流程，正式发布前仍需完成 PRD 中的发布条件。

新文档位于 Product/，本次 Git 提交包含产品原型、图标与交付资料。开始前已有的 docs/PRD.md 删除改动保留在本地工作区。尚未发布网站或 App。
