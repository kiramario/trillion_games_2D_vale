--! file: main.lua
--! brief: LÖVE2D 入口文件 —— 整个游戏的起点
--!
--! [LOVE] LÖVE2D 约定了几个回调函数：
--!   love.load()   — 启动时执行一次（类似 JS DOMContentLoaded / Python if __name__ == "__main__"）
--!   love.update(dt) — 每帧执行，dt 是上一帧到现在的秒数（类似 requestAnimationFrame 的 delta time）
--!   love.draw()   — 每帧渲染
--!   love.quit()   — 退出前执行
--!   love.keypressed(key) — 键盘按下时触发
--!   love.mousepressed(x,y,button) — 鼠标点击
--! 我们不把逻辑直接写在这些函数里，而是全部委托给 core.engine

-- [Lua] 把 src/ 目录加到 Lua 的模块搜索路径里
-- 类比：相当于 JS 里配置 import 的 baseUrl，或者 Python 里 sys.path.append
-- package.path 是 Lua 的 require 搜索路径列表，用分号分隔
-- 问号 ? 是占位符，require("core.engine") 会去尝试 src/core/engine.lua
package.path = "src/?.lua;src/?/init.lua;" .. package.path

-- [LOVE] 启动后第一时间设置随机种子
-- 不设置的话，每次启动 love.math.random() 序列是一样的（调试方便，但发布前要改掉）
love.math.setRandomSeed(os.time())

-- 导入核心引擎
local engine = require("core.engine")

-- 启动时由 LÖVE2D 调用一次
function love.load()
    -- [LOVE] 重置图形状态（防止 hot-reload 时状态脏）
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setBackgroundColor(0.08, 0.08, 0.1, 1)  -- 深灰蓝背景

    engine.init({
        title   = "Trillion Games 2D - Vale",
        width   = love.graphics.getWidth(),
        height  = love.graphics.getHeight(),
        debug   = true
    })
end

-- 每帧更新，dt (delta time) 单位秒，60fps 时约为 0.016
function love.update(dt)
    -- [LOVE] timer.step() 提供稳定的时间步长信息
    engine.update(dt)
end

-- 每帧绘制
function love.draw()
    engine.draw()
end

-- 键盘按下
function love.keypressed(key, scancode, isrepeat)
    engine.getInput().keypressed(key, scancode, isrepeat)
end

-- 键盘松开
function love.keyreleased(key, scancode)
    engine.getInput().keyreleased(key, scancode)
end

-- 鼠标按下
function love.mousepressed(x, y, button, istouch, presses)
    engine.getInput().mousepressed(x, y, button, istouch, presses)
end

-- 鼠标松开
function love.mousereleased(x, y, button, istouch, presses)
    engine.getInput().mousereleased(x, y, button, istouch, presses)
end

-- 鼠标移动
function love.mousemoved(x, y, dx, dy, istouch)
    engine.getInput().mousemoved(x, y, dx, dy, istouch)
end

-- 窗口大小变化
function love.resize(w, h)
    engine.resize(w, h)
end

-- 文本输入（后续做输入框用）
function love.textinput(text)
    engine.getInput().textinput(text)
end

-- 退出时清理
function love.quit()
    engine.shutdown()
end
