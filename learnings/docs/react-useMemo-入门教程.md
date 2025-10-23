# React useMemo Hook 入门教程

## 教程目标

本教程基于 Gemini CLI 项目中的真实代码，为已经了解
`useState`、`useEffect`、`useContext` 和 `useCallback`
的 React 初学者提供一份全面的 `useMemo`
Hook 学习指南。通过分析实际项目中的代码示例，您将学会：

- 理解 useMemo 的工作原理和使用场景
- 掌握如何正确使用 useMemo 优化组件性能
- 区分 useMemo 和 useCallback 的使用场景
- 避免常见的 useMemo 使用错误
- 学习 useMemo 与其他 Hooks 的配合使用

## 前置知识

在学习本教程之前，您应该已经了解：

- ✅ `useState` - 管理组件状态
- ✅ `useEffect` - 处理副作用
- ✅ `useContext` - 使用 Context API
- ✅ `useCallback` - 缓存函数引用
- ✅ JavaScript 基础语法和数组/对象操作

## 1. useMemo 基础概念

### 什么是 useMemo？

`useMemo`
是 React 提供的一个 Hook，用于**缓存（记忆化）计算结果**。它会缓存函数的返回值，只有在依赖项发生变化时才会重新计算。

**官方定义：**

```typescript
const memoizedValue = useMemo(
  () => {
    // 执行计算并返回结果
    return computeExpensiveValue(a, b);
  },
  [a, b], // 依赖项数组
);
```

### useMemo vs useCallback：核心区别

在深入学习 useMemo 之前，理解它与 useCallback 的区别至关重要：

| 特性         | useMemo                        | useCallback             |
| ------------ | ------------------------------ | ----------------------- |
| **缓存内容** | 缓存函数的**返回值**           | 缓存**函数本身**        |
| **返回类型** | 任意类型（数字、对象、数组等） | 函数                    |
| **使用场景** | 昂贵的计算、派生状态           | 回调函数、事件处理器    |
| **等价关系** | `useMemo(() => fn, deps)`      | `useCallback(fn, deps)` |

**直观对比：**

```typescript
// useCallback - 缓存函数本身
const handleClick = useCallback(() => {
  console.log('Clicked!');
}, []);
// 返回: 函数引用

// useMemo - 缓存函数的返回值
const expensiveResult = useMemo(() => {
  return calculateSomething();
}, []);
// 返回: calculateSomething() 的结果

// 特殊情况：useMemo 也可以返回函数
const handleClick = useMemo(() => {
  return () => console.log('Clicked!');
}, []);
// 等价于 useCallback(() => console.log('Clicked!'), [])
```

### 为什么需要 useMemo？

在 React 中，每次组件重新渲染时，组件函数会重新执行，导致所有计算都会重新进行：

```typescript
const MyComponent = ({ items }) => {
  const [count, setCount] = useState(0);

  // ❌ 问题：每次 MyComponent 重新渲染时，都会重新排序
  const sortedItems = items.slice().sort((a, b) => a.value - b.value);

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Button onClick={() => setCount(count + 1)}>Increment</Button>
      {sortedItems.map(item => <Text key={item.id}>{item.name}</Text>)}
    </Box>
  );
};
```

在这个例子中，即使 `items` 没有变化，每次点击按钮更新 `count` 时，`sortedItems`
都会被重新计算。如果数组很大，这会造成性能问题。

**使用 useMemo 的解决方案：**

```typescript
const MyComponent = ({ items }) => {
  const [count, setCount] = useState(0);

  // ✅ 只有当 items 变化时才重新排序
  const sortedItems = useMemo(() => {
    console.log('Sorting items...');
    return items.slice().sort((a, b) => a.value - b.value);
  }, [items]);

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Button onClick={() => setCount(count + 1)}>Increment</Button>
      {sortedItems.map(item => <Text key={item.id}>{item.name}</Text>)}
    </Box>
  );
};
```

### useMemo 的两大应用场景

#### 场景 1：避免昂贵的计算重复执行

当需要进行复杂计算（排序、过滤、聚合等）时，使用 useMemo 避免不必要的重复计算：

```typescript
// 昂贵的计算示例
const filteredAndSortedData = useMemo(() => {
  return data
    .filter((item) => item.active)
    .sort((a, b) => b.priority - a.priority)
    .map((item) => ({ ...item, formatted: formatItem(item) }));
}, [data]);
```

#### 场景 2：保持引用稳定性

在 JavaScript 中，每次创建对象或数组都会生成新的引用：

```typescript
const MyComponent = () => {
  // ❌ 每次渲染都创建新对象
  const config = { theme: 'dark', size: 'large' };

  return <ChildComponent config={config} />;
};
```

如果 `ChildComponent` 使用 `React.memo` 优化，它仍然会因为 `config`
的引用变化而重新渲染：

```typescript
const MyComponent = () => {
  // ✅ config 的引用保持稳定
  const config = useMemo(() => ({
    theme: 'dark',
    size: 'large'
  }), []);

  return <ChildComponent config={config} />;
};
```

## 2. Gemini CLI 项目实战案例

让我们分析 Gemini
CLI 项目中的真实 useMemo 使用案例，学习如何在实际项目中应用这个 Hook。

### 案例 1：计算派生的布局值

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const mainAreaWidth = calculateMainAreaWidth(terminalWidth, settings);

