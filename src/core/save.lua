--! file: src/core/save.lua
--! brief: 存档/读档系统（用 LÖVE2D 的文件系统写入 ~/.local/share/love/<identity>/saves/）
--! [Lua] 数据序列化：手写简单 table serializer，支持嵌套 table/数字/字符串/布尔
--! 为了保持零依赖不用 bitser/binser，V4 直接实现可读文本存档

local logger = require("core.logger")
local config = require("core.config")
local json_compat = nil

local M = {}
local SAVE_DIR = "saves"

-- 简单 Lua table -> string 序列化（只支持基础类型，足够 V4 存档用）
local function serialize(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "number" then
        if v == math.floor(v) then return tostring(v) end
        return string.format("%.6g", v)
    elseif t == "boolean" then
        return v and "true" or "false"
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        local parts = {}
        local has_array_key = false
        local max_arr = 0
        for k in pairs(v) do
            if type(k) == "number" and k == math.floor(k) and k > 0 then
                max_arr = math.max(max_arr, k)
            end
        end
        local ind2 = indent .. "  "
        table.insert(parts, "{\n")
        -- array part
        for i = 1, max_arr do
            local vi = v[i]
            if vi ~= nil then
                table.insert(parts, ind2 .. serialize(vi, ind2) .. ",\n")
            end
        end
        -- hash part
        for k, vv in pairs(v) do
            if not (type(k) == "number" and k == math.floor(k) and k > 0 and k <= max_arr) then
                local ks
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    ks = k
                else
                    ks = "[" .. serialize(k, ind2) .. "]"
                end
                table.insert(parts, ind2 .. ks .. " = " .. serialize(vv, ind2) .. ",\n")
            end
        end
        table.insert(parts, indent .. "}")
        return table.concat(parts)
    else
        return "nil"
    end
end

--! 确保存档目录存在
local function ensureDir()
    local info = love.filesystem.getInfo(SAVE_DIR)
    if not info then
        love.filesystem.createDirectory(SAVE_DIR)
        logger.info("save", "Created save dir: %s", SAVE_DIR)
    end
end

--! 存档
--! @param slot 存档槽位（"slot1"、"auto" 等）
--! @param data table
function M.save(slot, data)
    ensureDir()
    local path = SAVE_DIR .. "/" .. slot .. ".lua"
    local content = "return " .. serialize(data)
    local ok, err = love.filesystem.write(path, content)
    if ok then
        logger.info("save", "Saved to %s (%d bytes)", path, #content)
    else
        logger.error("save", "Failed to save: %s", tostring(err))
    end
    return ok
end

--! 读档
function M.load(slot)
    local path = SAVE_DIR .. "/" .. slot .. ".lua"
    local info = love.filesystem.getInfo(path)
    if not info then return nil end
    local chunk, err = love.filesystem.load(path)
    if not chunk then
        logger.error("save", "Load error: %s", err)
        return nil
    end
    local ok, data = pcall(chunk)
    if not ok then
        logger.error("save", "Run error: %s", data)
        return nil
    end
    logger.info("save", "Loaded from %s", path)
    return data
end

--! 列存档
function M.listSlots()
    ensureDir()
    local files = love.filesystem.getDirectoryItems(SAVE_DIR)
    local slots = {}
    for _, f in ipairs(files) do
        if f:sub(-4) == ".lua" then
            local name = f:sub(1, -5)
            local info = love.filesystem.getInfo(SAVE_DIR .. "/" .. f)
            table.insert(slots, {name = name, size = info.size, modtime = info.modtime})
        end
    end
    return slots
end

--! 删除存档
function M.delete(slot)
    local path = SAVE_DIR .. "/" .. slot .. ".lua"
    love.filesystem.remove(path)
end

return M
