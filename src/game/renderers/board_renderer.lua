--! file: src/game/renderers/board_renderer.lua
--! brief: 棋盘渲染（伪纵深：斜视角 + 厚度 + 木纹）
--! 注意：所有绘制直接使用 love.graphics 调用（在 camera:attach 包裹的 custom 中执行）

local C = require("game.constants")
local utils = require("core.utils")

local M = {}

function M.getBoardSize()
    local w = (C.FILES - 1) * C.CELL + C.MARGIN * 2
    local h = ((C.RANKS - 1) * C.CELL + C.MARGIN * 2) * C.TILT_Y
    return w, h
end

function M.draw(font)
    local bw, bh = M.getBoardSize()
    local ox = -bw / 2
    local oy = -bh / 2
    local gx0 = ox + C.MARGIN
    local gy0 = oy + C.MARGIN
    local gx1 = ox + bw - C.MARGIN
    local gy1 = oy + bh - C.MARGIN
    local inner_w = gx1 - gx0
    local inner_h = gy1 - gy0

    local lg = love.graphics
    local edge_col = utils.color(C.COLOR_BOARD_EDGE[1], C.COLOR_BOARD_EDGE[2], C.COLOR_BOARD_EDGE[3], 230)
    local base_col = utils.color(C.COLOR_BOARD_BASE[1], C.COLOR_BOARD_BASE[2], C.COLOR_BOARD_BASE[3])
    local line_col = utils.color(C.COLOR_LINE[1], C.COLOR_LINE[2], C.COLOR_LINE[3])

    -- 1. 侧面厚度（伪 3D）
    local THICK = 14
    lg.setColor(edge_col)
    lg.rectangle("fill", ox, oy + bh, bw, THICK)
    local right_col = utils.color(
        C.COLOR_BOARD_EDGE[1] + 15, C.COLOR_BOARD_EDGE[2] + 10, C.COLOR_BOARD_EDGE[3] + 10, 230)
    lg.setColor(right_col)
    lg.rectangle("fill", ox + bw, oy, THICK, bh + THICK)
    lg.setColor(edge_col)
    lg.polygon("fill",
        ox, oy + bh, ox + bw, oy + bh,
        ox + bw + THICK, oy + bh + THICK, ox + THICK, oy + bh + THICK)
    lg.setColor(right_col)
    lg.polygon("fill",
        ox + bw, oy, ox + bw + THICK, oy - 1,
        ox + bw + THICK, oy + bh + THICK, ox + bw, oy + bh)

    -- 2. 木板底色
    lg.setColor(base_col)
    lg.rectangle("fill", ox, oy, bw, bh)

    -- 3. 木纹 & 高光 & 边框
    local stripe_count = 14
    for i = 0, stripe_count do
        local sy = oy + (bh / stripe_count) * i
        local t = i / stripe_count
        local bright = (math.sin(t * 3.7) + math.sin(t * 7.3)) * 6
        lg.setColor(C.COLOR_BOARD_DARK[1]/255, C.COLOR_BOARD_DARK[2]/255,
                   C.COLOR_BOARD_DARK[3]/255, 0.22)
        lg.rectangle("fill", ox, sy, bw, bh / stripe_count * 0.4)
    end
    for i = 0, 8 do
        local t = i / 8
        lg.setColor(C.COLOR_BOARD_HILITE[1]/255, C.COLOR_BOARD_HILITE[2]/255,
                   C.COLOR_BOARD_HILITE[3]/255, (1 - t) * 0.1)
        lg.rectangle("fill", ox, oy + bh * t * 0.3, bw, bh * 0.08)
    end
    lg.setColor(line_col)
    lg.setLineWidth(2.5)
    lg.rectangle("line", ox, oy, bw, bh)
    lg.setLineWidth(1.5)
    lg.rectangle("line", gx0, gy0, inner_w, inner_h)

    -- 4. 网格线
    lg.setLineWidth(1.3)
    for ri = 0, C.RANKS - 1 do
        local y = gy0 + inner_h * ri / (C.RANKS - 1)
        lg.line(gx0, y, gx1, y)
    end
    for fi = 0, C.FILES - 1 do
        local x = gx0 + inner_w * fi / (C.FILES - 1)
        if fi == 0 or fi == C.FILES - 1 then
            lg.line(x, gy0, x, gy1)
        else
            local river_y_start = gy0 + inner_h * 4 / (C.RANKS - 1)
            local river_y_end   = gy0 + inner_h * 5 / (C.RANKS - 1)
            lg.line(x, gy0, x, river_y_start)
            lg.line(x, river_y_end, x, gy1)
        end
    end

    -- 5. 九宫斜线
    lg.line(gx0 + inner_w * 3 / 8, gy0,
            gx0 + inner_w * 5 / 8, gy0 + inner_h * 2 / 9)
    lg.line(gx0 + inner_w * 5 / 8, gy0,
            gx0 + inner_w * 3 / 8, gy0 + inner_h * 2 / 9)
    lg.line(gx0 + inner_w * 3 / 8, gy1,
            gx0 + inner_w * 5 / 8, gy0 + inner_h * 7 / 9)
    lg.line(gx0 + inner_w * 5 / 8, gy1,
            gx0 + inner_w * 3 / 8, gy0 + inner_h * 7 / 9)

    -- 6. 楚河汉界
    lg.setColor(utils.color(C.COLOR_RIVER_TEXT[1], C.COLOR_RIVER_TEXT[2], C.COLOR_RIVER_TEXT[3]))
    if font then lg.setFont(font) end
    local river_y = gy0 + inner_h * 4.5 / 9 - 12
    local t1, t2 = "楚 河", "漢 界"
    local f = lg.getFont()
    lg.print(t1, gx0 + inner_w * 0.18 - f:getWidth(t1)/2, river_y)
    lg.print(t2, gx0 + inner_w * 0.82 - f:getWidth(t2)/2, river_y)

    -- 7. 炮/兵位 L 标记
    lg.setColor(line_col)
    lg.setLineWidth(1.2)
    local marks = {
        {1,2},{7,2},{1,7},{7,7},
        {0,3},{2,3},{4,3},{6,3},{8,3},
        {0,6},{2,6},{4,6},{6,6},{8,6},
    }
    local LEN = 6
    local GAP = 4
    for _, m in ipairs(marks) do
        local fi, ri = m[1], m[2]
        local cx = gx0 + inner_w * fi / 8
        local cy = gy0 + inner_h * ri / 9
        local function corner(dx, dy)
            if (fi == 0 and dx < 0) or (fi == 8 and dx > 0) then return end
            if (ri == 0 and dy < 0) or (ri == 9 and dy > 0) then return end
            lg.line(cx + dx*GAP, cy + dy*GAP, cx + dx*(GAP+LEN), cy + dy*GAP)
            lg.line(cx + dx*GAP, cy + dy*GAP, cx + dx*GAP, cy + dy*(GAP+LEN))
        end
        corner(-1,-1); corner(1,-1); corner(-1,1); corner(1,1)
    end
    lg.setLineWidth(1)
end

--! 棋盘交点 (file, rank) → 世界坐标
function M.fileRankToWorld(f, r)
    local bw, bh = M.getBoardSize()
    local gx0 = -bw/2 + C.MARGIN
    local gy0 = -bh/2 + C.MARGIN
    local inner_w = bw - C.MARGIN * 2
    local inner_h = bh - C.MARGIN * 2
    local x = gx0 + inner_w * f / (C.FILES - 1)
    local y = gy0 + inner_h * r / (C.RANKS - 1)
    return x, y
end

function M.worldToFileRank(wx, wy)
    local bw, bh = M.getBoardSize()
    local gx0 = -bw/2 + C.MARGIN
    local gy0 = -bh/2 + C.MARGIN
    local inner_w = bw - C.MARGIN * 2
    local inner_h = bh - C.MARGIN * 2
    local fi = (wx - gx0) * (C.FILES - 1) / inner_w
    local ri = (wy - gy0) * (C.RANKS - 1) / inner_h
    local f = math.floor(fi + 0.5)
    local r = math.floor(ri + 0.5)
    if f < 0 or f >= C.FILES or r < 0 or r >= C.RANKS then return nil end
    return f, r
end

return M
