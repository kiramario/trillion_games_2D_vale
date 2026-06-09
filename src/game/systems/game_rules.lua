--! file: src/game/systems/game_rules.lua
--! brief: 高级规则：将军/将死/和棋/白脸将/走子后校验
--!
--! 核心概念：
--! - 将军：一方的将/帅处于被攻击状态
--! - 应将：走子后必须解除将军
--! - 白脸将：双方将帅在同一直线且中间无子（禁止）
--! - 将死：被将军时无合法走法 → 胜
--! - 困毙：未被将军但无合法走法（中国象棋算输）
--! - 和棋：双方均无进攻子力（简化判定，V3 不实现重复局面）

local MoveRules = require("game.systems.move_rules")
local C = require("game.constants")

local M = {}

--! 找到某方的王
function M.findKing(board, color)
    for _, p in ipairs(board.pieces) do
        if p.alive and p.color == color and p.type == "king" then
            return p
        end
    end
    return nil
end

--! 判断两个王是否照面（白脸将）
function M.kingsFacing(board)
    local rk = M.findKing(board, "red")
    local bk = M.findKing(board, "black")
    if not rk or not bk then return false end
    if rk.file ~= bk.file then return false end
    -- 同列，看中间是否有子
    local min_r = math.min(rk.rank, bk.rank)
    local max_r = math.max(rk.rank, bk.rank)
    for r = min_r + 1, max_r - 1 do
        if board:pieceAt(rk.file, r) then return false end
    end
    return true
end

--! 判断某方的王是否被将军
--! 算法：遍历对方所有活着的棋子，看它们的合法走法是否覆盖王位置
function M.isInCheck(board, color)
    local king = M.findKing(board, color)
    if not king then return false end
    local opp = color == "red" and "black" or "red"
    for _, p in ipairs(board.pieces) do
        if p.alive and p.color == opp then
            local moves = MoveRules.getLegalMoves(board, p)
            for _, m in ipairs(moves) do
                if m.f == king.file and m.r == king.rank then
                    return true, p  -- 将军方
                end
            end
        end
    end
    -- 白脸将也算将军
    if M.kingsFacing(board) then return true end
    return false
end

--! 执行走子（原地修改 board），返回可撤销的 move 记录
--! @return move {piece, from_f, from_r, to_f, to_r, captured_piece}
function M.applyMove(board, piece, to_f, to_r)
    local captured = board:pieceAt(to_f, to_r)
    local mv = {
        piece = piece,
        from_f = piece.file, from_r = piece.rank,
        to_f = to_f, to_r = to_r,
        captured = captured,
    }
    if captured then captured.alive = false end
    piece.file = to_f
    piece.rank = to_r
    return mv
end

--! 撤销 applyMove 所做的改动
function M.undoMove(board, mv)
    mv.piece.file = mv.from_f
    mv.piece.rank = mv.from_r
    if mv.captured then mv.captured.alive = true end
end

--! 判定某一步是否合法（考虑是否导致自己被将军）
function M.isMoveSafe(board, piece, to_f, to_r)
    local basic_ok, mv = MoveRules.isMoveLegal(board, piece, to_f, to_r)
    if not basic_ok then return false end
    local applied = M.applyMove(board, piece, to_f, to_r)
    local in_check = M.isInCheck(board, piece.color)
    M.undoMove(board, applied)
    return not in_check
end

--! 返回某方所有合法且安全的走法
function M.getAllSafeMoves(board, color)
    local moves = {}
    for _, p in ipairs(board.pieces) do
        if p.alive and p.color == color then
            for _, m in ipairs(MoveRules.getLegalMoves(board, p)) do
                if M.isMoveSafe(board, p, m.f, m.r) then
                    table.insert(moves, {
                        piece = p,
                        from_f = p.file, from_r = p.rank,
                        to_f = m.f, to_r = m.r,
                        capture = m.capture,
                    })
                end
            end
        end
    end
    return moves
end

--! 判定局面状态
--! @return "check" | "checkmate" | "stalemate" | "normal"
--!         winner: "red"|"black"|nil
function M.getGameState(board, to_move_color)
    local safe = M.getAllSafeMoves(board, to_move_color)
    local in_check = M.isInCheck(board, to_move_color)
    if #safe == 0 then
        if in_check then
            return "checkmate", (to_move_color == "red" and "black" or "red")
        else
            -- 困毙：无子可走也算输
            return "stalemate", (to_move_color == "red" and "black" or "red")
        end
    end
    if in_check then return "check", nil end
    return "normal", nil
end

return M
