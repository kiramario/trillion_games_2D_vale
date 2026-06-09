--! file: src/game/scenes/demo_scene.lua
--! brief: V0 演示场景 —— 展示分层渲染、输入响应、动画等核心系统
--! 类比：一个 "hello world" 但能看能按，证明所有核心系统通了
--!
--! 这个场景做的事情：
--!   - 显示 "Hello Engine" 大字
--!   - 中央一个彩色方块（可以按 1/2/3 切换颜色）
--!   - 方块上下缓动动画
--!   - 鼠标点击处产生涟漪效果
--!   - 展示 5 个渲染层各自的颜色
--!   - 按 ESC 退出（全局绑定的）

local logger = require("core.logger")
local input = require("core.input")
local renderer = require("core.renderer")
local timer = require("core.timer")
local utils = require("core.utils")
local resource = require("core.resource")
local event = require("core.event")

local DemoScene = {}
DemoScene.__index = DemoScene

function DemoScene.new()
    local self = setmetatable({}, DemoScene)
    return self
end

function DemoScene:load(params)
    logger.info("demo_scene", "Loaded")

    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()

    -- 字体
    self.font_title = resource.getFont(nil, 64)
    self.font_body  = resource.getFont(nil, 20)
    self.font_small = resource.getFont(nil, 14)

    -- 中央方块动画
    self.box = {
        x = self.w/2 - 100,
        y = self.h/2 - 100,
        w = 200,
        h = 200,
        base_y = self.h/2 - 100,
        color = 1,  -- 当前颜色索引
    }

    -- 颜色方案（按 1/2/3 切换）
    self.palettes = {
        { name = "Crimson",   color = utils.color(220, 50, 60) },
        { name = "Ocean",     color = utils.color(50, 130, 220) },
        { name = "Forest",    color = utils.color(60, 180, 90) },
    }

    -- 动画：方块上下浮动
    self.anim_time = 0
    self.box_tween = timer.tween(
        2.0,
        self.box,
        { y = self.box.base_y - 20 },
        "easeInOutQuad",
        function()
            -- 到顶后再下来，循环
            self.box_tween = timer.tween(
                2.0,
                self.box,
                { y = self.box.base_y + 20 },
                "easeInOutQuad",
                function()
                    self.box.y = self.box.base_y - 20
                    self:startBobAnim()
                end
            )
        end
    )

    -- 鼠标涟漪列表
    self.ripples = {}

    -- 订阅鼠标点击事件（演示事件系统）
    self.unsub_click = event.on("input:mousepressed", function(data)
        self:onClick(data.x, data.y, data.button)
    end)

    -- 显示时长（用来计算一些动画）
    self.time = 0
end

function DemoScene:startBobAnim()
    self.box_tween = timer.tween(
        2.0,
        self.box,
        { y = self.box.base_y - 20 },
        "easeInOutQuad",
        function()
            self.box_tween = timer.tween(
                2.0,
                self.box,
                { y = self.box.base_y + 20 },
                "easeInOutQuad",
                function()
                    self:startBobAnim()
                end
            )
        end
    )
end

function DemoScene:onClick(x, y, button)
    if button == 1 then
        -- 添加涟漪
        table.insert(self.ripples, {
            x = x, y = y,
            radius = 5,
            max_radius = 80,
            alpha = 1,
            color = self.palettes[self.box.color].color,
        })
    end
end

function DemoScene:update(dt)
    self.time = self.time + dt
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()

    -- 响应按键切换颜色（wasPressed 只在按下那一帧触发一次，不会一直触发）
    if input.wasPressed("1") then
        self.box.color = 1
        logger.info("demo", "Palette: Crimson")
    elseif input.wasPressed("2") then
        self.box.color = 2
        logger.info("demo", "Palette: Ocean")
    elseif input.wasPressed("3") then
        self.box.color = 3
        logger.info("demo", "Palette: Forest")
    end

    -- 按空格给方块一个弹性缩放
    if input.wasPressed("space") then
        self.box.w = 220
        self.box.h = 220
        timer.tween(0.3, self.box, { w = 200, h = 200 }, "easeOutBack")
    end

    -- 鼠标左键点击也能换颜色（右键）
    if input.wasMousePressed(2) then
        self.box.color = (self.box.color % 3) + 1
    end

    -- 更新涟漪
    for i = #self.ripples, 1, -1 do
        local r = self.ripples[i]
        r.radius = r.radius + 200 * dt
        r.alpha = 1 - (r.radius / r.max_radius)
        if r.radius >= r.max_radius then
            table.remove(self.ripples, i)
        end
    end

    -- 如果窗口 resize，让方块保持居中
    self.box.x = self.w/2 - self.box.w/2
    self.box.base_y = self.h/2 - self.box.h/2
end

