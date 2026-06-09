--! file: src/core/renderer.lua
--! brief: 分层渲染器
--! 类比：CSS z-index 分层 / Unity Sorting Layers
--!
--! 为什么需要分层？因为直接按 draw 调用顺序画，很难保证"背景在最后、UI 在最前"。
--! 分层让你把 draw 命令提交到指定层，渲染时按层顺序统一绘制。
--!
--! V0 有 5 层，顺序固定：
--!   background → world → effects → ui → overlay
--! 这对中国象棋来说：
--!   background = 棋盘木纹底色
--!   world      = 棋盘网格 + 棋子
--!   effects    = 粒子、光效
--!   ui         = 回合指示、按钮
--!   overlay    = 弹窗、debug FPS

local logger = require("core.logger")
local utils = require("core.utils")

local M = {}

-- 层定义（顺序 = 绘制顺序，数字越小越先画/在底层）
M.LAYERS = {
    BACKGROUND = "background",
    WORLD      = "world",
    EFFECTS    = "effects",
    UI         = "ui",
    OVERLAY    = "overlay",
}

local LAYER_ORDER = {
    "background",
    "world",
    "effects",
    "ui",
    "overlay",
}

-- 每层的绘制命令队列
local layers = {}
local camera = { x = 0, y = 0, scale = 1, shake = 0 }
local layer_configs = {
    -- 哪些层受 camera 变换影响
    background = { camera = false },
    world      = { camera = true },
    effects    = { camera = true },
    ui         = { camera = false },
    overlay    = { camera = false },
}

--! 初始化渲染器
function M.init()
    M.clear()
end

--! 清空所有层的绘制命令（每帧开始调用）
function M.clear()
    for _, name in ipairs(LAYER_ORDER) do
        layers[name] = {}
    end
end

-- ===== 绘制命令提交 API =====
-- 这些函数不直接画东西，而是把"画什么"添加到对应层的队列里
-- 在 draw() 时统一执行
--
-- 设计理由：场景的 update/draw 阶段可以提交命令，renderer 自己控制何时画。
-- 这让 camera 变换、层排序、未来的 Canvas 缓存都好处理。

--! 在指定层添加一个矩形
--! @param layer 层名（用 M.LAYERS 常量）
--! @param x, y, w, h 位置尺寸
--! @param color {r, g, b, a}（0-1 范围，可用 utils.color(255,...) 生成）
--! @param mode "fill" 填充 / "line" 描边
function M.rect(layer, x, y, w, h, color, mode)
    M._push(layer, {
        type = "rect",
        x = x, y = y, w = w, h = h,
        color = color or utils.COLORS.WHITE,
        mode = mode or "fill",
    })
end

--! 在指定层添加一个圆
function M.circle(layer, x, y, radius, color, mode, segments)
    M._push(layer, {
        type = "circle",
        x = x, y = y, radius = radius,
        color = color or utils.COLORS.WHITE,
        mode = mode or "fill",
        segments = segments or 32,
    })
end

--! 在指定层添加一条线
function M.line(layer, x1, y1, x2, y2, color, line_width)
    M._push(layer, {
        type = "line",
        x1 = x1, y1 = y1, x2 = x2, y2 = y2,
        color = color or utils.COLORS.WHITE,
        line_width = line_width or 1,
    })
end

--! 在指定层添加文字
function M.text(layer, text, x, y, color, font, align)
    M._push(layer, {
        type = "text",
        text = tostring(text),
        x = x, y = y,
        color = color or utils.COLORS.WHITE,
        font = font,
        align = align or "left",
    })
end

--! 在指定层添加图片
function M.image(layer, img, x, y, r, sx, sy, ox, oy, color)
    M._push(layer, {
        type = "image",
        img = img, x = x, y = y,
        r = r or 0, sx = sx or 1, sy = sy or 1,
        ox = ox or 0, oy = oy or 0,
        color = color,
    })
end

