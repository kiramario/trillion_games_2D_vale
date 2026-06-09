--! file: src/game/constants.lua
--! brief: 中国象棋常量定义
--! 所有"魔法数字"集中在这里，方便调参

local M = {}

-- ===== 棋盘尺寸 =====
M.FILES = 9      -- 列数（0-8）
M.RANKS = 10     -- 行数（0-9）

-- 渲染参数（像素）
M.CELL = 64      -- 格子边长
M.MARGIN = 44    -- 棋盘边距（从棋盘最外一条线到板子边缘）

-- 斜视角：Y 方向压缩比例（<1 产生俯瞰纵深感）
M.TILT_Y = 0.88

-- ===== 棋子参数 =====
M.PIECE_RADIUS = 28      -- 棋子半径
M.PIECE_RING = 2.5       -- 棋子外圈线宽
M.PIECE_INNER_MARGIN = 4 -- 内圈和外圈间距
M.PIECE_SHADOW_OFFSET_Y = 6
M.PIECE_SHADOW_SCALE_X = 1.2
M.PIECE_SHADOW_ALPHA = 0.25

-- ===== 颜色（木纹/玉石风格）=====
-- 棋盘木色（暖棕）
M.COLOR_BOARD_BASE   = {218, 175, 108}   -- 主木色
M.COLOR_BOARD_DARK   = {188, 140, 80}    -- 深色（木纹/阴影）
M.COLOR_BOARD_EDGE   = {120, 75, 35}     -- 侧边厚度（深棕）
M.COLOR_BOARD_HILITE = {240, 205, 140}   -- 高光

-- 线条
M.COLOR_LINE         = {50, 30, 15}      -- 棋盘线（深棕黑）

-- 红方棋子
M.COLOR_RED_PIECE    = {225, 185, 125}   -- 红方棋子底色（米黄/象牙）
M.COLOR_RED_TEXT     = {195, 50, 40}     -- 红方文字（中国红）
M.COLOR_RED_RING     = {195, 50, 40}

-- 黑方棋子
M.COLOR_BLACK_PIECE  = {225, 185, 125}
M.COLOR_BLACK_TEXT   = {30, 25, 20}      -- 黑方文字（深墨）
M.COLOR_BLACK_RING   = {30, 25, 20}

-- 河界
M.COLOR_RIVER_TEXT   = {100, 60, 25}

-- ===== 棋子类型 =====
M.PIECE_TYPES = {
    JIANG = "jiang",    -- 将/帅
    SHI   = "shi",      -- 士/仕
    XIANG = "xiang",    -- 象/相
    MA    = "ma",       -- 马
    JU    = "ju",       -- 车
    PAO   = "pao",      -- 炮
    BING  = "bing",     -- 兵/卒
}

-- 棋子中文显示
M.PIECE_CHARS = {
    red = {
        jiang = "帅", shi = "仕", xiang = "相", ma = "马",
        ju = "车", pao = "炮", bing = "兵",
    },
    black = {
        jiang = "将", shi = "士", xiang = "象", ma = "馬",
        ju = "車", pao = "砲", bing = "卒",
    }
}

-- 初始布局：{file, rank, color, type}
-- 红方在下方（rank 6-9），黑方在上方（rank 0-3）
M.INITIAL_SETUP = {
    -- 黑方底线（rank 0）
    {0, 0, "black", "ju"},    {8, 0, "black", "ju"},
    {1, 0, "black", "ma"},    {7, 0, "black", "ma"},
    {2, 0, "black", "xiang"}, {6, 0, "black", "xiang"},
    {3, 0, "black", "shi"},   {5, 0, "black", "shi"},
    {4, 0, "black", "jiang"},
    -- 黑炮（rank 2）
    {1, 2, "black", "pao"},   {7, 2, "black", "pao"},
    -- 黑卒（rank 3）
    {0, 3, "black", "bing"},  {2, 3, "black", "bing"},
    {4, 3, "black", "bing"},  {6, 3, "black", "bing"},
    {8, 3, "black", "bing"},

    -- 红方底线（rank 9）
    {0, 9, "red", "ju"},      {8, 9, "red", "ju"},
    {1, 9, "red", "ma"},      {7, 9, "red", "ma"},
    {2, 9, "red", "xiang"},   {6, 9, "red", "xiang"},
    {3, 9, "red", "shi"},     {5, 9, "red", "shi"},
    {4, 9, "red", "jiang"},
    -- 红炮（rank 7）
    {1, 7, "red", "pao"},     {7, 7, "red", "pao"},
    -- 红兵（rank 6）
    {0, 6, "red", "bing"},    {2, 6, "red", "bing"},
    {4, 6, "red", "bing"},    {6, 6, "red", "bing"},
    {8, 6, "red", "bing"},
}

return M