function DemoScene:draw(r)
    local w, h = self.w, self.h
    local L = r.LAYERS

    -- ===== LAYER: background =====
    -- 深色渐变背景（用多个矩形模拟）
    r.rect(L.BACKGROUND, 0, 0, w, h, utils.color(18, 20, 32))
    -- 装饰性大矩形（背景层的色块）
    r.rect(L.BACKGROUND, 0, h*0.7, w, h*0.3, utils.color(22, 25, 40))

    -- ===== LAYER: world =====
    -- 这是 "世界层"，V1+ 棋盘棋子会画在这一层
    -- V0 用彩色方块演示
    local palette = self.palettes[self.box.color]

    -- 方块阴影（模拟伪纵深！V1 会用来做棋子阴影）
    r.rect(L.WORLD, self.box.x + 8, self.box.y + self.box.h - 5, self.box.w, 15,
        {0, 0, 0, 0.3})
    -- 方块本体
    r.rect(L.WORLD, self.box.x, self.box.y, self.box.w, self.box.h, palette.color)
    -- 方块高光条（顶部 3px，让方块有立体感）
    r.rect(L.WORLD, self.box.x, self.box.y, self.box.w, 3,
        {1, 1, 1, 0.15})

    -- ===== LAYER: effects =====
    -- 涟漪粒子
    for _, rip in ipairs(self.ripples) do
        r.circle(L.EFFECTS, rip.x, rip.y, rip.radius,
            {rip.color[1], rip.color[2], rip.color[3], rip.alpha * 0.5}, "line", 32)
    end
    -- 方块周围光晕
    local glow_size = 30 + math.sin(self.time * 3) * 10
    r.circle(L.EFFECTS, w/2, self.box.y + self.box.h/2,
        self.box.w/2 + glow_size,
        {palette.color[1], palette.color[2], palette.color[3], 0.08},
        "fill", 48)

    -- ===== LAYER: ui =====
    -- 标题
    r.custom(L.UI, function()
        love.graphics.setFont(self.font_title)
        local title = "Hello Engine"
        local tw = self.font_title:getWidth(title)
        love.graphics.setColor(utils.color(240, 240, 250))
        love.graphics.print(title, (w - tw)/2, 80)

        love.graphics.setFont(self.font_body)
        love.graphics.setColor(palette.color)
        local sub = "Core systems operational — " .. palette.name
        local sw = self.font_body:getWidth(sub)
        love.graphics.print(sub, (w - sw)/2, 160)
    end)

    -- 操作说明
    local help_lines = {
        "Controls:",
        "  1 / 2 / 3  —  switch color palette",
        "  Space      —  bounce the box",
        "  Left click —  ripple effect",
        "  Right click — next palette",
        "  F11        —  toggle fullscreen",
        "  F12        —  take screenshot",
        "  ESC        —  quit",
    }
    for i, line in ipairs(help_lines) do
        r.text(L.UI, line, 30, h - 220 + (i-1)*22,
            i == 1 and utils.color(180, 180, 200) or utils.color(120, 120, 140),
            self.font_small)
    end

    -- 右边显示分层标签
    local layer_labels = {
        { name = "BACKGROUND", y = h*0.05, color = utils.color(60, 60, 80) },
        { name = "WORLD",      y = h*0.35, color = utils.color(200, 150, 50) },
        { name = "EFFECTS",    y = h*0.55, color = utils.color(50, 200, 200) },
        { name = "UI",         y = h*0.7,  color = utils.color(200, 50, 150) },
        { name = "OVERLAY",    y = h*0.85, color = utils.color(50, 200, 50) },
    }
    for _, ll in ipairs(layer_labels) do
        r.custom(L.UI, function()
            love.graphics.setFont(self.font_small)
            love.graphics.setColor(ll.color)
            love.graphics.print("LAYER: " .. ll.name, w - 180, ll.y)
        end)
    end

    -- 方块上的文字
    r.custom(L.UI, function()
        love.graphics.setFont(self.font_body)
        love.graphics.setColor(1, 1, 1, 1)
        local txt = "V0"
        local tw = self.font_body:getWidth(txt)
        love.graphics.print(txt, w/2 - tw/2, self.box.y + self.box.h/2 - 10)
    end)

    -- ===== LAYER: overlay =====
    -- 角落装饰线（overlay 始终在最前）
    r.line(L.OVERLAY, 0, 0, w, 0, {1, 1, 1, 0.05}, 2)
    r.line(L.OVERLAY, 0, h, w, h, {1, 1, 1, 0.05}, 2)
end

function DemoScene:unload()
    logger.info("demo_scene", "Unloaded")
    -- 取消事件订阅（非常重要！否则切换场景后旧场景还在响应事件）
    if self.unsub_click then
        self.unsub_click()
        self.unsub_click = nil
    end
    -- 取消 tween
    if self.box_tween then
        timer.cancelTween(self.box_tween)
        self.box_tween = nil
    end
end

return DemoScene.new()
