--! file: src/game/systems/ai.lua
--! brief: 简单 AI（贪心 + 1 步前瞻，V3 级别，不是 alpha-beta）
--!
--! 算法：
--!   1. 枚举当前方所有合法走法
--!   2. 对每个走法：
--!      a. 在棋盘副本上执行
--!      b. 计算"局面分数"（子力价值 + 简单位置奖励）
--!      c. 如果走法导致自己被将军，惩罚
--!      d. 如果走法将死对方，加巨大分
--!   3. 选最高分的走法
--!
--! V3 AI 很弱（1 层深度），V3 之后可以升级 alpha-beta。

local GameRules = require("game.systems.game_rules")
local C = require("game.constants")
local logger = require("core.logger")

local M = {}

-- 棋子价值（中国象棋常见估价，单位：分）
local PIECE_VALUES = {
    king     = 100000,
    chariot  = 900,
    horse    = 400,
    cannon   = 450,
    advisor  = 200,
    elephant = 200,
    pawn     = 100,
}

-- 兵卒过河奖励
local function bonusPawn(piece)
    if piece.type ~= "pawn" then return 0 end
    if piece.color == "red" then
        if piece.rank <= 4 then return 60 end  -- 过河
        if piece.rank <= 2 then return 30 end
    else
        if piece.rank >= 5 then return 60 end
        if piece.rank >= 7 then return 30 end
    end
    return 0
end

-- 车/马/炮 位于中线附近的奖励（鼓励出动）
local function centerBonus(piece)
    if piece.type == "chariot" or piece.type == "horse" or piece.type == "cannon" then
        local f = piece.file
        -- 列 3/4/5 有奖励
        if f == 3 or f == 5 then return 15 end
        if f == 4 then return 25 end
    end
    return 0
end

--! 计算某方局面分（分数越高，对该方越有利）
local function evaluate(board, color)
    local score = 0
    for _, p in ipairs(board.pieces) do
        if p.alive then
            local v = PIECE_VALUES[p.type] or 0
            v = v + bonusPawn(p) + centerBonus(p)
            if p.color == color then
                score = score + v
            else
                score = score - v
            end
        end
    end
    return score
end

--! 深拷贝 board（棋子位置/存活状态）
--! 用于 AI 模拟，避免修改真实棋盘
local function cloneBoard(board)
    -- 复用原模块的方法：创建新 Board 并复制棋子
    local Board = require("game.entities.board")
    local nb = Board.new()
    for _, p in ipairs(board.pieces) do
        local np = nb:addPiece(p.file, p.rank, p.color, p.type)
        np.alive = p.alive
        np.id = p.id
    end
    return nb
end

--! 选择一步棋
--! @param board   当前棋盘
--! @param color   AI 执什么颜色
--! @param strength 搜索强度（V3 固定 1）
--! @return {piece_clone (on cloned board), from_f, from_r, to_f, to_r} 或 nil
function M.chooseMove(board, color, strength)
    strength = strength or 1
    local all_moves = GameRules.getAllSafeMoves(board, color)
    if #all_moves == 0 then return nil end

    local best_score = -math.huge
    local best = nil

    for _, m in ipairs(all_moves) do
        local sim = cloneBoard(board)
        -- 找到对应的 piece
        local piece = nil
        for _, p in ipairs(sim.pieces) do
            if p.id == m.piece.id then piece = p; break end
        end
        if piece then
            local applied = GameRules.applyMove(sim, piece, m.to_f, m.to_r)
            local score = evaluate(sim, color)

            -- 如果这步之后对方被将死，加巨大分
            local opp = color == "red" and "black" or "red"
            local state, winner = GameRules.getGameState(sim, opp)
            if state == "checkmate" then
                score = score + 100000
            elseif state == "stalemate" then
                score = score + 50000
            end

            -- 将军加分
            if GameRules.isInCheck(sim, opp) then
                score = score + 30
            end

            -- 吃子加分
            if m.capture then
                score = score + 50
            end

            -- 随机扰动一点点（避免每次都走一样的）
            score = score + love.math.random() * 5

            GameRules.undoMove(sim, applied)

            if score > best_score then
                best_score = score
                best = m
            end
        end
    end

    if best then
        logger.debug("ai", "AI (%s) chose: %s (%d,%d)->(%d,%d) score=%.0f",
            color, best.piece.type, best.from_f, best.from_r, best.to_f, best.to_r, best_score)
    end
    return best
end

return M
