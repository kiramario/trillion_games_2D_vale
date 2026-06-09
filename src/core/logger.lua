--! file: src/core/logger.lua
--! brief: 分级日志系统
--! 类比：Python logging / JS console (debug/info/warn/error)
--! V0 只输出到控制台（print），后续可扩展输出到文件

local utils = require("core.utils")

local M = {}

-- 日志级别，数字越大越严重
local LEVELS = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
}

-- ANSI 颜色码（Linux/macOS 终端支持，Windows 10+ 也支持）
local COLORS = {
    DEBUG = "\27[36m",    -- 青色
    INFO  = "\27[32m",    -- 绿色
    WARN  = "\27[33m",    -- 黄色
    ERROR = "\27[31m",    -- 红色
    RESET = "\27[0m",     -- 重置
}

local current_level = LEVELS.DEBUG
local module_filter = nil  -- 如果设了模块名，只打印该模块的日志

--! 设置最低日志级别，低于这个级别的不会输出
function M.setLevel(level)
    if type(level) == "string" then
        current_level = LEVELS[string.upper(level)] or LEVELS.DEBUG
    else
        current_level = level
    end
end

--! 设置模块过滤（调试特定模块时用）
function M.setModule(name)
    module_filter = name
end

-- 内部：实际打印日志
-- [Lua] ... 是可变参数，类似 JS 的 ...rest / Python 的 *args
local function log(level, module, msg, ...)
    local level_val = LEVELS[level]
    if level_val < current_level then return end
    if module_filter and module ~= module_filter then return end

    -- 格式化消息
    local formatted = msg
    local args = {...}
    if #args > 0 then
        -- [Lua] pcall 是 protected call，类似 try-catch
        -- 防止 string.format 因为参数不匹配崩溃
        local ok, result = pcall(string.format, msg, ...)
        if ok then formatted = result end
    end

    -- 时间戳（格式 HH:MM:SS.mmm）
    local time = os.date("%H:%M:%S")
    -- [LOVE] love.timer.getTime() 返回游戏启动后的秒数，比 os.time() 精确
    local millis = math.floor((love.timer and love.timer.getTime() or 0) * 1000 % 1000)
    local timestamp = string.format("%s.%03d", time, millis)

    -- 构造输出行
    local color = COLORS[level] or ""
    local reset = COLORS.RESET
    local module_str = module and string.format("[%s] ", module) or ""
    local line = string.format("%s%s[%s]%s %s%s%s",
        color,
        timestamp,
        level,
        reset,
        color,
        module_str .. tostring(formatted),
        reset
    )

    print(line)
end

--! 对外 API：每个级别一个函数
--! 用法: logger.info("scene", "Switching to %s", sceneName)
function M.debug(module, msg, ...) log("DEBUG", module, msg, ...) end
function M.info (module, msg, ...) log("INFO",  module, msg, ...) end
function M.warn (module, msg, ...) log("WARN",  module, msg, ...) end
function M.error(module, msg, ...) log("ERROR", module, msg, ...) end

--! 快速打印一个变量（调试用，不管级别）
function M.dump(name, value)
    print(string.format("\27[35m[DUMP] %s:\27[0m", name))
    utils.printTable(value)
end

return M
