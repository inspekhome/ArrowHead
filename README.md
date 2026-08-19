# Arrow in Picture

## English

### Product Overview

Arrow in Picture is an iPhone camera app designed specifically for inspection work.

In a traditional inspection workflow, inspectors usually take a large number of photos first, review them later, identify the visible problems, and then manually add arrows, circles, ovals, squares, or other annotations to each image. This repetitive process takes valuable time when preparing inspection reports.

Arrow in Picture is built around a simpler idea: **complete the visual annotation while taking the photo and reduce post-processing work.**

When an inspector finds a problem, they can select an appropriate marker—such as an arrow, dot, circle, oval, square, or mosaic—aim the marker at the area of concern, and take the picture. When the photo is saved, the selected marker is permanently embedded in the image. The inspector therefore does not need to add the same annotation again while preparing the report.

### Photos With or Without Markers

Some inspection photos are intended only to show an overall condition and do not require a marker. Arrow in Picture includes a marker ON/OFF control for this purpose. When the marker is turned off, the camera continues to work normally, but the saved photo does not contain an arrow or other visual marker.

### Photo Preview and Apple Photos

Recently captured photos appear in the preview area at the top of the app for quick review. A photo can be removed from this preview area, but doing so removes only the in-app preview record. It does not delete the original image saved in Apple Photos.

Completed photos are saved to Apple Photos and organized in the `Arrow` album. Even if a photo is removed from the Arrow in Picture preview, it remains available in the iPhone photo library.

### Camera Controls

Arrow in Picture provides the following field-use controls:

- Front and rear camera switching
- Shooting-mode lock
- Flash modes: Off, On, and Auto
- Marker selection and marker ON/OFF control
- Photo ratios: 4:3, 16:9, 1:1, and 9:16

The 4:3 and 16:9 formats are commonly used in inspection reports, slide presentations, and PDF documents. The 9:16 portrait format is useful for short-form video, social media, and marketing content. The 1:1 format is available when a square image is preferred.

### Photo Memo

Arrow in Picture also supports adding a short Memo directly to a photo. Tap the camera preview once to open the Memo input area, then enter text with the keyboard or voice input. Tap the preview again to confirm the Memo.

When the shutter is pressed, the Memo and the selected visual marker are embedded together in the finished photo. Each Memo supports approximately 100 characters.

### Purpose

Arrow in Picture helps inspectors complete photo annotation and written explanation at the moment of capture. Its goal is to reduce repetitive editing, simplify report preparation, and improve the efficiency of field inspection work.

### Privacy

Arrow in Picture works offline and does not require an account, subscription, advertising service, analytics service, or developer-operated cloud service. Photos remain under the user's control in Apple Photos. App Store privacy and support pages are maintained in `docs/`, while App Store metadata and the TestFlight checklist are maintained in `AppStore/`.

### Run on iPhone

1. Open `ArrowHead.xcodeproj` in the full Xcode application.
2. Select the `ArrowHead` target and choose an Apple Development Team under Signing & Capabilities.
3. Connect an iPhone and select it as the run destination.
4. Press Run and allow Camera, Photos, and Microphone/Speech access when requested.

The project targets iOS 17 or later. A physical iPhone is required to validate the complete camera, flash, photo-saving, and hardware-capture workflow.

---

## 中文

### 产品简介

Arrow in Picture 是一款专为检查工作设计的 iPhone 拍照应用。

在传统的检查流程中，检查人员通常需要先拍摄大量照片，然后根据照片中发现的问题，再逐张添加箭头、圆圈、椭圆、方框或其他标记。这个过程不仅重复，而且会占用大量制作检查报告的时间。

Arrow in Picture 的核心理念是：**在拍照时直接完成视觉标注，减少后期处理工作。**

检查人员发现问题后，可以先选择需要的标记，例如箭头、圆点、圆圈、椭圆、方框或马赛克，将标记对准需要说明的位置，然后直接拍照。照片保存时，所选择的标记会永久嵌入照片中，因此不需要在制作检查报告时再次手工添加相同的标注。

### 有标记和无标记拍照

有些检查照片只用于展示现场的整体情况，并不需要任何标记。为此，Arrow in Picture 提供了标记 ON/OFF 按钮。关闭标记后仍然可以正常拍照，但最终保存的照片中不会出现箭头或其他视觉标识。

### 照片预览与 Apple Photos

拍摄完成的照片会显示在 App 顶部的预览区域，方便快速浏览。用户可以将照片从预览区域移除，但这个操作只会删除 App 内的预览记录，不会删除 Apple Photos 中保存的原始照片。

完成的照片会保存到 Apple Photos，并整理到 `Arrow` 相册中。因此，即使照片不再显示在 Arrow in Picture 顶部的预览区域，仍然可以在 iPhone 相册中找到。

### 相机控制功能

Arrow in Picture 提供以下适合现场使用的功能：

- 前置和后置摄像头切换
- 拍摄模式锁定
- 闪光灯 Off、On 和 Auto 切换
- 标记选择以及标记 ON/OFF 控制
- 4:3、16:9、1:1 和 9:16 四种照片比例

其中，4:3 和 16:9 适合检查报告、幻灯片以及 PDF 文档；9:16 竖屏格式适合短视频、社交媒体和营销内容；1:1 则适合需要方形照片的场景。

### 照片 Memo

Arrow in Picture 还支持为照片添加简短的 Memo 文字。只需点击一次相机预览画面，即可打开 Memo 输入区域，然后通过键盘或语音输入内容。再次点击预览画面，即可确认 Memo。

按下快门时，Memo 和所选择的视觉标记会一起嵌入最终照片中。每条 Memo 最多支持约 100 个字符。

### 设计目的

Arrow in Picture 帮助检查人员在现场拍照时直接完成照片标注和文字说明，从而减少重复编辑，简化检查报告的制作流程，并提高现场检查工作的效率。

### 隐私保护

Arrow in Picture 可以离线工作，不需要注册账户，也不包含订阅、广告、数据分析服务或开发者运营的云端服务。照片由用户通过 Apple Photos 自行管理。App Store 隐私政策和技术支持页面保存在 `docs/` 中；App Store 资料和 TestFlight 检查清单保存在 `AppStore/` 中。

### 在 iPhone 上运行

1. 使用完整版 Xcode 打开 `ArrowHead.xcodeproj`。
2. 选择 `ArrowHead` Target，并在 Signing & Capabilities 中选择 Apple Development Team。
3. 连接 iPhone，并将其选择为运行设备。
4. 点击 Run，并在系统询问时允许相机、照片、麦克风和语音识别权限。

项目支持 iOS 17 或更高版本。完整的相机、闪光灯、照片保存以及实体按键拍照流程需要使用真实 iPhone 进行验证。
