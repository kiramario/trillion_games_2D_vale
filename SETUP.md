# 部署、执行说明与注意事项

> 适用版本：**v0.0.0 "Hello Engine"**
> 本地仓库路径：`/home/love2DGame_vale`
> 远程仓库：`https://github.com/kiramario/trillion_games_2D_vale`

---

## 一、环境要求

| 项目 | 要求 | 备注 |
|------|------|------|
| 操作系统 | Linux / Windows / macOS | 跨平台，LÖVE2D 官方支持 |
| LÖVE2D | **11.3** 或更高（11.x 系列） | 本项目基于 11.3 开发；12.x 目前是预览版，不建议 |
| LuaJIT | 2.1.x（LÖVE2D 内置，无需单独装） | 不要用 PUC-Lua 5.1/5.3/5.4 代替 |
| Git | 任意版本 | 仅用于版本管理，不是运行时依赖 |
| GPU | 支持 OpenGL 2.1+ / OpenGL ES 2.0+ | 现代电脑和手机都满足，象棋游戏几乎不吃显卡 |
| 内存 | ≥ 100MB | V0 实际占用 < 30MB |
| 磁盘 | < 5MB（V0，V5 含资源后预估 < 200MB）| |

---

## 二、本地开发环境搭建（Linux，已完成验证）

### 2.1 安装 LÖVE2D

**Ubuntu / Debian（已安装环境，参考）：**
```bash
sudo add-apt-repository ppa:bartbes/love-stable
sudo apt update
sudo apt install love
```

**Arch Linux：**
```bash
sudo pacman -S love
```

**macOS：**
```bash
brew install --cask love
```

**Windows：**
1. 去官网 https://love2d.org/ 下载 64-bit Installer
2. 安装后把 `C:\Program Files\LOVE\` 加到 PATH
3. 命令行执行 `love --version` 验证

**验证安装：**
```bash
love --version
# 预期输出：LOVE 11.3 (Mysterious Mysteries) 或更高 11.x 版本
```

### 2.2 获取代码

**方式 A：克隆远程仓库（推荐）：**
```bash
git clone https://github.com/kiramario/trillion_games_2D_vale.git
cd trillion_games_2D_vale
```

**方式 B：使用本地已有的仓库：**
```bash
cd /home/love2DGame_vale
```

**方式 C：使用打包文件（随本说明提供）：**
```bash
tar -xzf trillion_games_2D_vale-v0.0.0.tar.gz
cd trillion_games_2D_vale
```

### 2.3 切换版本（每个版本都有 tag）
```bash
# 查看所有版本 tag
git tag

# 切换到 V0
git checkout v0.0.0

# 回到最新的 main 分支
git checkout main
```

---

## 三、执行（运行）说明

### 3.1 开发模式运行
```bash
cd /home/love2DGame_vale   # 或你克隆的目录
love .
```
> LÖVE2D 会自动读取当前目录下的 `main.lua` 和 `conf.lua`。

### 3.2 预期效果（V0）

启动后你应该看到：

1. **1 秒左右的启动画面**：
   - 深色背景
   - 白色大字 "Trillion Games 2D"
   - 紫色小字 "Vale"
   - 下方灰色 "Loading..."
2. **淡入切换到演示场景**（淡入淡出效果约 0.5 秒）：
   - 大字 "Hello Engine" 和 "Core systems operational — Crimson"
   - 一个红色方块上下浮动，带阴影（模拟伪纵深）和光晕
   - 左下角显示 FPS、当前 Scene、Frame 数、内存占用
   - 左上角按键说明
   - 右侧显示 5 个渲染层名称
   - 左下角底部显示快捷键提示

### 3.3 交互操作

| 按键/操作 | 功能 |
|-----------|------|
| `1` / `2` / `3` | 切换方块颜色（红 / 蓝 / 绿） |
| `Space` | 方块弹性缩放动画 |
| 鼠标左键点击画布任意位置 | 在点击处产生彩色涟漪效果 |
| 鼠标右键 | 切换到下一个颜色 |
| `F11` | 切换全屏/窗口 |
| `F12` | 截图（保存到 LÖVE 存档目录，见下文） |
| `ESC` | 退出游戏 |

### 3.4 截图位置

F12 截图保存在 LÖVE2D 的存档目录：
- Linux: `~/.local/share/love/trillion_games_vale/`
- Windows: `C:\Users\<用户名>\AppData\Roaming\LOVE\trillion_games_vale\`
- macOS: `~/Library/Application Support/LOVE/trillion_games_vale/`

用户配置 `user_config.lua` 也保存在该目录。

### 3.5 控制台输出

运行时终端会显示彩色分级日志：
```
[INFO] [config] No user config found, using defaults
[INFO] [engine] === Trillion Games 2D Engine Starting ===
[INFO] [engine] LÖVE2D version: 11.3.0
[INFO] [engine] Screen: 1280x720
[DEBUG] [scene] Registered scene: boot
[DEBUG] [scene] Registered scene: demo
[INFO] [scene] Switching: (none) -> boot
[INFO] [boot_scene] Booting...
[INFO] [engine] === Engine initialized in 0.00s ===
[INFO] [boot_scene] Boot complete, switching to 'demo'
[INFO] [demo_scene] Loaded
```
- 青色 = DEBUG
- 绿色 = INFO
- 黄色 = WARN
- 红色 = ERROR

如果需要更安静的输出，修改 `src/core/config.lua` 中 defaults.debug.log_level 为 `"INFO"` 或 `"WARN"`。

---

## 四、打包发布相关命令（V5 会自动化，V0 仅供参考）

### 4.1 生成 .love 文件（所有平台通用的游戏包）
```bash
cd /home/love2DGame_vale
zip -9 -r trillion_games.love . \
    -x "*.git*" -x "tests/*" -x "docs/*" -x "*.md" -x "*.zip" -x "*.tar.gz"