// 根据主区域宽度计算输入框和建议框的宽度
const { inputWidth, suggestionsWidth } = useMemo(() => {
  const { inputWidth, suggestionsWidth } = calculatePromptWidths(mainAreaWidth);
  return { inputWidth, suggestionsWidth };
}, [mainAreaWidth]);
```

**分析：**

- **目的**：根据 `mainAreaWidth` 计算两个派生值
- **为什么使用 useMemo**：
  1. `calculatePromptWidths` 可能涉及复杂的布局计算
  2. 返回一个对象，需要保持引用稳定性
  3. 只有当 `mainAreaWidth` 变化时才需要重新计算
- **依赖项**：`[mainAreaWidth]` - 只有一个依赖项

**学习要点：**

- 当需要基于某个值计算派生值时，使用 useMemo
- 返回对象时使用解构赋值保持代码简洁

### 案例 2：条件过滤数组

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const filteredConsoleMessages = useMemo(() => {
  // 如果开启调试模式，显示所有消息
  if (config.getDebugMode()) {
    return consoleMessages;
  }
  // 否则过滤掉 debug 类型的消息
  return consoleMessages.filter((msg) => msg.type !== 'debug');
}, [consoleMessages, config]);
```

**分析：**

- **目的**：根据调试模式过滤控制台消息
- **为什么使用 useMemo**：
  1. 数组的 `filter` 操作会创建新数组
  2. 避免每次渲染都执行过滤操作
  3. 保持 `filteredConsoleMessages` 的引用稳定性
- **依赖项**：`[consoleMessages, config]` - 当消息列表或配置变化时重新计算

**学习要点：**

- 条件逻辑可以放在 useMemo 内部
- 即使简单的 `filter` 操作，在大数组上也值得缓存
- 注意依赖项要包含所有使用到的外部变量

### 案例 3：聚合计算（链式操作）

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const errorCount = useMemo(
  () =>
    filteredConsoleMessages
      .filter((msg) => msg.type === 'error')
      .reduce((total, msg) => total + msg.count, 0),
  [filteredConsoleMessages],
);
```

**分析：**

- **目的**：统计错误消息的总数
- **为什么使用 useMemo**：
  1. 链式操作（filter + reduce）开销较大
  2. 返回的是基本类型（数字），但避免重复计算仍有意义
  3. `errorCount` 可能被多个子组件使用
- **依赖项**：`[filteredConsoleMessages]` - 只依赖过滤后的消息列表

**学习要点：**

- 链式数组操作是 useMemo 的理想使用场景
- 即使返回基本类型，避免重复计算仍然有价值
- 可以依赖另一个 useMemo 的结果（`filteredConsoleMessages`）

### 案例 4：合并多个数组

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const pendingHistoryItems = useMemo(
  () => [...pendingSlashCommandHistoryItems, ...pendingGeminiHistoryItems],
  [pendingSlashCommandHistoryItems, pendingGeminiHistoryItems],
);
```

**分析：**

- **目的**：合并两个待处理的历史记录数组
- **为什么使用 useMemo**：
  1. 扩展运算符 `...` 会创建新数组
  2. 保持数组引用的稳定性
  3. 避免不必要的重新渲染（如果用于子组件 props）
- **依赖项**：两个源数组都需要列为依赖项

**学习要点：**

- 即使是简单的数组合并，也可能需要 useMemo
- 当结果用作其他组件的 props 时，引用稳定性很重要
- 多个依赖项要全部列出

