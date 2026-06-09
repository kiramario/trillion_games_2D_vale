# SETUP —— 部署、执行、注意事项

项目：Trillion Games 2D — Vale（中国象棋 / Chinese Chess）
版本：v5.0.0（V0→V5 全部完成）
LÖVE2D 目标版本：11.3 / 11.5
远程仓库：git@github.com:kiramario/trillion_games_2D_vale.git

---

## 一、环境要求

### 运行环境（只玩）
- 操作系统：Windows 10+ / macOS 10.13+ / Ubuntu 18.04+ / Steam Deck（任何能跑 LÖVE2D 的系统）
- 内存：256 MB RAM 以上（本游戏实际占用 < 80 MB）
- 硬盘：解压后 ~55 MB（含中文字体 38MB）
- GPU：任何集成显卡都可以（纯 2D，无 shader 依赖）

### 开发环境（改代码）
- LÖVE2D 11.3 或 11.5（API 完全兼容）
- Git
- 文本编辑器（VS Code 推荐装 Lua/LÖVE2D 插件）
- Python / make（可选，打包脚本用）

---

## 二、本地部署（开发者模式）

### 2.1 安装 LÖVE2D

**Ubuntu/Debian：**
```bash
sudo add-apt-repository ppa:bartbes/love-stable
sudo apt update
sudo apt install love
love --version    # 应输出 11.x
```

**macOS：**
```bash
brew install --cask love
```

**Windows：**
去 https://love2d.org/ 下载 64-bit installer，安装后 love.exe 会自动关联 .love 文件。

**Linux 上跑 AppImage：**
```bash
wget https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage
chmod +x love-11.5-x86_64.AppImage
sudo mv love-11.5-x86_64.AppImage /usr/local/bin/love
```

### 2.2 拉取代码
```bash
cd ~
git clone git@github.com:kiramario/trillion_games_2D_vale.git love2DGame_vale
cd love2DGame_vale
```

### 2.3 切换到你要测试的版本
```bash
git tag              # 查看所有版本
git checkout v0.0.0  # V0 Hello Engine（引擎脚手架）
git checkout v1.0.0  # V1 棋盘初现（静态 32 棋子）
git checkout v2.0.0  # V2 落子有声（可点击走棋+音效）
git checkout v3.0.0  # V3 棋逢对手（将军/AI/悔棋）
git checkout v4.0.0  # V4 锦上添花（主菜单）
git checkout v5.0.0  # V5 整装待发（打包就绪，默认 main）
```

### 2.4 运行
```bash
love .
```
或使用 Makefile：
```bash
make run
```

---

## 三、预期启动效果（V5）

1. 双击/命令启动后，先黑屏闪出 Boot 场景（约 1 秒）
2. 进入主菜单：
   - 深木色背景 + 金色飘浮粒子
   - 标题"中国象棋 / Chinese Chess"
   - 三个按钮：
     - 红 "开始对战" → 人机对战（你执红，黑方 AI）
     - 蓝 "双人对战" → 两人同屏对下
     - 灰 "退出游戏" → 退出
3. 点击"开始对战"进入棋盘：
   - 居中木纹棋盘，带斜视角伪纵深
   - 32 枚棋子（红/黑方，中文字）
   - 顶部显示回合指示（红方/黑方）
   - 底部显示操作提示
4. 窗口左上角显示 "Trillion Games 2D - Vale" + 象棋图标
5. 左下角 FPS 数字（debug 模式，发布可关）

---

## 四、操作说明

### 菜单界面
| 按键 / 鼠标 | 作用 |
|---|---|
| 鼠标左键 | 点击按钮 |
| Enter / Space | 快速开始 AI 对战 |
| ESC | 退出游戏 |

### 棋盘界面
| 按键 / 鼠标 | 作用 |
|---|---|
| 鼠标左键 | 选子 / 落子 / 吃子 |
| R | 重新开局 |
| U | 悔棋（AI 模式下连悔两步，把 AI 的一步也撤掉） |
| A | 切换 AI 模式 / 双人模式 |
| ESC | 返回主菜单 |
| F11 | 全屏 / 窗口切换 |
| F12 | 截图（存到 love 截图目录） |
| Ctrl+Q | 退出游戏 |

