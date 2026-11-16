# 个人补丁与已安装的 NX2Apple.app

给未来的自己：这套东西为什么长这样、怎么用、坏了怎么退。

## 一句话结构

- **`local` 分支**（只在本地，不推、不提 PR）= `upstream/main` + 我的补丁（当前是 0056–0059）。
- **`patches/local`**（local 分支里的文件）= 个人补丁清单，一行一个文件名。
- **`tools/patch-app`**（工作树里的未跟踪文件）= 把这些补丁打进已安装的 app。
- **备份**：`~/Library/Application Support/nx2-wide-engine/engine-backup`，作者原始引擎，`--restore` 的唯一依据。

## 日常用法

```sh
# 1. 跟上游
git switch local
git sync-wide                       # fetch upstream main + rebase；别名已配好

# 2. 先看能不能打（只检查，不改任何文件；app 开着也能跑）
tools/patch-app --dry-run

# 3. 装进已安装的 app（app 必须退出）
tools/patch-app

# 4. 回滚
tools/patch-app --restore
```

在 `main` 或其他分支上也能直接跑 `tools/patch-app`：它默认从 `local` 分支的 git 对象读
`patches/local` 和补丁文件，不看当前 checkout。`--from BRANCH` 可以换来源分支。

## 新加一个补丁

```sh
# 功能分支上把补丁做出来（照常提 PR）
git switch local
git cherry-pick <补丁提交>
echo 0060-xxx.patch >> patches/local
git add patches/local && git commit -m "build: add 0060 to the local patches"
```

临时试某一条，不登记：

```sh
tools/patch-app --patches 0060
```

编号会在来源分支的 `series` 里解析成文件名。

## 为什么这样做

- app 里的引擎是**源树**（`Contents/Resources/engine`，`dm/ scripts/ docs/ ref/`），不是编进二进制的代码，
  所以打补丁就是改源文件，不用重建 app。
- app 是 **ad-hoc 签名**，改完必须重签：`codesign --force --deep -s - /Applications/NX2Apple.app`。
- `EngineInstaller.seed()` 有个坑：store 里已有同 `engine-id` 的树就**直接返回、不复制**。所以只改 app 内的树
  没用，必须同时删掉 `~/Library/Application Support/NX2Apple/engine/<engine-id>/`，让下次启动重新 seed。
  `tools/patch-app` 已自动处理。
- 所有补丁先 `patch -p1 --dry-run --forward`，全部通过才动手；有一条不匹配就停，零改动。
  `--forward` 是关键：不加它，`patch` 会把"已应用"误判成"可以再打"（甚至反向撤销）。
- 防呆：bundle id 必须是 `org.nxnative.NSPortBuilder`；`patches/local` 必须按 `series` 的顺序；
  中途打补丁或重签失败会**自动从备份还原**，不会留下半坏状态。

## 作者合并了补丁之后

有两种情况，处理方式不同。

### A. 原样吸收（最常见的宽屏补丁）

先确认：`git fetch upstream main`，然后看上游有没有新增同内容的补丁文件：

```sh
git log --oneline upstream/main -- patches/ | head
git diff upstream/main -- patches/ | head -50
```

确认被吸收后：

```sh
git switch local
git rebase upstream/main          # 对应提交会冲突或变成空提交
# 冲突：git rebase -i，把该补丁的提交 drop 掉
# 或者冲突解决后确认内容为空，git rebase --skip
# 更新清单：从 patches/local 删掉那一行
python3 tools/engine.py check     # 56 → 55 条干净
tools/patch-app --dry-run         # 应显示剩余补丁 fits / applied
```

同时把 `series` 与上游对齐（编号可能变），这是唯一需要手工看的地方。

### B. 改写后吸收（作者用自己的实现）

不能直接删。先按功能清单比对，确认上游实现覆盖了我们的目的：

- 画面取屏幕自身的形状，触摸落点映射回居中界面
- 动森自适应视图（`DM_SCREEN_ASPECT` 1.3–1.77）
- 主机模式：齿轮菜单第一行、Docked/Handheld、即时生效（`DM_OPMODE`）
- 电视 + 手柄时齿轮隐藏，双指唤回

- 全部覆盖 → 按 A 处理，删掉我们的补丁；
- 只覆盖一部分 → 删掉重复部分，把剩余差异缩成一个小补丁，重新登记到 `patches/local`；
- 行为有分歧 → 先在上游 issue 里问清楚，别在本地维护两套实现。

无论如何，`git sync-wide` 的冲突、`engine.py check` 的失败、`tools/patch-app --dry-run` 的 `applied/mismatch`，都是这套流程发出的信号，不是故障。

## 已知限制

- **作者发新版 app 会覆盖引擎**：装好后重跑一次 `tools/patch-app`。
- 装完在设置里**关掉自动更新**，否则启动检查会装回作者的引擎。
- 补丁变多、上游 pin 漂移导致 dry-run 失败时，用整树方案（一条命令）：
  `tools/patch-app --tree`。它在 local 分支的临时工作树里 `engine.py sync` + `tree`，替换 app 的引擎并重签。
- 补丁只是源文件；着色器链、游戏数据都不在补丁范围内。
- **补丁只能打在与它 pin 接近的引擎上**。作者 app 的引擎是某个旧 pin（当前 `ccd834e0`），local 分支基于新 main
  （`5a4e23a2`）。宽屏三个补丁能打，但 0059 依赖上游 #1344 之后的代码，在旧引擎上 `--dry-run` 就失败。
  这种情况只能用整树替换（见上一条），或者等作者发新版。
- 截至 2026-11-15：`tools/patch-app` 的 dry-run 与跨分支读取已验证，**替换 + 重签 + 启动的完整流程尚未实测**；
  `ios/console-mode-menu` 适配上游 #1344 后，Duo harness 也尚未重跑。

## 纪律

- `local` 分支不要推、不要提 PR。
- `tools/patch-app` 和本文件是**未跟踪文件**，故意不提交：这样它在任何分支都在，也不会混进 PR。
  （若怕 `git clean` 弄丢，可单独提交到 `local` 分支。）
- 环境里 `rm` 被包装成了 `trash`，脚本里统一用 `/bin/rm`。
