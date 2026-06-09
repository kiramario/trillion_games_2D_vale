--! file: src/core/engine.lua
--! brief: 核心引擎调度器（游戏循环的大脑）
--! 类比：整个游戏的 App 组件 / Game Loop Controller
--!
--! 负责把 LÖVE2D 的 love.load/update/draw 回调分发给各子系统。
--! 这是 Core 层唯一"指挥全局"的模块。

local config = require("core.config")
local logger = require("core.logger")
local event = require("core.event")
local input = require("core.input")
local resource = require("core.resource")
local renderer = require("core.renderer")
local scene_manager = require("core.scene_manager")
local timer = require("core.timer")
local utils = require("core.utils")

local M = {}

local initialized = false
local start_time = 0
local frame_count = 0
local fps = 0
local fps_accum = 0
local fps_frames = 0

--! 引擎初始化
--! @param opts { title, width, height, debug }
function M.init(opts)
    if initialized then
        logger.warn("engine", "Engine already initialized, skipping")
        return
    end
    opts = opts or {}

    -- 配置系统
    config.init()
    logger.setLevel(config.get("debug.log_level", "DEBUG"))

    logger.info("engine", "=== Trillion Games 2D Engine Starting ===")
    -- [LOVE] love.getVersion() 返回多个值（major, minor, revision）
    local maj, min, rev = love.getVersion()
    logger.info("engine", "LÖVE2D version: %d.%d.%d", maj, min, rev)
    logger.info("engine", "Screen: %dx%d", love.graphics.getWidth(), love.graphics.getHeight())

    -- 初始化渲染器
    renderer.init()

    -- 注册所有场景
    local boot_scene = require("game.scenes.boot_scene")
    local demo_scene = require("game.scenes.demo_scene")
    local board_scene = require("game.scenes.board_scene")
    local menu_scene = require("game.scenes.menu_scene")
    scene_manager.register("boot", boot_scene)
    scene_manager.register("demo", demo_scene)
    scene_manager.register("board", board_scene)
    scene_manager.register("menu", menu_scene)

    -- V4+ 启动到菜单场景
    scene_manager.switch("boot", { next = "menu", next_delay = 1.0 }, { fade = false })

    -- 绑定全局输入快捷键
    input.bindAction("screenshot", {"f12"})
    input.bindAction("toggle_fullscreen", {"f11"})
    input.bindAction("quit", {"lctrl", "q", "rctrl", "q"})  -- Ctrl+Q 退出，ESC 留给场景处理

    -- V5: Steamworks 钩子（如果 luasteam 可用自动启用，否则静默）
    local steam = require("core.steam")
    steam.init()

    -- [LOVE] 绑定事件：engine:shutdown 在退出时调用
    event.on("engine:quit_requested", function() M.shutdown() end)

    start_time = love.timer.getTime()
    initialized = true

    logger.info("engine", "=== Engine initialized in %.2fs ===", love.timer.getTime() - start_time)

    event.emit("engine:ready")
end

--! 每帧更新
function M.update(dt)
    if not initialized then return end

    -- 限制 dt 最大值（窗口被拖动/卡顿后恢复时，避免 dt 太大导致物理/动画跳帧）
    if dt > 0.1 then dt = 0.1 end

    frame_count = frame_count + 1

    -- FPS 统计
    fps_accum = fps_accum + dt
    fps_frames = fps_frames + 1
    if fps_accum >= 1.0 then
        fps = fps_frames / fps_accum
        fps_accum = 0
        fps_frames = 0
    end

    -- 更新 timer 系统（延时、重复计时、tween）
    timer.update(dt)

    -- 更新输入（清除 wasPressed/wasReleased 状态，这在每帧结束时也做）
    -- 这里先不调 input.update()，因为场景 update 可能要读 wasPressed

    -- 场景更新
    scene_manager.update(dt)

    -- 全局快捷键
    if input.actionPressed("toggle_fullscreen") then
        local full = not love.window.getFullscreen()
        love.window.setFullscreen(full)
        logger.info("engine", "Fullscreen: %s", tostring(full))
    end
    if input.actionPressed("screenshot") then
        M._takeScreenshot()
    end
    if input.actionPressed("quit") then
        event.emit("engine:quit_requested")
        love.event.quit()
    end

    -- 帧末清除输入状态
    input.update(dt)
end

--! 每帧绘制
function M.draw()
    if not initialized then return end

    renderer.clear()

    -- 场景往 renderer 提交绘制命令
    scene_manager.draw(renderer)

    -- Debug overlay（FPS、版本信息等）
    M._drawDebugOverlay(renderer)

    -- renderer 统一执行绘制
    renderer.draw()
end

--! 窗口大小变化
function M.resize(w, h)
    logger.info("engine", "Window resized to %dx%d", w, h)
    event.emit("window:resized", { width = w, height = h })
    local sm = scene_manager
    local cur = sm.current and sm.current()  -- current 是函数
    if cur and cur.resize then
        cur:resize(w, h)
    end
end

--! 关闭引擎
function M.shutdown()
    logger.info("engine", "Engine shutting down...")
    -- 保存用户配置
    config.save()
    event.emit("engine:shutdown")
    logger.info("engine", "Goodbye!")
end

--! 获取子系统引用（给 main.lua 用）
function M.getInput()        return input end
function M.getRenderer()     return renderer end
function M.getSceneManager() return scene_manager end
function M.getConfig()       return config end
function M.getTimer()        return timer end
function M.getEvent()        return event end
function M.getResource()     return resource end
function M.getFPS()          return math.floor(fps) end

-- ===== 内部 =====

-- 绘制 debug 覆盖层
function M._drawDebugOverlay(r)
    if not config.get("debug.show_fps", true) then return end

    local lg = love.graphics
    local font = resource.getFont(nil, 14)
    local y = 10

    -- FPS
    r.text("overlay", string.format("FPS: %d", math.floor(fps)), 10, y, utils.color(0, 255, 100), font)
    y = y + 20

    -- 场景名
    r.text("overlay", string.format("Scene: %s", scene_manager.currentName() or "?"), 10, y, utils.color(200, 200, 200), font)
    y = y + 20

    -- 帧数
    r.text("overlay", string.format("Frame: %d", frame_count), 10, y, utils.color(150, 150, 150), font)
    y = y + 20

    -- 内存（Lua 内存 KB）
    local mem = collectgarbage("count")
    r.text("overlay", string.format("Mem: %.1f KB", mem), 10, y, utils.color(150, 150, 150), font)
    y = y + 20

    -- 提示
    r.text("overlay", "ESC=quit | 1/2/3=demo colors | F11=fullscreen | F12=screenshot",
           10, lg.getHeight() - 24, utils.color(120, 120, 120), font)
end

-- 截图
function M._takeScreenshot()
    -- [LOVE] love.graphics.captureScreenshot 返回 ImageData 或写入文件
    local filename = string.format("screenshot_%d.png", os.time())
    love.graphics.captureScreenshot(filename)
    logger.info("engine", "Screenshot saved: %s", filename)
end

return M