### 走棋视觉反馈
- 选中棋子 → 黄色圆圈高亮 + "嗒" 一声
- 可走空格 → 绿色小点
- 可吃子 → 红色圆圈（该格子有对方棋子）
- 移动 → ease-out 动画 + 落子"哒"声
- 吃子 → 粒子爆炸（对方棋子颜色）+ "咔"脆响 + 镜头轻震
- 非法走法 → 闷响 + 镜头抖动
- 将军 → 红王周围红色脉冲圈 + 红色屏幕闪烁 + 警报声
- 将死 → 金色粒子烟花 + 全屏半透明覆盖 + 胜负提示
- 上一步 → 黄色连线 + 目标黄圈

### AI 说明
V3-V5 AI 是 1 层贪心搜索（greedy 1-ply），强度大约"刚会规则的新手"水平：
- 子力价值：车 900 / 炮 450 / 马 400 / 士象 200 / 兵 100 / 帅 100000
- 过河兵 +60，中线棋子 +15~25
- 将军 +30，将死 +100000
- 有随机扰动，不会每次都走一样的
- 思考延时固定 0.4 秒（像在思考一样）
- V6+ 可升级为 alpha-beta 搜索加深

---

## 五、打包分发

所有打包命令在项目根目录执行。

### 5.1 打 .love 文件（跨平台通用格式）
```bash
make love
# 产出 build/trillion_games_vale-5.0.0.love (约 31MB)
# 测试：love build/trillion_games_vale-5.0.0.love
```

### 5.2 Linux AppImage
```bash
# 1. 下载官方 love AppImage
wget https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage -O tools/pack/love.AppImage
# 2. 合并（见 Makefile 注释）
cat tools/pack/love.AppImage build/trillion_games_vale-5.0.0.love > dist/trillion_games_vale-5.0.0.AppImage
chmod +x dist/trillion_games_vale-5.0.0.AppImage
# 3. 直接运行
./dist/trillion_games_vale-5.0.0.AppImage
```

### 5.3 Windows exe
在 Windows 机器上（或用 Wine）：
1. 下载 love-11.5-win64.zip 解压到 tools/pack/win64/
2. 合并：
```
copy /b love.exe+trillion_games_vale-5.0.0.love trillion_games_vale.exe
```
3. 把 exe 和所有 DLL（SDL2.dll, OpenAL32.dll, love.dll 等）一起打包成 zip

### 5.4 macOS app
必须在 Mac 上做：
1. 安装 love.app
2. 复制为 TrillionGames.app
3. 把 .love 丢进 TrillionGames.app/Contents/Resources/
4. 用 iconutil + assets/images/icon*.png 转 .icns
5. 修改 Info.plist

### 5.5 Android APK
最简单：访问 https://simple.love2d.org/ 上传 .love → 直接下载 APK。
源码构建：见 PUBLISHING.md 第四节。

### 5.6 Steam
Steam 相关路径、Steamworks SDK 接入、成就/云存档钩子都已经预留，详见 PUBLISHING.md。

### 5.7 重新生成图标（不建议动）
```bash
make icon
# 会调用 tools/gen_icon/ 里的 LÖVE2D 小程序重画 assets/images/icon*.png
```

---

## 六、项目文件结构