### 案例 5：构建复杂的状态对象

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const uiState: UIState = useMemo(
  () => ({
    history: historyManager.history,
    historyManager,
    isThemeDialogOpen,
    themeError,
    isAuthenticating,
    isConfigInitialized,
    authError,
    isAuthDialogOpen,
    editorError,
    isEditorDialogOpen,
    showPrivacyNotice,
    corgiMode,
    debugMessage,
    quittingMessages,
    isSettingsDialogOpen,
    isModelDialogOpen,
    isPermissionsDialogOpen,
    slashCommands,
    pendingSlashCommandHistoryItems,
    commandContext,
    shellConfirmationRequest,
    confirmationRequest,
    confirmUpdateExtensionRequests,
    // ... 更多属性
  }),
  [
    historyManager.history,
    historyManager,
    isThemeDialogOpen,
    themeError,
    // ... 对应的依赖项
  ],
);
```

**分析：**

- **目的**：将多个状态值组合成一个对象，传递给 Context Provider
- **为什么使用 useMemo**：
  1. 对象字面量每次都会创建新引用
  2. 这个对象会作为 Context value，影响所有消费者
  3. 避免不必要的 Context 消费者重新渲染
- **依赖项**：包含对象中使用的所有状态值

**学习要点：**

- Context value 是 useMemo 的典型应用场景
- 复杂对象的依赖项列表可能很长，但必须完整
- 这种模式常与 Context Provider 配合使用

### 案例 6：在 Context Provider 中使用

**位置：** `packages/cli/src/ui/contexts/SessionContext.tsx`

```typescript
const SessionStatsProvider = ({ children }) => {
  const [stats, setStats] = useState<SessionMetrics>({
    promptCount: 0,
    // ... 其他字段
  });

  const startNewPrompt = useCallback(() => {
    setStats(prev => ({ ...prev, promptCount: prev.promptCount + 1 }));
  }, []);

  const getPromptCount = useCallback(
    () => stats.promptCount,
    [stats.promptCount],
  );

  // ✅ 使用 useMemo 缓存 Context value
  const value = useMemo(
    () => ({
      stats,
      startNewPrompt,
      getPromptCount,
    }),
    [stats, startNewPrompt, getPromptCount],
  );

  return (
    <SessionStatsContext.Provider value={value}>
      {children}
    </SessionStatsContext.Provider>
  );
};
```

**分析：**

- **目的**：优化 Context Provider 的性能
- **为什么使用 useMemo**：
  1. 避免每次渲染都创建新的 value 对象
  2. 防止所有 Context 消费者不必要的重新渲染
  3. 这是 Context Provider 的最佳实践
- **依赖项**：包含 value 对象中的所有属性

**学习要点：**

- Context Provider 的 value 应该**总是**使用 useMemo
- 将 useCallback 和 useMemo 结合使用是常见模式
- 这样可以大幅提升使用 Context 的应用性能

### 案例 7：基于条件计算派生值

**位置：** `packages/cli/src/ui/components/messages/ToolMessage.tsx`

```typescript
const ToolHeader = ({
  name,
  description,
  status,
  emphasis,
}) => {
  // 根据强调级别计算颜色
  const nameColor = React.useMemo<string>(() => {
    switch (emphasis) {
      case 'high':
        return theme.text.primary;
      case 'medium':
        return theme.text.primary;
      case 'low':
        return theme.text.secondary;
      default: {
        const exhaustiveCheck: never = emphasis;
        return theme.text.primary;
      }
    }
  }, [emphasis]);

  return <Text color={nameColor}>{name}</Text>;
};
```

**分析：**

- **目的**：根据 emphasis 属性计算文本颜色
- **为什么使用 useMemo**：
  1. 避免每次渲染都执行 switch 逻辑
  2. 保持颜色值的稳定性
  3. TypeScript 类型保护（exhaustive check）
- **依赖项**：`[emphasis]` - 只有一个依赖项

**学习要点：**

- 即使是简单的条件逻辑，也可以使用 useMemo
- 可以指定返回值的 TypeScript 类型
- switch/case 语句是 useMemo 的好场景

### 案例 8：计算文件名列表

**位置：** `packages/cli/src/ui/AppContainer.tsx`

```typescript
const contextFileNames = useMemo(() => {
  const fromSettings = settings.merged.context?.fileName;
  return fromSettings
    ? Array.isArray(fromSettings)
      ? fromSettings // 如果已经是数组，直接返回
      : [fromSettings] // 如果是字符串，转换为数组
    : getAllGeminiMdFilenames(); // 如果没有配置，获取默认值
}, [settings.merged.context?.fileName]);
```

**分析：**

- **目的**：统一处理配置中的文件名，确保返回数组格式
- **为什么使用 useMemo**：
  1. 避免重复的类型检查和转换
  2. `getAllGeminiMdFilenames()` 可能涉及文件系统操作
  3. 保持返回数组的引用稳定性
- **依赖项**：`[settings.merged.context?.fileName]` - 嵌套属性访问

**学习要点：**

- 可以在 useMemo 中处理复杂的条件逻辑
- 依赖项可以是嵌套的对象属性
- 三元运算符嵌套时，useMemo 让逻辑更清晰

## 3. 依赖数组详解

依赖数组是 useMemo 最关键的部分，理解它的工作原理至关重要。

### 依赖数组的工作原理

React 使用 `Object.is()` 比较依赖项的前后值：

```typescript
// React 内部的伪代码
if (dependencies.every((dep, i) => Object.is(dep, prevDependencies[i]))) {
  // 所有依赖项都没变，返回缓存的值
  return memoizedValue;
} else {
  // 有依赖项变化，重新计算
  const newValue = computeFunction();
  return newValue;
}
```

### 正确指定依赖项

#### ✅ 规则 1：包含所有使用的外部变量

```typescript
const FilteredList = ({ items, searchTerm, category }) => {
  // ✅ 正确：包含所有使用的变量
  const filteredItems = useMemo(() => {
    return items
      .filter(item => item.category === category)
      .filter(item => item.name.includes(searchTerm));
  }, [items, searchTerm, category]);

  // ❌ 错误：遗漏 searchTerm 和 category
  const wrongFilteredItems = useMemo(() => {
    return items
      .filter(item => item.category === category)
      .filter(item => item.name.includes(searchTerm));
  }, [items]);  // 会导致数据不同步！

  return <>{/* ... */}</>;
};
```

#### ✅ 规则 2：基本类型 vs 引用类型

```typescript
const MyComponent = ({ count, user }) => {
  // 基本类型：值比较
  const doubledCount = useMemo(() => {
    return count * 2;
  }, [count]); // count 变化时重新计算

  // 对象引用：引用比较
  const userName = useMemo(() => {
    return user.name.toUpperCase();
  }, [user]); // user 对象引用变化时重新计算

  // ❌ 错误：依赖对象的属性
  const wrongUserName = useMemo(() => {
    return user.name.toUpperCase();
  }, [user.name]); // 不推荐！应该依赖整个 user
};
```

#### ✅ 规则 3：函数作为依赖项

```typescript
const SearchComponent = ({ onSearch }) => {
  const [query, setQuery] = useState('');

  // ❌ 问题：onSearch 每次可能是新函数
  const debouncedSearch = useMemo(() => {
    return debounce(onSearch, 500);
  }, [onSearch]); // onSearch 变化会导致重新创建

  // ✅ 解决方案：父组件应该用 useCallback 包装 onSearch
  // 或者使用 useCallback 而不是 useMemo
};
```

### 依赖项的常见错误

#### 错误 1：遗漏依赖项

```typescript
const ProductList = ({ products, discountRate }) => {
  // ❌ 错误：遗漏 discountRate
  const discountedPrices = useMemo(() => {
    return products.map((p) => p.price * (1 - discountRate));
  }, [products]);
  // 当 discountRate 变化时，价格不会更新！

  // ✅ 正确：包含所有依赖项
  const correctDiscountedPrices = useMemo(() => {
    return products.map((p) => p.price * (1 - discountRate));
  }, [products, discountRate]);
};
```

ESLint 插件 `eslint-plugin-react-hooks` 会帮助你检测这类问题。

#### 错误 2：依赖项过于细粒度

```typescript
const UserProfile = ({ user }) => {
  // ❌ 不推荐：依赖对象的属性
  const displayName = useMemo(() => {
    return `${user.firstName} ${user.lastName}`;
  }, [user.firstName, user.lastName]);

  // ✅ 推荐：依赖整个对象
  const betterDisplayName = useMemo(() => {
    return `${user.firstName} ${user.lastName}`;
  }, [user]);

  // 或者使用解构
  const { firstName, lastName } = user;
  const anotherDisplayName = useMemo(() => {
    return `${firstName} ${lastName}`;
  }, [firstName, lastName]);
};
```

#### 错误 3：空依赖数组的误用

```typescript
const Counter = ({ initialCount }) => {
  // ❌ 错误：空依赖数组导致 initialCount 变化不生效
  const count = useMemo(() => {
    return initialCount * 2;
  }, []); // 只会使用第一次的 initialCount

  // ✅ 正确：包含 initialCount
  const correctCount = useMemo(() => {
    return initialCount * 2;
  }, [initialCount]);
};
```

### 依赖项优化技巧

#### 技巧 1：提取不变的部分

```typescript
const DataTable = ({ data, sortField, filterType }) => {
  // ❌ 不够优化：即使只是排序字段变化，也会重新过滤
  const processedData = useMemo(() => {
    const filtered = data.filter((item) => item.type === filterType);
    const sorted = filtered.sort((a, b) =>
      a[sortField] > b[sortField] ? 1 : -1,
    );
    return sorted;
  }, [data, sortField, filterType]);

  // ✅ 优化：分离过滤和排序
  const filteredData = useMemo(() => {
    return data.filter((item) => item.type === filterType);
  }, [data, filterType]);

  const sortedData = useMemo(() => {
    return filteredData.sort((a, b) => (a[sortField] > b[sortField] ? 1 : -1));
  }, [filteredData, sortField]);
};
```

#### 技巧 2：使用函数式更新避免依赖

```typescript
const TodoList = () => {
  const [todos, setTodos] = useState([]);

  // ❌ 需要依赖 todos
  const addTodo = useMemo(() => {
    return (text) => {
      setTodos([...todos, { id: Date.now(), text }]);
    };
  }, [todos]); // todos 变化会重新创建函数

  // ✅ 使用函数式更新，避免依赖
  const betterAddTodo = useMemo(() => {
    return (text) => {
      setTodos((prev) => [...prev, { id: Date.now(), text }]);
    };
  }, []); // 空依赖数组，函数永远不会重新创建
};
```

## 4. useMemo vs useCallback：深度对比

理解这两个 Hook 的区别和联系，有助于在实际开发中做出正确选择。

### 核心区别总结

```typescript
// useCallback：缓存函数本身
const memoizedFunction = useCallback(
  (param) => {
    doSomething(param);
  },
  [dependency],
);
// 类型：(param: any) => void

