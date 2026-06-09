--! file: src/game/scenes/board_scene.lua
--! brief: V2 棋盘主场景 - 可交互版
--! 功能：
--!   - 鼠标点击选子
--!   - 显示合法落点（半透明绿点 + 红点表示可吃）
--!   - 移动动画（tween）
--!   - 吃子粒子 + 音效
--!   - 回合切换（红先黑后）
--!   - 非法移动音效
--!   - 上一次走子标记（源-目标连线高亮）

local logger = require("core.logger")
local resource = require("core.resource")
local input = require("core.input")
local event = require("core.event")
local Camera = require("engine.camera")
local particles = require("engine.particles")
local audio = require("engine.audio")
local Board = require("game.entities.board")
local BoardRen = require("game.renderers.board_renderer")
local PieceRen = require("game.renderers.piece_renderer")
local MoveRules = require("game.systems.move_rules")
local C = require("game.constants")
local utils = require("core.utils")

local BoardScene = {}
BoardScene.__index = BoardScene

function BoardScene.new()
    local self = setmetatable({}, BoardScene)
    return self
end

function BoardScene:load(params)
    logger.info("board_scene", "V2 Board scene loading...")

    -- 字体
    self.font_piece = resource.getFont("NotoSansCJK-Bold.ttc", 32)
    self.font_body  = resource.getFont("NotoSansCJK-Regular.ttc", 18)
    self.font_small = resource.getFont("NotoSansCJK-Regular.ttc", 14)
    self.font_river = resource.getFont("NotoSansCJK-Regular.ttc", 26)
    self.font_big   = resource.getFont("NotoSansCJK-Bold.ttc", 40)

    -- 棋盘
    self.board = Board.new()
    self.board:setupInitial()

    -- 相机
    self.camera = Camera.new()
    self.w, self.h = love.graphics.getDimensions()
    self:_applyZoom()

    -- 游戏状态
    self.turn = "red"         -- red 先
    self.selected = nil       -- 选中的 piece
    self.legal_moves = {}     -- 当前选中棋子的合法落点 {{f,r,capture},...}
    self.last_move = nil      -- {from_f, from_r, to_f, to_r, color}
    self.animating = nil      -- {piece, from_x, from_y, to_x, to_y, t, dur, on_complete}
    self.hover_f, self.hover_r = nil, nil

    -- 注册音频
    audio.init()

    -- 监听鼠标
    event.on("input:mousepressed", function(d)
        if d.button == 1 then self:_onClick(d.x, d.y) end
    end)

    -- R 键重开
    event.on("input:keypressed", function(d)
        if d.key == "r" then self:_reset() end
    end)

    logger.info("board_scene", "V2 ready: 32 pieces, turn=red")
end

function BoardScene:_applyZoom()
    local bw, bh = BoardRen.getBoardSize()
    local scale_x = (self.w * 0.88) / bw
    local scale_y = (self.h * 0.88) / bh
    local scale = math.min(scale_x, scale_y, 1.8)
    self.camera:setZoom(scale)
    self.camera:jumpTo(0, 0)
end

function BoardScene:resize(w, h)
    self.w, self.h = w, h
    if self.camera then self:_applyZoom() end
end

-- 屏幕坐标 → 世界坐标 → file/rank
function BoardScene:_screenToFileRank(sx, sy)
    local cx = self.w / 2
    local cy = self.h / 2
    local s = self.camera.scale
    local wx = (sx - cx) / s + self.camera.x
    local wy = (sy - cy) / s + self.camera.y
    return BoardRen.worldToFileRank(wx, wy)
end

