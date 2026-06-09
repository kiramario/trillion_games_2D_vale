--! file: src/core/scene_manager.lua
--! brief: 场景管理器
--! 类比：Phaser Scene Manager / Unity SceneManager
--!
--! 场景是实现了 :load(params), :update(dt), :draw(renderer), :unload() 的 table
--! 场景切换时旧场景 unload，新场景 load
--! V0 支持简单的淡入淡出过渡效果

local logger = require("core.logger")
local event = require("core.event")
local timer = require("core.timer")
local renderer = require("core.renderer")

local M = {}

-- 场景注册表: { name = scene_factory }
-- scene_factory 是一个返回场景实例的函数（或者就是场景 table 本身）
local scenes = {}
local current = nil
local current_name = nil
local transition = nil  -- 当前过渡动画状态

--! 注册场景
--! @param name 场景名
--! @param scene 场景 table（或返回场景的工厂函数）
function M.register(name, scene)
    scenes[name] = scene
    logger.debug("scene", "Registered scene: %s", name)
end

--! 获取当前场景
function M.current()
    return current
end

function M.currentName()
    return current_name
end

--! 切换场景
--! @param name 场景名
--! @param params 传给新场景 :load() 的参数
--! @param options { fade = true/false, fade_duration = 0.3 }
function M.switch(name, params, options)
    if not scenes[name] then
        logger.error("scene", "Cannot switch to unknown scene: %s", name)
        return
    end

    options = options or { fade = true, fade_duration = 0.3 }

    logger.info("scene", "Switching: %s -> %s", current_name or "(none)", name)

    -- 卸载当前场景
    if current and current.unload then
        local ok, err = pcall(current.unload, current)
        if not ok then
            logger.error("scene", "Error unloading %s: %s", current_name, err)
        end
    end

    -- 清理 timer 里的计时器（场景切换时不把计时器带到新场景）
    timer.clearAll()

    event.emit("scene:unload", { name = current_name })

    -- 加载新场景
    local new_scene
    if type(scenes[name]) == "function" then
        new_scene = scenes[name]()  -- 工厂模式
    else
        new_scene = scenes[name]    -- 直接是 table
    end

    current = new_scene
    current_name = name

    if current.load then
        local ok, err = pcall(current.load, current, params)
        if not ok then
            logger.error("scene", "Error loading %s: %s", name, err)
        end
    end

    event.emit("scene:load", { name = name, params = params })

    -- 淡入效果
    if options.fade then
        transition = {
            type = "fade_in",
            duration = options.fade_duration or 0.3,
            elapsed = 0,
            alpha = 1,
        }
    end
end

--! reload 当前场景（重新调用 load）
function M.reload(params)
    if current and current.load then
        current:load(params)
    end
end

-- ===== 更新 =====
function M.update(dt)
    -- 更新过渡动画
    if transition then
        transition.elapsed = transition.elapsed + dt
        local t = transition.elapsed / transition.duration
        if t > 1 then t = 1 end

        if transition.type == "fade_in" then
            transition.alpha = 1 - t  -- 从 1（黑）到 0（透明）
        end

        if transition.elapsed >= transition.duration then
            transition = nil
        end
    end

    if current and current.update then
        local ok, err = pcall(current.update, current, dt)
        if not ok then
            logger.error("scene", "Error updating %s: %s", current_name, err)
        end
    end
end

-- ===== 绘制 =====
function M.draw(r)
    if current and current.draw then
        local ok, err = pcall(current.draw, current, r)
        if not ok then
            logger.error("scene", "Error drawing %s: %s", current_name, err)
            -- 在场景画错时显示错误文字
            r.text(r.LAYERS.OVERLAY, "Scene error: " .. tostring(err), 20, 20,
                utils and utils.COLORS.RED or {1,0,0,1})
        end
    end

    -- 绘制过渡黑屏
    if transition then
        local lg = love.graphics
        lg.setColor(0, 0, 0, transition.alpha)
        lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    end
end

return M
