--! file: src/core/steam.lua
--! brief: Steamworks 集成占位钩子
--! V5 只预留 API；真正调用 luasteam/greenworks 在游戏接近上架时接入
--! 所有 steam 调用都要先检测 M.available，这样无 Steam 环境时不会崩溃

local logger = require("core.logger")
local event = require("core.event")

local M = {}
M.available = false
M._impl = nil

function M.init()
    -- 尝试加载 luasteam
    local ok, mod = pcall(require, "luasteam")
    if ok then
        M._impl = mod
        M.available = true
        logger.info("steam", "Steamworks loaded, userId=%s", tostring(mod.user and mod.user.getSteamID and mod.user.getSteamID()))
        event.emit("steam:ready")
    else
        logger.debug("steam", "Steamworks not available (running without Steam)")
    end
end

function M.shutdown()
    if M.available and M._impl and M._impl.shutdown then
        pcall(M._impl.shutdown)
    end
end

--! 设置成就（失败静默）
function M.setAchievement(name)
    if not M.available then return false end
    local ok, err = pcall(function() M._impl.userStats.setAchievement(name) end)
    if not ok then logger.warn("steam", "setAchievement failed: %s", err) end
    return ok
end

--! 解锁/加统计
function M.setStat(name, value)
    if not M.available then return false end
    pcall(function() M._impl.userStats.setStat(name, value) end)
end

--! 云存档读取（如果可用）
function M.cloudRead(filename)
    if not M.available then return nil end
    local ok, data = pcall(function() return M._impl.cloud.read(filename) end)
    return ok and data or nil
end

function M.cloudWrite(filename, data)
    if not M.available then return false end
    return pcall(function() M._impl.cloud.write(filename, data) end)
end

return M
