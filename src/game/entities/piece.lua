--! file: src/game/entities/piece.lua
--! brief: 棋子数据结构
--! 纯数据对象 + 少量辅助方法。不包含绘制和规则。

local next_id = 1

local Piece = {}
Piece.__index = Piece

function Piece.new(file, rank, color, type)
    local self = setmetatable({}, Piece)
    self.id = next_id
    next_id = next_id + 1
    self.file = file     -- 列 0-8
    self.rank = rank     -- 行 0-9
    self.color = color   -- "red" | "black"
    self.type = type     -- "jiang" | "shi" | "xiang" | "ma" | "ju" | "pao" | "bing"
    self.alive = true
    return self
end

function Piece:posKey()
    return self.file .. "," .. self.rank
end

function Piece:moveTo(f, r)
    self.file = f
    self.rank = r
end

return Piece