function BoardScene:_onClick(sx, sy)
    if self.animating then return end  -- 动画中禁止操作
    local f, r = self:_screenToFileRank(sx, sy)
    if f == nil then
        self.selected = nil
        self.legal_moves = {}
        return
    end
    local clicked = self.board:pieceAt(f, r)

    -- 如果已经选中棋子
    if self.selected then
        -- 点自己 → 取消选择
        if clicked and clicked.id == self.selected.id then
            self.selected = nil
            self.legal_moves = {}
            audio.playSfx("select")
            return
        end
        -- 点己方其他棋子 → 切换选中
        if clicked and clicked.color == self.turn then
            self.selected = clicked
            self.legal_moves = MoveRules.getLegalMoves(self.board, clicked)
            audio.playSfx("select")
            return
        end
        -- 尝试走棋
        local legal, mv = MoveRules.isMoveLegal(self.board, self.selected, f, r)
        if legal then
            self:_doMove(self.selected, f, r, mv and mv.capture or false)
        else
            audio.playSfx("invalid")
            -- 震动一下镜头
            self.camera:shake(0.15, 3)
        end
        return
    end

    -- 未选中：点己方棋子 → 选中
    if clicked and clicked.color == self.turn then
        self.selected = clicked
        self.legal_moves = MoveRules.getLegalMoves(self.board, clicked)
        audio.playSfx("select")
    end
end

function BoardScene:_doMove(piece, to_f, to_r, is_capture)
    local from_x, from_y = BoardRen.fileRankToWorld(piece.file, piece.rank)
    local to_x, to_y   = BoardRen.fileRankToWorld(to_f, to_r)

    local captured_piece = nil
    if is_capture then
        captured_piece = self.board:pieceAt(to_f, to_r)
    end

    self.animating = {
        piece = piece,
        from_x = from_x, from_y = from_y,
        to_x = to_x, to_y = to_y,
        t = 0,
        dur = is_capture and 0.25 or 0.18,
        to_f = to_f, to_r = to_r,
        _from_f = piece.file, _from_r = piece.rank,
        captured = captured_piece,
        is_capture = is_capture,
    }
    self.selected = nil
    self.legal_moves = {}
end

function BoardScene:_finishMove()
    local a = self.animating
    if not a then return end
    local piece = a.piece

    -- 处理吃子
    if a.captured then
        a.captured.alive = false
        -- 粒子爆发（棋子被吃的颜色）
        local px, py = a.to_x, a.to_y
        local col = a.captured.color == "red" and {1, 0.35, 0.25} or {0.25, 0.25, 0.3}
        particles.addBurst(px, py, {
            count = 20, speed = 140, life = 0.45, size = 4,
            color = col, gravity = 200, spread = math.pi * 2,
        })
        audio.playSfx("capture")
    else
        audio.playSfx("move")
    end

    -- 更新棋盘数据
    piece.file = a.to_f
    piece.rank = a.to_r

    -- 记录上一步
    self.last_move = {
        from_f = a._from_f, from_r = a._from_r,
        to_f = a.to_f, to_r = a.to_r,
        piece = piece,
    }

    -- 切换回合
    self.turn = self.turn == "red" and "black" or "red"
    self.animating = nil
end

--! R 键重开
function BoardScene:_reset()
    particles.clear()
    self.board = Board.new()
    self.board:setupInitial()
    self.turn = "red"
    self.selected = nil
    self.legal_moves = {}
    self.last_move = nil
    self.animating = nil
    logger.info("board_scene", "Game reset")
end

function BoardScene:update(dt)
    if self.camera then self.camera:update(dt) end
    particles.update(dt)

    -- 更新鼠标 hover
    local mx, my = love.mouse.getPosition()
    self.hover_f, self.hover_r = self:_screenToFileRank(mx, my)

    -- 走子动画
    if self.animating then
        self.animating.t = self.animating.t + dt
        local p = math.min(1, self.animating.t / self.animating.dur)
        -- ease out quad
        local ep = 1 - (1 - p) * (1 - p)
        self.animating.cur_x = self.animating.from_x + (self.animating.to_x - self.animating.from_x) * ep
        self.animating.cur_y = self.animating.from_y + (self.animating.to_y - self.animating.from_y) * ep
        if p >= 1 then self:_finishMove() end
    end
end