// useMemo：缓存函数的返回值
const memoizedValue = useMemo(() => computeValue(dependency), [dependency]);
// 类型：computeValue 的返回类型

// 特殊情况：useMemo 返回函数
const memoizedFunction = useMemo(
  () => (param) => {
    doSomething(param);
  },
  [dependency],
);
// 完全等价于 useCallback
```

### 使用场景对比

| 场景               | 使用 Hook     | 示例                                                      |
| ------------------ | ------------- | --------------------------------------------------------- |
| 事件处理函数       | `useCallback` | `const handleClick = useCallback(() => {...}, [])`        |
| 传递给子组件的回调 | `useCallback` | `<Child onSave={handleSave} />`                           |
| 昂贵的计算         | `useMemo`     | `const sorted = useMemo(() => data.sort(), [data])`       |
| 派生状态           | `useMemo`     | `const total = useMemo(() => items.reduce(...), [items])` |
| 保持对象引用稳定   | `useMemo`     | `const config = useMemo(() => ({...}), [])`               |
| 保持数组引用稳定   | `useMemo`     | `const list = useMemo(() => [...], [])`                   |

### 实战对比示例

```typescript
const UserList = ({ users, onUserClick }) => {
  // useCallback：缓存事件处理函数
  const handleSort = useCallback(() => {
    console.log('Sorting users...');
  }, []);

  // useMemo：缓存排序后的数据
  const sortedUsers = useMemo(() => {
    return [...users].sort((a, b) => a.name.localeCompare(b.name));
  }, [users]);

  // useCallback：缓存传递给子组件的回调
  const handleUserClick = useCallback((userId) => {
    onUserClick(userId);
  }, [onUserClick]);

  // useMemo：缓存用户统计信息对象
  const userStats = useMemo(() => ({
    total: users.length,
    active: users.filter(u => u.active).length,
    inactive: users.filter(u => !u.active).length,
  }), [users]);

  return (
    <Box>
      <Text>Total: {userStats.total}, Active: {userStats.active}</Text>
      <Button onClick={handleSort}>Sort</Button>
      {sortedUsers.map(user => (
        <UserItem
          key={user.id}
          user={user}
          onClick={handleUserClick}
        />
      ))}
    </Box>
  );
};
```

### 等价转换

```typescript
// 这两种写法完全等价：

// 方式 1：useCallback
const handleClick = useCallback(() => {
  console.log('clicked');
}, []);

// 方式 2：useMemo 返回函数
const handleClick = useMemo(() => {
  return () => {
    console.log('clicked');
  };
}, []);

// React 源码中 useCallback 的实现：
function useCallback(callback, deps) {
  return useMemo(() => callback, deps);
}
```

**建议：** 尽管它们可以互换，但为了代码可读性：

- 缓存函数时使用 `useCallback`
- 缓存值时使用 `useMemo`

## 5. 性能优化最佳实践

### 何时应该使用 useMemo

#### ✅ 场景 1：昂贵的计算

```typescript
const DataAnalysis = ({ data }) => {
  // ✅ 适合：复杂的统计计算
  const statistics = useMemo(() => {
    return {
      mean: calculateMean(data),
      median: calculateMedian(data),
      stdDev: calculateStandardDeviation(data),
      percentiles: calculatePercentiles(data),
    };
  }, [data]);

  return <StatisticsDisplay stats={statistics} />;
};
```

**判断标准：** 如果计算需要遍历大量数据或执行复杂算法，使用 useMemo。

#### ✅ 场景 2：引用类型的依赖

```typescript
const ChildComponent = React.memo(({ config }) => {
  // 组件使用 React.memo 优化
  return <div>{config.theme}</div>;
});

