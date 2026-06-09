# CHANGELOG

## v0.0.0 — "Hello Engine" (2026-06-09)

### Added
- 项目初始化，LÖVE2D 11.3 环境
- Core 层全部 9 个基础模块：
  - engine.lua — 游戏循环调度器
  - config.lua — 配置管理（默认值 + 用户持久化）
  - logger.lua — 四级日志（DEBUG/INFO/WARN/ERROR）
  - event.lua — 发布/订阅事件总线
  - input.lua — 键盘/鼠标输入抽象（含 action 映射）
  - resource.lua — 图片/字体/音效/Shader 加载与缓存
  - renderer.lua — 五层分层渲染（background/world/effects/ui/overlay）
  - scene_manager.lua — 场景切换与淡入淡出
  - timer.lua — 延时/重复计时 + Tween 补间动画（8 种 easing）
  - utils.lua — 工具函数集（深拷贝、颜色转换、数学工具等）
- 两个测试场景：
  - BootScene — 启动画面，1 秒后自动切换
  - DemoScene — 彩色方块演示，支持按键切换颜色、鼠标涟漪、动画
- 完整文档体系（docs/01~07）
- .gitignore、conf.lua、main.lua 入口

### How to run
```bash
cd /home/love2DGame_vale
love .
```
