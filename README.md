# ImgDeck

ImgDeck 是使用 SwiftUI 开发的原生 macOS A4 图片排版工具，基于开源项目 `imgcom` 的功能思路重新实现。图片导入、版式选择、预览和保存均在图形界面中完成。

## 软件界面

![ImgDeck 软件界面](assets/screenshot.png)

## 项目来源

本项目基于 [makalin/imgcom](https://github.com/makalin/imgcom)
修改和扩展。原项目由 Mehmet T. AKALIN 开发，本版本的后续修改
和维护由“你的姓名或组织名称”完成。

## 功能

- 1×1、2×1、1×2、3×1、1×3、2×2、3×2、3×3 共 8 种 A4 版式
- 支持导入、排序和移除 1–9 张图片
- 图片保持原始长宽比并完整显示，未填充区域使用白色背景
- 支持每英寸点数和每厘米点数两种分辨率单位
- 实时显示输出像素尺寸和预计文件大小
- 支持 PNG、JPG 保存，默认 PNG
- 调整分辨率时保留当前预览，重新预览后应用新尺寸

## 开发与构建

项目位于 `macos/`，不依赖 Python、OpenCV、NumPy 或 Pillow。当前目标为 Apple Silicon，最低支持 macOS 13。开发环境需要完整安装 Xcode。

使用 Xcode 打开工程：

```bash
open macos/ImgDeck.xcodeproj
```

在 Xcode 中选择 `ImgDeck` Scheme 和 `My Mac`，点击运行即可。要生成可直接双击运行的本地测试版，请在项目根目录执行：

```bash
./scripts/build-swift-app.sh
```

脚本会依次完成 Release 编译、复制、临时签名和完整性验证，并将成品固定输出到 `dist-swift/ImgDeck.app`。即使清理过 Xcode 构建缓存，也可以再次运行该脚本恢复应用。

运行 Swift 单元测试：

```bash
xcodebuild -project macos/ImgDeck.xcodeproj -scheme ImgDeck \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/swift CODE_SIGNING_ALLOWED=NO test
```

本地测试版输出到 `dist-swift/ImgDeck.app`。该版本未使用 Developer ID 正式签名，仅用于本机测试。

## 使用方法

1. 点击“添加图片”导入图片，并用“上移”“下移”调整顺序。
2. 选择 A4 版式；图片按编号顺序填入，超出容量的图片不显示。
3. 设置分辨率与单位，点击“预览”。
4. 选择 PNG 或 JPG，点击“保存图片”。

## 项目结构

```text
imgdeck/
├── assets/             # README 截图与应用图标源文件
├── macos/              # SwiftUI 源码、Xcode 工程与单元测试
├── scripts/            # 本地构建脚本
├── dist-swift/         # 本地测试版输出目录
├── README.md
└── LICENSE
```

## 开源说明

本项目基于 Mehmet T. AKALIN 的开源项目 `imgcom` 修改，继续采用 MIT License。
