# npm run build 执行逻辑详解

## 概述

当执行 `npm run build` 命令时，会触发一系列复杂的构建流程，最终生成完整的 Gemini
CLI 可执行文件。以下是详细的执行逻辑分析。

## 命令调用链

### 1. 根目录 package.json 中的 scripts 定义

```json
"scripts": {
  "build": "node scripts/build.js"
}
```

执行 `npm run build` 实际上是运行 `node scripts/build.js`。

## 详细执行流程

### 阶段一：环境检查和依赖安装（scripts/build.js）

#### 步骤 1：检查 node_modules 是否存在

```javascript
if (!existsSync(join(root, 'node_modules'))) {
  execSync('npm install', { stdio: 'inherit', cwd: root });
}
```

如果 `node_modules` 目录不存在，会自动运行 `npm install` 安装依赖。

#### 步骤 2：生成 Git 提交信息文件

```javascript
execSync('npm run generate', { stdio: 'inherit', cwd: root });
```

这会执行 `scripts/generate-git-commit-info.js`，生成以下文件：

- `packages/cli/src/generated/git-commit.ts`
- `packages/core/src/generated/git-commit.ts`

文件内容包括：

```typescript
export const GIT_COMMIT_INFO = 'abc123'; // Git 短哈希
export const CLI_VERSION = '0.11.0-nightly.20251020.a96f0659'; // 包版本号
```

#### 步骤 3：构建所有工作空间包

```javascript
execSync('npm run build --workspaces', { stdio: 'inherit', cwd: root });
```

这是构建过程的核心步骤，会并行构建所有工作空间中的包。

## 工作空间包构建详解

### 包结构

项目使用 npm workspaces 管理以下包：

```
packages/
├── a2a-server/          # A2A 服务器
├── cli/                 # CLI 前端
├── core/                # 核心逻辑
├── test-utils/          # 测试工具
└── vscode-ide-companion/  # VS Code 扩展
```

### 每个包的构建流程（scripts/build_package.js）

#### 步骤 1：检查执行环境

```javascript
if (!process.cwd().includes('packages')) {
  console.error('must be invoked from a package directory');
  process.exit(1);
}
```

确保在包目录中执行。

#### 步骤 2：TypeScript 编译

```javascript
execSync('tsc --build', { stdio: 'inherit' });
```

使用 TypeScript 编译器编译代码，基于每个包的 `tsconfig.json` 配置。

**TypeScript 编译配置特点：**

- 根目录 `tsconfig.json` 提供基础配置
- 各包 `tsconfig.json` 继承根配置并自定义
- 启用严格模式和现代 ES 特性
- 使用 `references` 处理包间依赖关系

#### 步骤 3：复制资源文件

```javascript
execSync('node ../../scripts/copy_files.js', { stdio: 'inherit' });
```

执行 `scripts/copy_files.js`，复制以下类型文件到 `dist` 目录：

- `.md` 文件（文档）
- `.json` 文件（配置）
- `.sb` 文件（macOS 沙箱配置）

#### 步骤 4：创建构建标记

```javascript
writeFileSync(join(process.cwd(), 'dist', '.last_build'), '');
```

在 `dist` 目录创建 `.last_build` 文件作为构建完成标记。

## 特殊包的构建细节

### CLI 包特殊处理

`scripts/copy_files.js` 对 CLI 包有额外处理：

```javascript
// 复制示例扩展到 bundle 中
const examplesSource = path.join(
  sourceDir,
  'commands',
  'extensions',
  'examples',
);
const examplesTarget = path.join(
  targetDir,
  'commands',
  'extensions',
  'examples',
);
```

确保示例扩展能够包含在最终的构建产物中。

## 阶段二：沙箱检测（可选）

在包构建完成后，`scripts/build.js` 会尝试检测沙箱环境：

```javascript
try {
  execSync('node scripts/sandbox_command.js -q', {
    stdio: 'inherit',
    cwd: root,
  });
  if (
    process.env.BUILD_SANDBOX === '1' ||
    process.env.BUILD_SANDBOX === 'true'
  ) {
    execSync('node scripts/build_sandbox.js -s', {
      stdio: 'inherit',
      cwd: root,
    });
  }
} catch {
  // ignore
}
```

### 沙箱命令检测逻辑（scripts/sandbox_command.js）

#### 1. 环境变量优先级

