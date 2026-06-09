--! file: src/game/scenes/menu_scene.lua
--! brief: V4 主菜单场景

local logger = require("core.logger")
local resource = require("core.resource")
local scene_manager = require("core.scene_manager")
local audio = require("engine.audio")
local Button = require("engine.ui.button")
local particles = require("engine.particles")
local event = require("core.event")
local utils = require("core.utils")
local input = require("core.input")

local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene.new()
    local self = setmetatable({}, MenuScene)
    return self
end

function MenuScene:load(params)
    logger.info("menu_scene", "Loading main menu...")

    self.font_title   = resource.getFont("NotoSansCJK-Bold.ttc", 68)
    self.font_sub     = resource.getFont("NotoSansCJK-Regular.ttc", 22)
    self.font_btn     = resource.getFont("NotoSansCJK-Regular.ttc", 20)
    self.font_small   = resource.getFont("NotoSansCJK-Regular.ttc", 14)
    self.font_version = resource.getFont("NotoSansCJK-Regular.ttc", 13)

    self.w, self.h = love.graphics.getDimensions()
    self.t = 0
    particles.clear()
    Button.clear()

    local bw, bh = 300, 54
    local bx = self.w / 2 - bw / 2
    local by_start = self.h * 0.42
    local gap = 70

    self.btn_start = Button.add({
        x=bx, y=by_start, w=bw, h=bh, label="开始对战",
        font=self.font_btn, on_click=function()
            audio.playSfx("select")
            scene_manager.switch("board", {ai_mode = true, new_game = true})
        end,
        color={0.6, 0.25, 0.2, 0.95}, hover_color={0.85, 0.35, 0.25, 1},
    })
    self.btn_pvp = Button.add({
        x=bx, y=by_start + gap, w=bw, h=bh, label="双人对战",
        font=self.font_btn, on_click=function()
            audio.playSfx("select")
            scene_manager.switch("board", {ai_mode = false, new_game = true})
        end,
        color={0.25, 0.3, 0.55, 0.95}, hover_color={0.4, 0.5, 0.8, 1},
    })
    self.btn_quit = Button.add({
        x=bx, y=by_start + gap * 2, w=bw, h=bh, label="退出游戏",
        font=self.font_btn, on_click=function()
            audio.playSfx("select")
            love.event.quit()
        end,
        color={0.25, 0.25, 0.3, 0.9}, hover_color={0.5, 0.5, 0.6, 1},
    })

    -- 菜单背景粒子（飘散的"棋子"光影）
    self.floats = {}
    for i = 1, 30 do
        table.insert(self.floats, {
            x = love.math.random() * self.w,
            y = love.math.random() * self.h,
            r = 4 + love.math.random() * 16,
            vy = 8 + love.math.random() * 20,
            a = 0.03 + love.math.random() * 0.1,
            phase = love.math.random() * math.pi * 2,
        })
    end

    -- 键盘快捷键
    event.on("input:keypressed", function(d)
        if d.key == "return" or d.key == "space" then
            scene_manager.switch("board", {ai_mode = true, new_game = true})
        end
    end)

    audio.init()
end

function MenuScene:resize(w, h)
    self.w, self.h = w, h
    Button.clear()
    self:load()
end

function MenuScene:update(dt)
    self.t = self.t + dt
    particles.update(dt)
    local mx, my = love.mouse.getPosition()
    local mdown = input.mousePressedThisFrame and input.mousePressedThisFrame(1)
    -- 简化：直接用 love.mouse.isDown(1) 但要避免连点
    -- V4 简化：每帧检测鼠标刚按下
    if not self._was_down then self._was_down = false end
    local is_down = love.mouse.isDown(1)
    local just_pressed = is_down and not self._was_down
    self._was_down = is_down
    Button.update(dt, mx, my, just_pressed)

    -- 飘浮粒子
    for _, f in ipairs(self.floats) do
        f.y = f.y + f.vy * dt
        if f.y - f.r > self.h then
            f.y = -f.r
            f.x = love.math.random() * self.w
        end
    end
end

function MenuScene:draw(r)
    local L = r.LAYERS
    local w, h = self.w, self.h
    local lg = love.graphics

    -- 深木色背景渐变
    r.rect(L.BACKGROUND, 0, 0, w, h, utils.color(42, 28, 22))
    for i = 0, 20 do
        local t = i / 20
        local a = 0.1 * (1 - t)
        r.rect(L.BACKGROUND, 0, i * (h/20), w, h/20, utils.color(70, 45, 30, a*255))
    end

    -- 飘浮圆
    r.custom(L.BACKGROUND, function()
        for _, f in ipairs(self.floats) do
            local a = f.a * (0.5 + 0.5 * math.sin(self.t * 0.7 + f.phase))
            lg.setColor(1, 0.8, 0.5, a)
            lg.circle("fill", f.x, f.y, f.r, 16)
        end
    end)

    -- 标题
    r.custom(L.UI, function()
        lg.setFont(self.font_title)
        local title = "中国象棋"
        local tw = self.font_title:getWidth(title)
        -- 阴影
        lg.setColor(0,0,0,0.5)
        lg.print(title, w/2 - tw/2 + 3, h*0.18 + 3)
        -- 主体金色带微红光晕
        lg.setColor(0.9, 0.75, 0.3, 1)
        lg.print(title, w/2 - tw/2, h*0.18)

        lg.setFont(self.font_sub)
        local sub = "Chinese Chess"
        local sw = self.font_sub:getWidth(sub)
        lg.setColor(0.7, 0.55, 0.35, 1)
        lg.print(sub, w/2 - sw/2, h*0.18 + 78)

        lg.setFont(self.font_small)
        local tagline = "Trillion Games 2D — Vale  ·  v5.0.0（开发版）"
        local tgw = self.font_small:getWidth(tagline)
        lg.setColor(0.5, 0.4, 0.3, 1)
        lg.print(tagline, w/2 - tgw/2, h*0.18 + 118)
    end)

    -- 按钮
    r.custom(L.UI, function()
        Button.draw(lg)
        particles.draw()
    end)

    -- 版本/快捷键提示
    r.text(L.UI, "回车/空格快速开始  ·  ESC退出", w - 280, h - 30,
           utils.color(120, 100, 80), self.font_version)
end

function MenuScene:unload()
    Button.clear()
    particles.clear()
end

return MenuScene.new()
