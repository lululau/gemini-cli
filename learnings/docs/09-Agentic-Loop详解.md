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
  ): AsyncGenerator<ServerGeminiStreamEvent>;
}
```

### Turn 事件

- `Thought` - 模型思维过程
- `Content` - 文本输出
- `ToolCall` - 工具调用请求
- `Error` - 错误事件

## 最大轮次限制

```typescript
const MAX_TURNS = 10; // 最多 10 个 Turn

while (turnCount < MAX_TURNS) {
  const turn = await nextTurn();
  if (!turn.hasToolCalls()) break;
  turnCount++;
}
```