1. `GEMINI_SANDBOX` 环境变量
2. `~/.gemini/settings.json` 中的 `sandbox` 配置
3. 项目目录中的 `.env` 文件中的 `GEMINI_SANDBOX`

#### 2. 沙箱类型选择

- **Docker/Podman**: 当 `GEMINI_SANDBOX=true` 时自动选择
- **自定义命令**: 当指定具体沙箱命令时
- **macOS sandbox-exec**: 在 macOS 上的默认选择

#### 3. 平台特定处理

- **Windows**: 支持 `.exe` 后缀检查
- **macOS**: 检查 `sandbox-exec` 命令
- **Linux**: 优先使用 Docker/Podman

## 阶段三：沙箱构建（如果启用）

如果检测到沙箱环境且 `BUILD_SANDBOX=true`，会执行 `scripts/build_sandbox.js`：

### 主要步骤

#### 1. 检测沙箱命令

```javascript
const sandboxCommand = execSync('node scripts/sandbox_command.js')
  .toString()
  .trim();
```

#### 2. 打包 npm 包

```javascript
// 打包 CLI
execSync(
  `npm pack -w @google/gemini-cli --pack-destination ./packages/cli/dist`,
  { stdio: 'ignore' },
);

// 打包 Core
execSync(
  `npm pack -w @google/gemini-cli-core --pack-destination ./packages/core/dist`,
  { stdio: 'ignore' },
);
```

#### 3. 构建 Docker 镜像

```javascript
execSync(
  `${sandboxCommand} build --build-arg CLI_VERSION_ARG=${npmPackageVersion} -f "${dockerfile}" -t "${finalImageName}" .`,
  { stdio: buildStdout, shell: shellToUse },
);
```

### Docker 构建特点

#### 构建参数

- `CLI_VERSION_ARG`: CLI 版本号作为构建参数
- `BUILD_SANDBOX_FLAGS`: 额外的构建标志
- `GEMINI_SANDBOX_IMAGE_TAG`: 镜像标签（可选）

#### 认证处理

- **Podman**: 处理认证文件
- **Windows**: 使用临时文件处理认证

## 构建产物分析

### 包级别构建产物

每个包在 `dist` 目录生成：

```
packages/cli/dist/
├── index.js              # 编译后的主入口
├── src/                  # 复制的资源文件
├── google-gemini-cli-*.tgz  # npm 打包文件（用于沙箱构建）
└── .last_build           # 构建完成标记
```

### 根目录构建产物

```
bundle/
├── gemini.js             # ESBuild 打包的可执行文件（需运行 npm run bundle）
└── sandbox-*.sb          # macOS 沙箱配置文件
```

## 错误处理机制

### 1. 构建失败处理

- TypeScript 编译错误会立即中断构建
- 依赖安装失败会显示详细错误信息
- 沙箱构建失败会被捕获并忽略（除非在 CI 环境中）

### 2. 环境检查

- Node.js 版本检查（通过 `engines.node`）
- 必要工具检查（Docker/Podman/sandbox-exec）
- 包依赖关系检查

## 性能优化

### 1. 并行构建

- npm workspaces 支持并行构建
- TypeScript 项目引用优化编译速度

### 2. 增量构建

- TypeScript `incremental: true` 启用增量编译
- `.last_build` 文件作为构建标记

### 3. 缓存机制

- node_modules 缓存
- Docker 镜像缓存（`image prune -f` 清理无用镜像）

## 调试技巧

### 1. 详细日志

```bash
# 启用详细输出
npm run build --verbose

# 启用沙箱详细输出
VERBOSE=1 npm run build
```

### 2. 调试模式

```bash
# Node.js 调试
node --inspect-brk scripts/build.js

# TypeScript 调试
npx tsc --build --traceResolution
```

### 3. 环境变量

```bash
# 启用沙箱构建
BUILD_SANDBOX=true npm run build

# 设置自定义构建标志
BUILD_SANDBOX_FLAGS="--no-cache" npm run build
```

## 总结

`npm run build` 的执行逻辑可以概括为：

1. **环境准备**: 检查依赖、生成版本信息
2. **并行构建**: 使用 npm workspaces 构建所有包
3. **资源复制**: 复制必要的非 TypeScript 文件
4. **沙箱检测**: 检测并可选地构建沙箱环境
5. **产物生成**: 生成可分发包和配置文件

整个过程设计为模块化和可扩展的，支持不同平台和环境的构建需求。
