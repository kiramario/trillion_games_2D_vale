--! file: src/game/scenes/board_scene.lua
--! brief: V3 棋盘主场景 - 将军/将死/AI/悔棋/历史

local logger = require("core.logger")
local resource = require("core.resource")
local input = require("core.input")
local event = require("core.event")
local scene_manager = require("core.scene_manager")
local Camera = require("engine.camera")
local particles = require("engine.particles")
local audio = require("engine.audio")
local Board = require("game.entities.board")
local BoardRen = require("game.renderers.board_renderer")
local PieceRen = require("game.renderers.piece_renderer")
local MoveRules = require("game.systems.move_rules")
local GameRules = require("game.systems.game_rules")
local AI = require("game.systems.ai")
local C = require("game.constants")
local utils = require("core.utils")

local BoardScene = {}
BoardScene.__index = BoardScene

function BoardScene.new()
    local self = setmetatable({}, BoardScene)
    return self
end

function BoardScene:load(params)
    logger.info("board_scene", "V3 Board scene loading...")

    self.params = params or {}
    self.w, self.h = love.graphics.getDimensions()

    -- 字体
    self.font_piece = resource.getFont("NotoSansCJK-Bold.ttc", 32)
    self.font_body  = resource.getFont("NotoSansCJK-Regular.ttc", 18)
    self.font_small = resource.getFont("NotoSansCJK-Regular.ttc", 14)
    self.font_river = resource.getFont("NotoSansCJK-Regular.ttc", 26)
    self.font_big   = resource.getFont("NotoSansCJK-Bold.ttc", 60)
    self.font_ui    = resource.getFont("NotoSansCJK-Regular.ttc", 15)
    self.font_btn   = resource.getFont("NotoSansCJK-Regular.ttc", 16)

    -- 相机
    self.camera = Camera.new()
    self:_reset()

    -- 接收参数
    if params and params.ai_mode ~= nil then
        self.ai_mode = params.ai_mode
    end

    -- 音频
    audio.init()

    -- 输入
    event.on("input:mousepressed", function(d)
        if d.button == 1 then self:_onClick(d.x, d.y) end
    end)
    event.on("input:keypressed", function(d)
        local k = d.key
        if k == "r" then self:_reset()
        elseif k == "u" then self:_undo()
        elseif k == "a" then self.ai_mode = not self.ai_mode
            self.status_text = self.ai_mode and "AI 对战模式（执红）" or "双人对战模式"
        elseif k == "escape" then
            scene_manager.switch("menu", nil, {fade = true})
        end
    end)

    logger.info("board_scene", "V3 ready: AI mode toggle with A, undo with U")
end

function BoardScene:_reset()
    particles.clear()
    self.board = Board.new()
    self.board:setupInitial()
    self.turn = "red"
    self.selected = nil
    self.legal_moves = {}
    self.last_move = nil
    self.animating = nil
    self.hover_f, self.hover_r = nil, nil
    self.game_state = "normal"  -- normal/check/checkmate/stalemate
    self.winner = nil
    self.check_flash = 0  -- 将军时的闪烁计时
    self.status_text = ""
    self.history = {}
    self.ai_mode = true
    self.ai_thinking = false
    self.ai_think_timer = 0
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

function BoardScene:_screenToFileRank(sx, sy)
    local cx = self.w / 2
    local cy = self.h / 2
    local s = self.camera.scale
    local wx = (sx - cx) / s + self.camera.x
    local wy = (sy - cy) / s + self.camera.y
    return BoardRen.worldToFileRank(wx, wy)
end

function BoardScene:_onClick(sx, sy)
    if self.animating or self.game_state == "checkmate" or self.game_state == "stalemate" then return end
    -- AI 模式下只能操控红方
    if self.ai_mode and self.turn ~= "red" then return end
    -- AI 正在思考
    if self.ai_thinking then return end

    local f, r = self:_screenToFileRank(sx, sy)
    if f == nil then
        self.selected = nil
        self.legal_moves = {}
        return
    end
    local clicked = self.board:pieceAt(f, r)

    if self.selected then
        if clicked and clicked.id == self.selected.id then
            self.selected = nil
            self.legal_moves = {}
            audio.playSfx("select")
            return
        end
        if clicked and clicked.color == self.turn then
            self.selected = clicked
            self.legal_moves = self:_computeSafeMoves(clicked)
            audio.playSfx("select")
            return
        end
        if self:_tryMove(self.selected, f, r) then return end
        audio.playSfx("invalid")
        self.camera:shake(0.15, 3)
        return
    end

    if clicked and clicked.color == self.turn then
        self.selected = clicked
        self.legal_moves = self:_computeSafeMoves(clicked)
        audio.playSfx("select")
    end
