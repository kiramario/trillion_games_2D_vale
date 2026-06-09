--! file: conf.lua
--! brief: LÖVE2D 全局配置文件
--!
--! [LOVE] conf.lua 是一个特殊文件，LÖVE2D 在加载 main.lua 之前会先执行它。
--! 类比：类似 JS 框架的 next.config.js / Python Flask 的 app.config
--! 在这里你设置窗口大小、标题、要启用哪些模块（禁用不用的模块可以减少内存占用）

function love.conf(t)
    -- 窗口标题
    t.identity = "trillion_games_vale"    -- [LOVE] 存档目录名（love.filesystem 的读写目录）
    t.version  = "11.3"                  -- 目标 LÖVE 版本，和你本地装的一致
    t.console  = false                   -- Windows 上是否弹出控制台（开发时可设 true，发布时 false）

    -- 窗口配置
    t.window.title      = "Trillion Games 2D - Vale"
    t.window.icon       = nil            -- 窗口图标路径，V5 再放真实图标
    t.window.width      = 1280
    t.window.height     = 720
    t.window.minwidth   = 800
    t.window.minheight  = 600
    t.window.resizable  = true
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"  -- "desktop" = 无边框窗口全屏；"exclusive" = 真全屏
    t.window.vsync      = 1              -- 1 = 开启垂直同步（防止画面撕裂），0 = 关闭
    t.window.msaa       = 0              -- 多重采样抗锯齿（0 = 关，棋盘类游戏不需要）
    t.window.highdpi    = true           -- 高 DPI 屏幕适配（Retina 显示器）

    -- [LOVE] 模块开关：禁用不需要的模块以节省内存和启动时间
    -- V0 只开最基础的；V2+ 按需打开 audio 等
    t.modules.audio    = true
    t.modules.event    = true
    t.modules.graphics = true
    t.modules.image    = true
    t.modules.joystick = false           -- 手柄支持，V5 再加
    t.modules.keyboard = true
    t.modules.math     = true
    t.modules.mouse    = true
    t.modules.physics  = false           -- Box2D 物理引擎，象棋完全不需要，弹珠游戏也自己写简单物理
    t.modules.sound    = true
    t.modules.system   = true
    t.modules.timer    = true
    t.modules.touch    = true            -- APK 需要，先开着不影响桌面
    t.modules.video    = false           -- 视频播放，不需要
    t.modules.window   = true
    t.modules.thread  = true
end
