# 06 - 关键模块说明 (Key Modules)

## Core 层（V0 实现，完全通用）

### core/engine.lua — 游戏循环调度器
**类比：** JS 的 requestAnimationFrame 主循环 / Python 游戏的 main loop
**职责：**
- `engine.init(config_table)` — 初始化所有子模块，进入 boot 场景
- `engine.update(dt)` — 调用 timer/input/scene_manager 的 update
- `engine.draw()` — 调用 renderer.draw() 画所有层
- 这是整个程序的"心脏"，LÖVE2D 的 `love.update`/`love.draw` 都委托给它
**接口：**
```lua
engine.init({ title = "...", width = 1280, height = 720, ... })
engine.update(dt)
engine.draw()
engine.getSceneManager()
engine.getRenderer()
```

### core/config.lua — 配置系统
**类比：** Python 的 configparser / JS 的 dotenv
**职责：**
- 加载默认配置 + 合并用户配置（love.filesystem 读取）
- 提供 `config.get("key")` / `config.set("key", value)`
- 持久化到 save directory
**默认配置项：**
- window.width, window.height, window.fullscreen, window.vsync
- audio.bgm_volume, audio.sfx_volume
- debug.show_fps, debug.log_level

### core/logger.lua — 日志
**类比：** Python logging / JS console 的分级输出
**职责：**
- `logger.debug/info/warn/error(msg)` 四级日志
- 输出格式：`[LEVEL] [module] message`
- 根据 config 中的 log_level 过滤
- V0 只输出到控制台（print），V5 可扩展输出到文件

### core/event.lua — 事件总线
**类比：** JS EventEmitter / Python blinker / Java EventBus
**职责：**
- `event.on(name, callback)` — 订阅
- `event.off(name, callback)` — 取消订阅
- `event.emit(name, data)` — 发布（同步，立即调用所有回调）
- 模块间零耦合通信
**用法：**
```lua
event.on("piece:captured", function(data)
    logger.info("Captured!", data.captured.type)
end)
event.emit("piece:captured", { captured = piece })
```

### core/input.lua — 输入抽象
**类比：** Unity Input System / Python pygame key.get_pressed()
**职责：**
- 维护当前帧的键盘/鼠标状态
- 提供 "action" 映射（配置文件里把 "escape" 映射到 "quit" action）
- 检测 pressed/released/held 三种状态
- V2+ 扩展 touch 支持（为 APK 准备）
**API：**
```lua
input.isDown("left")           -- 当前是否按住
input.wasPressed("space")      -- 这帧刚按下（边缘触发）
input.wasReleased("space")     -- 这帧刚松开
input.getMousePosition()       -- {x, y}
input.getMouseWheel()          -- 滚轮
```

### core/resource.lua — 资源管理
**类比：** Webpack asset pipeline / Unity Resources.Load
**职责：**
- 统一加载图片/字体/音效/Shader，带缓存
- `resource.getImage(path)` 首次加载并缓存，后续取缓存
- `resource.getFont(path, size)` 字体缓存（同字体不同 size 分开缓存）
- `resource.preload({{type="image", path="xx.png"}, ...})` 预加载一批
- V4 可扩展异步加载带进度条
**注意：** 路径是相对于 assets/ 目录的，模块内部拼接前缀。

### core/renderer.lua — 分层渲染
**类比：** CSS z-index 分层 / Unity Sorting Layers
**职责：**
- 管理 5 个渲染层：background, world, effects, ui, overlay
- 每帧清空后按顺序绘制各层
- 每层是一个 draw list，由 scene 往里面添加 draw command
- `renderer.drawRect(layer, x, y, w, h, color)` / `drawText(layer, ...)` / `drawImage(layer, ...)`
- V1 后会添加 camera 变换支持（world/effects 层应用 camera）

