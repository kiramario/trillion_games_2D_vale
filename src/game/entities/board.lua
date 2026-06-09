--! file: src/game/entities/board.lua
--! brief: 棋盘状态（数据层，不负责渲染）
--! 维护 9x10 的网格，提供增删查改棋子的 API

local Piece = require("game.entities.piece")
local C = require("game.constants")

local Board = {}
Board.__index = Board

function Board.new()
    local self = setmetatable({}, Board)
    -- grid[f][r] = Piece or nil。[Lua] 我们用 file 作为外层索引
    self.grid = {}
    for f = 0, C.FILES - 1 do
        self.grid[f] = {}
        for r = 0, C.RANKS - 1 do
            self.grid[f][r] = nil
        end
    end
    self.pieces = {}  -- 所有存活棋子列表（方便遍历）
    return self
end

--! 按初始布局摆棋
function Board:setupInitial()
    self.pieces = {}
    for f = 0, C.FILES - 1 do
        for r = 0, C.RANKS - 1 do
            self.grid[f][r] = nil
        end
    end
    for _, setup in ipairs(C.INITIAL_SETUP) do
        local piece = Piece.new(setup[1], setup[2], setup[3], setup[4])
        self.grid[setup[1]][setup[2]] = piece
        table.insert(self.pieces, piece)
    end
end

function Board:pieceAt(f, r)
    if f < 0 or f >= C.FILES or r < 0 or r >= C.RANKS then return nil end
    return self.grid[f][r]
end

--! 是否在棋盘内
function Board:inBounds(f, r)
    return f >= 0 and f < C.FILES and r >= 0 and r < C.RANKS
end

--! 红方的半场是 rank 5-9（下方），黑方半场是 rank 0-4（上方）
function Board:inOwnHalf(color, r)
    if color == "red" then
        return r >= 5
    else
        return r <= 4
    end
end

function Board:inOpponentHalf(color, r)
    return not self:inOwnHalf(color, r)
end

--! 九宫格：红方九宫 file 3-5, rank 7-9；黑方九宫 file 3-5, rank 0-2
function Board:inPalace(color, f, r)
    if f < 3 or f > 5 then return false end
    if color == "red" then
        return r >= 7 and r <= 9
    else
        return r >= 0 and r <= 2
    end
end

return Board
