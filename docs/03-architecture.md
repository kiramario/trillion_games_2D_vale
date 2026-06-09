# 03 - 整体架构 (Architecture)

## 分层架构图

```
┌──────────────────────────────────────────────────────────┐
│                    Game Layer (游戏业务层)                 │
│  ┌────────────────┐  ┌────────────────┐                  │
│  │  chess (象棋)   │  │  pinball (未来) │  ...            │
│  │  scenes/        │  │  scenes/        │                  │
│  │  entities/      │  │  entities/      │                  │
│  │  systems/       │  │  systems/       │                  │
│  └────────────────┘  └────────────────┘                  │
├──────────────────────────────────────────────────────────┤
│                  Engine Layer (通用游戏系统层)              │
│  ui/  audio/  particles/  anim/  camera/  save/  fsm/   │
│  (这些模块任何 2D 游戏都能复用)                              │
├──────────────────────────────────────────────────────────┤
│                   Core Layer (核心基础层)                  │
│  engine (game loop)  config  logger  event  input         │
│  resource  renderer  scene_manager  timer  utils          │
│  (完全与具体游戏无关，换游戏一行不动)                          │
├──────────────────────────────────────────────────────────┤
│                     LÖVE2D 11.x API                       │
│  love.graphics  love.audio  love.filesystem  ...          │
└──────────────────────────────────────────────────────────┘
```

## 核心数据流

```
main.lua (LÖVE2D 入口)
  └─ love.load()
       └─ core/engine.init()  ── 加载 config, logger, 初始化各模块
            └─ scene_manager.switch("boot")
  └─ love.update(dt)  ── 每帧 ~60fps
       └─ engine.update(dt)
            ├─ timer.update(dt)          # 计时/缓动
            ├─ input.update(dt)          # 输入状态刷新
            ├─ scene_manager.update(dt)  # 当前场景 update
            └─ event.dispatch()          # 处理积压事件
  └─ love.draw()
       └─ engine.draw()
            └─ renderer.draw()
                 ├─ layer "background"   # 场景画背景
                 ├─ layer "world"        # 棋盘/棋子
                 ├─ layer "effects"      # 粒子/光效
                 ├─ layer "ui"           # UI 元素
                 └─ layer "overlay"      # 弹窗/debug 信息
```

## 设计原则

### 1. 依赖方向单向
```
Game → Engine → Core → LÖVE2D
```
Core 层不知道 Engine 和 Game 存在；Engine 层不知道 Game 存在；Game 层可以使用所有下层。绝不反向依赖。

### 2. 模块间通过事件松耦合
```lua
-- 模块 A 发事件：
event.emit("piece:captured", { attacker = piece1, captured = piece2 })

-- 模块 B 监听：
event.on("piece:captured", function(data)
    audio.play("capture")
    particles.spawn("capture_dust", data.captured.x, data.captured.y)
end)
```
这等同于 JS 的 EventEmitter、Python 的 blinker/pubsub。模块之间不需要 require 对方。

### 3. 场景就是一切
每个场景 (Scene) 是一个实现了 `:load()`, `:update(dt)`, `:draw()`, `:unload()` 的表 (table)。
等同于 JS 游戏框架 Phaser 的 Scene 概念。场景切换时旧场景 unload、新场景 load。

### 4. 资源统一由 ResourceManager 管理
不允许在业务代码里直接写 `love.graphics.newImage("xxx.png")`，统一走 `resource.getImage("xxx")`。
好处：自动缓存、自动预热、统一路径前缀、方便后续做异步加载。

### 5. 配置驱动
窗口大小、音量、全屏、色彩主题都从 config 读，不写死在代码里。

## 目录结构（最终态示意）

```
love2DGame_vale/
├── main.lua                      # LÖVE2D 入口
├── conf.lua                      # LÖVE2D 配置（窗口尺寸/版本/模块开关）
├── CHANGELOG.md                  # 版本变更记录
├── README.md
├── .gitignore
├── docs/                         # 所有项目文档
│   ├── 01-vision.md
│   ├── 02-methodology.md
│   ├── 03-architecture.md
│   ├── 04-roadmap.md
│   ├── 05-coding-standards.md
│   ├── 06-key-modules.md
│   └── 07-publishing.md
├── src/
│   ├── core/                     # 核心基础层（完全通用）
│   │   ├── init.lua              # package.path 设置 + core 模块聚合
│   │   ├── engine.lua            # 游戏循环调度器
│   │   ├── config.lua            # 配置加载/读取/写回
│   │   ├── logger.lua            # 日志（debug/info/warn/error）
│   │   ├── event.lua             # 事件总线
│   │   ├── input.lua             # 输入抽象（keyboard/mouse/touch）
│   │   ├── resource.lua          # 资源加载/缓存
│   │   ├── renderer.lua          # 分层渲染器
│   │   ├── scene_manager.lua     # 场景管理器
│   │   ├── timer.lua             # 计时器 + Tween 框架
│   │   └── utils.lua             # 工具函数
│   ├── engine/                   # 通用游戏系统层（V2+ 逐步填充）
│   │   ├── ui/
│   │   ├── audio/
│   │   ├── particles/
│   │   ├── anim/
│   │   ├── camera/
│   │   ├── save/
│   │   └── fsm/
│   └── game/                     # 中国象棋业务层（V1+ 开始写）
│       ├── scenes/
│       ├── entities/
│       ├── systems/
│       └── ui/
├── assets/
│   ├── images/
│   ├── fonts/
│   ├── sounds/
│   └── shaders/
└── tests/                        # 手动测试脚本
```
