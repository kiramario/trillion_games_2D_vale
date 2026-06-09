--! file: src/core/config.lua
--! brief: 配置管理系统
--! 类比：Python configparser / JS dotenv
--! 负责加载默认配置 + 用户覆盖配置，并支持运行时读写
--! [LOVE] love.filesystem 提供跨平台的存档目录读写，不需要关心路径

local logger = require("core.logger")
local utils = require("core.utils")

local M = {}

-- 默认配置
local defaults = {
    window = {
        width  = 1280,
        height = 720,
        fullscreen = false,
        vsync  = true,
    },
    audio = {
        bgm_volume = 0.7,
        sfx_volume = 0.9,
        muted      = false,
    },
    game = {
        language = "zh",
        ai_difficulty = 2,
    },
    debug = {
        show_fps    = true,
        log_level   = "DEBUG",
        show_layers = false,
    }
}

local config_data = nil

--! 初始化：加载默认配置，然后尝试读取用户配置合并
--! [LOVE] love.filesystem 是 LÖVE 提供的文件系统抽象
--!   读取: love.filesystem.read("config.lua")
--!   写入: love.filesystem.write("config.lua", data)
--!   在 Linux 上它实际读写 ~/.local/share/love/trillion_games_vale/
function M.init()
    config_data = utils.deepcopy(defaults)

    -- 尝试加载用户配置
    -- [Lua] 我们不直接 dofile 用户配置（安全问题），而是用 love.filesystem.read + 简单解析
    -- 这里简化处理：如果存在就尝试加载，失败就用默认值
    local ok, content = pcall(love.filesystem.read, "user_config.lua")
    if ok and content then
        -- [Lua] load() 把字符串编译为函数但不执行，安全沙盒
        -- 类似 JS 的 new Function() 但 Lua 可以设置环境
        local chunk, err = load(content, "user_config.lua", "t", {})
        if chunk then
            local ok2, user_conf = pcall(chunk)
            if ok2 and type(user_conf) == "table" then
                M._merge(config_data, user_conf)
                logger.info("config", "Loaded user config")
            else
                logger.warn("config", "User config returned invalid data: %s", tostring(user_conf))
            end
        else
            logger.warn("config", "Failed to parse user config: %s", err)
        end
    else
        logger.info("config", "No user config found, using defaults")
    end
end

--! 内部：递归合并配置表（b 覆盖 a）
function M._merge(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" and type(a[k]) == "table" then
            M._merge(a[k], v)
        else
            a[k] = v
        end
    end
end

--! 获取配置值，支持点号路径如 "audio.sfx_volume"
--! 用法: config.get("audio.bgm_volume")
function M.get(path, default)
    if not config_data then M.init() end
    local keys = {}
    -- [Lua] gmatch 做全局模式匹配，这里按点分割路径
    for key in string.gmatch(path, "[^%.]+") do
        table.insert(keys, key)
    end

    local node = config_data
    for _, key in ipairs(keys) do
        if type(node) ~= "table" then return default end
        node = node[key]
        if node == nil then return default end
    end
    return node
end

--! 设置配置值（运行时修改，需要调用 save() 持久化）
function M.set(path, value)
    if not config_data then M.init() end
    local keys = {}
    for key in string.gmatch(path, "[^%.]+") do
        table.insert(keys, key)
    end

    local node = config_data
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(node[key]) ~= "table" then
            node[key] = {}
        end
        node = node[key]
    end
    node[keys[#keys]] = value
end

--! 保存当前配置到用户存档目录
function M.save()
    -- [Lua] 我们不能直接序列化任意 table 到 Lua 源码（太复杂）
    -- V0 简化：保存为简单的 "return { ... }" 格式
    -- V4 用专业序列化库处理存档时会重新设计
    local serialized = M._serialize(config_data, 0)
    local content = "-- User configuration - auto generated, edit via game settings\nreturn " .. serialized .. "\n"
    love.filesystem.write("user_config.lua", content)
    logger.info("config", "User config saved")
end

-- 简单 table 序列化为 Lua 源码（支持嵌套 table、字符串、数字、布尔）
function M._serialize(val, indent)
    local pad = string.rep("  ", indent)
    local pad2 = string.rep("  ", indent + 1)

    if type(val) == "string" then
        return string.format("%q", val)
    elseif type(val) == "number" or type(val) == "boolean" then
        return tostring(val)
    elseif type(val) == "table" then
        -- 判断是数组还是字典
        local is_array = true
        local max_idx = 0
        for k, _ in pairs(val) do
            if type(k) ~= "number" or k ~= math.floor(k) then
                is_array = false
                break
            end
            max_idx = math.max(max_idx, k)
        end
        if is_array and max_idx > 0 then
            is_array = true
            for i = 1, max_idx do
                if val[i] == nil then is_array = false; break end
            end
        end

        local parts = {}
        if is_array then
            for _, v in ipairs(val) do
                table.insert(parts, pad2 .. M._serialize(v, indent + 1))
            end
        else
            for k, v in pairs(val) do
                if type(k) == "string" then
                    table.insert(parts, string.format("%s%s = %s", pad2, k, M._serialize(v, indent + 1)))
                end
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
    else
        return "nil"
    end
end

return M
