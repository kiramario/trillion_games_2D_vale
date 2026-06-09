--! file: src/core/utils.lua
--! brief: 工具函数集合
--! 类比：类似 JS 的 Lodash / Python 的工具函数库
--! 这里放没有依赖、到处都会用的纯函数。

local M = {}

-- ===== 表（table）操作 =====

--! 深拷贝一个 table
--! [Lua] Lua 里赋值 table 是引用传递，要复制内容需要递归拷贝
--! 类比：JS 的 structuredClone() / Python 的 copy.deepcopy()
function M.deepcopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[M.deepcopy(k)] = M.deepcopy(v)
    end
    return setmetatable(copy, getmetatable(orig))
end

--! 浅拷贝
function M.shallowcopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

--! 数组是否包含某个值（线性查找，小数组用）
function M.contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

--! 数组合并（追加 b 到 a 末尾，返回新数组）
function M.concat(a, b)
    local result = {}
    for _, v in ipairs(a) do table.insert(result, v) end
    for _, v in ipairs(b) do table.insert(result, v) end
    return result
end

-- ===== 数学工具 =====

--! 把值夹在 [min, max] 范围内
--! 类比：Python 3 的 numpy.clip()
function M.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

--! 线性插值：在 a 和 b 之间，t=0 返回 a，t=1 返回 b
function M.lerp(a, b, t)
    return a + (b - a) * t
end

--! 欧几里得距离
function M.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy)
end

--! 符号函数：正数返回 1，负数返回 -1，零返回 0
function M.sign(v)
    if v > 0 then return 1 end
    if v < 0 then return -1 end
    return 0
end

--! 角度转弧度
function M.deg2rad(deg)
    return deg * math.pi / 180
end

--! 弧度转角度
function M.rad2deg(rad)
    return rad * 180 / math.pi
end

-- ===== 颜色工具 =====

--! 把 0-255 的 RGBA 转成 LÖVE 用的 0-1 范围
--! [LOVE] LÖVE 11.x 起颜色分量范围是 0-1，不是 0-255！
--! 为了方便，游戏代码里统一用 0-255，传入渲染前用这个函数转换
--! 用法: love.graphics.setColor(utils.color(255, 100, 50))
function M.color(r, g, b, a)
    return {
        r / 255,
        g / 255,
        b / 255,
        (a or 255) / 255
    }
end

--! 常用颜色常量（0-1 范围，可直接给 setColor 用）
M.COLORS = {
    WHITE   = {1, 1, 1, 1},
    BLACK   = {0, 0, 0, 1},
    RED     = {1, 0.2, 0.2, 1},
    GREEN   = {0.2, 1, 0.2, 1},
    BLUE    = {0.3, 0.5, 1, 1},
    YELLOW  = {1, 0.9, 0.2, 1},
    GRAY    = {0.5, 0.5, 0.5, 1},
    DARKGRAY = {0.15, 0.15, 0.18, 1},
    TRANSPARENT = {0, 0, 0, 0},
}

-- ===== 调试工具 =====

--! 打印 table 内容到控制台（带缩进，调试用）
function M.printTable(tbl, indent, depth)
    indent = indent or 0
    depth = depth or 0
    if depth > 5 then
        print(string.rep("  ", indent) .. "... (max depth)")
        return
    end
    if type(tbl) ~= "table" then
        print(string.rep("  ", indent) .. tostring(tbl))
        return
    end
    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        if type(v) == "table" then
            print(string.rep("  ", indent) .. keyStr .. " = {")
            M.printTable(v, indent + 1, depth + 1)
            print(string.rep("  ", indent) .. "}")
        else
            print(string.rep("  ", indent) .. keyStr .. " = " .. tostring(v))
        end
    end
end

--! 格式化字符串（和 string.format 一样，只是暴露方便用）
--! 类比：JS 的模板字符串 / Python 的 f-string
function M.fmt(str, ...)
    return string.format(str, ...)
end

return M
