--! file: src/game/scenes/boot_scene.lua
--! brief: Boot/Loading 场景
--! 类比：游戏的启动画面/Splash screen
--! 职责：显示 loading 文字，短暂停留后切换到下一个场景
--! V0 没有真正的资源预加载，所以这个场景很短，只是演示场景切换流程

local logger = require("core.logger")
local scene_manager = require("core.scene_manager")
local renderer = require("core.renderer")
local timer = require("core.timer")
local utils = require("core.utils")
local resource = require("core.resource")

local BootScene = {}
BootScene.__index = BootScene

function BootScene.new()
    local self = setmetatable({}, BootScene)
    return self
end

--! 场景加载
--! @param params { next = 下一个场景名, next_delay = 停留秒数 }
function BootScene:load(params)
    logger.info("boot_scene", "Booting...")
    self.params = params or { next = "demo", next_delay = 1.0 }
    self.elapsed = 0
    self.phase = "loading"  -- loading -> ready
    self.font_large = resource.getFont(nil, 48)
    self.font_small = resource.getFont(nil, 16)

    -- V0 没有外部资源要加载；V1+ 在这里调用 resource.preload() 加载图片/字体/音效
    -- 模拟加载完成
    timer.after(self.params.next_delay, function()
        logger.info("boot_scene", "Boot complete, switching to '%s'", self.params.next)
        scene_manager.switch(self.params.next, nil, { fade = true, fade_duration = 0.5 })
    end)
end

function BootScene:update(dt)
    self.elapsed = self.elapsed + dt
end

function BootScene:draw(r)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- 深色背景
    r.rect("background", 0, 0, w, h, utils.color(15, 18, 28))

    -- 标题
    local title = "Trillion Games 2D"
    local subtitle = "Vale"
    local loading_text = "Loading..."

    r.text("ui", title, 0, h/2 - 80, utils.color(220, 220, 230), self.font_large, "center")
    -- 居中显示
    r.custom("ui", function()
        local font = self.font_large
        local tw = font:getWidth(title)
        love.graphics.setColor(utils.color(220, 220, 230))
        love.graphics.setFont(font)
        love.graphics.print(title, (w - tw) / 2, h/2 - 80)

        local font2 = self.font_large
        love.graphics.setColor(utils.color(180, 140, 255))
        love.graphics.print(subtitle, (w - font2:getWidth(subtitle)) / 2, h/2 - 30)

        local font3 = self.font_small
        love.graphics.setColor(utils.color(120, 120, 140))
        love.graphics.setFont(font3)
        love.graphics.print(loading_text, (w - font3:getWidth(loading_text)) / 2, h/2 + 50)
    end)

    -- 底部版本号
    local version = "v0.0.0"
    r.custom("overlay", function()
        love.graphics.setFont(self.font_small)
        love.graphics.setColor(utils.color(80, 80, 100))
        love.graphics.print(version, 10, h - 24)
    end)
end

function BootScene:unload()
    logger.debug("boot_scene", "Unloaded")
end

return BootScene.new()
