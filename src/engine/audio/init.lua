--! file: src/engine/audio/init.lua
--! brief: 音频管理（BGM + SFX）
--! V2 音效用程序化生成（不依赖外部音频文件），V4 再加 BGM
--!
--! [LOVE] love.sound.newSoundData 创建原始 PCM 数据
--! love.audio.newSource(data, "static") 创建可播放源

local logger = require("core.logger")
local config = require("core.config")

local M = {}

local sfx_sources = {}  -- 缓存合成好的音效
local bgm_source = nil
local sfx_volume = 1.0
local bgm_volume = 0.7
local muted = false

function M.init()
    sfx_volume = config.get("audio.sfx_volume", 0.9)
    bgm_volume = config.get("audio.bgm_volume", 0.7)
    muted = config.get("audio.muted", false)
    M._generateSfx()
    logger.info("audio", "Audio initialized")
end

-- 程序化合成短音效（避免引入外部资源依赖）
-- 使用简单的正弦波/方波 + 衰减包络
function M._generateSfx()
    local sample_rate = 44100
    local bit_depth = 16
    local channels = 1

    local function makeTone(freq, duration, wave_type, attack, decay, volume)
        attack = attack or 0.005
        decay = decay or duration
        volume = volume or 0.3
        local samples = math.floor(sample_rate * duration)
        local sd = love.sound.newSoundData(samples, sample_rate, bit_depth, channels)
        for i = 0, samples - 1 do
            local t = i / sample_rate
            local env
            if t < attack then
                env = t / attack
            elseif t < decay then
                env = 1 - (t - attack) / (decay - attack)
            else
                env = 0
            end
            local sample
            if wave_type == "square" then
                sample = math.sin(2 * math.pi * freq * t) > 0 and 1 or -1
            elseif wave_type == "noise" then
                sample = love.math.random() * 2 - 1
            else
                sample = math.sin(2 * math.pi * freq * t)
            end
            sd:setSample(i, sample * env * volume)
        end
        return love.audio.newSource(sd, "static")
    end

    -- 落子声：短促低频"哒"（180Hz 方波快速衰减）
    sfx_sources.move = makeTone(180, 0.08, "square", 0.002, 0.06, 0.4)
    -- 吃子声：更高更脆"咔"（400Hz 正弦）
    sfx_sources.capture = makeTone(520, 0.15, "square", 0.001, 0.1, 0.5)
    -- 选中：两个短音组成
    sfx_sources.select = makeTone(800, 0.06, "sine", 0.002, 0.05, 0.2)
    -- 非法移动：低音 buzz
    sfx_sources.invalid = makeTone(120, 0.12, "square", 0.001, 0.1, 0.3)
    -- 将军：高音警报
    sfx_sources.check = makeTone(900, 0.2, "sine", 0.005, 0.15, 0.3)

    logger.debug("audio", "Generated %d SFX sources", 5)
end

--! 播放音效
function M.playSfx(name)
    if muted then return end
    local src = sfx_sources[name]
    if not src then return end
    -- clone 以便可以重叠播放（同一个 Source 对象不能同时播两次）
    local clone = src:clone()
    clone:setVolume(sfx_volume)
    clone:play()
end

--! 播放 BGM（V4 实现，V2 留空）
function M.playBgm(name)
    -- V4: 加载并循环播放背景音乐
end

function M.setSfxVolume(v)
    sfx_volume = v
    config.set("audio.sfx_volume", v)
end

function M.setBgmVolume(v)
    bgm_volume = v
    if bgm_source then bgm_source:setVolume(v) end
    config.set("audio.bgm_volume", v)
end

function M.setMuted(m)
    muted = m
    if bgm_source then
        if m then bgm_source:pause() else bgm_source:play() end
    end
    config.set("audio.muted", m)
end

return M
