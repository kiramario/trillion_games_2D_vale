--! file: src/core/resource.lua
--! brief: 资源管理器（图片、字体、音效、Shader 的加载与缓存）
--! 类比：Unity Resources.Load / Webpack asset pipeline
--!
--! 为什么不直接在业务代码里写 love.graphics.newImage？
--! 1. 自动缓存：同一张图加载第二次直接取缓存，不重复读磁盘/解码
--! 2. 统一路径前缀：业务代码传 "board.png"，内部自动拼 "assets/images/board.png"
--! 3. 方便后续做异步加载、加载进度条、热更新

local logger = require("core.logger")
local utils = require("core.utils")

local M = {}

-- ===== 缓存表 =====
local image_cache = {}
local font_cache = {}
local sound_cache = {}
local source_cache = {}
local shader_cache = {}

-- ===== 路径前缀配置 =====
local PATHS = {
    image  = "assets/images/",
    font   = "assets/fonts/",
    sound  = "assets/sounds/",
    shader = "assets/shaders/",
}

--! 预加载一批资源，通常在 boot scene 中调用
--! @param list 资源描述数组，每项 { type = "image", name = "board", path = "board.png" }
function M.preload(list, progress_callback)
    local total = #list
    local loaded = 0
    for _, item in ipairs(list) do
        if item.type == "image" then
            M.getImage(item.path)
        elseif item.type == "font" then
            M.getFont(item.path, item.size or 16)
        elseif item.type == "sound" then
            M.getSound(item.path, item.stream)
        elseif item.type == "shader" then
            M.getShader(item.path)
        end
        loaded = loaded + 1
        if progress_callback then
            progress_callback(loaded, total, item)
        end
    end
    logger.info("resource", "Preloaded %d resources", total)
end

-- ===== 图片 =====

--! 加载/获取图片
--! @param filename 相对 assets/images/ 的路径，也可以传完整路径（以 / 开头）
--! @return LÖVE Image 对象 (love.graphics.Image)
function M.getImage(filename)
    if image_cache[filename] then
        return image_cache[filename]
    end

    local fullpath = filename
    if not filename:match("^/") then
        fullpath = PATHS.image .. filename
    end

    -- [LOVE] love.graphics.newImage 支持 PNG/JPG/BMP/TGA
    -- 如果文件不存在，LÖVE2D 不会抛出 Lua error，而是输出一条错误并返回 nil
    -- 我们用 pcall 捕获以优雅降级
    local ok, image = pcall(love.graphics.newImage, fullpath)
    if not ok or not image then
        logger.warn("resource", "Failed to load image: %s (%s)", filename, tostring(image))
        -- 返回一个占位 1x1 白色纹理
        image = M._getPlaceholderImage()
    end

    -- [LOVE] setFilter 设置缩放时的插值方式
    -- "nearest" = 最近邻（像素风清晰），"linear" = 双线性（模糊但平滑）
    -- 棋盘棋子用 linear，像素游戏用 nearest
    image:setFilter("linear", "linear")
    image_cache[filename] = image

    logger.debug("resource", "Loaded image: %s", filename)
    return image
end

-- ===== 字体 =====

--! 加载/获取字体
--! @param filename 字体文件名（相对于 assets/fonts/），nil 使用内置默认字体
--! @param size 字号（像素），默认 16
function M.getFont(filename, size)
    size = size or 16
    local cache_key = (filename or "_default") .. "_" .. tostring(size)

    if font_cache[cache_key] then
        return font_cache[cache_key]
    end

    local font
    if not filename then
        -- [LOVE] love.graphics.newFont(size) 创建默认字体（Bitstream Vera Sans）
        -- 这个字体不支持中文！V1 会加载中文字体，V0 先用默认
        font = love.graphics.newFont(size)
    else
        local fullpath = filename
        if not filename:match("^/") then
            fullpath = PATHS.font .. filename
        end
        local ok, result = pcall(love.graphics.newFont, fullpath, size)
        if ok and result then
            font = result
        else
            logger.warn("resource", "Failed to load font: %s (%s), fallback to default", filename, tostring(result))
            font = love.graphics.newFont(size)
        end
    end

    font_cache[cache_key] = font
    logger.debug("resource", "Loaded font: %s size=%d", filename or "(default)", size)
    return font
end

-- ===== 音效/音乐 =====

--! 加载音效
--! @param filename 文件名（相对 assets/sounds/）
--! @param stream true = 流式加载（大文件如 BGM 用），false = 静态加载（短音效，默认 false）
function M.getSound(filename, stream)
    local cache_key = filename .. (stream and "_stream" or "_static")
    if sound_cache[cache_key] then
        return sound_cache[cache_key]
    end

    local fullpath = PATHS.sound .. filename
    local mode = stream and "stream" or "static"

    -- [LOVE] love.audio.newSource 创建音频源
    -- "static" = 全部解码到内存（适合短音效）
    -- "stream" = 流式解码（适合 BGM）
    local ok, source = pcall(love.audio.newSource, fullpath, mode)
    if not ok or not source then
        logger.warn("resource", "Failed to load sound: %s (%s)", filename, tostring(source))
        return nil
    end

    sound_cache[cache_key] = source
    logger.debug("resource", "Loaded sound: %s (%s)", filename, mode)
    return source
end

-- ===== Shader =====

function M.getShader(filename)
    if shader_cache[filename] then
        return shader_cache[filename]
    end

    local fullpath = PATHS.shader .. filename
    local ok, shader = pcall(love.graphics.newShader, fullpath)
    if not ok or not shader then
        logger.warn("resource", "Failed to load shader: %s (%s)", filename, tostring(shader))
        return nil
    end

    shader_cache[filename] = shader
    logger.debug("resource", "Loaded shader: %s", filename)
    return shader
end

-- ===== 缓存管理 =====

function M.clearCache()
    image_cache = {}
    font_cache = {}
    sound_cache = {}
    source_cache = {}
    shader_cache = {}
    collectgarbage("collect")
    logger.info("resource", "All caches cleared")
end

--! 获取缓存统计
function M.getStats()
    return {
        images  = utils._countKeys(image_cache),
        fonts   = utils._countKeys and utils._countKeys(font_cache) or M._countKeys(font_cache),
        sounds  = M._countKeys(sound_cache),
        shaders = M._countKeys(shader_cache),
    }
end

function M._countKeys(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

-- ===== 内部：占位图（资源加载失败时的降级）=====

local placeholder = nil
function M._getPlaceholderImage()
    if placeholder then return placeholder end
    -- [LOVE] 创建 1x1 像素的 Canvas 作为占位符
    local canvas = love.graphics.newCanvas(1, 1)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 0, 1, 1)  -- 洋红色（醒目，方便发现没加载成功的图）
    love.graphics.setCanvas()
    placeholder = canvas
    return placeholder
end

return M
