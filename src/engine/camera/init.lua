--! file: src/engine/camera/init.lua
--! brief: 相机系统（世界坐标 ↔ 屏幕坐标变换 + 震动）
--! 类比：Unity Camera / Godot Camera2D
--!
--! 相机决定 world 层如何投影到屏幕。V1 用它让棋盘居中显示。
--! V2+ 用震动做吃子反馈。V5 用缩放做窗口自适应。

local math_abs = math.abs

local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    self.x = 0
    self.y = 0
    self.target_x = 0
    self.target_y = 0
    self.scale = 1
    self.target_scale = 1
    self.shake = 0
    self.shake_x = 0
    self.shake_y = 0
    self.smoothing = 5   -- 跟随平滑度（越大越快，0=瞬移）
    return self
end

--! 设置相机目标位置（世界坐标系下，相机会看向的中心点）
function M:lookAt(x, y)
    self.target_x = x
    self.target_y = y
end

--! 立即跳到目标位置（不用平滑）
function M:jumpTo(x, y)
    self.x = x
    self.y = y
    self.target_x = x
    self.target_y = y
end

--! 设置缩放
function M:zoomTo(s)
    self.target_scale = s
end

function M:setZoom(s)
    self.scale = s
    self.target_scale = s
end

--! 添加屏幕震动（强度单位像素，比如 8）
function M:addShake(intensity)
    self.shake = self.shake + intensity
end

--! 每帧更新
function M:update(dt)
    -- 平滑跟随（指数衰减）
    local t = math.min(1, self.smoothing * dt)
    self.x = self.x + (self.target_x - self.x) * t
    self.y = self.y + (self.target_y - self.y) * t
    self.scale = self.scale + (self.target_scale - self.scale) * t

    -- 震动：当前帧随机偏移，震动量衰减
    if self.shake > 0.2 then
        self.shake_x = (love.math.random() - 0.5) * self.shake * 2
        self.shake_y = (love.math.random() - 0.5) * self.shake * 2
        self.shake = self.shake * 0.85
    else
        self.shake = 0
        self.shake_x = 0
        self.shake_y = 0
    end
end

--! 将相机变换应用到当前 love.graphics（world 层绘制前调用）
function M:attach(screen_w, screen_h)
    love.graphics.push()
    -- 先把原点移到屏幕中心，然后缩放、平移到相机位置
    love.graphics.translate(screen_w/2 + self.shake_x, screen_h/2 + self.shake_y)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

--! 取消变换（world 层绘制后调用）
function M:detach()
    love.graphics.pop()
end

--! 屏幕坐标 → 世界坐标
function M:screenToWorld(sx, sy, screen_w, screen_h)
    local wx = (sx - screen_w/2 - self.shake_x) / self.scale + self.x
    local wy = (sy - screen_h/2 - self.shake_y) / self.scale + self.y
    return wx, wy
end

--! 世界坐标 → 屏幕坐标
function M:worldToScreen(wx, wy, screen_w, screen_h)
    local sx = (wx - self.x) * self.scale + screen_w/2 + self.shake_x
    local sy = (wy - self.y) * self.scale + screen_h/2 + self.shake_y
    return sx, sy
end

return M