function BoardScene:draw(r)
    local L = r.LAYERS
    local w, h = self.w, self.h
    local lg = love.graphics

    r.rect(L.BACKGROUND, 0, 0, w, h, utils.color(42, 30, 24))

    -- World
    r.custom(L.WORLD, function()
        self.camera:attach(w, h)

        BoardRen.draw(self.font_river)

        -- 绘制上一步高亮
        if self.last_move then
            local fx, fy = BoardRen.fileRankToWorld(self.last_move.from_f, self.last_move.from_r)
            local tx, ty = BoardRen.fileRankToWorld(self.last_move.to_f, self.last_move.to_r)
            lg.setColor(1, 0.9, 0.3, 0.35)
            lg.setLineWidth(2)
            lg.line(fx, fy, tx, ty)
            lg.setLineWidth(1)
            -- 目标圈
            lg.setColor(1, 0.85, 0.2, 0.25)
            lg.circle("fill", tx, ty, 26, 24)
        end

        -- 合法走法提示点
        for _, m in ipairs(self.legal_moves) do
            local mx, my = BoardRen.fileRankToWorld(m.f, m.r)
            if m.capture then
                -- 可吃：红色环
                lg.setColor(1, 0.3, 0.3, 0.7)
                lg.setLineWidth(2.5)
                lg.circle("line", mx, my, 28, 32)
                lg.setLineWidth(1)
            else
                -- 可走：绿色小点
                lg.setColor(0.3, 0.9, 0.3, 0.6)
                lg.circle("fill", mx, my, 8, 16)
            end
        end

        -- 选中棋子高亮环
        if self.selected and not self.animating then
            local sx, sy = BoardRen.fileRankToWorld(self.selected.file, self.selected.rank)
            lg.setColor(1, 1, 0.4, 0.9)
            lg.setLineWidth(3)
            lg.circle("line", sx, sy, C.PIECE_RADIUS + 4, 40)
            lg.setLineWidth(1)
        end

        -- 鼠标 hover 高亮
        if self.hover_f and not self.animating then
            local hx, hy = BoardRen.fileRankToWorld(self.hover_f, self.hover_r)
            lg.setColor(1, 1, 1, 0.08)
            lg.circle("fill", hx, hy, 26, 24)
        end

        -- 绘制棋子
        local sorted = {}
        for _, p in ipairs(self.board.pieces) do
            if p.alive and not (self.animating and self.animating.piece.id == p.id) then
                table.insert(sorted, p)
            end
        end
        table.sort(sorted, function(a, b) return a.rank < b.rank end)
        for _, p in ipairs(sorted) do
            PieceRen.draw(p, self.font_piece)
        end

        -- 绘制动画中的棋子（总是画在最上层）
        if self.animating then
            local a = self.animating
            local p = a.piece
            -- 临时绘制
            -- 保存 piece 的 file/rank，用动画位置绘制
            local saved_f, saved_r = p.file, p.rank
            local BoardRen2 = BoardRen
            -- 简化：直接在动画位置画，不走 fileRankToWorld
            -- 复用 PieceRen.draw 的内部逻辑会绕路，直接画
            -- 但 PieceRen.draw 用 file/rank，所以临时改
            -- 更干净做法：让 PieceRen.draw 接受 (x,y) 覆盖
            -- V2 简化：临时替换
            PieceRen.drawAt(p, self.font_piece, a.cur_x, a.cur_y)
        end

        -- 粒子
        particles.draw()

        self.camera:detach()
    end)

    -- 顶栏：回合指示
    local turn_text = self.turn == "red" and "● 红方回合" or "● 黑方回合"
    local turn_col = self.turn == "red" and utils.color(255, 80, 60) or utils.color(40, 40, 60)
    r.text(L.UI, turn_text, w - 180, 20, turn_col, self.font_body)
    r.text(L.UI, "中国象棋  ·  Chinese Chess  (V2)", 20, 20,
           utils.color(220, 200, 170), self.font_body)
    r.text(L.UI, "鼠标点击选子 → 点绿点移动 → 红点吃子",
           20, 50, utils.color(160, 140, 110), self.font_small)
    r.text(L.UI, "ESC 退出  ·  F11 全屏  ·  R 重开",
           20, h - 30, utils.color(120, 100, 80), self.font_small)
    r.text(L.UI, "Trillion Games 2D — Vale",
           w - 230, h - 30, utils.color(120, 100, 80), self.font_small)
end

function BoardScene:unload()
    particles.clear()
    logger.info("board_scene", "V2 Unloaded")
end

return BoardScene.new()