```
love2DGame_vale/
├── main.lua                    # LÖVE2D 入口
├── conf.lua                    # LÖVE2D 配置（窗口/模块/版本/图标）
├── LICENSE                     # MIT License
├── README.md                   # 项目总览 / 架构 / 版本路线
├── SETUP.md                    # 本文档
├── PUBLISHING.md               # 三平台发布详细指南
├── CHANGELOG.md                # 版本变更日志
├── Makefile                    # 构建脚本
├── docs/
│   └── images/                 # 架构图等文档图片
├── src/
│   ├── core/                   # 通用引擎层（Game-agnostic）
│   │   ├── engine.lua          #   引擎主入口
│   │   ├── logger.lua          #   彩色日志
│   │   ├── config.lua          #   配置读写
│   │   ├── event.lua           #   事件总线
│   │   ├── timer.lua           #   延时/定时/补间
│   │   ├── input.lua           #   键鼠输入映射
│   │   ├── scene_manager.lua   #   场景切换
│   │   ├── resource.lua        #   字体/图像/声音缓存
│   │   ├── renderer.lua        #   分层渲染 (8层)
│   │   ├── save.lua            #   V4 存档系统
│   │   ├── steam.lua           #   V5 Steamworks 钩子
│   │   └── utils.lua           #   工具函数
│   ├── engine/                 # 游戏引擎扩展（可复用）
│   │   ├── camera/init.lua     #   相机/震动/缩放
│   │   ├── audio/init.lua      #   程序化音效
│   │   ├── particles/init.lua  #   粒子系统
│   │   └── ui/button.lua       #   通用按钮组件
│   └── game/                   # 中国象棋业务层
│       ├── constants.lua       #   棋盘/颜色/棋子字符
│       ├── entities/
│       │   ├── board.lua       #     棋盘数据
│       │   └── piece.lua       #     棋子数据
│       ├── systems/
│       │   ├── move_rules.lua  #     单步走法判定
│       │   ├── game_rules.lua  #     将军/将死/白脸将
│       │   └── ai.lua          #     贪心 AI
│       ├── renderers/
│       │   ├── board_renderer.lua #  棋盘绘制
│       │   └── piece_renderer.lua #  棋子绘制
│       └── scenes/
│           ├── boot_scene.lua     # 启动闪屏
│           ├── menu_scene.lua     # V4 主菜单
│           ├── board_scene.lua    # 主游戏场景
│           └── demo_scene.lua     # V0 测试场景
├── assets/
│   ├── fonts/                     # Noto Sans CJK SC (Regular+Bold)
│   ├── images/                    # 图标 PNG (16~512)
│   └── sounds/                    # （V5 无外部音效，程序化生成）
├── tools/
│   └── gen_icon/                  # 图标程序化生成器
└── build/                         # make 产出目录（.gitignore）
```

---

## 七、注意事项（坑点总结）

### 7.1 Lua 语言新手常踩坑
1. **Lua 数组下标从 1 开始**（不是 0），但棋盘坐标我们用 0 起
2. **`local a = 1, b = 2` 是非法语法**，必须分开两行：`local a=1; local b=2`
3. **`#table` 只对 array 有效**，hash 部分不算；遍历 hash 用 `pairs`
4. **`..` 是字符串拼接**（不是 +），`tostring(x)` 数字转字符串
5. **`obj:method()` 是 `obj.method(obj)` 的语法糖**，注意 `:` 和 `.` 的区别
6. **没有 class 关键字**，用 metatable + `__index` 实现
7. **`nil` vs `false`**：条件判断时只有 nil 和 false 为假，0 和 "" 都算真

### 7.2 LÖVE2D 引擎常见坑
1. **图形变换栈深度默认 32 层**！循环里 push/pop 超过 32 次会直接 segfault
   - 解决：画椭圆用 `love.graphics.ellipse(...)` 而非 `push/scale/circle/pop`
   - 本项目所有代码都已遵守
2. **love.filesystem 有安全沙箱**，只能读写：
   - 游戏目录（只读）
   - save 目录 `~/.local/share/love/trillion_games_vale/`（可写）
3. **文件路径大小写敏感**（Linux/Mac/APK 上），Windows 上不敏感；统一小写
4. **中文显示必须自己加载中文字体**，LÖVE2D 默认字体不含 CJK
   - 本项目自带 Noto Sans CJK SC
5. **`dt` 在窗口被拖大的时候可能跳变大**，engine.lua 已做 0.1s clamp
6. **`love.math.random` 不调 `setRandomSeed` 每次会一样**，main.lua 已设
7. **Canvas 后注意 `setCanvas()` 还原**，否则后续画到 Canvas 上而不显示
8. **t.window.icon 必须是 PNG 路径**（本项目已生成）
9. **鼠标事件里按钮编号**：1=左键，2=右键，3=中键
10. **场景切换时旧场景的 event 监听要在 unload 时清理**（本项目已做）

