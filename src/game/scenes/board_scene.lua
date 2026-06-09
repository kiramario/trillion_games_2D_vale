--! file: src/game/scenes/board_scene.lua
--! brief: V1 棋盘主场景

local logger = require("core.logger")
local resource = require("core.resource")
local Camera = require("engine.camera")
local Board = require("game.entities.board")
local BoardRen = require("game.renderers.board_renderer")
local PieceRen = require("game.renderers.piece_renderer")
local utils = require("core.utils")

local BoardScene = {}
BoardScene.__index = BoardScene

function BoardScene.new()
    local self = setmetatable({}, BoardScene)
    return self
end

function BoardScene:load(params)
    logger.info("board_scene", "Loading...")

    self.font_piece = resource.getFont("NotoSansCJK-Bold.ttc", 32)
    self.font_body  = resource.getFont("NotoSansCJK-Regular.ttc", 18)
    self.font_small = resource.getFont("NotoSansCJK-Regular.ttc", 14)
    self.font_river = resource.getFont("NotoSansCJK-Regular.ttc", 26)

    self.board = Board.new()
    self.board:setupInitial()
    logger.info("board_scene", "Board ready: %d pieces", #self.board.pieces)

    self.camera = Camera.new()
    self.w, self.h = love.graphics.getDimensions()
    self:_applyZoom()
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

function BoardScene:update(dt)
    if self.camera then self.camera:update(dt) end
end

function BoardScene:draw(r)
    local L = r.LAYERS
    local w, h = self.w, self.h
    r.rect(L.BACKGROUND, 0, 0, w, h, utils.color(42, 30, 24))

    -- 画棋盘 + 棋子（在 camera 包裹下直接用 love.graphics 绘制）
    r.custom(L.WORLD, function()
        self.camera:attach(w, h)
        BoardRen.draw(self.font_river)
        for _, p in ipairs(self.board.pieces) do
            if p.alive then PieceRen.draw(p, self.font_piece) end
        end
        self.camera:detach()
    end)

    r.text(L.UI, "中国象棋  ·  Chinese Chess  (V1)", 20, 20,
           utils.color(220, 200, 170), self.font_body)
    r.text(L.UI, "V1 棋盘初现  ·  32 枚棋子就位  ·  V2 将加入交互走棋",
           20, 50, utils.color(160, 140, 110), self.font_small)
    r.text(L.UI, "ESC 退出  ·  F11 全屏  ·  窗口可缩放",
           20, h - 30, utils.color(120, 100, 80), self.font_small)
    r.text(L.UI, "Trillion Games 2D — Vale",
           w - 230, h - 30, utils.color(120, 100, 80), self.font_small)
end

function BoardScene:unload()
    logger.info("board_scene", "Unloaded")
end

return BoardScene.new()
