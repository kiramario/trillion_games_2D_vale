# 07 - 发布路径建议 (Publishing Guide)

## 跨平台发布原理

LÖVE2D 本身是跨平台的。你的游戏代码（.lua + assets）打包成一个 .love 文件（本质是 zip），然后在目标平台上：
- 桌面：用对应平台的 love 二进制去加载 .love 文件，或者把 .love 拼接到二进制后面
- Android：用 love-android 的 APK 模板，把你的 .love 放进 assets/
- Steam：本质是桌面版，加 Steamworks SDK 集成

> 好消息：你的 Lua/游戏代码完全不需要改。平台差异只在打包脚本和配置。

---

## 桌面版（Linux / Windows / macOS）

### Linux（最简单，你的开发环境就是 Linux）

有三种选择，推荐程度排序：

1. **AppImage**（推荐）
   - 工具：[love-release](https://github.com/MisterDA/love-release)（Lua 写的，可通过 luarocks 安装）
   - 一条命令产出单文件 AppImage，双击即跑
   - 也可以用 [appimagetool](https://appimagetool.org/) 手动打包
   ```bash
   love-release -L AppImage -v 11.3
   ```

2. **.love 文件分发**
   - 用户自己装 LÖVE2D，然后 `love game.love`
   - 不推荐给普通用户，但适合 itch.io 上传给有经验的玩家

3. **Flatpak / .deb**
   - Flatpak 适合 Flathub 分发，工作量大些
   - .deb 适合 Ubuntu 系，但碎片化严重

### Windows

1. **love-release**（推荐）
   ```bash
   love-release -W 32 -W 64 -v 11.3
   ```
   产出 `game-win32.zip` / `game-win64.zip`，解压即用。
   - 自动下载对应版本的 love.dll 和 love.exe
   - 把你的 .love 内容 fuse 进去

2. **手动方式（原理演示）**
   ```bash
   # 做 .love 文件
   zip -9 -r game.love . -x "*.git*" "tests/*" "docs/*"
   # 在 Windows 上：copy /b love.exe+game.love game.exe
   # 然后连同 love.dll / SDL2.dll / OpenAL32.dll 一起分发
   ```

### macOS

1. **love-release** 支持 macOS，产出 .app 包
2. **注意事项**：
   - macOS Catalina+ 要求 notarization（公证），需要 Apple 开发者账号 $99/年
   - 没有签名的 app 用户需要右键 → 打开
   - 可以先不签名（开发阶段），发布时再签
   - love-release 产出的 app 在 M1 架构上可能需要额外处理（目前 LÖVE 11.5 已支持 Apple Silicon）

### 桌面版建议优先级
**Linux AppImage（先做）→ Windows exe（Steam 必做）→ macOS（Steam/itch.io 后续）**

---

## Steam 发布路径

### 前置条件
1. 注册 Steamworks 开发者：https://partner.steamgames.com/
   - 费用：$100/每款游戏（可退还，当游戏收入超过 $1000 时退还）
2. 下载 Steamworks SDK
3. 安装 Steam 客户端

### 技术集成（两种方式）

**方式 A：无 SDK 集成（最简单，先上）**
- 直接把桌面版（Windows exe + Linux AppImage + macOS app）上传 Steam Depot
- 不做成就/云存档/排行榜
- Steam overlay 由 Steam 客户端自动注入，不需要代码
- 优点：零代码改动，1-2 天就能上 Steam
- 缺点：没有 Steam 特有功能

**方式 B：用 luasteam 集成（V5 后期做）**
- luasteam：https://github.com/uspgamedev/luasteam（LuaJIT FFI 绑定 Steamworks）
- 可使用：
  - 成就（Achievements）
  - 云存档（Steam Remote Storage）
  - 统计（Stats）——比如总对局数
  - 好友邀请（如果做双人本地联机）
- 集成代码量不大，主要在启动时检查 Steam 是否运行

### Steam 发布检查清单
- [ ] Steamworks 账号审批通过（1-5 天）
- [ ] 商店页面素材：capsule、截图、trailer、description、tags
- [ ] 游戏 build 通过 SteamPipe 上传
- [ ] 至少 10 个成就（可选但推荐）
- [ ] 手柄支持（Steam Input 可自动映射键盘）
- [ ] Steam Deck 兼容性测试（象棋应该完美通过）

---

## APK（Android）发布路径

### 使用 love-android 项目
https://github.com/love2d/love-android

这是 LÖVE2D 官方维护的 Android 端口。

**步骤概述：**
1. 克隆 love-android 仓库
2. 把你的 game.love 放到 `app/src/main/assets/` 目录（命名为 `game.love`）
3. 修改 `app/build.gradle` 中的 applicationId、versionCode、versionName
4. 修改图标（res/mipmap-*/ic_launcher.png）
5. 用 Android Studio 或命令行 gradle 构建 debug/release APK
6. release APK 需要签名（jarsigner 或 apksigner）

### Android 适配要点（V5 做）

```
代码层面需要考虑：
├── 触摸代替鼠标
│   ├── input.lua 需要扩展 touch 支持（love.touch 模块）
│   ├── 点击区域要放大（手指不像鼠标精确，棋子点击半径 ≥ 44dp）
│   └── 没有 hover 状态，"选中"要靠点击切换
├── 返回键（Android back button）
│   └── love.keyboard.isDown("escape") 已在 Android 上映射返回键
├── 屏幕尺寸
│   ├── Android 屏幕碎片化严重
│   ├── 用 conf.lua 设置 resizable = true，BoardScene 自适应
│   └── 棋盘尺寸取 min(width, height) * 0.9
├── 性能
│   ├── 移动端 GPU 弱，减少 overdraw
│   ├── AI 搜索可能导致卡帧，放 coroutine 里分帧算
│   └── 控制粒子数量
└── 生命周期
    ├── app 切后台时 love.focus(false) 触发，暂停游戏循环
    └── love.quit() 时自动存档
```

### APK 分发渠道
- itch.io（最简单，直接上传 APK）
- TapTap / 好游快爆（国内安卓渠道，需要版号！）
- Google Play（需要 Google 开发者账号 $25 一次性）
- 直接在 GitHub releases 放 APK（让用户侧载）

> **重要风险提示：** 国内安卓应用商店上架游戏需要**版号**（国家新闻出版署审批），独立开发者几乎无法在短期内拿到。建议 APK 走 itch.io + GitHub releases 海外分发，不要碰国内商店。

---

## 不推荐的路径

| 平台 | 原因 |
|------|------|
| iOS | 需要 $99/年 + Mac 构建 + App Store 审核 + 版号（国内市场）。投入产出比低。弹珠游戏等后续产品再考虑。 |
| Web (WASM/JS) | LÖVE 有 [love.js](https://github.com/Davidobot/love.js) 移植，但性能差、音频坑多、移动端浏览器不一致。如果未来要做网页 demo 可以尝试。 |
| 主机 (Switch/PS/Xbox) | 需要成为主机开发者（申请门槛高）+ 重新适配输入 + 额外集成费用。象棋这种体量不值得。 |

---

## 版本号与构建脚本（V5 实现）

在项目根目录放 Makefile 或 build.sh：
```
make          # 开发模式运行（等价于 love .）
make love     # 产出 game.love
make linux    # 产出 AppImage
make windows  # 产出 Windows zip
make apk      # 产出 Android APK
make clean    # 清理构建产物
make test     # 运行基础自检
```

## 资源打包注意事项

1. .love 文件就是 zip，所以：
   - 不要压缩太过度（游戏运行时是从 zip 直接读，不影响性能）
   - 排除 .git/、docs/、tests/、*.md 等非运行时文件
2. 大资源（>100MB 音频/高清图）用 Git LFS 或干脆不进 git
3. 构建前检查所有资源路径大小写（Windows 不区分大小写，Linux/Android 区分！常见 bug）
