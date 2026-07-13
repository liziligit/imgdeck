# AGENTS.md

## 项目概览

- 项目类型：原生 macOS SwiftUI 应用。
- 主要目标：将 1～9 张图片按 A4 版式排版，支持格位移动、图片拖放、逐图调整、预览缩放和 PNG/JPG 导出。
- 关键目录：
  - `macos/`：SwiftUI 源码、Xcode 工程和单元测试。
  - `app-store/`：App Store 文案、隐私资料、审核资料和截图。
  - `docs/`：技术支持与隐私页面。
  - `assets/`：应用图标和 README 图片资源。
- 不要修改的目录：
  - `.git/`：Git 内部数据。
  - `.workbuddy/`：工作区辅助数据。
  - `build/`、DerivedData 等构建产物目录。
  - `app-store/screenshots/`、`assets/` 等用户提供素材，除非用户明确要求更新。

## 常用命令

- 安装依赖：不需要 Python、NumPy、OpenCV、Pillow 或额外第三方依赖；需要安装完整 Xcode。
- 打开工程：

  ```bash
  open macos/ImgDeck.xcodeproj
  ```

- 本地运行：在 Xcode 中选择 `ImgDeck` Scheme 和 `My Mac`，按 `⌘R`。
- 测试：

  ```bash
  xcodebuild -project macos/ImgDeck.xcodeproj -scheme ImgDeck \
    -configuration Debug -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath build/swift CODE_SIGNING_ALLOWED=NO test
  ```

- 构建：

  ```bash
  xcodebuild -project macos/ImgDeck.xcodeproj -scheme ImgDeck \
    -configuration Debug -destination 'platform=macOS,arch=arm64' \
    -derivedDataPath build/swift CODE_SIGNING_ALLOWED=NO build
  ```

## 工作规则

- 修改前先读取相关源文件、README 和工程配置。
- 优先进行小范围修改，不做无关重构。
- 不编造数据、案例、测试结果或构建结果。
- 涉及 UI 修改时同时检查简体中文、繁体中文、英文、日语、韩语、西班牙语、法语、德语和葡萄牙语（巴西）。
- 修改后运行与影响范围匹配的构建和测试。
- 不把 `.workbuddy/`、构建产物、DerivedData 或 `.DS_Store` 加入提交。

## GitHub 推送前检查

每次接受用户“推送到 GitHub”的指令时，必须在推送前检查 `README.md` 中以下三个部分是否仍与当前代码和本次改动一致：

- `## 推广文本`
- `## 描述`
- `## 此版本的新增内容`

如果本次改动导致其中任一部分过时，必须先更新对应内容，再进行构建检查、提交和推送。推送完成后说明：

- 修改了哪些文件。
- 使用了什么提交备注。
- 运行了哪些验证。
- 是否存在未验证项或剩余风险。

## 安全边界

- 不读取、复制或提交 `.env`、密钥、证书、账号密码、私有令牌或登录凭证。
- 不提交 `xcuserdata/`、构建产物、DerivedData、`.DS_Store` 和临时文件。
- 不批量删除文件。
- 不修改用户提供的原始图片、截图和 App Store 资料，除非用户明确要求。
- 不执行 `git reset --hard`、`git checkout --` 等破坏性操作，除非用户明确授权。

## 交付要求

每次完成代码修改时说明：

- 修改的文件及功能影响。
- 执行的构建、测试或其他验证。
- 未验证项目和剩余风险。

## 验证

创建或修改文档后检查：

- 文件位于项目根目录。
- Markdown 标题和命令代码块格式正确。
- GitHub 推送检查规则明确包含三个 README 标题。
- AGENTS.md 本身不包含密钥、账号或临时路径。