end

-- 用安全走法（不导致自己被将军）
function BoardScene:_computeSafeMoves(piece)
    local out = {}
    local basics = MoveRules.getLegalMoves(self.board, piece)
    for _, m in ipairs(basics) do
        if GameRules.isMoveSafe(self.board, piece, m.f, m.r) then
            table.insert(out, m)
        end
    end
    return out
end

function BoardScene:_tryMove(piece, to_f, to_r)
    if not GameRules.isMoveSafe(self.board, piece, to_f, to_r) then return false end
    local from_x, from_y = BoardRen.fileRankToWorld(piece.file, piece.rank)
    local to_x, to_y = BoardRen.fileRankToWorld(to_f, to_r)
    local captured = self.board:pieceAt(to_f, to_r)
    self.animating = {
        piece = piece,
        from_x = from_x, from_y = from_y,
        to_x = to_x, to_y = to_y,
        t = 0,
        dur = captured and 0.25 or 0.18,
        _from_f = piece.file, _from_r = piece.rank,
        to_f = to_f, to_r = to_r,
        captured = captured,
    }
    self.selected = nil
    self.legal_moves = {}
    return true
end

function BoardScene:_finishMove()
    local a = self.animating
    local piece = a.piece
    local captured = a.captured

    -- 粒子
    if captured then
        captured.alive = false
        local px, py = a.to_x, a.to_y
        local col = captured.color == "red" and {1, 0.35, 0.25} or {0.25, 0.25, 0.3}
        particles.addBurst(px, py, {count=22, speed=150, life=0.5, size=4, color=col, gravity=240})
        audio.playSfx("capture")
        self.camera:shake(0.2, 5)
    else
        audio.playSfx("move")
    end

    -- 记录历史（用于悔棋）
    table.insert(self.history, {
        piece_id = piece.id,
        from_f = a._from_f, from_r = a._from_r,
        to_f = a.to_f, to_r = a.to_r,
        captured_id = captured and captured.id or nil,
        turn_before = self.turn,
    })

    -- 应用到棋盘
    piece.file = a.to_f
    piece.rank = a.to_r

    self.last_move = {
        from_f = a._from_f, from_r = a._from_r,
        to_f = a.to_f, to_r = a.to_r,
        piece = piece,
    }

    -- 切换回合
    self.turn = self.turn == "red" and "black" or "red"
    self.animating = nil

    -- 判定局面
    local state, winner = GameRules.getGameState(self.board, self.turn)
    self.game_state = state
    self.winner = winner
    if state == "checkmate" then
        audio.playSfx("check")
        self.camera:shake(0.6, 12)
        self.status_text = (winner == "red" and "红方胜！" or "黑方胜！") .. "  将死！"
        particles.addBurst(0, 0, {count=80, speed=400, life=1.2, size=5, color={1, 0.85, 0.2}, gravity=0})
    elseif state == "stalemate" then
        self.status_text = (winner == "red" and "红方胜！" or "黑方胜！") .. "  困毙！"
    elseif state == "check" then
        self.check_flash = 1.5
        audio.playSfx("check")
        self.camera:shake(0.3, 8)
        self.status_text = self.turn == "red" and "红方被将军！" or "黑方被将军！"
    else
        self.status_text = ""
    end
end

