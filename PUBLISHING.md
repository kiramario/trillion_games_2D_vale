# 发布指南 (PUBLISHING.md)

本文档汇总了把《中国象棋》打包到 Steam / APK / 桌面三平台的完整路线。
V5 已完成所有"项目侧"准备（.love 打包、图标、Steam 钩子占位、Makefile）。

---

## 一、通用：先打 .love 文件

```bash
make love
# 产出：build/trillion_games_vale-5.0.0.love
```

.love 是一个 zip 文件，里面是 main.lua + conf.lua + src/ + assets/。
三种桌面平台和 Steam 都可以由 .love 进一步打包。

测试 .love：
```bash
love build/trillion_games_vale-5.0.0.love
```

---

## 二、桌面版（Linux / Windows / macOS）

### Linux AppImage（最推荐）
1. 去 https://github.com/love2d/love/releases 下载 love-11.5-x86_64.AppImage
2. 放到 tools/pack/ 下
3. 合并：
```bash
cat tools/pack/love-11.5-x86_64.AppImage build/trillion_games_vale-5.0.0.love \
    > dist/trillion_games_vale-5.0.0-x86_64.AppImage
chmod +x dist/trillion_games_vale-5.0.0-x86_64.AppImage
```
4. 双击就能运行。Steam Linux 上传这个 AppImage。

### Windows exe
1. 下载 love-11.5-win64.zip，解压到 tools/pack/win64/
2. 合并 exe：
```bash
cd tools/pack/win64
copy /b love.exe+../../../build/trillion_games_vale-5.0.0.love trillion_games_vale.exe
```
3. 把所有 DLL 和 trillion_games_vale.exe 一起打包成 zip
4. 建议用 Inno Setup / NSIS 做安装包（可选）

### macOS app（必须在 Mac 上完成）
1. 安装 LÖVE2D for mac（love.app）
2. 复制 love.app 改名为 TrillionGames.app
3. 把 .love 放入 Contents/Resources/
4. 修改 Info.plist 中的 Bundle name、Bundle identifier、图标 (icon.icns)
5. 用 iconutil 把 assets/images/icon*.png 转成 .icns
6. 签名 & notarization（上架 Mac App Store 必须；不进 App Store 可跳过）

---

## 三、Steam 上架

### 1. Steamworks 账号
- 注册 Steam 开发者（$100 美元一次性费用）
- 在 Steamworks 后台创建 App，拿到 AppID（例如 1234560）

### 2. Steamworks SDK
- 下载 Steamworks SDK（v1.60+）
- 安装 luasteam（Lua 绑定）：luarocks install luasteam
- 或者使用 Greenworks（node/Electron 系，不推荐）
- 本项目已有 src/core/steam.lua 封装 API，只需 luaopen 找到 luasteam 即自动启用

### 3. 成就设计（示例）
在 Steamworks 后台创建：
- FIRST_WIN：首局胜利
- HUNDRED_GAMES：下满 100 局
- PERFECT_CAPTURE：一局中吃光对方
- AI_MASTER：对 AI 最高难度连胜 5 局

代码中触发：
```lua
local steam = require("core.steam")
steam.setAchievement("FIRST_WIN")
```

### 4. 云存档
```lua
steam.cloudWrite("save_slot1.lua", save_data_string)
local data = steam.cloudRead("save_slot1.lua")
```
在 Steamworks 后台开启 Steam Cloud，配额填 1MB 足够（象棋存档很小）。

### 5. 上传构建
- 使用 SteamPipe (steamcmd.exe)
- 每个 depot 上传对应平台的构建产物（AppImage/win64 文件夹/mac .app）
- 初始 depot 配置见 tools/pack/steam_depots_build_template.vdf（TODO）

### 6. Steam Deck 兼容
- LÖVE2D 游戏天然兼容 Steam Deck（Linux + 手柄/触屏）
- 需要做：手柄输入支持（V6+，本 V5 已预留 joystick 模块开关）
- 在 Steamworks 后台勾选 Steam Deck Compatibility

---

## 四、APK (Android)

LÖVE2D 11.x 官方支持 Android，有三种方式：

### 方法 A —— 最简单：love2d 官网 APK 打包器
1. 访问 https://simple.love2d.org/ （或 love2d.org 官方工具）
2. 上传 .love 文件，填包名、版本、图标
3. 直接下载 APK

### 方法 B —— love-android 源码构建
1. git clone https://github.com/love2d/love-android
2. Android Studio 打开项目
3. 把 build/trillion_games_vale-5.0.0.love 拷到 app/src/main/assets/game.love
4. 修改 app/build.gradle：
```
applicationId "com.trilliongames.chinesechess"
versionCode 5
versionName "5.0.0"
```
5. 替换 app/src/main/res/ 下的图标为 assets/images/ 中的 PNG
6. 生成签名 keystore：
```
keytool -genkey -v -keystore trillion.keystore -alias trillion -keyalg RSA -keysize 2048 -validity 10000
```
7. 构建：
```
./gradlew assembleRelease
```
8. APK 产出位置：app/build/outputs/apk/release/

### 方法 C —— 使用 love-android-apk CLI
社区有预构建的 apk 模板，把 .love 直接 zip 进 assets 即可，适合命令行党。

### Google Play 上架注意
- 目标 SDK 至少 33
- 准备隐私政策 URL
- 需要 aab 格式（bundle），love-android 最新版支持
- 中国象棋属"棋牌"类别，部分地区需年龄分级

---

## 五、iOS (App Store，预留)

- LÖVE2D 也支持 iOS，但需要 Mac + Xcode + $99/年苹果开发者账号
- 流程和 APK 类似：clone love-ios，把 .love 丢进资源，改 Bundle ID
- 中国象棋因含"棋牌"分类审核会略严，但单机版通常可以通过

---

## 六、Web (HTML5 / itch.io，预留)

- love.js 可以把 LÖVE2D 编译成 WebAssembly
- 适合放 itch.io 当试玩版
- 注意：本项目 V2 用 love.sound.newSoundData 生成 PCM，浏览器上可能不支持，
  需要改为用文件加载或预生成 ogg
- 部署到 itch.io 最简单：zip html 产物后上传

---

## 七、版本 checklist

每次发新版前执行：
- [ ] `make love` 本地 .love 能跑
- [ ] CHANGELOG.md 已更新
- [ ] SETUP.md 如有新命令则更新
- [ ] git tag -a vX.Y.Z -m "..."
- [ ] git push --tags
- [ ] 三平台 .love 各自 smoke test（至少每个平台进游戏下一盘）
- [ ] Steam：更新 depot 构建并切到 preview 分支验证
- [ ] APK：真机安装测试（至少 Android 10+）
