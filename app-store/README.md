# ImgDeck App Store 发布资料

本目录保存提交 Mac App Store 时需要使用的文字和截图资料，不存放 Debug App 或 Archive。

## 文件说明

- `AppStoreMetadata.md`：App Store 产品页文案与后台字段。
- `AppReviewNotes.md`：提供给 Apple 审核人员的操作说明。
- `PrivacyPolicy.md`：隐私政策正文，与 `docs/privacy.md` 保持一致。
- `Support.md`：技术支持正文，与 `docs/support.md` 保持一致。
- `screenshots/`：Mac App Store 截图及拍摄要求。

## 提交前待办

- [ ] 将文档中的 `【待填写】` 全部替换为真实信息。
- [ ] 确认 App Store Connect 中的 Bundle ID 为 `com.liziligit.imgdeck`。
- [ ] 确认版本号为 `1.0.0`，构建号为 `1`。
- [ ] 在 GitHub 仓库设置中启用 GitHub Pages，发布 `docs/` 目录。
- [ ] 验证隐私政策和技术支持网址可在未登录状态下访问。
- [ ] 使用最新 Swift 版 ImgDeck 拍摄 3～5 张 16:10 截图。
- [ ] 在 Xcode 中通过 `Product → Archive` 创建并上传正式构建。

## 计划使用的网址

- 产品主页：https://github.com/liziligit/imgdeck
- 技术支持：https://liziligit.github.io/imgdeck/support.html
- 隐私政策：https://liziligit.github.io/imgdeck/privacy.html
- 问题反馈：https://github.com/liziligit/imgdeck/issues

GitHub Pages 尚未启用前，`github.io` 地址不会生效。