--! 悔棋（U 键）
function BoardScene:_undo()
    if self.animating then return end
    if #self.history == 0 then return end
    local mv = table.remove(self.history)
    -- 找到 piece
    local piece = nil
    for _, p in ipairs(self.board.pieces) do
        if p.id == mv.piece_id then piece = p; break end
    end
    if piece then
        piece.file = mv.from_f
        piece.rank = mv.from_r
    end
    if mv.captured_id then
        for _, p in ipairs(self.board.pieces) do
            if p.id == mv.captured_id then p.alive = true; break end
        end
    end
    self.turn = mv.turn_before
    -- 重算 last_move
    if #self.history > 0 then
        local last = self.history[#self.history]
        self.last_move = {from_f=last.from_f, from_r=last.from_r, to_f=last.to_f, to_r=last.to_r}
    else
        self.last_move = nil
    end
    self.game_state = "normal"
    self.winner = nil
    self.status_text = "悔棋成功"
    self.selected = nil
    self.legal_moves = {}
    audio.playSfx("select")
    -- AI 模式下连悔两步（悔掉 AI 的一步 + 自己的一步）
    if self.ai_mode and self.turn == "black" and #self.history > 0 then
        self:_undo()
    end
end

function BoardScene:update(dt)
    if self.camera then self.camera:update(dt) end
    particles.update(dt)
    if self.check_flash > 0 then self.check_flash = self.check_flash - dt end

    local mx, my = love.mouse.getPosition()
    self.hover_f, self.hover_r = self:_screenToFileRank(mx, my)

    -- 走子动画
    if self.animating then
        self.animating.t = self.animating.t + dt
        local p = math.min(1, self.animating.t / self.animating.dur)
        local ep = 1 - (1 - p) * (1 - p)
        self.animating.cur_x = self.animating.from_x + (self.animating.to_x - self.animating.from_x) * ep
        self.animating.cur_y = self.animating.from_y + (self.animating.to_y - self.animating.from_y) * ep
        if p >= 1 then self:_finishMove() end
    end

    -- AI 走棋
    if self.ai_mode and self.turn == "black" and not self.animating and
       self.game_state ~= "checkmate" and self.game_state ~= "stalemate" then
        self.ai_thinking = true
        self.ai_think_timer = self.ai_think_timer + dt
        -- 延迟 0.4 秒，模拟思考
        if self.ai_think_timer >= 0.4 then
            self.ai_think_timer = 0
            local mv = AI.chooseMove(self.board, "black", 1)
            if mv then
                -- 找到当前 board 上对应 piece
                local piece = nil
                for _, p in ipairs(self.board.pieces) do
                    if p.id == mv.piece.id then piece = p; break end
                end
                if piece then
                    self:_tryMove(piece, mv.to_f, mv.to_r)
                end
            end
            self.ai_thinking = false
        end
    end
end

function BoardScene:draw(r)
    local L = r.LAYERS
    local w, h = self.w, self.h
    local lg = love.graphics

    -- 将军时整个背景闪红
    local bg = {42, 30, 24}
    if self.check_flash > 0 then
        local k = self.check_flash / 1.5
        bg = {42 + k * 80, 30 - k * 20, 24}
    end
    r.rect(L.BACKGROUND, 0, 0, w, h, utils.color(bg[1], bg[2], bg[3]))

    r.custom(L.WORLD, function()
        self.camera:attach(w, h)
        BoardRen.draw(self.font_river)

        -- 上一步高亮
        if self.last_move then
            local fx, fy = BoardRen.fileRankToWorld(self.last_move.from_f, self.last_move.from_r)
            local tx, ty = BoardRen.fileRankToWorld(self.last_move.to_f, self.last_move.to_r)
            lg.setColor(1, 0.9, 0.3, 0.35)
            lg.setLineWidth(2)
            lg.line(fx, fy, tx, ty)
            lg.setLineWidth(1)
            lg.setColor(1, 0.85, 0.2, 0.25)
            lg.circle("fill", tx, ty, 26, 24)
        end

        -- 合法落点
        for _, m in ipairs(self.legal_moves) do
            local mx, my = BoardRen.fileRankToWorld(m.f, m.r)
            if m.capture then
                lg.setColor(1, 0.3, 0.3, 0.7)
                lg.setLineWidth(2.5)
                lg.circle("line", mx, my, 28, 32)
                lg.setLineWidth(1)
            else
                lg.setColor(0.3, 0.9, 0.3, 0.6)
                lg.circle("fill", mx, my, 8, 16)
            end
        end

        -- 选中环
        if self.selected and not self.animating then
            local sx, sy = BoardRen.fileRankToWorld(self.selected.file, self.selected.rank)
            lg.setColor(1, 1, 0.4, 0.9)
            lg.setLineWidth(3)
            lg.circle("line", sx, sy, C.PIECE_RADIUS + 4, 40)
            lg.setLineWidth(1)
        end

        -- hover
        if self.hover_f and not self.animating and not self.ai_thinking then
            local hx, hy = BoardRen.fileRankToWorld(self.hover_f, self.hover_r)
            lg.setColor(1, 1, 1, 0.08)
            lg.circle("fill", hx, hy, 26, 24)
        end

        -- 被将军的王红圈闪烁
        if self.game_state == "check" or self.check_flash > 0 then
            local king_color_in_check = self.turn
            local k = GameRules.findKing(self.board, king_color_in_check)
            if k then
                local kx, ky = BoardRen.fileRankToWorld(k.file, k.rank)
                local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 12)
                lg.setColor(1, 0.2, 0.2, 0.4 + pulse * 0.4)
                lg.setLineWidth(3)
                lg.circle("line", kx, ky, C.PIECE_RADIUS + 8 + pulse * 4, 40)
                lg.setLineWidth(1)
            end
        end

        -- 棋子
        for _, p in ipairs(self.board.pieces) do
            if p.alive and not (self.animating and self.animating.piece.id == p.id) then
                PieceRen.draw(p, self.font_piece)
            end
        end

        -- 动画中的棋子
        if self.animating then
            PieceRen.drawAt(self.animating.piece, self.font_piece,
                            self.animating.cur_x, self.animating.cur_y)
        end

        particles.draw()
        self.camera:detach()
    end)

    -- UI 顶栏
    r.rect(L.UI, 0, 0, w, 42, utils.color(30, 22, 18, 210))
    r.text(L.UI, "中国象棋  ·  Chinese Chess  (V3)", 16, 11,
           utils.color(220, 200, 170), self.font_body)
    local turn_str = self.turn == "red" and "● 红方回合" or "● 黑方回合"
    local turn_c = self.turn == "red" and utils.color(255, 90, 70) or utils.color(60, 60, 90)
    if self.ai_thinking then turn_str = "... AI 思考中" turn_c = utils.color(180,180,200) end
    r.text(L.UI, turn_str, w - 200, 11, turn_c, self.font_body)

    -- 状态栏
    if self.status_text ~= "" then
        local sc = utils.color(255, 220, 100)
        if self.winner then sc = self.winner == "red" and utils.color(255,90,70) or utils.color(80,80,120) end
        r.rect(L.OVERLAY, 0, h - 80, w, 48, utils.color(0,0,0,160))
        r.text(L.OVERLAY, self.status_text, w/2 - 160, h - 70, sc, self.font_body)
    end

    -- 胜负覆盖层
    if self.game_state == "checkmate" or self.game_state == "stalemate" then
        r.rect(L.OVERLAY, 0, 0, w, h, utils.color(0,0,0,150))
        local win_text = self.winner == "red" and "红方胜！" or "黑方胜！"
        local sub = self.game_state == "checkmate" and "将死" or "困毙"
        r.text(L.OVERLAY, win_text, w/2 - 120, h/2 - 50, utils.color(255,230,120), self.font_big)
        r.text(L.OVERLAY, sub .. "  ·  按 R 重新开始", w/2 - 160, h/2 + 30,
               utils.color(200,200,200), self.font_body)
    end

    -- 底栏：操作提示
    r.rect(L.UI, 0, h - 32, w, 32, utils.color(30,22,18,210))
    r.text(L.UI, "LMB 选子/走棋  ·  U 悔棋  ·  R 重开  ·  A 切换AI/双人", 16, h - 24,
           utils.color(160,140,110), self.font_small)
    local mode_str = self.ai_mode and "AI 模式（执红）" or "双人对战"
    r.text(L.UI, mode_str, w - 180, h - 24, utils.color(160,140,110), self.font_small)
end

function BoardScene:unload()
    particles.clear()
    logger.info("board_scene", "V3 Unloaded")
end

return BoardScene.new()