```
生成的 `.love` 文件可用任何平台的 LÖVE2D 打开。

### 4.2 直接用 LÖVE 运行 .love
```bash
love trillion_games.love
```

---

## 五、项目文件结构（对照代码）

```
love2DGame_vale/
├── main.lua                     ← LÖVE2D 入口（love.load/update/draw 委托给 engine）
├── conf.lua                     ← LÖVE2D 配置（窗口/模块开关/分辨率）
├── README.md                    ← 项目介绍
├── CHANGELOG.md                 ← 版本变更记录
├── SETUP.md                     ← 本文件
├── .gitignore                   ← Git 忽略规则
├── docs/                        ← 项目设计文档
│   ├── 01-vision.md             ← 愿景
│   ├── 02-methodology.md        ← 开发方法论（迭代式）
│   ├── 03-architecture.md       ← 整体架构
│   ├── 04-roadmap.md            ← V0-V5 详细路线图
│   ├── 05-coding-standards.md   ← 代码规范（含 Lua 速查）
│   ├── 06-key-modules.md        ← 关键模块说明
│   └── 07-publishing.md         ← 发布路径（Steam/APK/桌面）
├── src/
│   ├── core/                    ← 核心基础层（V0 完成，完全通用）
│   │   ├── engine.lua           ← 游戏循环调度器
│   │   ├── config.lua           ← 配置加载/持久化
│   │   ├── logger.lua           ← 分级日志
│   │   ├── event.lua            ← 事件总线
│   │   ├── input.lua            ← 输入抽象层
│   │   ├── resource.lua         ← 资源管理/缓存
│   │   ├── renderer.lua         ← 五层渲染器
│   │   ├── scene_manager.lua    ← 场景管理
│   │   ├── timer.lua            ← 计时器 + Tween
│   │   └── utils.lua            ← 工具函数
│   ├── engine/                  ← 通用游戏系统层（V2+ 逐步填充）
│   └── game/                    ← 中国象棋业务层（V1+ 开始写）
│       └── scenes/
│           ├── boot_scene.lua   ← 启动画面
│           └── demo_scene.lua   ← V0 演示场景
├── assets/                      ← 资源目录（V0 为空占位）
│   ├── images/
│   ├── fonts/
│   ├── sounds/
│   └── shaders/
└── tests/                       ← 测试脚本（后续填充）
```

---

## 六、注意事项（Important Notes）

### 6.1 Lua 初学者陷阱（V0 已经避免的坑）

1. **table 索引从 1 开始**，不是 0。第一个元素是 `tbl[1]`。
   V0 的所有代码都是 1-indexed，没有 C 风格的 0 索引。
2. **只有 `false` 和 `nil` 是假值**。`0` 和 `""`（空字符串）在 if 判断中是真！
3. **`..` 拼接字符串**，不是 `+`。`"hello" .. " " .. "world"`。
4. **`local` 关键字务必加**。不加 local 会污染全局环境。V0 代码里所有变量都带 local。
5. **`require` 路径用点分隔**：`require("core.engine")` 对应 `src/core/engine.lua`。
   `src/` 前缀已在 main.lua 里加入 `package.path`，所以不用写 `src.core.engine`。
6. **函数定义两种写法**：
   - `M.foo = function(x) ... end` — 点号调用 `M.foo(x)`
   - `function M:foo(x) ... end` — 冒号调用 `M:foo(x)`，自动传入 `self`
   V0 混用了两种：模块 API 用点号，场景生命周期用冒号。

### 6.2 LÖVE2D 坑点

1. **颜色是 0-1 范围，不是 0-255**！`utils.color(255, 0, 0)` 返回 `{1, 0, 0}`。
   V0 已封装 `utils.color()` 转换，业务代码永远传 0-255。
2. **love.filesystem 的读写目录是隔离的**，不能直接写项目源码目录。
   跨平台存档/配置统一用 love.filesystem（`core/config.lua` 已封装）。
3. **坐标系原点 (0,0) 在左上角**，Y 轴向下，不是数学坐标系。
4. **窗口 resize 会让 Canvas 尺寸变化**，要在 love.resize 里处理（V0 engine 已处理）。
5. **dt (delta time) 在窗口拖动/卡顿后会很大**，V0 engine.update 里已 clamp 到 0.1 秒，防止跳帧。
6. **资源路径大小写敏感！** Linux/Android 严格区分 `Board.png` 和 `board.png`，Windows 不区分。
   后续加资源时全部用小写文件名，避免跨平台 bug。

### 6.3 Git / 版本管理注意

1. **永远不要 commit 构建产物**（.love、.zip、.exe、.apk）。已在 .gitignore 配置。
2. **每个版本一个 annotated tag**：`git tag -a vN.0.0 -m "VN: 描述"`。
3. **不要直接 push 大二进制资源**到 git（V5 如有大 BGM/高清图用 Git LFS）。
4. **切换 tag 后会进入 detached HEAD**，这是正常的，做完实验后 `git checkout main` 回来。

### 6.4 后续开发注意

1. **V0 是通用脚手架**，`src/core/` 的代码在 V1-V5 不要为象棋需求做侵入性修改。
   如果需要新增能力，优先放在 `src/engine/` 层。
2. **场景必须实现 `:load()`, `:update(dt)`, `:draw(r)`, `:unload()` 四个方法**。
   在 `:unload()` 里**务必**取消事件订阅和 tween（参考 demo_scene.lua 的 unload 写法），否则切场景后旧场景还在响应事件。
3. **绘制不要直接调用 love.graphics**，统一用 `r.rect(...)`, `r.text(...)` 等 renderer API 提交到层，保证分层顺序正确。需要直接画的用 `r.custom(layer, fn)`。
4. **配置项先加默认值**到 `src/core/config.lua` 的 defaults 表，再用 `config.get()` 读取。
5. **模块间不要直接 require 对方**，能用 event bus 就用 event bus。比如输入不调用场景，而是发 `input:mousepressed` 事件。

### 6.5 性能注意（提前提醒）

1. **不要在 update/draw 里创建 table**（比如每帧 `{x=..., y=...}`），GC 压力大。
   V0 里 demo_scene 涟漪创建是可以接受的小量，象棋正式版要避免每帧 new 对象。
2. **资源加载只做一次**（resource.lua 已做缓存，放心调用 getImage/getFont）。
3. **Tween 不要每帧创建**，在事件触发时创建。
4. **V3 AI 搜索时必须用 coroutine**，不能阻塞主循环超过 1 帧（16ms）。

### 6.6 调试技巧

1. **看 FPS/内存**：默认左上角 debug overlay 已显示，不需要时改 config `debug.show_fps = false`。
2. **打印 table**：`logger.dump("name", tbl)` 会递归打印内容。
3. **日志过滤**：`logger.setModule("scene")` 只显示 scene 模块的日志。
4. **单步调试 Lua**：推荐用 ZeroBrane Studio（支持 LÖVE2D 调试），V0 之后如果需要我再教你配置。
5. **热重载**：LÖVE2D 没有内置 hot reload，推荐装 [lovebird](https://github.com/rxi/lovebird) 或 [lurker](https://github.com/rxi/lurker) 实现改代码自动重启（V1 之后如果需要我加上）。

---

## 七、下一步（V1 预告）

V0 验收通过后，V1 "棋盘初现" 会：
- 加载中文字体
- 渲染 9×10 象棋棋盘（网格/楚河汉界/九宫斜线）
- 放置 32 枚棋子到初始位置
- 棋盘 15° 斜视角偏移 + 厚度 + 棋子椭圆阴影（伪纵深）
- Camera 居中适配窗口

想进入 V1 时告诉我即可。

---

## 八、故障排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `bash: love: command not found` | LÖVE2D 没装或不在 PATH | 见 2.1 节安装 |
| `Error: module 'core.xxx' not found` | 不在项目根目录运行 / package.path 错了 | `cd` 到项目根目录再 `love .` |
| 窗口乱码 / 中文显示为方块 | V0 默认字体不含中文 | **预期行为**，V1 才加载中文字体 |
| 全屏后黑屏 | Linux 某些窗口管理器兼容问题 | 按 F11 切回，或改 conf.lua window.fullscreen = false |
| 帧率低 / 卡顿 | 开了其他 GPU 重负载程序 | 象棋类游戏应该永远 60fps，如果低于 60 报 bug |
| 配置修改不生效 | 旧的 user_config.lua 覆盖了默认值 | 删除存档目录下的 user_config.lua 重启 |
