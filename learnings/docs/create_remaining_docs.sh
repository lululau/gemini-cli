#!/bin/bash

# Create documents 08-12 (Core Logic)
cat > 08-命令处理流程.md << 'EOF'
# 命令处理流程

## 用户输入解析

用户输入可以采用多种形式：
- 自然语言问题：`gemini "为我写一个 HTTP 服务器"`
- 文件引用：`gemini @main.ts "这个文件有问题吗？"`
- 管道输入：`cat error.log | gemini "分析这个错误"`

### 输入流程

```
读取用户输入
    ↓
检测输入源
    ├─ TTY (交互式)
    ├─ 管道 (piped)
    └─ 参数 (CLI args)
    ↓
解析输入
    ├─ 提取问题文本
    ├─ 识别文件引用
    └─ 加载上下文
    ↓
构造消息
    ├─ 组合文本内容
    ├─ 附加文件内容
    └─ 包含上下文信息
    ↓
发送给 Agent
```

## 命令路由

### 命令类型

```typescript
enum CommandType {
  QUERY = 'query',              // 普通查询
  SLASH_COMMAND = 'slash',     // 斜杠命令 /auth, /settings
  MCP_COMMAND = 'mcp',         // MCP 命令
  EXTENSION_COMMAND = 'ext',   // 扩展命令
}
```

### 路由逻辑

```typescript
function routeCommand(input: string): CommandType {
  if (input.startsWith('/')) {
    return identifySlashCommand(input);
  }
  if (input.startsWith('mcp:')) {
    return CommandType.MCP_COMMAND;
  }
  return CommandType.QUERY;
}
```

## 交互式 vs 非交互式

### 交互式模式

```
启动 Gemini CLI
    ↓
初始化 UI
    ↓
显示提示符
    ↓
等待用户输入
    ↓
处理输入
    ↓
显示输出
    ↓
返回步骤4
```

### 非交互式模式

```
gemini "问题"
    ↓
解析参数
    ↓
初始化 Core
    ↓
构造单个请求
    ↓
流式输出响应
    ↓
退出
```

## 最佳实践

- 验证输入有效性
- 提供清晰的错误消息
- 支持多种输入格式
EOF

cat > 09-Agentic-Loop详解.md << 'EOF'
# Agentic Loop 详解

## Loop 核心机制

```
初始化
    ├─ 加载历史记录
    ├─ 准备工具列表
    └─ 初始化状态
    ↓
Turn N
    ├─ 构造 Prompt
    ├─ 调用 LLM
    ├─ 解析响应
    ├─ 执行工具
    └─ 更新历史
    ↓
检查是否继续
    ├─ 有更多工具调用？
    │   └─ 是 → Turn N+1
    └─ 无 → 结束
    ↓
返回最终响应
```

## Turn 管理

### Turn 类

```typescript
// packages/core/src/core/turn.ts
export class Turn {
  readonly pendingToolCalls: ToolCallRequestInfo[] = [];
  
  async *run(
    model: string,
    req: PartListUnion,
    signal: AbortSignal,
  ): AsyncGenerator<ServerGeminiStreamEvent>
}
```

### Turn 事件

- `Thought` - 模型思维过程
- `Content` - 文本输出
- `ToolCall` - 工具调用请求
- `Error` - 错误事件

## 最大轮次限制

```typescript
const MAX_TURNS = 10;  // 最多 10 个 Turn

while (turnCount < MAX_TURNS) {
  const turn = await nextTurn();
  if (!turn.hasToolCalls()) break;
  turnCount++;
}
```
EOF

echo "✓ Documents 08-09 created"

cat > 10-模型交互流程.md << 'EOF'
# 模型交互流程

## API 调用流程

```
构造请求
    ├─ 系统提示
    ├─ 历史记录
    ├─ 工具定义
    └─ 用户消息
    ↓
调用 Gemini API
    ├─ sendMessageStream()
    └─ 返回流
    ↓
处理响应
    ├─ 流式接收 chunks
    ├─ 解析 delta
    └─ 生成事件
    ↓
错误处理
    ├─ 重试
    ├─ 降级
    └─ 报错
```

## 流式处理

```typescript
const stream = await client.generateContentStream(request);

for await (const response of stream) {
  // 处理每个 chunk
  yield parseResponse(response);
}
```

## 重试机制

- 指数退避
- 最多 3 次重试
- 可配置的超时

EOF

echo "✓ Documents 10 created"

cat > 11-思维链集成.md << 'EOF'
# 思维链集成

## 思维过程展示

模型可以在响应前展示思维过程，帮助用户理解推理过程。

```typescript
// 思维部分
if (part.thought) {
  yield {
    type: GeminiEventType.Thought,
    value: parseThought(part.text),
  };
}
```

## 思维链优化

- 支持用户查看或隐藏思维
- 缓存重复的思维结果
- 在摘要中总结思维过程
EOF

echo "✓ Documents 11 created"

cat > 12-上下文管理.md << 'EOF'
# 上下文管理

## IDE 上下文

当使用 VS Code 或 Zed 时，IDE 可以向 CLI 提供：
- 当前打开的文件
- 选中的代码
- 项目根目录

## 历史记录管理

保持完整的对话历史以供 LLM 参考。

## 上下文压缩

当 Token 数量超过限制时：
1. 识别关键信息
2. 压缩旧的对话
3. 保留最近的交互
4. 维持语义连贯性

EOF

echo "✓ Documents 12 created"

cat > 13-工具系统架构.md << 'EOF'
# 工具系统架构

## 核心组件

### ToolRegistry
中央工具注册表，存储所有可用工具。

### DeclarativeTool
工具基类，定义工具的接口和行为。

### ToolInvocation
工具执行的实例，包含参数和执行逻辑。

## 工具生命周期

```
注册工具
    ↓
验证工具定义
    ↓
LLM 请求调用
    ↓
查询 ToolRegistry
    ↓
构造 ToolInvocation
    ↓
验证参数
    ↓
执行工具
    ↓
收集结果
    ↓
转换为 LLM 消息
```
EOF

echo "✓ Documents 13 created"

# 继续其他文档...
echo "Creating documents 14-30..."

for i in {14..30}; do
  case $i in
    14)
      title="内置工具详解"
      ;;
    15)
      title="MCP集成指南"
      ;;
    16)
      title="工具确认机制"
      ;;
    17)
      title="自定义工具开发"
      ;;
    18)
      title="工具执行与调度"
      ;;
    19)
      title="CLI-UI架构"
      ;;
    20)
      title="交互模式详解"
      ;;
    21)
      title="确认对话设计"
      ;;
    22)
      title="主题与样式系统"
      ;;
    23)
      title="身份验证与授权"
      ;;
    24)
      title="沙箱隔离机制"
      ;;
    25)
      title="扩展系统"
      ;;
    26)
      title="IDE集成"
      ;;
    27)
      title="性能优化指南"
      ;;
    28)
      title="错误处理与恢复"
      ;;
    29)
      title="测试策略"
      ;;
    30)
      title="开发最佳实践"
      ;;
  esac
  
  cat > "0${i}-${title}.md" << EOF
# ${title}

## 概述

本文档介绍了 Gemini CLI 中 ${title} 相关的内容。

## 关键概念

[待补充详细内容]

## 实践示例

[待补充代码示例]

## 最佳实践

[待补充最佳实践]

## 相关资源

- 详见项目源代码
- 参考其他相关文档
EOF
  
  echo "✓ Document $i created"
done

echo "All documents created successfully!"
