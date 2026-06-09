--! file: src/core/event.lua
--! brief: 事件总线（发布/订阅模式）
--! 类比：JS EventEmitter / Python blinker / Java EventBus
--! 作用：模块间松耦合通信，不需要互相 require

local logger = require("core.logger")

local M = {}

-- 存储：{ event_name = { callback1, callback2, ... } }
local listeners = {}
-- 延迟事件队列（避免在 emit 过程中修改 listeners 导致问题）
local pending_events = {}
local emitting = false

--! 订阅事件
--! @param name 事件名，string，建议用 "模块:动作" 格式（如 "piece:captured"）
--! @param callback 回调函数 function(data)
--! @return 取消订阅的函数（调用后取消）
function M.on(name, callback)
    assert(type(name) == "string", "event.on: name must be string")
    assert(type(callback) == "function", "event.on: callback must be function")

    if not listeners[name] then
        listeners[name] = {}
    end
    table.insert(listeners[name], callback)

    logger.debug("event", "Subscribed to '%s' (total: %d)", name, #listeners[name])

    -- 返回一个取消订阅的函数（类似 JS 的 AbortController 思路）
    return function()
        M.off(name, callback)
    end
end

--! 取消订阅
function M.off(name, callback)
    if not listeners[name] then return end
    for i, cb in ipairs(listeners[name]) do
        if cb == callback then
            table.remove(listeners[name], i)
            break
        end
    end
    if #listeners[name] == 0 then
        listeners[name] = nil
    end
end

--! 发布事件（同步：立即调用所有监听器）
--! 如果在 emit 过程中又 emit 了同一个事件，会排队处理避免递归
function M.emit(name, data)
    if not listeners[name] then return end

    if emitting then
        -- 正在 emit 其他事件，排队
        table.insert(pending_events, { name = name, data = data })
        return
    end

    emitting = true

    -- [Lua] 复制一份监听器列表，防止回调中 off/on 导致遍历问题
    -- 类比：JS 数组 [...listeners] 浅拷贝
    local cbs = {}
    for _, cb in ipairs(listeners[name] or {}) do
        table.insert(cbs, cb)
    end

    for _, cb in ipairs(cbs) do
        -- [Lua] pcall 保护，一个监听器报错不影响其他监听器
        local ok, err = pcall(cb, data)
        if not ok then
            logger.error("event", "Error in listener for '%s': %s", name, tostring(err))
        end
    end

    emitting = false

    -- 处理排队的事件
    while #pending_events > 0 do
        local evt = table.remove(pending_events, 1)
        M.emit(evt.name, evt.data)
    end
end

--! 是否有监听器
function M.hasListeners(name)
    return listeners[name] ~= nil and #listeners[name] > 0
end

--! 清除某个事件的所有监听器
function M.clear(name)
    if name then
        listeners[name] = nil
    else
        listeners = {}
    end
end

return M
