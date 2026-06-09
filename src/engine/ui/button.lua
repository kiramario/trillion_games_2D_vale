--! file: src/engine/ui/button.lua
--! brief: 简单 UI 按钮组件
--! 提供文本按钮：检测 hover、click、绘制样式

local M = {}
local buttons = {}
local next_id = 1

--! 创建一个按钮
--! @param opts {x,y,w,h,label,on_click,font,color,hover_color}
--! @return 按钮 id（用于 update/draw/isHit）
function M.add(opts)
    local b = {
        id = next_id,
        x = opts.x, y = opts.y, w = opts.w, h = opts.h,
        label = opts.label or "Button",
        on_click = opts.on_click or function() end,
        font = opts.font,
        color = opts.color or {0.3, 0.3, 0.4, 0.9},
        hover_color = opts.hover_color or {0.5, 0.4, 0.6, 1.0},
        text_color = opts.text_color or {1,1,1,1},
        visible = true,
        hovered = false,
        click_anim = 0,
    }
    next_id = next_id + 1
    table.insert(buttons, b)
    return b.id
end

function M.clear() buttons = {}; next_id = 1 end

function M.remove(id)
    for i, b in ipairs(buttons) do
        if b.id == id then table.remove(buttons, i); return end
    end
end

function M.setLabel(id, label)
    for _, b in ipairs(buttons) do
        if b.id == id then b.label = label; return end
    end
end

function M.setVisible(id, v)
    for _, b in ipairs(buttons) do
        if b.id == id then b.visible = v; return end
    end
end

function M.update(dt, mx, my, mdown)
    for _, b in ipairs(buttons) do
        if b.visible then
            b.hovered = mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
            if b.click_anim > 0 then b.click_anim = b.click_anim - dt end
            if b.hovered and mdown then
                b.click_anim = 0.1
                b.on_click()
            end
        end
    end
end

function M.draw(lg)
    for _, b in ipairs(buttons) do
        if b.visible then
            local col = b.hovered and b.hover_color or b.color
            local yoff = b.click_anim > 0 and 2 or 0
            -- 阴影
            lg.setColor(0,0,0,0.4)
            lg.rectangle("fill", b.x+3, b.y+3+yoff, b.w, b.h, 6, 6)
            -- 主体
            lg.setColor(col)
            lg.rectangle("fill", b.x, b.y+yoff, b.w, b.h, 6, 6)
            -- 边框
            lg.setColor(1,1,1,0.2)
            lg.setLineWidth(1.5)
            lg.rectangle("line", b.x, b.y+yoff, b.w, b.h, 6, 6)
            lg.setLineWidth(1)
            -- 文字
            if b.font then lg.setFont(b.font) end
            lg.setColor(b.text_color)
            local f = lg.getFont()
            local tw = f:getWidth(b.label)
            local th = f:getHeight()
            lg.print(b.label, b.x + (b.w - tw)/2, b.y + yoff + (b.h - th)/2 - 2)
        end
    end
end

return M