### 7.3 中国象棋规则边界（本项目已处理）
1. 相不能过河，有塞象眼
2. 马有蹩马腿
3. 炮走子不吃子，吃子必须翻一个
4. 兵过河前只能向前，过河后可左右但不能后退
5. 帅/将不能离开九宫
6. 白脸将（将帅照面）判将军
7. 走子后不能让自己的将/帅处于被将军状态（应将）
8. 困毙也算输（无子可走，和国际象棋不同）

### 7.4 性能建议
- 当前代码 60fps 无压力（32 棋子 + 粒子 + 渲染 8 层）
- 如果后续加更多特效（弹珠游戏），注意每帧 draw call < 500
- 粒子系统在 particles/init.lua 自己管理生命周期，不需要手动 GC
- 字体和图片已通过 resource.lua 缓存，不会重复加载

### 7.5 Git 规范
- 每个版本一个 tag：v0.0.0 → v5.0.0
- 每个版本 commit message 格式：`[vN] 版本名 - 简要说明`
- commit 前确认 love . 能正常运行
- 不要把 build/ dist/ ~/.local 里的东西提交

### 7.6 调试技巧
```bash
# 打开 LÖVE2D 控制台（Windows 有用）
# conf.lua 设 t.console = true

# 查看日志级别
# 启动时 export 环境变量
LOVE_DEBUG=1 love .

# 截图会自动存到 ~/.local/share/love/trillion_games_vale/screenshots/
ls ~/.local/share/love/trillion_games_vale/

# 重置用户配置
rm ~/.local/share/love/trillion_games_vale/user_config.lua
```

---

## 八、常见问题排查

| 问题 | 可能原因 | 解决方法 |
|---|---|---|
| `bash: love: command not found` | LÖVE2D 没装或不在 PATH | 见第 2.1 节安装 |
| 窗口里中文变方块 | 字体没加载或字体文件缺 | 检查 assets/fonts 下 .ttc 文件存在 |
| 启动直接 crash/segfault | push/pop 栈溢出或 shader 问题 | 看 CHANGELOG 里 Fixed 部分是否已修 |
| 鼠标点选无反应 | 场景未切换 / 被动画锁 | 看日志有无 `[board_scene] V3 ready` |
| AI 不走棋 | 你在用双人模式或已将死 | 按 A 切换 AI 模式；按 R 重开 |
| 棋子走不过去（明明是合法格） | 走了之后你被将军（应将规则） | 换一步应将的走法 |
| `make love` zip 报错 | 某些文件不存在（README/LICENSE）| 不要删这几个文件；或改 Makefile |
| 图标没显示 | assets/images/icon.png 缺失 | `make icon` 重新生成 |
| 音效很小/听不见 | 系统音量/被 mute | core.audio 默认 0.9 sfx_volume |

---

## 九、从 v0.0.0 到 v5.0.0 的切换顺序（你要回归测试用）

```bash
git checkout v0.0.0 && love .     # 看到 Boot→Demo 场景、三原色方块、F11 全屏即可
git checkout v1.0.0 && love .     # 看到棋盘+32棋子即可
git checkout v2.0.0 && love .     # 可以点选棋子、看绿点红点、走子有声音
git checkout v3.0.0 && love .     # 试下把对面将死，看到金色彩带；按 U 悔棋；按 A 切双人
git checkout v4.0.0 && love .     # 先看到主菜单，点击才进游戏
git checkout v5.0.0 && love .     # 同上，且窗口有图标，make love 可打包
git checkout main                # 回到最新
```

每个版本退出后切下一个 tag，都可以独立运行。

---

## 十、下一步（V6 及以后建议）

- AI 升级：alpha-beta 剪枝 + 4 层深度 + 开局库
- 手柄 / Steam Deck 支持（joystick 模块已预留）
- 对局计时（中国象棋比赛规则）
- 棋谱导出（PGN 格式）
- 在线对战（WebSocket 或 Steam P2P）
- 皮肤系统（可切换棋盘/棋子外观）
- 多语言（i18n）
- 复用引擎做弹珠游戏！只需在 src/game/ 里加另一个项目即可，engine/core 完全不动

---

项目已全部就绪。祝开发愉快 🎮