const ParentComponent = () => {
  const theme = 'dark';

  // ✅ 适合：保持 config 引用稳定，避免子组件重新渲染
  const config = useMemo(() => ({
    theme,
    fontSize: 14,
  }), [theme]);

  return <ChildComponent config={config} />;
};
```

**判断标准：** 如果对象/数组作为 props 传递给使用 `React.memo`
的子组件，使用 useMemo。

#### ✅ 场景 3：作为其他 Hook 的依赖

```typescript
const SearchComponent = ({ items, query }) => {
  // ✅ 适合：filteredItems 被用作 useEffect 的依赖
  const filteredItems = useMemo(() => {
    return items.filter(item =>
      item.name.toLowerCase().includes(query.toLowerCase())
    );
  }, [items, query]);

  useEffect(() => {
    // 当 filteredItems 变化时执行某些操作
    saveToLocalStorage(filteredItems);
  }, [filteredItems]);  // 依赖 useMemo 的结果

  return <>{/* ... */}</>;
};
```

**判断标准：** 如果计算结果被用作 `useEffect`、`useMemo` 或 `useCallback`
的依赖，使用 useMemo。

### 何时不应该使用 useMemo

#### ❌ 场景 1：简单的基本类型计算

```typescript
const Counter = ({ count }) => {
  // ❌ 不必要：简单的数学运算
  const doubled = useMemo(() => count * 2, [count]);

  // ✅ 更好：直接计算
  const doubled = count * 2;

  return <Text>{doubled}</Text>;
};
```

#### ❌ 场景 2：小数组的操作

```typescript
const SmallList = ({ items }) => {  // items 只有 5-10 个元素
  // ❌ 过度优化：数组很小，map 操作很快
  const upperCaseNames = useMemo(() => {
    return items.map(item => item.name.toUpperCase());
  }, [items]);

  // ✅ 更好：直接计算
  const upperCaseNames = items.map(item => item.name.toUpperCase());

  return <>{/* ... */}</>;
};
```

#### ❌ 场景 3：计算成本低于 useMemo 开销

```typescript
const UserGreeting = ({ firstName, lastName }) => {
  // ❌ 不必要：字符串拼接的成本很低
  const fullName = useMemo(() => {
    return `${firstName} ${lastName}`;
  }, [firstName, lastName]);

  // ✅ 更好：直接计算
  const fullName = `${firstName} ${lastName}`;

  return <Text>Hello, {fullName}!</Text>;
};
```

### 性能测量方法

不要盲目优化，使用工具测量实际性能：

#### 方法 1：使用 React DevTools Profiler

```typescript
import { Profiler } from 'react';

const MyComponent = () => {
  const onRenderCallback = (
    id,
    phase,
    actualDuration,
    baseDuration,
    startTime,
    commitTime
  ) => {
    console.log(`${id} (${phase}) took ${actualDuration}ms`);
  };

  return (
    <Profiler id="MyComponent" onRender={onRenderCallback}>
      {/* 你的组件 */}
    </Profiler>
  );
};
```

#### 方法 2：使用 console.time

```typescript
const ExpensiveComponent = ({ data }) => {
  const processedData = useMemo(() => {
    console.time('data-processing');
    const result = /* 复杂处理 */;
    console.timeEnd('data-processing');
    return result;
  }, [data]);

  return <>{/* ... */}</>;
};
```

#### 方法 3：比较有无 useMemo 的差异

```typescript
// 测试版本 1：不使用 useMemo
const Version1 = ({ items }) => {
  console.time('without-useMemo');
  const sorted = items.sort((a, b) => a.value - b.value);
  console.timeEnd('without-useMemo');
  // ...
};

// 测试版本 2：使用 useMemo
const Version2 = ({ items }) => {
  const sorted = useMemo(() => {
    console.time('with-useMemo');
    const result = items.sort((a, b) => a.value - b.value);
    console.timeEnd('with-useMemo');
    return result;
  }, [items]);
  // ...
};
```

### 优化决策流程图

```
开始
  ↓
计算是否昂贵？（>10ms）
  ↓ 是                    ↓ 否
使用 useMemo          计算结果是引用类型？
                        ↓ 是            ↓ 否
                      作为 props 传递？   直接计算
                        ↓ 是      ↓ 否     （不用 useMemo）
                      使用 useMemo  可能不需要
```

## 6. 常见错误和解决方案

### 错误 1：在 useMemo 中使用副作用

```typescript
// ❌ 错误：在 useMemo 中执行副作用
const MyComponent = ({ userId }) => {
  const userData = useMemo(() => {
    // ❌ 错误：在 useMemo 中发起网络请求
    fetch(`/api/users/${userId}`).then(res => res.json());
    return null;
  }, [userId]);

  return <>{/* ... */}</>;
};

// ✅ 正确：使用 useEffect 处理副作用
const MyComponent = ({ userId }) => {
  const [userData, setUserData] = useState(null);

  useEffect(() => {
    // ✅ 正确：副作用应该在 useEffect 中
    fetch(`/api/users/${userId}`)
      .then(res => res.json())
      .then(data => setUserData(data));
  }, [userId]);

  return <>{/* ... */}</>;
};
```

**规则：**
useMemo 应该是**纯函数**，不应该有副作用（网络请求、DOM 操作、订阅等）。

### 错误 2：依赖项中包含不稳定的引用

```typescript
// ❌ 错误：对象字面量作为依赖项
const MyComponent = ({ data }) => {
  const options = { sort: 'asc', limit: 10 }; // 每次渲染都是新对象

  const processedData = useMemo(() => {
    return processData(data, options);
  }, [data, options]); // options 每次都不同，useMemo 失效
};

// ✅ 解决方案 1：提取到组件外部
const OPTIONS = { sort: 'asc', limit: 10 };

