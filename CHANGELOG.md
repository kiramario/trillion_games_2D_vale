# CHANGELOG

## v5.0.0 — "整装待发" (2026-06-09)

### Added
- Makefile：一站式构建（`make run`/`make icon`/`make love`/`make linux`/`make win`/`make mac`/`make apk`/`make steam`/`make dist`）
- 游戏图标（程序化生成 512/256/128/64/32/16 PNG，红帅 + 金环风格）
- tools/gen_icon 图标生成工具（纯几何，不依赖字体）
- conf.lua: 启用窗口图标
- src/core/steam.lua: Steamworks 占位钩子（成就/统计/云存档 API，无 Steam 时静默降级）
- PUBLISHING.md: 完整的 Steam/Linux/Win/Mac/APK/iOS/Web 发布路线
- LICENSE: MIT License + 第三方声明
- `make love` 可生成 31MB 的可分发 .love 文件

### Packaging
- .love 已验证可独立运行：`love build/trillion_games_vale-5.0.0.love`
- 桌面版打包：`cat love.AppImage game.love > game.AppImage`
- APK 打包：推荐 simple.love2d.org 或 love-android 源码构建
- Steam：SteamPipe + luasteam，core/steam.lua 已预留所有钩子

---

## v4.0.0 — "锦上添花" (2026-06-09)

### Added
- game/scenes/menu_scene：主菜单场景（金色标题、开始AI/双人/退出按钮、背景漂浮粒子）
- engine/ui/button：通用按钮组件（hover/click 动画/阴影/文字居中）
- core/save：存档系统（table serializer、slot-based save/load/list）
- 启动流程：boot → menu → board
- Enter/Space 在菜单快速开始；ESC 在游戏中返回菜单
- 棋盘中支持 ai_mode 参数传入

### Visual
- 菜单深木色背景 + 金色飘散光点

---

## v3.0.0 — "棋逢对手" (2026-06-09)

### Added

### Added
- V1 棋盘场景：渲染完整中国象棋棋盘
- engine/camera 相机模块：居中、缩放、屏幕震动（后续 V3+ 用）
- game/constants.lua：棋盘尺寸、颜色、棋子字符、初始布局
- game/entities/piece.lua, game/entities/board.lua：棋子和棋盘数据
- game/renderers/board_renderer.lua：棋盘渲染（斜视角Y压缩、木纹、厚度、九宫斜线、楚河汉界、炮位L标）
- game/renderers/piece_renderer.lua：棋子渲染（阴影/底座/主体/高光/内外圈/汉字）
- 中文字体：Noto Sans CJK SC Regular + Bold（assets/fonts/）

### Changed
- engine.lua: 启动后默认进入 board 场景；resize 事件通知场景
- renderer.lua: world 层不再自动做 camera 变换（由场景自行控制）

### Fixed
- 修复 renderer custom 中嵌套提交 draw command 导致 crash 的问题
- 修复 Lua 多变量声明语法错误 (`local a=1,b=2` 非法)
- 修复 love.graphics push/pop 变换栈溢出导致 segfault 的问题
  （LÖVE2D 图形栈深度 32，循环中不能每个元素都 push/pop）

### How to run
```bash
love .
```

---

## v0.0.0 — "Hello Engine" (2026-06-09)

### Added
- 项目初始化，LÖVE2D 11.3 环境
- Core 层全部 9 个基础模块：
  - engine.lua — 游戏循环调度器
  - config.lua — 配置管理（默认值 + 用户持久化）
  - logger.lua — 四级日志（DEBUG/INFO/WARN/ERROR）
  - event.lua — 发布/订阅事件总线
  - input.lua — 键盘/鼠标输入抽象（含 action 映射）
  - resource.lua — 图片/字体/音效/Shader 加载与缓存
  - renderer.lua — 五层分层渲染（background/world/effects/ui/overlay）
  - scene_manager.lua — 场景切换与淡入淡出
  - timer.lua — 延时/重复计时 + Tween 补间动画（8 种 easing）
  - utils.lua — 工具函数集（深拷贝、颜色转换、数学工具等）
- 两个测试场景：
  - BootScene — 启动画面，1 秒后自动切换
  - DemoScene — 彩色方块演示，支持按键切换颜色、鼠标涟漪、动画
- 完整文档体系（docs/01~07）
- .gitignore、conf.lua、main.lua 入口

### How to run
```bash
cd /home/love2DGame_vale
love .
```