### core/scene_manager.lua — 场景管理
**类比：** Phaser Scene Manager / Unity SceneManager
**职责：**
- `scene_manager.switch(name, params)` — 切换场景（带淡入淡出过渡）
- `scene_manager.current()` — 返回当前场景
- 场景需实现接口：`:load(params)`, `:update(dt)`, `:draw(renderer)`, `:unload()`
- 切换时旧场景 unload，新场景 load，自动收集垃圾
**内置过渡：** V0 有简单的黑色 fade in/out，时长可配置。

### core/timer.lua — 计时器 + Tween
**类比：** JS setTimeout/setInterval + tween.js
**职责：**
- `timer.after(seconds, callback)` — 延时执行
- `timer.every(seconds, callback)` — 定时重复
- `timer.tween(duration, from, to, easing, onUpdate, onComplete)` — 补间动画
- 提供常用 easing 函数：linear, easeOutQuad, easeOutBack, easeInOutQuad
- 所有 timer 句柄可 cancel
**注意：** tween 只修改传入的 table 字段，不负责渲染。业务代码把动画目标值传给 tween，然后在 draw 里使用该值。

### core/utils.lua — 工具函数
**类比：** Lodash (JS) / Apache Commons (Java)
**内容：**
- `utils.copy(tbl)` — 深拷贝 table
- `utils.clamp(v, min, max)` — 夹紧
- `utils.lerp(a, b, t)` — 线性插值
- `utils.distance(x1,y1,x2,y2)` — 欧几里得距离
- `utils.color(r,g,b,a)` — 返回 {r/255, g/255, b/255, a/255}（LÖVE 颜色是 0-1）
- `utils.sign(v)` — 返回符号
- `utils.contains(tbl, val)` — 数组是否包含值
- `utils.printTable(tbl, indent)` — debug 打印

---

## Engine 层（V1+ 逐步实现，通用游戏系统）

### engine/ui/ — UI 组件框架（V4 重点）
- Button、Panel、Label、Slider、Dialog
- 自动布局、hover/click 反馈
- 9-patch 支持

### engine/audio/ — 音效管理（V2）
- BGM 循环播放、淡入淡出
- SFX 一次性播放，音量独立
- 音频源池（避免频繁 newSource）

### engine/particles/ — 粒子（V2）
- 封装 love.graphics.ParticleSystem
- 预设效果：dust（落子灰尘）、spark（吃子火花）、fireworks（胜利烟花）

### engine/anim/ — 动画扩展（V2）
- timer.tween 的高级封装：按 target 对象和属性名自动 bind
- 序列动画（seq1:then(seq2)）
- 弹性、震动效果

### engine/camera/ — 相机（V1 基础版，V3 扩展）
- 位置、缩放、屏幕震动
- world 坐标 ↔ 屏幕坐标转换

### engine/save/ — 存档（V4）
- 序列化 game state 到 JSON（用 lunajson 或自写简单序列化）
- 多存档位、自动存档

### engine/fsm/ — 有限状态机（V3）
- 通用 FSM，用于 game state（playing/gameover/menu/paused）
- 状态转换时触发事件

---

## Game 层（V1+ 实现，象棋专属）

### game/scenes/
- BootScene（V0 就有）— 显示 loading，切到 MainMenu（V4）或直接进 BoardScene（V1-V3）
- BoardScene（V1）— 棋盘主场景
- MainMenuScene（V4）— 主菜单
- SettingsScene（V4）— 设置

### game/entities/
- Piece（V1）— 棋子数据（type, color, position, alive）
- Board（V1）— 棋盘状态（9×10 数组）

### game/systems/
- MoveValidator（V2）— 各兵种走法校验
- RuleEngine（V3）— 将军/将死/和棋判定
- AI（V3）— Minimax AI
- MoveHistory（V3）— 走棋历史与简记

### game/renderers/（V1）
- BoardRenderer — 画棋盘（网格/河界/九宫/木纹/厚度）
- PieceRenderer — 画棋子（圆形/文字/阴影）
