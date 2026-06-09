#! file: Makefile
#! brief: 项目构建/打包/运行一站式 Makefile
#! 用法：
#!   make run         —— 本地运行 (love .)
#!   make icon        —— 重新生成图标
#!   make love        —— 打包成 .love 文件
#!   make linux       —— 打出 Linux AppImage (需要 love 二进制)
#!   make win         —— 打出 Windows exe (需要下载 win32/64 love 压缩包)
#!   make mac         —— 打出 Mac .app (需要在 Mac 上做)
#!   make apk         —— 打出 APK (需要 love-android)
#!   make clean       —— 清理构建产物

GAME_NAME  := trillion_games_vale
GAME_VER   := 5.0.0
LOVE_BIN   ?= love
BUILD_DIR  := build
DIST_DIR   := dist

SRC_FILES  := $(shell find src assets conf.lua main.lua LICENSE README.md CHANGELOG.md -type f 2>/dev/null)
LOVE_FILE  := $(BUILD_DIR)/$(GAME_NAME)-$(GAME_VER).love

.PHONY: all run icon love clean linux win mac apk dist

all: run

# ==== 运行 ====
run:
	$(LOVE_BIN) .

# ==== 图标 ====
icon:
	mkdir -p assets/images
	cd tools/gen_icon && $(LOVE_BIN) .
	cp ~/.local/share/love/gen_icon/icon_out/*.png assets/images/
	@echo "Icons written to assets/images/"

# ==== .love 打包 ====
$(LOVE_FILE): $(SRC_FILES)
	mkdir -p $(BUILD_DIR) $(DIST_DIR)
	zip -r $(LOVE_FILE) \
	    main.lua conf.lua LICENSE README.md CHANGELOG.md SETUP.md \
	    docs src assets \
	    -x "*.DS_Store" "*.git*" "build/*" "dist/*" "tools/*" "Makefile"
	@echo "Built $(LOVE_FILE)"

love: $(LOVE_FILE)

# ==== Linux ====
# 把 .love 和 love 二进制合并成 AppImage
linux: $(LOVE_FILE)
	@echo "Linux packaging requires love AppImage from https://api.github.com/repos/love2d/love/releases"
	@echo "Place love-11.5-x86_64.AppImage in tools/pack/ then:"
	@echo "  cat tools/pack/love-11.5.AppImage $(LOVE_FILE) > $(DIST_DIR)/$(GAME_NAME)-$(GAME_VER)-x86_64.AppImage"
	@echo "  chmod +x $(DIST_DIR)/$(GAME_NAME)-$(GAME_VER)-x86_64.AppImage"

# ==== Windows ====
win: $(LOVE_FILE)
	@echo "Windows packaging requires love-11.5-win64.zip from love2d.org"
	@echo "Steps:"
	@echo "  1. Unzip love-11.5-win64.zip to tools/pack/win64/"
	@echo "  2. copy /b tools/pack/win64/love.exe+$(LOVE_FILE) $(DIST_DIR)/$(GAME_NAME).exe"
	@echo "  3. bundle required DLLs alongside the exe"

# ==== macOS ====
mac: $(LOVE_FILE)
	@echo "macOS packaging needs to be done on a Mac with love.app installed"
	@echo "Steps:"
	@echo "  1. cp $(LOVE_FILE) /Applications/love.app/Contents/Resources/"
	@echo "  2. Rename love.app to $(GAME_NAME).app, update Info.plist"
	@echo "  3. Use iconutil to convert assets/images/*.png to .icns"

# ==== APK (Android) ====
apk:
	@echo "=== Android APK 打包（推荐 love-android 或 love-apk-builder） ==="
	@echo ""
	@echo "方法 A —— love-apk-builder (命令行):"
	@echo "  1. npm install -g love-js (或下载 love-android apk 模板)"
	@echo "  2. 最简方法：去 https://simple.love2d.org/ 上传 .love 直接下载 APK"
	@echo ""
	@echo "方法 B —— 自编译 love-android:"
	@echo "  1. git clone https://github.com/love2d/love-android"
	@echo "  2. 把 .love 放到 app/src/main/assets/ 改名 game.love"
	@echo "  3. 修改 app/build.gradle 的 applicationId/versionCode"
	@echo "  4. ./gradlew assembleRelease"
	@echo ""
	@echo "方法 C —— love2d Android 官方模板:"
	@echo "  下载 love-11.5-android-embed.apk 用 APKTool 改包名 + 注入 .love"

# ==== Steamworks 钩子准备 ====
steam:
	@echo "=== Steamworks ==="
	@echo "Steam SDK 集成步骤（V5 预留钩子，实际集成在游戏接近上架时）："
	@echo "1. 下载 Steamworks SDK -> tools/pack/steamworks_sdk/"
	@echo "2. 使用 luasteam (https://github.com/uspgamedev/luasteam) 或 Greenworks"
	@echo "3. 在 core/steam.lua 里封装 Steam API（成就/统计/云存档）"
	@echo "4. 桌面发布版打包时带上 steam_api64.dll/.so/.dylib"
	@echo "5. Steam DRM 可选（简单加密，不是强保护）"

# ==== 清理 ====
clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	rm -f ~/.local/share/love/$(GAME_NAME)/user_config.lua

# ==== 全平台发布包 ====
dist: love
	@echo "Built .love at $(LOVE_FILE)"
	@echo "Run Linux/Win/Mac targets for platform-specific packaging"
