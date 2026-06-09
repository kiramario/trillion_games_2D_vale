--! file: tools/gen_icon/conf.lua
function love.conf(t)
    t.window.width = 600
    t.window.height = 600
    t.window.title = "Icon Generator"
    t.window.hidden = true  -- 不显示窗口
    t.modules.audio = false
    t.modules.sound = false
    t.modules.physics = false
    t.modules.joystick = false
end