const MyComponent = ({ data }) => {
  const processedData = useMemo(() => {
    return processData(data, OPTIONS);
  }, [data]); // OPTIONS 是常量，不需要作为依赖项
};

// ✅ 解决方案 2：使用 useMemo 缓存 options
const MyComponent = ({ data }) => {
  const options = useMemo(
    () => ({
      sort: 'asc',
      limit: 10,
    }),
    [],
  );

  const processedData = useMemo(() => {
    return processData(data, options);
  }, [data, options]);
};

// ✅ 解决方案 3：内联使用，不作为依赖项
const MyComponent = ({ data }) => {
  const processedData = useMemo(() => {
    const options = { sort: 'asc', limit: 10 };
    return processData(data, options);
  }, [data]);
};
```

### 错误 3：过度使用 useMemo

```typescript
// ❌ 错误：到处都是 useMemo
const OverOptimizedComponent = ({ a, b, c }) => {
  const sum = useMemo(() => a + b, [a, b]);  // ❌ 不必要
  const product = useMemo(() => a * b, [a, b]);  // ❌ 不必要
  const isEven = useMemo(() => sum % 2 === 0, [sum]);  // ❌ 不必要
  const message = useMemo(() => `Sum is ${sum}`, [sum]);  // ❌ 不必要

  return <Text>{message}</Text>;
};

// ✅ 正确：只优化必要的地方
const OptimizedComponent = ({ a, b, c }) => {
  const sum = a + b;  // ✅ 直接计算
  const product = a * b;  // ✅ 直接计算
  const isEven = sum % 2 === 0;  // ✅ 直接计算
  const message = `Sum is ${sum}`;  // ✅ 直接计算

  return <Text>{message}</Text>;
};
```

**原则：** 默认不使用 useMemo，只在确实需要时才使用。

### 错误 4：依赖项包含函数但未用 useCallback

```typescript
// ❌ 问题：formatter 每次都是新函数
const DataList = ({ data }) => {
  const formatter = (item) => item.name.toUpperCase();

  const formattedData = useMemo(() => {
    return data.map(formatter);
  }, [data, formatter]);  // formatter 每次都变化，useMemo 失效

  return <>{/* ... */}</>;
};

// ✅ 解决方案 1：在 useMemo 内部定义函数
const DataList = ({ data }) => {
  const formattedData = useMemo(() => {
    const formatter = (item) => item.name.toUpperCase();
    return data.map(formatter);
  }, [data]);

  return <>{/* ... */}</>;
};

// ✅ 解决方案 2：使用 useCallback 缓存函数
const DataList = ({ data }) => {
  const formatter = useCallback(
    (item) => item.name.toUpperCase(),
    []
  );

  const formattedData = useMemo(() => {
    return data.map(formatter);
  }, [data, formatter]);

  return <>{/* ... */}</>;
};
```

### 错误 5：返回值被立即解构/修改

```typescript
// ❌ 问题：返回的对象立即被修改，失去引用稳定性
const MyComponent = ({ items }) => {
  const sortedItems = useMemo(() => {
    return [...items].sort();
  }, [items]);

  // ❌ 修改了 memoized 的数组
  sortedItems.push({ id: 'new' });

  return <>{/* ... */}</>;
};

// ✅ 解决方案：不要修改 useMemo 返回的值
const MyComponent = ({ items }) => {
  const sortedItems = useMemo(() => {
    return [...items].sort();
  }, [items]);

  // ✅ 如果需要修改，创建新副本
  const modifiedItems = [...sortedItems, { id: 'new' }];

  return <>{/* ... */}</>;
};
```

## 7. 进阶技巧和模式

### 技巧 1：链式 useMemo

多个 useMemo 可以形成依赖链：

```typescript
const DataPipeline = ({ rawData, filterType, sortField }) => {
  // 第一步：过滤
  const filteredData = useMemo(() => {
    console.log('Filtering...');
    return rawData.filter(item => item.type === filterType);
  }, [rawData, filterType]);

  // 第二步：排序（依赖第一步的结果）
  const sortedData = useMemo(() => {
    console.log('Sorting...');
    return [...filteredData].sort((a, b) =>
      a[sortField] > b[sortField] ? 1 : -1
    );
  }, [filteredData, sortField]);

  // 第三步：格式化（依赖第二步的结果）
  const formattedData = useMemo(() => {
    console.log('Formatting...');
    return sortedData.map(item => ({
      ...item,
      displayName: `${item.name} (${item.type})`,
    }));
  }, [sortedData]);

  return <DataTable data={formattedData} />;
};
```

**优势：** 当只有部分条件变化时，只会重新执行必要的步骤。

### 技巧 2：与 React.memo 配合使用

```typescript
// 子组件使用 React.memo 优化
const ExpensiveChild = React.memo(({ data, config }) => {
  console.log('ExpensiveChild rendering');
  return (
    <Box>
      {data.map(item => <Text key={item.id}>{item.name}</Text>)}
    </Box>
  );
});

const ParentComponent = ({ items, theme }) => {
  const [count, setCount] = useState(0);

  // ✅ 使用 useMemo 保持 config 引用稳定
  const config = useMemo(() => ({
    theme,
    showBorder: true,
  }), [theme]);

  // ✅ 使用 useMemo 保持 data 引用稳定
  const processedData = useMemo(() => {
    return items.slice(0, 10);
  }, [items]);

  return (
    <Box>
      <Button onClick={() => setCount(count + 1)}>
        Count: {count}
      </Button>
      {/* count 变化时，ExpensiveChild 不会重新渲染 */}
      <ExpensiveChild data={processedData} config={config} />
    </Box>
  );
};
```

### 技巧 3：在自定义 Hook 中使用

```typescript
// 自定义 Hook：useFilteredAndSortedData
const useFilteredAndSortedData = (data, filterFn, sortFn) => {
  const filteredData = useMemo(() => {
    return data.filter(filterFn);
  }, [data, filterFn]);

  const sortedData = useMemo(() => {
    return [...filteredData].sort(sortFn);
  }, [filteredData, sortFn]);

  return sortedData;
};

