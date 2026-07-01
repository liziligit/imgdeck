#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
PROJECT_PATH="$ROOT_DIR/macos/ImgDeck.xcodeproj"
DERIVED_DATA_PATH="$ROOT_DIR/build/swift-release"
OUTPUT_DIR="$ROOT_DIR/dist-swift"
APP_PATH="$OUTPUT_DIR/ImgDeck.app"
DSYM_PATH="$OUTPUT_DIR/ImgDeck.app.dSYM"
MODULE_PATH="$OUTPUT_DIR/ImgDeck.swiftmodule"

mkdir -p "$OUTPUT_DIR"
rm -rf "$APP_PATH" "$DSYM_PATH" "$MODULE_PATH"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme ImgDeck \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CONFIGURATION_BUILD_DIR="$OUTPUT_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

codesign --force --deep --sign - "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

# Xcode 还会在输出目录生成调试符号和模块元数据；本地测试版只保留 App。
rm -rf "$DSYM_PATH" "$MODULE_PATH"

if [[ ! -x "$APP_PATH/Contents/MacOS/ImgDeck" ]]; then
  print -u2 "构建失败：未找到可执行文件 $APP_PATH/Contents/MacOS/ImgDeck"
  exit 1
fi

print "构建完成：$APP_PATH"
