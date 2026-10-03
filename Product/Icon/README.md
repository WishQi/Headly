# Headly 轻记 App 图标

设计日期：2026 年 10 月 3 日。

图标以圆润的小写 h 作为 Headly 的首字母标记，上方弧线呼应头部轮廓。深墨绿背景配暖白笔画，粗笔画与开放的内部空间便于小尺寸识别，延续现有产品的安静、轻量感。

## 文件与接入

- [iOS 图标 PNG](Headly-AppIcon.png)：1024 × 1024，RGB、不透明，完整正方形；外部圆角交给 iOS。
- [生成母稿](Headly-Generated-Master.png)：保留 ImageGen 原始输出。
- Xcode 使用 `Headly/Assets.xcassets/AppIcon.appiconset/HeadlyIcon-v2.png`，与 iOS 图标 PNG 内容一致。
- [原图标归档](archive/HeadlyIcon-v1.png)：旧版半圆图案已保留，可恢复。

使用内置 ImageGen 生成及细化，没有使用 CLI/API 回退。原始输出为 1254 × 1254；使用 macOS sips 完成 1024 × 1024 的资源尺寸转换。图形内容由 ImageGen 制作。

以下颜色为生成时的设计目标；生成图像的像素颜色含细微变化，不是严格的两色矢量母版。本次交付为可直接使用的位图图标。

## 生成提示词

```text
Use case: logo-brand
Asset type: production iOS app icon for Headly / 轻记, a premium, minimal headache journal with local private records.
Primary request: Design one original, memorable monogram symbol for Headly. The symbol is a beautifully proportioned lowercase h, crafted as a custom broad, flowing ivory ribbon rather than an ordinary typeface glyph. Its tall left stem ends in a soft rounded cap; its generous arched shoulder subtly evokes the crown of a head, and its open inner counter is exceptionally clear. Rounded transitions, restrained geometry, and a slightly calligraphic flow convey a calm personal diary. The mark should read instantly as a lowercase h. This is the one main symbol, not an illustration of a person.
Scene/backdrop: full-bleed solid deep forest green #173B33, covering every pixel of the square including the corners.
Color palette: exactly deep forest green #173B33 and warm ivory #F6F5EF, with only clean edge antialiasing.
Style/medium: exceptionally polished flat vector-like brand mark, quiet premium editorial identity, optically balanced, confident silhouette, crisp smooth edges.
Composition/framing: square 1024 by 1024 icon master, a single large centered ivory symbol around 58 percent of canvas width and 61 percent of canvas height, generous equal optical padding. It should remain recognizable at 29 pixels. Present only the actual square asset edge-to-edge.
Constraints: opaque full-square canvas; NO rounded outer corners or external icon container; iOS applies its own mask. No written brand name, Chinese text, tagline, watermark, frame, border, phone, presentation board, mockup, extra objects, medical cross, brain drawing, lightning bolt, heartbeat, tiny decorative lines, texture, grain, gradient, 3D, bevel, lighting, or cast shadow. Do not imitate any existing brand.
```

## 最终细化提示词

```text
Use case: logo-brand
Asset type: final Headly iOS app icon master.
Input image: Image 1 is the edit target, the approved Headly lowercase h composition.
Primary request: Make this logo absolutely FLAT and clean, with solid uniform fills. Keep the exact h silhouette, stroke proportions, curved terminals, scale, center and padding unchanged. Replace all of the background with one single perfectly uniform deep forest green #173B33. Replace the complete h interior with one single perfectly uniform warm ivory #F6F5EF. Keep clean edge antialiasing. Remove ALL grain, mottling, texture, gradients, highlights, shadows and uneven color from both foreground and background. No other design changes.
Output: a single opaque square 1024 x 1024 PNG icon, full green square right into all four corners, no rounded outer mask or border, no mockup, no words, no watermark. Two flat colors, just one original h mark.
```
