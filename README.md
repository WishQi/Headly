# Headly 轻记

简洁的 iOS 头痛记录产品原型：今日、回顾两个主页面，一个记录浮层。无需登录，本地保存。

- [完整 PRD](Product/PRD.md) 和 [排版 PDF](output/pdf/Headly-PRD.pdf)
- [高保真交互原型](Prototype/index.html)
- [三页预览](Product/Preview.png)
- [App 图标与设计说明](Product/Icon/README.md)
- [设计规范](Product/Design-Spec.md)
- [运行方式与交付说明](Product/README.md)
- [验证结果](Product/Verification.md)
- [代码审查与清理](Product/Code-Review.md)

打开 `Headly.xcodeproj`，选择 Headly scheme 即可运行原生原型。浏览器版本直接打开 HTML，或在工作区运行 `python3 -m http.server 8769 --bind 127.0.0.1` 后访问 <http://localhost:8769/Prototype/>。

原生与浏览器各自保存数据，首次使用为空状态。演示数据需明确加载。当前为产品原型，正式发布前的设备、辅助功能和健康文案检查见 PRD。
