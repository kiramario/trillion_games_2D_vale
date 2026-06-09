--! file: src/core/input.lua
--! brief: 输入抽象层
--! 类比：Unity Input System / pygame key.get_pressed()
--! 维护当前帧的键盘/鼠标状态，支持：
--!   - isDown: 当前是否按住
--!   - wasPressed: 这一帧刚按下（边缘触发）
--!   - wasReleased: 这一帧刚松开
--! 支持 action 映射：通过 bindings 表把物理按键映射到逻辑 action

local logger = require("core.logger")
local config = require("core.config")
local event = require("core.event")

local M = {}

-- ===== 物理按键状态 =====
local keys_down    = {}  -- key -> true（当前按下）
local keys_pressed = {}  -- key -> true（这帧刚按下）
local keys_released = {} -- key -> true（这帧刚松开）

-- ===== 鼠标状态 =====
local mouse = {
    x = 0, y = 0,
    dx = 0, dy = 0,
    buttons_down    = {},  -- button -> true
    buttons_pressed = {},  -- button -> true（这帧按下）
    buttons_released = {}, -- button -> true（这帧松开）
    wheel_x = 0,
    wheel_y = 0,
}

-- ===== Action 绑定 =====
-- 格式: { action_name = { "key1", "key2", ... } }
-- 例如 { quit = {"escape"}, confirm = {"return", "space"} }
local bindings = {
    quit    = {"escape"},
    confirm = {"return", "space"},
    cancel  = {"backspace", "delete"},
}

--! 注册按键到 action 的映射
function M.bindAction(action, ...)
    bindings[action] = {...}
end

--! 设置多个绑定（覆盖）
function M.setBindings(new_bindings)
    for k, v in pairs(new_bindings) do
        bindings[k] = v
    end
end

-- ===== 物理按键接口 =====

--! 当前是否按住某键（持续按住每帧都返回 true）
function M.isDown(key)
    return keys_down[key] == true
end

--! 这帧刚按下某键（只在按下的那一帧返回 true）
function M.wasPressed(key)
    return keys_pressed[key] == true
end

--! 这帧刚松开某键
function M.wasReleased(key)
    return keys_released[key] == true
end

-- ===== Action 接口 =====
-- 和物理按键接口一样，但用 action 名代替键名

local function isAnyKeyDown(keys)
    for _, k in ipairs(keys) do
        if keys_down[k] then return true end
    end
    return false
end

local function wasAnyKeyPressed(keys)
    for _, k in ipairs(keys) do
        if keys_pressed[k] then return true end
    end
    return false
end

local function wasAnyKeyReleased(keys)
    for _, k in ipairs(keys) do
        if keys_released[k] then return true end
    end
    return false
end

function M.actionDown(action)
    local b = bindings[action]
    if not b then return false end
    return isAnyKeyDown(b)
end

function M.actionPressed(action)
    local b = bindings[action]
    if not b then return false end
    return wasAnyKeyPressed(b)
end

function M.actionReleased(action)
    local b = bindings[action]
    if not b then return false end
    return wasAnyKeyReleased(b)
end

-- ===== 鼠标接口 =====

function M.getMousePosition()
    return mouse.x, mouse.y
end

function M.getMouseDelta()
    return mouse.dx, mouse.dy
end

function M.isMouseDown(button)
    button = button or 1
    return mouse.buttons_down[button] == true
end

function M.wasMousePressed(button)
    button = button or 1
    return mouse.buttons_pressed[button] == true
end

function M.wasMouseReleased(button)
    button = button or 1
    return mouse.buttons_released[button] == true
end

function M.getMouseWheel()
    return mouse.wheel_x, mouse.wheel_y
end

-- ===== LÖVE2D 回调（由 main.lua 调用）=====

function M.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        keys_pressed[key] = true
        keys_down[key] = true
    end
    event.emit("input:keypressed", { key = key, scancode = scancode, repeat_flag = isrepeat })
end

function M.keyreleased(key, scancode)
    keys_released[key] = true
    keys_down[key] = nil
    event.emit("input:keyreleased", { key = key, scancode = scancode })
end

function M.mousepressed(x, y, button, istouch, presses)
    mouse.buttons_pressed[button] = true
    mouse.buttons_down[button] = true
    mouse.x, mouse.y = x, y
    event.emit("input:mousepressed", { x = x, y = y, button = button, istouch = istouch })
end

function M.mousereleased(x, y, button, istouch, presses)
    mouse.buttons_released[button] = true
    mouse.buttons_down[button] = nil
    mouse.x, mouse.y = x, y
    event.emit("input:mousereleased", { x = x, y = y, button = button, istouch = istouch })
end

function M.mousemoved(x, y, dx, dy, istouch)
    mouse.x, mouse.y = x, y
    mouse.dx, mouse.dy = dx, dy
end

function M.textinput(text)
    event.emit("input:textinput", { text = text })
end

function M.wheelmoved(x, y)
    mouse.wheel_x = x
    mouse.wheel_y = y
    event.emit("input:wheelmoved", { x = x, y = y })
end

-- ===== 每帧结束时调用：清除一次性状态 =====
-- wasPressed / wasReleased 只在按下/松开那帧有效，update 结束后必须清空
function M.update(dt)
    keys_pressed = {}
    keys_released = {}
    mouse.buttons_pressed = {}
    mouse.buttons_released = {}
    mouse.dx = 0
    mouse.dy = 0
    mouse.wheel_x = 0
    mouse.wheel_y = 0
end

--! LÖVE2D 回调：鼠标滚轮
function M.wheelmovedHandler(x, y)
    -- 这个是给 love.wheelmoved 回调用的
    -- 实际上 LÖVE2D 把 wheelmoved 作为全局回调，不是 mousepressed 那种
end

return M
