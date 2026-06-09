--! file: src/game/systems/move_rules.lua
--! brief: 中国象棋走法规则
--! 每种棋子的合法移动判定。只判定单步（不考虑将军/被将军，那是 V3 的事）
--!
--! 规则速记：
--!   帅/将: 九宫内走一格，不能与对方帅/将照面
--!   仕/士: 九宫内斜走一格
--!   相/象: 走"田"字，不能过河，田心有子则塞象眼
--!   马:   走"日"字，马腿有子则蹩马腿
--!   车:   直线走任意步，中间有子挡
--!   炮:   直线走任意步；吃子时必须恰好翻一个棋子
--!   兵/卒: 过河前只能向前；过河后可左右

local C = require("game.constants")

local M = {}

--! 判断 (f,r) 是否在棋盘内
function M.inBounds(f, r)
    return f >= 0 and f < C.FILES and r >= 0 and r < C.RANKS
end

--! 判断坐标是否在九宫
local function inPalace(f, r, color)
    if f < 3 or f > 5 then return false end
    if color == "black" then
        return r >= 0 and r <= 2
    else
        return r >= 7 and r <= 9
    end
end

--! 红方兵的前进方向是 rank-1（朝上），黑方卒是 rank+1（朝下）
local function forwardDir(color)
    return color == "red" and -1 or 1
end

--! 判断某位置是否"过了河"（从该方视角）
local function crossedRiver(r, color)
    return color == "red" and r <= 4 or color == "black" and r >= 5
end

--! 返回 piece 从 (f,r) 出发可以走到的所有合法目标格子
--! @param board  棋盘对象（含 :pieceAt(f,r) 方法）
--! @param piece  棋子
--! @return table 形如 {{f=target_f, r=target_r, capture=bool}, ...}
function M.getLegalMoves(board, piece)
    local f, r = piece.file, piece.rank
    local color = piece.color
    local moves = {}

    local function target(ff, rr)
        -- 必须在棋盘内
        if not M.inBounds(ff, rr) then return end
        local target_piece = board:pieceAt(ff, rr)
        -- 目标位置不能有己方棋子
        if target_piece and target_piece.color == color then return end
        table.insert(moves, {
            f = ff, r = rr,
            capture = target_piece ~= nil,
        })
    end

    -- 扫描直线（车/炮用）
    local function slide(dx, dr, for_cannon)
        local ff, rr = f + dx, r + dr
        local jumped = false
        while M.inBounds(ff, rr) do
            local p = board:pieceAt(ff, rr)
            if not p then
                if not jumped then
                    -- 空格：车和未跳的炮都能走
                    table.insert(moves, {f=ff, r=rr, capture=false})
                end
                -- 炮跳了之后，空格里不走，继续找下一个吃
            else
                if not jumped then
                    if for_cannon then
                        jumped = true
                        -- 炮遇到第一个子：翻过去，继续找下一个目标
                    else
                        -- 车遇到第一个子：若为敌子可吃，然后停
                        if p.color ~= color then
                            table.insert(moves, {f=ff, r=rr, capture=true})
                        end
                        break
                    end
                else
                    -- 炮遇到第二个子
                    if p.color ~= color then
                        table.insert(moves, {f=ff, r=rr, capture=true})
                    end
                    break
                end
            end
            ff = ff + dx
            rr = rr + dr
        end
    end

    if piece.type == "king" then
        -- 帅/将：上下左右一格，必须在九宫内
        local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
        for _, d in ipairs(dirs) do
            local nf, nr = f + d[1], r + d[2]
            if inPalace(nf, nr, color) then target(nf, nr) end
        end

    elseif piece.type == "advisor" then
        -- 仕/士：斜走一格，九宫
        local dirs = {{-1,-1},{-1,1},{1,-1},{1,1}}
        for _, d in ipairs(dirs) do
            local nf, nr = f + d[1], r + d[2]
            if inPalace(nf, nr, color) then target(nf, nr) end
        end

    elseif piece.type == "elephant" then
        -- 相/象：田字，不能过河，塞象眼
        local jumps = {
            {df=-2, dr=-2, eye_f=-1, eye_r=-1},
            {df=-2, dr= 2, eye_f=-1, eye_r= 1},
            {df= 2, dr=-2, eye_f= 1, eye_r=-1},
            {df= 2, dr= 2, eye_f= 1, eye_r= 1},
        }
        for _, j in ipairs(jumps) do
            local nf, nr = f + j.df, r + j.dr
            -- 不能过河：红象必须 r>=5，黑象必须 r<=4
            if color == "red" and nr < 5 then goto continue end
            if color == "black" and nr > 4 then goto continue end
            if not M.inBounds(nf, nr) then goto continue end
            -- 塞象眼
            if board:pieceAt(f + j.eye_f, r + j.eye_r) then goto continue end
            target(nf, nr)
            ::continue::
        end

    elseif piece.type == "horse" then
        -- 马：日字，蹩马腿
        -- 日字形：(±1,±2) 和 (±2,±1)
        -- 蹩马腿：向 (1,2) 走时，(0,1) 有子即蹩
        local moves_def = {
            {df=1, dr=2,  leg_f=0, leg_r=1},
            {df=-1,dr=2,  leg_f=0, leg_r=1},
            {df=1, dr=-2, leg_f=0, leg_r=-1},
            {df=-1,dr=-2, leg_f=0, leg_r=-1},
            {df=2, dr=1,  leg_f=1, leg_r=0},
            {df=2, dr=-1, leg_f=1, leg_r=0},
            {df=-2,dr=1,  leg_f=-1,leg_r=0},
            {df=-2,dr=-1, leg_f=-1,leg_r=0},
        }
        for _, m in ipairs(moves_def) do
            local nf, nr = f + m.df, r + m.dr
            if not M.inBounds(nf, nr) then goto continue end
            if board:pieceAt(f + m.leg_f, r + m.leg_r) then goto continue end
            target(nf, nr)
            ::continue::
        end

    elseif piece.type == "chariot" then
        -- 车：四方向直线
        slide(0, -1, false)
        slide(0,  1, false)
        slide(-1, 0, false)
        slide(1,  0, false)

    elseif piece.type == "cannon" then
        -- 炮：四方向直线（吃子需翻山）
        slide(0, -1, true)
        slide(0,  1, true)
        slide(-1, 0, true)
        slide(1,  0, true)

    elseif piece.type == "pawn" then
        -- 兵/卒
        local fd = forwardDir(color)
        -- 永远能向前
        target(f, r + fd)
        -- 过河后可左右
        if crossedRiver(r, color) then
            target(f - 1, r)
            target(f + 1, r)
        end
    end

    return moves
end

--! 检查某一步走法是否合法（对比 getLegalMoves）
function M.isMoveLegal(board, piece, to_f, to_r)
    local moves = M.getLegalMoves(board, piece)
    for _, m in ipairs(moves) do
        if m.f == to_f and m.r == to_r then return true, m end
    end
    return false
end

return M
