--! file: src/core/timer.lua
--! brief: 计时器 + Tween 补间动画系统
--! 类比：JS setTimeout/setInterval + tween.js
--! [LOVE] 没有内置 setTimeout，都是在 love.update(dt) 里累加时间
--! 用法：timer.after(2, function() ... end)  -- 2秒后执行
--!       timer.tween(0.5, obj, {x = 100}, "easeOutQuad", onComplete)

local logger = require("core.logger")

local M = {}

-- ===== 计时器列表 =====
local timers = {}
local next_timer_id = 1
local tweens = {}
local next_tween_id = 1

-- ===== Easing 函数（缓动曲线）=====
-- 数学来源：Robert Penner 的 easing equations
-- t = 当前时间比例 0~1，返回插值比例
M.easings = {
    -- 匀速
    linear = function(t) return t end,

    -- 先慢后快
    easeInQuad = function(t) return t * t end,
    easeInCubic = function(t) return t * t * t end,

    -- 先快后慢（落子动画用这个最自然）
    easeOutQuad = function(t) return 1 - (1 - t) * (1 - t) end,
    easeOutCubic = function(t) return 1 - math.pow(1 - t, 3) end,

    -- 过头回弹（按钮选中、UI 弹出用）
    easeOutBack = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
    end,

    -- 先加后减（对称）
    easeInOutQuad = function(t)
        if t < 0.5 then return 2 * t * t end
        return 1 - math.pow(-2 * t + 2, 2) / 2
    end,

    -- 弹性效果
    easeOutElastic = function(t)
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * (2 * math.pi) / 3) + 1
    end,
}

-- ===== 延时/定时 =====

--! 延时 seconds 秒后执行 callback
--! @return timer ID（可用于 cancel）
function M.after(seconds, callback)
    local id = next_timer_id
    next_timer_id = next_timer_id + 1
    timers[id] = {
        type     = "once",
        remaining = seconds,
        callback  = callback,
    }
    return id
end

--! 每间隔 seconds 秒重复执行 callback
--! @return timer ID
function M.every(seconds, callback)
    local id = next_timer_id
    next_timer_id = next_timer_id + 1
    timers[id] = {
        type     = "repeat",
        interval = seconds,
        remaining = seconds,
        callback = callback,
    }
    return id
end

--! 取消计时器
function M.cancel(id)
    if id and timers[id] then
        timers[id] = nil
    end
end

-- ===== Tween 补间 =====

--! 创建补间动画
--! @param duration 时长（秒）
--! @param target 要修改的 table（通常是某个对象的引用）
--! @param properties 目标属性值 {x = 100, y = 200, alpha = 0}
--! @param easing 缓动函数名（字符串，默认 "linear"）或函数
--! @param onComplete 完成回调（可选）
--! @return tween ID（可用于 cancel）
--!
--! 例子：
--!   timer.tween(0.3, piece, {x = 200}, "easeOutQuad", function()
--!       logger.info("anim", "Piece moved!")
--!   end)
function M.tween(duration, target, properties, easing, onComplete)
    assert(type(target) == "table", "tween target must be a table")
    assert(type(properties) == "table", "tween properties must be a table")

    local easing_fn = easing
    if type(easing) == "string" then
        easing_fn = M.easings[easing] or M.easings.linear
    end

    -- 记录起始值（tween 开始时各属性的当前值）
    local from = {}
    for k, v in pairs(properties) do
        from[k] = target[k]
    end

    local id = next_tween_id
    next_tween_id = next_tween_id + 1

    tweens[id] = {
        target     = target,
        from       = from,
        to         = properties,
        duration   = duration,
        elapsed    = 0,
        easing     = easing_fn or M.easings.linear,
        onComplete = onComplete,
    }
    return id
end

--! 取消 tween
function M.cancelTween(id)
    if id and tweens[id] then
        tweens[id] = nil
    end
end

--! 取消所有 tween 和 timer（场景切换时调用）
function M.clearAll()
    timers = {}
    tweens = {}
end

-- ===== 每帧更新 =====
-- 由 engine.update(dt) 调用
function M.update(dt)
    -- 处理 timers
    local to_remove = {}
    for id, timer in pairs(timers) do
        timer.remaining = timer.remaining - dt
        if timer.remaining <= 0 then
            if timer.type == "once" then
                table.insert(to_remove, id)
                -- [Lua] pcall 保护回调
                local ok, err = pcall(timer.callback)
                if not ok then
                    logger.error("timer", "Timer callback error: %s", tostring(err))
                end
            elseif timer.type == "repeat" then
                local ok, err = pcall(timer.callback)
                if not ok then
                    logger.error("timer", "Interval callback error: %s", tostring(err))
                end
                timer.remaining = timer.interval
            end
        end
    end
    for _, id in ipairs(to_remove) do
        timers[id] = nil
    end

    -- 处理 tweens
    local tween_remove = {}
    for id, tw in pairs(tweens) do
        tw.elapsed = tw.elapsed + dt
        local t = tw.elapsed / tw.duration
        if t >= 1 then
            t = 1
        end

        local eased = tw.easing(t)

        -- 对每个属性插值
        for k, to_val in pairs(tw.to) do
            local from_val = tw.from[k]
            if from_val ~= nil then
                tw.target[k] = from_val + (to_val - from_val) * eased
            end
        end

        if t >= 1 then
            table.insert(tween_remove, id)
            if tw.onComplete then
                local ok, err = pcall(tw.onComplete)
                if not ok then
                    logger.error("timer", "Tween onComplete error: %s", tostring(err))
                end
            end
        end
    end
    for _, id in ipairs(tween_remove) do
        tweens[id] = nil
    end
end

return M
