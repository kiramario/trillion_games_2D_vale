--! file: tools/gen_icon/main.lua
--! brief: 程序化生成游戏图标（写到 LOVE save dir，由 Makefile 拷贝到 assets/images/）

local OUT = "icon_out"

function love.load()
    love.filesystem.createDirectory(OUT)
    local SIZE = 512
    local canvas = love.graphics.newCanvas(SIZE, SIZE)
    love.graphics.setCanvas(canvas)

    -- 清透明
    love.graphics.clear(0,0,0,0)

    local cx, cy, R = SIZE/2, SIZE/2 + 10, 180

    -- 外层金环（装饰）
    love.graphics.setColor(0.95, 0.8, 0.3, 1)
    love.graphics.setLineWidth(16)
    love.graphics.circle("line", cx, cy, R+20, 80)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", cx, cy, R+36, 80)
    love.graphics.setLineWidth(1)

    -- 阴影
    love.graphics.setColor(0,0,0,0.55)
    love.graphics.ellipse("fill", cx, cy + R*0.9, R*0.92, R*0.3, 48)

    -- 底座（深色侧面）
    love.graphics.setColor(0.55, 0.42, 0.25, 1)
    love.graphics.circle("fill", cx, cy + 8, R+6, 64)

    -- 棋子主体（米黄/象牙色）
    love.graphics.setColor(0.96, 0.9, 0.76, 1)
    love.graphics.circle("fill", cx, cy, R, 80)

    -- 高光
    love.graphics.setColor(1, 0.98, 0.92, 0.3)
    love.graphics.ellipse("fill", cx, cy - R*0.32, R*0.7, R*0.5, 48)

    -- 内外双圈（红色）
    love.graphics.setColor(0.8, 0.12, 0.08, 1)
    love.graphics.setLineWidth(10)
    love.graphics.circle("line", cx, cy, R-8, 80)
    love.graphics.setLineWidth(5)
    love.graphics.circle("line", cx, cy, R-32, 80)
    love.graphics.setLineWidth(1)

    -- 中央"楚河汉界"风格符号：用几何绘制一个简化"帅"的方块徽记
    -- 红底方形
    local sq = 80
    love.graphics.setColor(0.8, 0.12, 0.08, 1)
    love.graphics.rectangle("fill", cx-sq/2, cy-sq/2+4, sq, sq, 10, 10)
    -- 金色"将"字方块边框
    love.graphics.setColor(0.95, 0.8, 0.3, 1)
    love.graphics.setLineWidth(6)
    love.graphics.rectangle("line", cx-sq/2+8, cy-sq/2+12, sq-16, sq-16, 4, 4)
    love.graphics.setLineWidth(1)
    -- 方块中心金色装饰十字（模拟汉字笔画感）
    love.graphics.setColor(0.95, 0.8, 0.3, 1)
    love.graphics.setLineWidth(8)
    love.graphics.line(cx, cy-sq/2+14, cx, cy+sq/2-6)
    love.graphics.line(cx-sq/2+16, cy, cx+sq/2-16, cy)
    love.graphics.setLineWidth(1)

    -- 角落星芒（四个方向）
    love.graphics.setColor(0.95, 0.8, 0.3, 0.6)
    for i = 0, 7 do
        local a = i * math.pi/4 + math.pi/8
        local r1, r2 = R + 40, R + 55
        love.graphics.line(
            cx + math.cos(a)*r1, cy + math.sin(a)*r1,
            cx + math.cos(a)*r2, cy + math.sin(a)*r2)
    end

    love.graphics.setCanvas()

    -- 保存 512
    local d = canvas:newImageData()
    d:encode("png", OUT .. "/icon.png")
    print("Wrote icon.png")

    -- 多尺寸
    for _, sz in ipairs({256, 128, 64, 32, 16}) do
        local c = love.graphics.newCanvas(sz, sz)
        love.graphics.setCanvas(c)
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setBlendMode("alpha")
        love.graphics.draw(canvas, 0, 0, 0, sz/SIZE, sz/SIZE)
        love.graphics.setCanvas()
        local dd = c:newImageData()
        dd:encode("png", OUT .. "/icon_" .. sz .. ".png")
        print("  icon_" .. sz .. ".png")
    end

    love.event.quit()
end
