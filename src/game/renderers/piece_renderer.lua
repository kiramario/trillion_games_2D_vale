--! file: src/game/renderers/piece_renderer.lua
--! brief: 棋子渲染（love.graphics 直接绘制）

local C = require("game.constants")
local utils = require("core.utils")
local BoardRen = require("game.renderers.board_renderer")

local M = {}

function M.draw(piece, font)
    local sx, sy = BoardRen.fileRankToWorld(piece.file, piece.rank)
    if not sx then return end
    M.drawAt(piece, font, sx, sy)
end

--! 在指定世界坐标 (x,y) 绘制棋子（动画/拖动用）
function M.drawAt(piece, font, sx, sy)
    if not sx then return end

    local lg = love.graphics
    local radius = C.PIECE_RADIUS
    local is_red = piece.color == "red"

    local body_col  = utils.color(C.COLOR_RED_PIECE[1], C.COLOR_RED_PIECE[2], C.COLOR_RED_PIECE[3])
    local ring_col  = is_red
        and utils.color(C.COLOR_RED_RING[1], C.COLOR_RED_RING[2], C.COLOR_RED_RING[3])
        or  utils.color(C.COLOR_BLACK_RING[1], C.COLOR_BLACK_RING[2], C.COLOR_BLACK_RING[3])
    local text_col  = is_red
        and utils.color(C.COLOR_RED_TEXT[1], C.COLOR_RED_TEXT[2], C.COLOR_RED_TEXT[3])
        or  utils.color(C.COLOR_BLACK_TEXT[1], C.COLOR_BLACK_TEXT[2], C.COLOR_BLACK_TEXT[3])

    -- 1. 椭圆阴影（用 ellipse 直接画，避免 push/scale 消耗变换栈）
    lg.setColor(0, 0, 0, C.PIECE_SHADOW_ALPHA)
    lg.ellipse("fill",
        sx, sy + C.PIECE_SHADOW_OFFSET_Y + radius * 0.55,
        radius * 0.95 * C.PIECE_SHADOW_SCALE_X,
        radius * 0.95 * 0.35, 24)

    -- 2. 底座
    lg.setColor(utils.color(150, 110, 60, 220))
    lg.circle("fill", sx, sy + 3, radius + 1, 24)

    -- 3. 主体
    lg.setColor(body_col)
    lg.circle("fill", sx, sy, radius, 32)

    -- 4. 高光
    lg.setColor(1, 0.95, 0.85, 0.15)
    lg.ellipse("fill", sx, sy - radius * 0.32, radius * 0.68, radius * 0.5, 24)

    -- 5. 内外圈
    lg.setColor(ring_col)
    lg.setLineWidth(C.PIECE_RING)
    lg.circle("line", sx, sy, radius - 2, 32)
    lg.setLineWidth(1.3)
    lg.circle("line", sx, sy, radius - 2 - C.PIECE_INNER_MARGIN, 32)
    lg.setLineWidth(1)

    -- 6. 文字
    lg.setFont(font)
    lg.setColor(text_col)
    local ch = C.PIECE_CHARS[piece.color][piece.type]
    local w = font:getWidth(ch)
    local h = font:getHeight()
    lg.print(ch, sx - w/2, sy - h/2 - 2)
end

return M
