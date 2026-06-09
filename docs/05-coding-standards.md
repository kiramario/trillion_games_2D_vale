# 05 - 代码规范与文档规范 (Coding & Docs Standards)

## Lua 语言速查（JS/Java/Python 开发者视角）

| 概念 | Lua | JS/Java/Python 类比 |
|------|-----|-------------------|
| 变量 | `local x = 1` | `let x = 1` (JS) / `int x = 1` (Java) |
| 全局变量 | `x = 1`（不加 local）| 尽量不用，像 JS 不加 let/const |
| 字符串 | `"hello"` 或 `'hello'` | 同 JS/Python |
| 数组/列表 | `{1, 2, 3}`（索引从 1 开始！）| Python list / JS array（但 0-indexed） |
| 字典/对象 | `{name = "bob", age = 30}` | JS object / Python dict / Java HashMap |
| 函数 | `function foo(a, b) return a+b end` | `function foo(a,b) { return a+b }` |
| 匿名函数 | `function(x) return x*2 end` | `x => x*2` (JS) / `lambda x: x*2` (Python) |
| 空值 | `nil` | `null` / `None` |
| 假值 | 只有 `false` 和 `nil` 为假 | Python: False/None/0/"" 都假；Lua 里 0 和 "" 是真！ |
| 类/面向对象 | 没有 class 关键字，用 table + metatable 模拟 | JS prototype / Python class |
| 模块返回 | `return M` 在文件末尾 | `export default M` (ES6) |
| 导入模块 | `local M = require("path.to.module")` | `import M from 'path/to/module'` |
| 字符串拼接 | `a .. b`（两个点） | `a + b` (JS) / `a + b` (Python) |
| 注释 | `--` 单行, `--[[ 多行 ]]--` | `//` 和 `/* */` (JS/Java), `#` 和 `"""` (Python) |
| 不等 | `~=` | `!=` / `<>` |
| 长度 | `#tbl` | `arr.length` (JS) / `len(arr)` (Python) |
| for 循环 | `for i=1,10 do ... end` | `for i in range(1,11)` |
| foreach | `for k,v in pairs(tbl) do ... end` | `for (let [k,v] of Object.entries(tbl))` |
| foreach 数组有序 | `for i,v in ipairs(tbl) do ... end` | `for (let i=0; i<arr.length; i++)` |
| self | `function M:foo(x) ... end` 隐含 self 参数 | `this` (JS/Java) / `self` (Python) |
| 三元表达式 | 没有，用 `a and b or c`（近似）| `a ? b : c` |

> **Lua 最大坑**：table 索引从 1 开始；只有 false 和 nil 是假值；`..` 拼接字符串。

## 代码规范

### 命名

```lua
-- 模块名：小写，路径用点（require 风格）
local config = require("core.config")

-- 变量和函数：snake_case
local board_width = 540
local function calculate_move(piece, target_x, target_y)

-- 类/构造器：大驼峰（PascalCase），但在本项目尽量用返回 table 的工厂模式
local Scene = {}

-- 常量：UPPER_SNAKE_CASE，定义在模块顶部
local MAX_PIECES = 32
local LAYER_COUNT = 5

-- 私有函数：前缀 _local（用 local 就够了，不用前缀；但如果需要标识模块内部）
local function _internal_helper()
```

### 文件结构

每个模块文件的结构：
```lua
--! file: src/core/xxx.lua
--! breif: 一句话说明这个模块做什么
--! 类比：JS/Java/Python 中对应什么
local M = {}

-- ===== 模块常量 =====

-- ===== 模块私有变量（闭包内）=====

-- ===== 私有函数 =====

-- ===== 公共 API =====

--! 函数名: M.do_something
--! 功能: 做什么
--! 参数:
--!   a - 类型, 说明
--! 返回: 返回值说明
function M.do_something(a)
    -- 注释用中文，面向 Lua 初学者
end

return M
```

### 注释原则

1. **公共 API 必须注释**：参数、返回值、副作用
2. **Lua/LÖVE 特性处必须注释**：比如用到 metatable、coroutine、love.graphics 状态机等地方，要加 `-- [Lua] ...` 或 `-- [LOVE] ...` 说明
3. **业务逻辑关键处加注释**：特别是象棋规则代码（马走日、炮打隔山等）
4. **不要注释代码本身在做什么**（`x = x + 1 -- x加1`），要注释为什么这么做

### 模式选择

- **不用 OOP class 系统**：不用经典的 `Class = {} Class.__index = Class` 模式到处写。优先用**工厂函数 + 闭包**或**纯数据 table + 外部函数**模式，类似 JS 函数式/Go 风格。
- **场景是例外**：Scene 可以用 `setmetatable` 实现简单 OOP，因为它们有生命周期方法（load/update/draw/unload）。
- **模块不持有状态（尽量）**：除了单例性质的管理器（SceneManager、ResourceManager），普通工具模块应为纯函数。

### 错误处理

- 配置/资源加载失败：logger.error + 合理的默认值/降级
- 程序员错误（传了 nil 参数等）：用 `assert()` 快速失败
- 不使用 pcall/xpcall 做控制流；只在调用外部/不可靠代码时用

### Git 规范

- Commit message 格式：`[模块] 简短描述`
  - 例：`[core] add event bus with on/off/emit`
  - 例：`[chess] implement horse move with leg-block rule`
- 每个 VN 版本合并到 main 时打 annotated tag：`git tag -a v0.0.0 -m "V0: Hello Engine"`
- 不 push 二进制资源到 git（assets 下除了占位文件，图片音效后期考虑 Git LFS）

## 文档规范

- 所有文档放在 `docs/` 下，文件名 `NN-name.md`（NN 两位数字序号）
- 新模块创建时，在 `docs/06-key-modules.md` 追加说明
- 每个版本更新 CHANGELOG.md
- 代码注释用中文（因为你是中文开发者），文档也用中文