// 使用自定义 Hook
const MyComponent = ({ items }) => {
  const filterFn = useCallback(
    item => item.active,
    []
  );

  const sortFn = useCallback(
    (a, b) => a.name.localeCompare(b.name),
    []
  );

  const processedItems = useFilteredAndSortedData(
    items,
    filterFn,
    sortFn
  );

  return <>{/* ... */}</>;
};
```

### 技巧 4：条件性记忆化

```typescript
const ConditionalMemo = ({ data, shouldOptimize }) => {
  // 根据条件决定是否使用 useMemo
  const processedData = shouldOptimize
    ? useMemo(() => expensiveProcessing(data), [data])
    : expensiveProcessing(data);

  return <>{/* ... */}</>;
};
```

**注意：**
这违反了 Hook 的规则（条件调用），实际中不推荐。更好的做法是始终使用 useMemo，或者始终不使用。

### 技巧 5：使用 useMemo 实现计算属性模式

```typescript
const UserProfile = ({ user }) => {
  // 类似 Vue 的计算属性
  const computed = useMemo(() => ({
    // 计算属性 1：全名
    fullName: `${user.firstName} ${user.lastName}`,

    // 计算属性 2：年龄
    age: new Date().getFullYear() - user.birthYear,

    // 计算属性 3：是否成年
    isAdult: (new Date().getFullYear() - user.birthYear) >= 18,

    // 计算属性 4：显示名称
    displayName: user.nickname || `${user.firstName} ${user.lastName}`,
  }), [user]);

  return (
    <Box>
      <Text>Name: {computed.fullName}</Text>
      <Text>Age: {computed.age}</Text>
      {computed.isAdult && <Text>Adult</Text>}
      <Text>Display: {computed.displayName}</Text>
    </Box>
  );
};
```

### 技巧 6：优化 Context 性能

```typescript
// 分离频繁变化和不常变化的 Context

// Context 1：不常变化的配置
const ConfigContext = createContext();

const ConfigProvider = ({ children }) => {
  const [theme, setTheme] = useState('dark');

  // ✅ 配置对象使用 useMemo
  const configValue = useMemo(() => ({
    theme,
    setTheme,
  }), [theme]);

  return (
    <ConfigContext.Provider value={configValue}>
      {children}
    </ConfigContext.Provider>
  );
};

// Context 2：频繁变化的状态
const StateContext = createContext();

const StateProvider = ({ children }) => {
  const [count, setCount] = useState(0);

  // ✅ 使用 useMemo，但 count 经常变化
  const stateValue = useMemo(() => ({
    count,
    setCount,
  }), [count]);

  return (
    <StateContext.Provider value={stateValue}>
      {children}
    </StateContext.Provider>
  );
};

// 组件只订阅需要的 Context
const CountDisplay = () => {
  const { count } = useContext(StateContext);  // 只在 count 变化时更新
  return <Text>{count}</Text>;
};

const ThemeDisplay = () => {
  const { theme } = useContext(ConfigContext);  // 只在 theme 变化时更新
  return <Text>{theme}</Text>;
};
```

## 8. 调试技巧

### 技巧 1：添加日志追踪重新计算

```typescript
const MyComponent = ({ data }) => {
  const processedData = useMemo(() => {
    console.log('🔄 useMemo: recalculating processedData');
    console.log('📊 Data length:', data.length);
    const result = expensiveProcessing(data);
    console.log('✅ useMemo: calculation complete');
    return result;
  }, [data]);

  return <>{/* ... */}</>;
};
```

### 技巧 2：使用自定义 Hook 监控 useMemo

```typescript
const useMonitoredMemo = (factory, deps, label) => {
  const renderCount = useRef(0);
  const memoCount = useRef(0);

  renderCount.current++;

  const value = useMemo(() => {
    memoCount.current++;
    console.log(
      `[${label}] Memo recalculated (${memoCount.current}/${renderCount.current})`
    );
    return factory();
  }, deps);

  return value;
};

// 使用示例
const MyComponent = ({ data }) => {
  const sortedData = useMonitoredMemo(
    () => [...data].sort(),
    [data],
    'sortedData'
  );

  return <>{/* ... */}</>;
};
```

### 技巧 3：使用 React DevTools

1. 打开 React DevTools
2. 选择 Profiler 标签
3. 点击录制按钮
4. 与应用交互
5. 查看组件渲染次数和时间
6. 识别不必要的重新渲染

### 技巧 4：依赖项变化检测

```typescript
const useWhyDidYouUpdate = (name, props) => {
  const previousProps = useRef();

  useEffect(() => {
    if (previousProps.current) {
      const allKeys = Object.keys({ ...previousProps.current, ...props });
      const changedProps = {};

      allKeys.forEach(key => {
        if (previousProps.current[key] !== props[key]) {
          changedProps[key] = {
            from: previousProps.current[key],
            to: props[key],
          };
        }
      });

      if (Object.keys(changedProps).length > 0) {
        console.log('[why-did-you-update]', name, changedProps);
      }
    }

    previousProps.current = props;
  });
};

