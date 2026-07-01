# Swift 版构建输出

运行项目根目录下的构建脚本：

```bash
./scripts/build-swift-app.sh
```

成功后，未正式签名的本地测试版固定生成在：

```text
dist-swift/ImgDeck.app
```

`ImgDeck.app` 是生成文件，不提交到 Git；本说明文件用于确保 `dist-swift` 目录始终存在。
