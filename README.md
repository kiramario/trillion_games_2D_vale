# Trillion Games 2D - Vale

> A reusable 2D game framework, first shipped as Chinese Chess.

## 项目愿景 (Vision)

打造一个**可复用的 LÖVE2D 2D 游戏引擎脚手架**，第一作是中国象棋（优先 Steam，后覆盖桌面与 APK），后续复用同一套 Core + Engine 层开发弹珠等其他 2D 游戏。

### 核心原则

1. **架构先行但不锁死**：Core 层与具体游戏完全解耦；Engine 层提供可组合的通用游戏系统；Game 层只写当前游戏的业务逻辑。换一个新项目只需替换 game/ 目录。
2. **视觉 2.1D（伪纵深）**：通过分层渲染、斜视角偏移、阴影、光影、粒子、缓动动画和镜头微震来获得"有一点透视"的观感，绝不引入真 3D 相机。
3. **独立开发者节奏**：一个人写、一个人测、一个人发版。每个版本打 tag，随时可回滚。
4. **代码可教学**：Lua 和 LÖVE2D API 处都有注释，用 JS/Java/Python 视角做类比。不炫技。
5. **跨平台一次写**：业务代码零平台判断；平台差异通过 conf.lua 和构建脚本处理。

### 第一个成品目标

一款可在 Steam / Windows / macOS / Linux / Android 上运行的中国象棋，含：
- 完整象棋规则（含将军/将死/和棋/困毙判定）
- 可调难度 AI（Minimax + Alpha-Beta 剪枝）
- 本地双人对弈
- 残局/棋谱保存
- 视觉有质感（木纹棋盘、玉石棋子、落子动效）

### 复用目标

V5 之后，新项目只需：
```
cp -r src/core src/engine new_game/
# 新建 src/game/ ，写场景和实体即可
```