// 使用示例
const MyComponent = ({ data, filter, sort }) => {
  useWhyDidYouUpdate('MyComponent', { data, filter, sort });

  const processedData = useMemo(() => {
    return data.filter(filter).sort(sort);
  }, [data, filter, sort]);

  return <>{/* ... */}</>;
};
```

## 9. 实战练习建议

### 练习 1：优化列表过滤和排序

创建一个产品列表组件，实现：

- 按类别过滤
- 按价格排序
- 搜索功能
- 使用 useMemo 优化性能

```typescript
const ProductList = ({ products }) => {
  const [category, setCategory] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [searchTerm, setSearchTerm] = useState('');

  // TODO: 实现 filteredProducts 使用 useMemo
  // TODO: 实现 sortedProducts 使用 useMemo
  // TODO: 实现 searchResults 使用 useMemo

  return (
    <Box>
      {/* UI 实现 */}
    </Box>
  );
};
```

### 练习 2：优化购物车总价计算

创建购物车组件，计算：

- 商品总价
- 折扣金额
- 税费
- 最终价格

```typescript
const ShoppingCart = ({ items, discountRate, taxRate }) => {
  // TODO: 使用 useMemo 计算 subtotal
  // TODO: 使用 useMemo 计算 discount
  // TODO: 使用 useMemo 计算 tax
  // TODO: 使用 useMemo 计算 total

  return (
    <Box>
      {/* 显示价格明细 */}
    </Box>
  );
};
```

### 练习 3：优化表格数据处理

创建可分页、可排序的表格组件：

```typescript
const DataTable = ({ data }) => {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [sortField, setSortField] = useState('id');
  const [sortOrder, setSortOrder] = useState('asc');

  // TODO: 实现排序逻辑（使用 useMemo）
  // TODO: 实现分页逻辑（使用 useMemo）
  // TODO: 实现统计信息（使用 useMemo）

  return (
    <Box>
      {/* 表格 UI */}
    </Box>
  );
};
```

### 练习 4：优化 Context Provider

创建一个主题系统，包含：

- 主题配置（颜色、字体等）
- 主题切换功能
- 使用 useMemo 优化 Context value

```typescript
const ThemeProvider = ({ children }) => {
  const [themeName, setThemeName] = useState('light');

  // TODO: 使用 useMemo 创建 theme 对象
  // TODO: 使用 useMemo 创建 Context value

  return (
    <ThemeContext.Provider value={/* ... */}>
      {children}
    </ThemeContext.Provider>
  );
};
```

## 10. 学习检查清单

完成本教程后，您应该能够：

- [ ] 解释 useMemo 的工作原理
- [ ] 区分 useMemo 和 useCallback 的使用场景
- [ ] 正确指定依赖项数组
- [ ] 识别何时应该使用 useMemo
- [ ] 识别何时不应该使用 useMemo（避免过度优化）
- [ ] 在实际项目中应用 useMemo 优化性能
- [ ] 使用 useMemo 保持引用稳定性
- [ ] 在 Context Provider 中正确使用 useMemo
- [ ] 调试 useMemo 相关的问题
- [ ] 使用链式 useMemo 处理复杂的数据流

## 11. 总结

### 核心要点回顾

1. **useMemo 的本质**
   - 缓存计算结果，而不是函数本身
   - 只在依赖项变化时重新计算
   - 是性能优化工具，不是业务逻辑工具

2. **主要使用场景**
   - 昂贵的计算（排序、过滤、聚合）
   - 保持引用稳定性（对象、数组）
   - 作为其他 Hook 的依赖项
   - 优化 Context Provider

3. **与 useCallback 的关系**
   - useCallback 是 useMemo 的特殊情况
   - `useCallback(fn, deps)` 等价于 `useMemo(() => fn, deps)`
   - useCallback 用于函数，useMemo 用于值

4. **最佳实践**
   - 默认不使用，只在需要时使用
   - 正确指定依赖项（使用 ESLint 插件）
   - 测量性能，避免盲目优化
   - 不在 useMemo 中执行副作用

5. **常见陷阱**
   - 遗漏依赖项
   - 依赖项中包含不稳定的引用
   - 过度使用导致代码复杂化
   - 在计算函数中执行副作用

### 进阶学习资源

- [React 官方文档 - useMemo](https://react.dev/reference/react/useMemo)
- [React 官方文档 - useCallback](https://react.dev/reference/react/useCallback)
- [When to useMemo and useCallback](https://kentcdodds.com/blog/usememo-and-usecallback)
- [React DevTools Profiler](https://react.dev/learn/react-developer-tools)

### 下一步学习

现在您已经掌握了 `useMemo`，可以继续学习：

- `useRef` - 持久化引用和访问 DOM
- `useReducer` - 复杂状态管理
- `useImperativeHandle` - 自定义暴露给父组件的实例值
- `useLayoutEffect` - 同步的副作用执行
- 自定义 Hooks - 封装可复用的逻辑

## 附录：快速参考

### useMemo 语法模板

```typescript
// 基本用法
const value = useMemo(() => computeValue(), [dependency]);

// 返回对象
const config = useMemo(() => ({ key: value }), [value]);

// 返回数组
const list = useMemo(() => [...items], [items]);

// 复杂计算
const result = useMemo(() => {
  const intermediate = process(data);
  return transform(intermediate);
}, [data]);

// 链式调用
const step1 = useMemo(() => filter(data), [data]);
const step2 = useMemo(() => sort(step1), [step1]);
```

### 常见模式速查

| 模式          | 代码示例                                       |
| ------------- | ---------------------------------------------- |
| 过滤数组      | `useMemo(() => arr.filter(fn), [arr])`         |
| 排序数组      | `useMemo(() => [...arr].sort(fn), [arr])`      |
| 映射数组      | `useMemo(() => arr.map(fn), [arr])`            |
| 聚合计算      | `useMemo(() => arr.reduce(fn, init), [arr])`   |
| 创建对象      | `useMemo(() => ({ key: val }), [val])`         |
| 创建数组      | `useMemo(() => [...arr], [arr])`               |
| 链式操作      | `useMemo(() => arr.filter().sort(), [arr])`    |
| Context value | `useMemo(() => ({ state, actions }), [state])` |

### 决策树

```
需要优化吗？
├─ 是 → 是计算结果还是函数？
│       ├─ 计算结果 → 使用 useMemo
│       └─ 函数 → 使用 useCallback
└─ 否 → 直接计算
```

---

**版本：** 1.0  
**最后更新：** 2025年10月  
**基于项目：** Gemini CLI (gemini-cli)
