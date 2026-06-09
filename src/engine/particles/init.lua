--! file: src/engine/particles/init.lua
--! brief: 简单粒子系统
--! 支持一次性 burst（爆发）和持续发射，每帧 update + draw

local M = {}
local systems = {}
local next_id = 1

--! 创建一个粒子系统
--! @param opts { x, y, count, speed, life, size, color, gravity, spread=math.pi*2 }
function M.addBurst(x, y, opts)
    local sys = {
        id = next_id,
        x = x,
        y = y,
        particles = {},
        life = opts.life or 0.5,
        gravity = opts.gravity or 0,
        size = opts.size or 3,
        color = opts.color or {1, 1, 1, 1},
        done = false,
    }
    next_id = next_id + 1

    local count = opts.count or 12
    local speed = opts.speed or 100
    local spread = opts.spread or (math.pi * 2)
    local dir0 = opts.direction or 0
    for i = 1, count do
        local angle
        if spread >= math.pi * 2 then
            angle = love.math.random() * math.pi * 2
        else
            angle = dir0 - spread/2 + love.math.random() * spread
        end
        local s = speed * (0.5 + love.math.random() * 0.8)
        table.insert(sys.particles, {
            x = x, y = y,
            vx = math.cos(angle) * s,
            vy = math.sin(angle) * s - (opts.upVel or 0),
            life = (opts.life or 0.5) * (0.6 + love.math.random() * 0.6),
            max_life = (opts.life or 0.5) * (0.6 + love.math.random() * 0.6),
            size = opts.size * (0.7 + love.math.random() * 0.6),
        })
    end
    table.insert(systems, sys)
    return sys.id
end

--! 更新所有粒子
function M.update(dt)
    for i = #systems, 1, -1 do
        local sys = systems[i]
        local alive_count = 0
        for _, p in ipairs(sys.particles) do
            p.life = p.life - dt
            if p.life > 0 then
                alive_count = alive_count + 1
                p.vy = p.vy + sys.gravity * dt
                p.x = p.x + p.vx * dt
                p.y = p.y + p.vy * dt
            end
        end
        if alive_count == 0 then
            table.remove(systems, i)
        end
    end
end

--! 绘制所有粒子（在当前 love.graphics 变换下绘制，所以放在 world 层的 custom 里）
function M.draw()
    local lg = love.graphics
    for _, sys in ipairs(systems) do
        for _, p in ipairs(sys.particles) do
            if p.life > 0 then
                local a = p.life / p.max_life
                lg.setColor(sys.color[1], sys.color[2], sys.color[3], sys.color[4] * a)
                lg.circle("fill", p.x, p.y, p.size * a, 8)
            end
        end
    end
end

function M.clear()
    systems = {}
end

return M