--! 提交任意自定义绘制函数（不推荐滥用，但方便做复杂绘制）
--! 用法: renderer.custom(renderer.LAYERS.UI, function() love.graphics.polygon(...) end)
function M.custom(layer, draw_fn)
    M._push(layer, { type = "custom", fn = draw_fn })
end

-- ===== 内部：压入命令队列 =====
function M._push(layer, cmd)
    if not layers[layer] then
        -- 未知层名，放到 overlay（最前面，容易发现问题）
        logger.warn("renderer", "Unknown layer '%s', drawing to overlay", tostring(layer))
        layer = "overlay"
    end
    table.insert(layers[layer], cmd)
end

-- ===== Camera =====

function M.setCamera(x, y, scale)
    if x then camera.x = x end
    if y then camera.y = y end
    if scale then camera.scale = scale end
end

function M.getCamera()
    return camera.x, camera.y, camera.scale
end

function M.shake(intensity)
    camera.shake = camera.shake + intensity
end

function M.worldToScreen(wx, wy)
    return (wx - camera.x) * camera.scale, (wy - camera.y) * camera.scale
end

function M.screenToWorld(sx, sy)
    return sx / camera.scale + camera.x, sy / camera.scale + camera.y
end

-- ===== 执行绘制 =====
-- 由 engine.draw() 调用
function M.draw()
    for _, layer_name in ipairs(LAYER_ORDER) do
        local cmds = layers[layer_name]
        if not cmds then goto continue end

        -- 应用 camera 变换
        local use_camera = layer_configs[layer_name] and layer_configs[layer_name].camera

        -- 计算震动偏移（仅 world/effects 层）
        local shake_x, shake_y = 0, 0
        if use_camera and camera.shake > 0.1 then
            shake_x = (love.math.random() - 0.5) * camera.shake * 8
            shake_y = (love.math.random() - 0.5) * camera.shake * 8
        end

        love.graphics.push("all")
        -- [V1+] 注：world 层的相机变换由场景在 custom 绘制里自行处理，renderer 不做全局 transform
        -- （保持正交，让场景完全控制 world 层的相机）
        for _, cmd in ipairs(cmds) do
            M._executeCmd(cmd)
        end
        love.graphics.pop()

        ::continue::
    end

    -- 震动衰减
    if camera.shake > 0 then
        camera.shake = camera.shake * 0.85
        if camera.shake < 0.1 then camera.shake = 0 end
    end

    -- 本帧结束，清空命令队列（下一帧从新收集）
    M.clear()
end

-- ===== 内部：执行单条绘制命令 =====
function M._executeCmd(cmd)
    love.graphics.setColor(1, 1, 1, 1)  -- 默认白色

    if cmd.type == "rect" then
        love.graphics.setColor(cmd.color)
        love.graphics.rectangle(cmd.mode, cmd.x, cmd.y, cmd.w, cmd.h)

    elseif cmd.type == "circle" then
        love.graphics.setColor(cmd.color)
        love.graphics.circle(cmd.mode, cmd.x, cmd.y, cmd.radius, cmd.segments)

    elseif cmd.type == "line" then
        love.graphics.setColor(cmd.color)
        love.graphics.setLineWidth(cmd.line_width)
        love.graphics.line(cmd.x1, cmd.y1, cmd.x2, cmd.y2)
        love.graphics.setLineWidth(1)

    elseif cmd.type == "text" then
        love.graphics.setColor(cmd.color)
        if cmd.font then
            love.graphics.setFont(cmd.font)
        end
        love.graphics.printf(cmd.text, cmd.x, cmd.y, 1000, cmd.align)

    elseif cmd.type == "image" then
        if cmd.color then
            love.graphics.setColor(cmd.color)
        end
        love.graphics.draw(cmd.img, cmd.x, cmd.y, cmd.r, cmd.sx, cmd.sy, cmd.ox, cmd.oy)
        love.graphics.setColor(1, 1, 1, 1)

    elseif cmd.type == "custom" then
        cmd.fn()
    end
end

return M
