# React useCallback Hook 入门教程

## 教程目标

本教程基于 Gemini CLI 项目中的真实代码，为已经了解 `useState`、`useEffect` 和
`useContext` 的 React 初学者提供一份全面的 `useCallback`
Hook 学习指南。通过分析实际项目中的代码示例，您将学会：

- 理解 useCallback 的工作原理和使用场景
- 掌握如何正确使用 useCallback 优化组件性能
- 避免常见的 useCallback 使用错误
- 学习 useCallback 与其他 Hooks 的配合使用

## 前置知识

在学习本教程之前，您应该已经了解：

- ✅ `useState` - 管理组件状态
- ✅ `useEffect` - 处理副作用
- ✅ `useContext` - 使用 Context API
- ✅ JavaScript 基础语法和函数概念

## 1. useCallback 基础概念

### 什么是 useCallback？

`useCallback`
是 React 提供的一个 Hook，用于**缓存（记忆化）函数**。它返回一个记忆化的回调函数，只有在依赖项发生变化时才会重新创建这个函数。

**官方定义：**

```typescript
const memoizedCallback = useCallback(
  () => {
    // 你的函数逻辑
  },
  [dependencies], // 依赖项数组
);
```

### 为什么需要 useCallback？

在理解 useCallback 之前，我们需要先理解 JavaScript 中的一个重要概念：**函数引用**。

#### JavaScript 中的函数引用

在 JavaScript 中，每次创建函数时都会生成一个新的函数引用：

```javascript
// 每次调用 createHandler 都会创建一个新函数
function createHandler() {
  const handler = () => {
    console.log('Hello');
  };
  return handler;
}

const handler1 = createHandler();
const handler2 = createHandler();

console.log(handler1 === handler2); // false - 不是同一个函数引用
```

#### React 组件重新渲染时的问题

在 React 中，每次组件重新渲染时，组件函数会重新执行，导致内部定义的所有函数都会被重新创建：

```typescript
const MyComponent = () => {
  const [count, setCount] = useState(0);

  // ❌ 问题：每次 MyComponent 重新渲染时，handleClick 都会被重新创建
  const handleClick = () => {
    console.log('Clicked!');
  };

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Button onClick={handleClick}>Click me</Button>
    </Box>
  );
};
```

这会导致两个问题：

1. **子组件不必要的重新渲染**：如果 `handleClick`
   作为 prop 传递给子组件，子组件会因为接收到"新"函数而重新渲染
2. **useEffect 的依赖问题**：如果函数作为 useEffect 的依赖项，会导致 useEffect 频繁执行

### 对比：使用和不使用 useCallback

#### 不使用 useCallback（每次渲染都创建新函数）

```typescript
const ParentComponent = () => {
  const [count, setCount] = useState(0);

  // ❌ 每次 ParentComponent 重新渲染，handleClick 都是新函数
  const handleClick = () => {
    console.log('Clicked!');
  };

  return (
    <Box>
      <Text>Count: {count}</Text>
      {/* 每次 count 改变，ChildComponent 都会重新渲染 */}
      <ChildComponent onClick={handleClick} />
    </Box>
  );
};
```

#### 使用 useCallback（缓存函数引用）

```typescript
const ParentComponent = () => {
  const [count, setCount] = useState(0);

  // ✅ 使用 useCallback，handleClick 的引用保持不变
  const handleClick = useCallback(() => {
    console.log('Clicked!');
  }, []); // 空依赖数组表示函数永远不会改变

  return (
    <Box>
      <Text>Count: {count}</Text>
      {/* count 改变时，ChildComponent 不会重新渲染 */}
      <ChildComponent onClick={handleClick} />
    </Box>
  );
};
```

## 2. useCallback 的语法和参数

### 基本语法

```typescript
const memoizedFunction = useCallback(
  callbackFunction, // 第一个参数：要缓存的函数
  dependencies, // 第二个参数：依赖项数组
);
```

### 参数详解

#### 第一个参数：要缓存的函数

这是你想要缓存的函数。可以是任何类型的函数：

```typescript
// 箭头函数
const handler = useCallback(() => {
  console.log('Hello');
}, []);

// 带参数的函数
const handler = useCallback((value: string) => {
  console.log(value);
}, []);

// 异步函数
const handler = useCallback(async () => {
  const data = await fetchData();
  return data;
}, []);
```

#### 第二个参数：依赖项数组

依赖项数组决定了函数何时需要重新创建：

```typescript
const [count, setCount] = useState(0);
const [name, setName] = useState('Alice');

// 1. 空数组：函数永远不会改变
const handler1 = useCallback(() => {
  console.log('This never changes');
}, []);

// 2. 依赖 count：只有 count 改变时函数才会重新创建
const handler2 = useCallback(() => {
  console.log(`Count is: ${count}`);
}, [count]);

// 3. 依赖多个值
const handler3 = useCallback(() => {
  console.log(`${name}'s count is: ${count}`);
}, [name, count]);
```

### 返回值：记忆化的函数引用

`useCallback`
返回一个记忆化的函数引用。只要依赖项不变，返回的函数引用就保持不变：

```typescript
const memoizedFn = useCallback(() => {
  console.log('Hello');
}, []);

// memoizedFn 在组件的整个生命周期中保持相同的引用
```

### 简单完整示例

```typescript
import { useState, useCallback } from 'react';
import { Box, Text } from 'ink';

const Counter = () => {
  const [count, setCount] = useState(0);

  // 使用 useCallback 缓存增加函数
  const increment = useCallback(() => {
    setCount(prev => prev + 1);
  }, []); // 空数组：函数不依赖任何外部变量

  // 使用 useCallback 缓存重置函数
  const reset = useCallback(() => {
    setCount(0);
  }, []); // 空数组：函数不依赖任何外部变量

  return (
    <Box flexDirection="column">
      <Text>Count: {count}</Text>
      <Text onPress={increment}>Increment</Text>
      <Text onPress={reset}>Reset</Text>
    </Box>
  );
};
```

## 3. 使用场景详解

### 场景 1：作为子组件的 props 传递

这是 useCallback 最常见的使用场景。当函数作为 prop 传递给使用 `React.memo`
优化的子组件时，使用 useCallback 可以避免子组件不必要的重新渲染。

#### 问题说明

```typescript
// ❌ 问题示例
const ParentComponent = () => {
  const [count, setCount] = useState(0);

  // 每次父组件渲染，handleClick 都是新函数
  const handleClick = () => {
    console.log('Button clicked');
  };

  return (
    <Box>
      <Text>Count: {count}</Text>
      {/* 即使 ExpensiveChild 用了 React.memo，仍会重新渲染 */}
      <ExpensiveChild onClick={handleClick} />
    </Box>
  );
};

// 使用 React.memo 优化的子组件
const ExpensiveChild = React.memo(({ onClick }) => {
  console.log('ExpensiveChild rendered'); // 每次都会打印
  return <Text onPress={onClick}>Click me</Text>;
});
```

#### 实战示例：主题对话框（来自 Gemini CLI）

让我们看一个来自 Gemini
CLI 项目的真实示例，展示如何使用 useCallback 优化主题选择功能：

```typescript
// 来自 packages/cli/src/ui/hooks/useThemeCommand.ts
import { useState, useCallback } from 'react';

export const useThemeCommand = (
  loadedSettings: LoadedSettings,
  setThemeError: (error: string | null) => void,
  addItem: (item: Omit<HistoryItem, 'id'>, timestamp: number) => void,
  initialThemeError: string | null,
) => {
  const [isThemeDialogOpen, setIsThemeDialogOpen] =
    useState(!!initialThemeError);

  // ✅ 使用 useCallback：openThemeDialog 只依赖 addItem
  // 只有 addItem 改变时，这个函数才会重新创建
  const openThemeDialog = useCallback(() => {
    if (process.env['NO_COLOR']) {
      addItem(
        {
          type: MessageType.INFO,
          text: 'Theme configuration unavailable due to NO_COLOR env variable.',
        },
        Date.now(),
      );
      return;
    }
    setIsThemeDialogOpen(true);
  }, [addItem]); // 依赖项：只有 addItem

  // ✅ applyTheme 函数只依赖 setThemeError
  const applyTheme = useCallback(
    (themeName: string | undefined) => {
      if (!themeManager.setActiveTheme(themeName)) {
        setIsThemeDialogOpen(true);
        setThemeError(`Theme "${themeName}" not found.`);
      } else {
        setThemeError(null);
      }
    },
    [setThemeError], // 依赖项：只有 setThemeError
  );

  // ✅ handleThemeHighlight 依赖 applyTheme
  const handleThemeHighlight = useCallback(
    (themeName: string | undefined) => {
      applyTheme(themeName);
    },
    [applyTheme], // 依赖项：applyTheme 函数
  );

  // ✅ closeThemeDialog 依赖 applyTheme 和 loadedSettings
  const closeThemeDialog = useCallback(() => {
    // 重新应用保存的主题以恢复预览更改
    applyTheme(loadedSettings.merged.ui?.theme);
    setIsThemeDialogOpen(false);
  }, [applyTheme, loadedSettings]); // 依赖项：applyTheme 和 loadedSettings

  return {
    isThemeDialogOpen,
    openThemeDialog,
    closeThemeDialog,
    handleThemeSelect,
    handleThemeHighlight,
  };
};
```

**关键点：**

1. `openThemeDialog` 只依赖 `addItem`，所以只有 `addItem` 改变时才会重新创建
2. `applyTheme` 只依赖 `setThemeError`
3. `handleThemeHighlight` 依赖 `applyTheme`，形成了函数依赖链
4. 这些函数会被传递给子组件作为 props，使用 useCallback 避免不必要的子组件渲染

### 场景 2：作为 useEffect 的依赖

当函数作为 `useEffect`
的依赖项时，如果不使用 useCallback，会导致 useEffect 在每次渲染时都执行。

#### 问题示例

```typescript
// ❌ 问题：无限循环
const ProblemComponent = () => {
  const [data, setData] = useState(null);

  // 每次渲染都创建新函数
  const fetchData = () => {
    fetch('/api/data')
      .then(res => res.json())
      .then(setData);
  };

  useEffect(() => {
    fetchData();
  }, [fetchData]); // ❌ fetchData 每次都不同，导致 useEffect 无限循环

  return <Text>{data}</Text>;
};
```

#### 解决方案

```typescript
// ✅ 解决方案：使用 useCallback
const SolutionComponent = () => {
  const [data, setData] = useState(null);

  // 使用 useCallback 缓存函数
  const fetchData = useCallback(() => {
    fetch('/api/data')
      .then(res => res.json())
      .then(setData);
  }, []); // 空数组：函数不依赖任何值

  useEffect(() => {
    fetchData();
  }, [fetchData]); // ✅ fetchData 引用不变，useEffect 只执行一次

  return <Text>{data}</Text>;
};
```

#### 带依赖项的示例

```typescript
const SearchComponent = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  // fetchResults 依赖 query
  const fetchResults = useCallback(() => {
    if (!query) return;

    fetch(`/api/search?q=${query}`)
      .then(res => res.json())
      .then(setResults);
  }, [query]); // 依赖 query，query 改变时函数会重新创建

  useEffect(() => {
    fetchResults();
  }, [fetchResults]); // fetchResults 改变时重新执行搜索

  return (
    <Box flexDirection="column">
      <TextInput value={query} onChange={setQuery} />
      {results.map(item => <Text key={item.id}>{item.name}</Text>)}
    </Box>
  );
};
```

### 场景 3：复杂事件处理器

对于复杂的事件处理逻辑，使用 useCallback 可以避免在每次渲染时重新创建处理函数。

#### 实战示例：键盘事件处理（来自 Gemini CLI）

这是一个来自 Gemini
CLI 的真实示例，展示了如何使用 useCallback 处理复杂的键盘导航：

```typescript
// 来自 packages/cli/src/ui/hooks/useSelectionList.ts（简化版）
export function useSelectionList<T>({
  items,
  initialIndex = 0,
  onSelect,
  isFocused = true,
  showNumbers = false,
}: UseSelectionListOptions<T>) {
  const [activeIndex, setActiveIndex] = useState(initialIndex);
  const itemsLength = items.length;

  // ✅ 使用 useCallback 缓存键盘处理函数
  // 这个函数会被传递给 useKeypress hook，需要稳定的引用
  const handleKeypress = useCallback(
    (key: Key) => {
      const { sequence, name } = key;

      // 处理上下箭头和 vim 风格的 j/k 键
      if (name === 'k' || name === 'up') {
        setActiveIndex((prev) => {
          // 向上移动，支持循环
          return prev > 0 ? prev - 1 : itemsLength - 1;
        });
        return;
      }

      if (name === 'j' || name === 'down') {
        setActiveIndex((prev) => {
          // 向下移动，支持循环
          return prev < itemsLength - 1 ? prev + 1 : 0;
        });
        return;
      }

      // 处理回车键选择
      if (name === 'return') {
        const currentItem = items[activeIndex];
        if (currentItem && !currentItem.disabled) {
          onSelect(currentItem.value);
        }
        return;
      }

      // 处理数字快速选择
      if (showNumbers && /^[0-9]$/.test(sequence)) {
        const targetIndex = Number.parseInt(sequence, 10) - 1;
        if (targetIndex >= 0 && targetIndex < itemsLength) {
          setActiveIndex(targetIndex);
          onSelect(items[targetIndex]!.value);
        }
      }
    },
    [itemsLength, showNumbers, items, activeIndex, onSelect],
    // ☝️ 依赖项包含了函数中使用的所有外部变量
  );

  // 使用 handleKeypress
  useKeypress(handleKeypress, { isActive: !!(isFocused && itemsLength > 0) });

  return { activeIndex, setActiveIndex };
}
```

**关键点：**

1. `handleKeypress` 是一个复杂的事件处理器，包含多个键盘事件的处理逻辑
2. 它被传递给 `useKeypress` hook，需要稳定的函数引用
3. 依赖项数组包含了所有在函数中使用的外部变量
4. 使用 `setActiveIndex(prev => ...)` 的函数式更新避免依赖 `activeIndex`

## 4. 依赖项数组详解

依赖项数组是 useCallback 的核心概念，理解它的工作机制至关重要。

### 依赖项数组的作用机制

React 会在每次渲染时比较依赖项数组中的值：

```typescript
const [count, setCount] = useState(0);
const [name, setName] = useState('Alice');

const handler = useCallback(() => {
  console.log(`${name}: ${count}`);
}, [name, count]);

// 渲染 1: name='Alice', count=0 -> 创建新函数
// 渲染 2: name='Alice', count=1 -> count 改变，创建新函数
// 渲染 3: name='Alice', count=1 -> 无变化，返回上次的函数
// 渲染 4: name='Bob', count=1 -> name 改变，创建新函数
```

### 如何确定应该包含哪些依赖项

**规则：函数中使用的所有外部变量都应该包含在依赖项数组中。**

```typescript
const MyComponent = () => {
  const [count, setCount] = useState(0);
  const [multiplier, setMultiplier] = useState(2);
  const baseValue = 10;

  // ✅ 正确：包含所有使用的外部变量
  const calculate = useCallback(() => {
    return count * multiplier + baseValue;
  }, [count, multiplier, baseValue]);

  // ❌ 错误：遗漏了 multiplier
  const wrongCalculate = useCallback(() => {
    return count * multiplier + baseValue;
  }, [count, baseValue]); // 缺少 multiplier

  return <Text>{calculate()}</Text>;
};
```

### 不需要包含在依赖项中的情况

某些值不需要包含在依赖项数组中：

```typescript
const MyComponent = () => {
  const [count, setCount] = useState(0);

  const handler = useCallback(() => {
    // ✅ setState 函数是稳定的，不需要包含在依赖项中
    setCount(prev => prev + 1);

    // ✅ useRef 返回的 ref.current 也不需要
    const ref = useRef(null);
    console.log(ref.current);
  }, []); // 空数组是正确的

  return <Text onPress={handler}>Increment</Text>;
};
```

### ESLint 规则：react-hooks/exhaustive-deps

React 提供了 ESLint 规则来帮助你正确设置依赖项：

```typescript
// ESLint 会警告你遗漏的依赖项
const handler = useCallback(() => {
  console.log(count); // ESLint: 'count' should be included in dependencies
}, []); // ⚠️ 警告：count 应该包含在依赖项中
```

**建议：始终听从 ESLint 的警告，不要随意禁用这个规则。**

### 常见错误示例

#### 错误 1：遗漏依赖项

```typescript
// ❌ 错误：count 没有包含在依赖项中
const [count, setCount] = useState(0);
const handler = useCallback(() => {
  console.log(`Count is: ${count}`); // 使用了 count
}, []); // 但依赖项是空数组

// 问题：handler 永远打印初始值 0，即使 count 改变了
```

#### 错误 2：依赖项过多

```typescript
// ❌ 不好：不必要的依赖项
const [count, setCount] = useState(0);
const [name, setName] = useState('Alice');

const increment = useCallback(() => {
  setCount((prev) => prev + 1); // 只改变 count
}, [count, name]); // ❌ name 是不必要的依赖项
```

#### 错误 3：对象和数组依赖

```typescript
// ❌ 问题：对象每次都是新的引用
const MyComponent = () => {
  const config = { threshold: 10 }; // 每次渲染都是新对象

  const handler = useCallback(() => {
    console.log(config.threshold);
  }, [config]); // ❌ config 每次都不同，useCallback 失效
};

// ✅ 解决方案 1：只依赖需要的属性
const MyComponent = () => {
  const config = { threshold: 10 };

  const handler = useCallback(() => {
    console.log(config.threshold);
  }, [config.threshold]); // ✅ 只依赖 threshold 值
};

// ✅ 解决方案 2：将对象提升到组件外部
const CONFIG = { threshold: 10 }; // 组件外部的常量

const MyComponent = () => {
  const handler = useCallback(() => {
    console.log(CONFIG.threshold);
  }, []); // ✅ CONFIG 是常量，不需要依赖
};
```

## 5. 实战案例深度分析

### 案例 1：主题管理系统（完整版）

让我们深入分析 Gemini CLI 中完整的主题管理 hook：

```typescript
// 完整的 useThemeCommand hook
export const useThemeCommand = (
  loadedSettings: LoadedSettings,
  setThemeError: (error: string | null) => void,
  addItem: (item: Omit<HistoryItem, 'id'>, timestamp: number) => void,
  initialThemeError: string | null,
): UseThemeCommandReturn => {
  // 状态：控制主题对话框是否打开
  const [isThemeDialogOpen, setIsThemeDialogOpen] =
    useState(!!initialThemeError);

  // 函数 1：打开主题对话框
  // 依赖项：[addItem]
  // 为什么：函数内部调用了 addItem，需要访问最新的 addItem 引用
  const openThemeDialog = useCallback(() => {
    // 检查是否禁用了颜色输出
    if (process.env['NO_COLOR']) {
      // 使用 addItem 添加提示消息
      addItem(
        {
          type: MessageType.INFO,
          text: 'Theme configuration unavailable due to NO_COLOR env variable.',
        },
        Date.now(),
      );
      return;
    }
    // 打开对话框
    setIsThemeDialogOpen(true);
  }, [addItem]); // 只依赖 addItem

  // 函数 2：应用主题
  // 依赖项：[setThemeError]
  // 为什么：需要调用 setThemeError 来设置错误状态
  const applyTheme = useCallback(
    (themeName: string | undefined) => {
      // 尝试设置主题
      if (!themeManager.setActiveTheme(themeName)) {
        // 主题不存在，显示错误
        setIsThemeDialogOpen(true);
        setThemeError(`Theme "${themeName}" not found.`);
      } else {
        // 成功，清除错误
        setThemeError(null);
      }
    },
    [setThemeError], // 只依赖 setThemeError
  );

  // 函数 3：处理主题高亮（预览）
  // 依赖项：[applyTheme]
  // 为什么：内部调用了 applyTheme 函数
  const handleThemeHighlight = useCallback(
    (themeName: string | undefined) => {
      applyTheme(themeName);
    },
    [applyTheme], // 依赖另一个 useCallback 函数
  );

  // 函数 4：关闭对话框
  // 依赖项：[applyTheme, loadedSettings]
  // 为什么：需要 applyTheme 和 loadedSettings 来恢复保存的主题
  const closeThemeDialog = useCallback(() => {
    // 恢复保存的主题（撤销预览）
    applyTheme(loadedSettings.merged.ui?.theme);
    setIsThemeDialogOpen(false);
  }, [applyTheme, loadedSettings]);

  // 函数 5：处理主题选择
  // 依赖项：[applyTheme, loadedSettings, setThemeError]
  // 为什么：需要所有这些来验证和应用选择的主题
  const handleThemeSelect = useCallback(
    (themeName: string, scope: SettingScope) => {
      try {
        // 合并用户和工作区的自定义主题
        const mergedCustomThemes = {
          ...(loadedSettings.user.settings.ui?.customThemes || {}),
          ...(loadedSettings.workspace.settings.ui?.customThemes || {}),
        };

        // 验证主题是否存在
        const isBuiltIn = themeManager.findThemeByName(themeName);
        const isCustom = themeName && mergedCustomThemes[themeName];

        if (!isBuiltIn && !isCustom) {
          setThemeError(`Theme "${themeName}" not found in selected scope.`);
          setIsThemeDialogOpen(true);
          return;
        }

        // 保存主题设置
        loadedSettings.setValue(scope, 'ui.theme', themeName);

        // 加载自定义主题
        if (loadedSettings.merged.ui?.customThemes) {
          themeManager.loadCustomThemes(loadedSettings.merged.ui?.customThemes);
        }

        // 应用主题
        applyTheme(loadedSettings.merged.ui?.theme);
        setThemeError(null);
      } finally {
        // 关闭对话框
        setIsThemeDialogOpen(false);
      }
    },
    [applyTheme, loadedSettings, setThemeError],
  );

  // 返回所有函数供外部使用
  return {
    isThemeDialogOpen,
    openThemeDialog,
    closeThemeDialog,
    handleThemeSelect,
    handleThemeHighlight,
  };
};
```

**架构设计亮点：**

1. **函数分层**：`applyTheme` 是基础函数，其他函数依赖它
2. **最小依赖**：每个函数只依赖真正需要的值
3. **函数复用**：多个函数复用 `applyTheme`，形成清晰的依赖链
4. **状态封装**：所有状态和函数都封装在自定义 hook 中

### 案例 2：键盘选择器（简化实用版）

让我们创建一个简化但实用的列表选择器示例：

```typescript
import { useState, useCallback } from 'react';
import { Box, Text } from 'ink';

interface SelectionItem {
  id: string;
  label: string;
  value: any;
}

interface UseSimpleListOptions {
  items: SelectionItem[];
  onSelect: (value: any) => void;
}

function useSimpleList({ items, onSelect }: UseSimpleListOptions) {
  const [activeIndex, setActiveIndex] = useState(0);

  // ✅ 移动到上一项
  // 依赖项：[items.length]
  // 为什么：需要知道列表长度来实现循环
  const moveUp = useCallback(() => {
    setActiveIndex(prev => {
      // 如果在第一项，循环到最后一项
      return prev > 0 ? prev - 1 : items.length - 1;
    });
  }, [items.length]);

  // ✅ 移动到下一项
  // 依赖项：[items.length]
  const moveDown = useCallback(() => {
    setActiveIndex(prev => {
      // 如果在最后一项，循环到第一项
      return prev < items.length - 1 ? prev + 1 : 0;
    });
  }, [items.length]);

  // ✅ 选择当前项
  // 依赖项：[items, activeIndex, onSelect]
  // 为什么：需要访问当前选中的项并调用 onSelect
  const selectCurrent = useCallback(() => {
    const currentItem = items[activeIndex];
    if (currentItem) {
      onSelect(currentItem.value);
    }
  }, [items, activeIndex, onSelect]);

  // ✅ 通过键盘处理导航
  // 依赖项：[moveUp, moveDown, selectCurrent]
  // 为什么：内部调用了这些函数
  const handleKeyPress = useCallback((key: string) => {
    switch (key) {
      case 'up':
      case 'k':
        moveUp();
        break;
      case 'down':
      case 'j':
        moveDown();
        break;
      case 'return':
        selectCurrent();
        break;
    }
  }, [moveUp, moveDown, selectCurrent]);

  return {
    activeIndex,
    handleKeyPress,
  };
}

// 使用示例
const SelectionList = () => {
  const items = [
    { id: '1', label: 'Option 1', value: 'opt1' },
    { id: '2', label: 'Option 2', value: 'opt2' },
    { id: '3', label: 'Option 3', value: 'opt3' },
  ];

  const handleSelect = useCallback((value: string) => {
    console.log('Selected:', value);
  }, []);

  const { activeIndex, handleKeyPress } = useSimpleList({
    items,
    onSelect: handleSelect,
  });

  return (
    <Box flexDirection="column">
      {items.map((item, index) => (
        <Text
          key={item.id}
          color={index === activeIndex ? 'green' : 'white'}
        >
          {index === activeIndex ? '> ' : '  '}
          {item.label}
        </Text>
      ))}
      <Text dimColor>Use ↑↓ or j/k to navigate, Enter to select</Text>
    </Box>
  );
};
```

**设计要点：**

1. **分离关注点**：每个函数负责单一功能
2. **函数组合**：`handleKeyPress` 组合了其他导航函数
3. **依赖链管理**：清晰的函数依赖关系
4. **性能优化**：避免不必要的函数重新创建

## 6. useCallback vs useMemo

`useCallback` 和 `useMemo` 都是记忆化 Hook，但它们缓存的内容不同。

### 核心区别

```typescript
// useCallback：缓存函数本身
const memoizedFunction = useCallback(() => {
  return a + b;
}, [a, b]);

// useMemo：缓存函数的返回值
const memoizedValue = useMemo(() => {
  return a + b;
}, [a, b]);
```

### 详细对比

```typescript
const MyComponent = () => {
  const [count, setCount] = useState(0);

  // useCallback：返回函数引用
  const handleClick = useCallback(() => {
    console.log(count);
  }, [count]);
  // handleClick 是一个函数，需要调用：handleClick()

  // useMemo：返回计算结果
  const doubleCount = useMemo(() => {
    return count * 2;
  }, [count]);
  // doubleCount 是一个值，直接使用：doubleCount

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Text>Double: {doubleCount}</Text> {/* 直接使用值 */}
      <Text onPress={handleClick}>Click</Text> {/* 传递函数 */}
    </Box>
  );
};
```

### 等价关系

实际上，`useCallback` 可以用 `useMemo` 实现：

```typescript
// 这两个是等价的：
const fn1 = useCallback(() => {
  console.log('Hello');
}, []);

const fn2 = useMemo(() => {
  return () => {
    console.log('Hello');
  };
}, []);
```

### 使用场景对比

| 使用场景            | useCallback | useMemo |
| ------------------- | ----------- | ------- |
| 缓存函数引用        | ✅          | ❌      |
| 缓存计算结果        | ❌          | ✅      |
| 传递给子组件的回调  | ✅          | ❌      |
| 昂贵的计算          | ❌          | ✅      |
| 作为 useEffect 依赖 | ✅          | ❌      |
| 复杂对象的创建      | ❌          | ✅      |

### 实际示例对比

```typescript
const DataTable = ({ data }) => {
  // ✅ useCallback：缓存排序函数
  const sortData = useCallback((column: string) => {
    // 排序逻辑
    return [...data].sort((a, b) => a[column] - b[column]);
  }, [data]);

  // ✅ useMemo：缓存已排序的数据
  const sortedData = useMemo(() => {
    return [...data].sort((a, b) => a.name.localeCompare(b.name));
  }, [data]);

  // ✅ useCallback：缓存点击处理器
  const handleRowClick = useCallback((row) => {
    console.log('Clicked row:', row);
  }, []);

  // ✅ useMemo：缓存过滤后的数据
  const filteredData = useMemo(() => {
    return sortedData.filter(item => item.active);
  }, [sortedData]);

  return (
    <Box flexDirection="column">
      {filteredData.map(row => (
        <Text key={row.id} onPress={() => handleRowClick(row)}>
          {row.name}
        </Text>
      ))}
    </Box>
  );
};
```

## 7. 性能优化考虑

### useCallback 不是万能的

使用 useCallback 本身也有开销：

```typescript
// 使用 useCallback 的开销：
// 1. 创建依赖项数组
// 2. 比较依赖项是否变化
// 3. 存储和检索缓存的函数

// 简单的事件处理器可能不需要 useCallback
const SimpleComponent = () => {
  const [count, setCount] = useState(0);

  // ❌ 过度优化：这个简单函数不需要 useCallback
  const increment = useCallback(() => {
    setCount(prev => prev + 1);
  }, []);

  // ✅ 更好：直接定义函数
  const increment = () => {
    setCount(prev => prev + 1);
  };

  return <Text onPress={increment}>Increment</Text>;
};
```

### 何时使用 useCallback

#### ✅ 应该使用的情况

**1. 传递给优化过的子组件**

```typescript
const Parent = () => {
  const [count, setCount] = useState(0);

  // ✅ 子组件使用了 React.memo，需要 useCallback
  const handleClick = useCallback(() => {
    console.log('Clicked');
  }, []);

  return <ExpensiveChild onClick={handleClick} />;
};

const ExpensiveChild = React.memo(({ onClick }) => {
  // 昂贵的渲染逻辑
  return <Text onPress={onClick}>Click me</Text>;
});
```

**2. 作为其他 Hook 的依赖**

```typescript
const Component = () => {
  const [data, setData] = useState([]);

  // ✅ fetchData 用在 useEffect 依赖中
  const fetchData = useCallback(async () => {
    const result = await api.getData();
    setData(result);
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return <DataList data={data} />;
};
```

**3. 传递给自定义 Hook**

```typescript
const Component = () => {
  const [value, setValue] = useState('');

  // ✅ 传递给自定义 hook
  const handleChange = useCallback((newValue: string) => {
    setValue(newValue);
  }, []);

  useDebounce(handleChange, 500);

  return <TextInput value={value} onChange={handleChange} />;
};
```

**4. 函数创建开销大**

```typescript
const Component = () => {
  const [config, setConfig] = useState({});

  // ✅ 复杂的函数创建逻辑
  const processData = useCallback((data) => {
    // 复杂的转换逻辑
    return data
      .map(item => transformItem(item))
      .filter(item => validateItem(item))
      .reduce((acc, item) => mergeItems(acc, item), {});
  }, []);

  return <DataProcessor onProcess={processData} />;
};
```

#### ❌ 不需要使用的情况

**1. 简单的事件处理器**

```typescript
// ❌ 不必要：简单的函数
const BadExample = () => {
  const [count, setCount] = useState(0);

  const increment = useCallback(() => {
    setCount(prev => prev + 1);
  }, []);

  return <Text onPress={increment}>Increment</Text>;
};

// ✅ 更好：直接定义
const GoodExample = () => {
  const [count, setCount] = useState(0);

  const increment = () => {
    setCount(prev => prev + 1);
  };

  return <Text onPress={increment}>Increment</Text>;
};
```

**2. 函数不被传递或依赖**

```typescript
// ❌ 不必要：函数只在组件内部使用
const BadExample = () => {
  const [data, setData] = useState([]);

  const processData = useCallback(() => {
    const result = data.map(item => item * 2);
    console.log(result);
  }, [data]);

  // 直接在这里调用
  useEffect(() => {
    processData();
  }, [processData]);

  return <Text>Data processed</Text>;
};

// ✅ 更好：直接在 useEffect 中处理
const GoodExample = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    const result = data.map(item => item * 2);
    console.log(result);
  }, [data]);

  return <Text>Data processed</Text>;
};
```

**3. 组件很少重新渲染**

```typescript
// ❌ 过度优化：这个组件可能只渲染一次
const StaticComponent = () => {
  const handleClick = useCallback(() => {
    console.log('Clicked');
  }, []);

  return <Text onPress={handleClick}>Static content</Text>;
};
```

### 性能优化的权衡

```typescript
// 记住：过早优化是万恶之源
//
// 优化前提：
// 1. 确认存在性能问题
// 2. 使用性能分析工具定位问题
// 3. 针对性优化
// 4. 验证优化效果

// ❌ 糟糕：盲目优化所有函数
const OverOptimized = () => {
  const fn1 = useCallback(() => {}, []);
  const fn2 = useCallback(() => {}, []);
  const fn3 = useCallback(() => {}, []);
  const fn4 = useCallback(() => {}, []);
  // ...代码难以阅读和维护
};

// ✅ 良好：在必要的地方使用
const Balanced = () => {
  // 传递给优化的子组件 - 使用 useCallback
  const handleSubmit = useCallback(() => {}, []);

  // 简单的内部函数 - 不使用 useCallback
  const handleChange = (e) => {};

  return (
    <Box>
      <OptimizedForm onSubmit={handleSubmit} />
      <TextInput onChange={handleChange} />
    </Box>
  );
};
```

## 8. 常见错误和调试技巧

### 错误 1：忘记添加依赖项

#### 问题表现

```typescript
const Component = () => {
  const [count, setCount] = useState(0);
  const [multiplier, setMultiplier] = useState(2);

  // ❌ 错误：multiplier 没有在依赖项中
  const calculate = useCallback(() => {
    return count * multiplier; // 使用了 multiplier
  }, [count]); // 但只依赖 count

  // 问题：calculate 永远使用初始的 multiplier 值（2）
  // 即使 multiplier 改变了，calculate 也不会更新

  return (
    <Box>
      <Text>Result: {calculate()}</Text>
      <Text>Expected: {count * multiplier}</Text>
    </Box>
  );
};
```

#### 解决方法

```typescript
// ✅ 解决方案：包含所有依赖项
const Component = () => {
  const [count, setCount] = useState(0);
  const [multiplier, setMultiplier] = useState(2);

  const calculate = useCallback(() => {
    return count * multiplier;
  }, [count, multiplier]); // ✅ 包含所有使用的变量

  return <Text>Result: {calculate()}</Text>;
};
```

#### 调试技巧

```typescript
// 添加 console.log 检查依赖项变化
const calculate = useCallback(() => {
  console.log('calculate created with:', { count, multiplier });
  return count * multiplier;
}, [count, multiplier]);

// 或者使用 useEffect 监控
useEffect(() => {
  console.log('Dependencies changed:', { count, multiplier });
}, [count, multiplier]);
```

### 错误 2：依赖项过多导致频繁重新创建

#### 问题表现

```typescript
const Component = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    age: 0,
    address: '',
    // ...很多字段
  });

  // ❌ 问题：formData 改变时，所有使用它的函数都会重新创建
  const validateName = useCallback(() => {
    return formData.name.length > 0;
  }, [formData]); // formData 的任何字段改变都会重新创建函数

  const validateEmail = useCallback(() => {
    return formData.email.includes('@');
  }, [formData]); // 即使只需要 email 字段

  // 每个字段的输入都会导致所有验证函数重新创建
};
```

#### 解决方案 1：只依赖需要的字段

```typescript
// ✅ 解决方案 1：只依赖实际使用的字段
const Component = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    age: 0,
  });

  const validateName = useCallback(() => {
    return formData.name.length > 0;
  }, [formData.name]); // 只依赖 name 字段

  const validateEmail = useCallback(() => {
    return formData.email.includes('@');
  }, [formData.email]); // 只依赖 email 字段
};
```

#### 解决方案 2：使用 useReducer

```typescript
// ✅ 解决方案 2：使用 useReducer 避免依赖项问题
const formReducer = (state, action) => {
  switch (action.type) {
    case 'SET_NAME':
      return { ...state, name: action.payload };
    case 'SET_EMAIL':
      return { ...state, email: action.payload };
    default:
      return state;
  }
};

const Component = () => {
  const [formData, dispatch] = useReducer(formReducer, {
    name: '',
    email: '',
  });

  // ✅ dispatch 是稳定的，不需要依赖项
  const handleNameChange = useCallback((name: string) => {
    dispatch({ type: 'SET_NAME', payload: name });
  }, []); // 空依赖项

  const handleEmailChange = useCallback((email: string) => {
    dispatch({ type: 'SET_EMAIL', payload: email });
  }, []); // 空依赖项
};
```

#### 解决方案 3：使用 useRef

```typescript
// ✅ 解决方案 3：使用 useRef 存储可变数据
const Component = () => {
  const [count, setCount] = useState(0);
  const dataRef = useRef({ value: 0, timestamp: Date.now() });

  // useRef 的 current 不需要作为依赖项
  const logData = useCallback(() => {
    console.log('Data:', dataRef.current);
    console.log('Count:', count);
  }, [count]); // 不需要 dataRef

  // 更新 ref 不会触发重新渲染
  const updateData = () => {
    dataRef.current = { value: count, timestamp: Date.now() };
  };
};
```

### 错误 3：闭包陷阱

#### 问题表现

```typescript
const Component = () => {
  const [count, setCount] = useState(0);

  // ❌ 问题：setTimeout 中的 count 是闭包捕获的旧值
  const delayedLog = useCallback(() => {
    setTimeout(() => {
      console.log('Count:', count); // 这是创建函数时的 count 值
    }, 3000);
  }, []); // 空依赖项

  // 场景：
  // 1. count = 0，点击按钮调用 delayedLog
  // 2. 3 秒内，点击增加 count 到 5
  // 3. 3 秒后，打印 "Count: 0" （不是 5！）

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Text onPress={delayedLog}>Log after 3s</Text>
      <Text onPress={() => setCount(count + 1)}>Increment</Text>
    </Box>
  );
};
```

#### 解决方案 1：添加依赖项

```typescript
// ✅ 解决方案 1：将 count 添加到依赖项
const Component = () => {
  const [count, setCount] = useState(0);

  const delayedLog = useCallback(() => {
    setTimeout(() => {
      console.log('Count:', count); // 使用最新的 count
    }, 3000);
  }, [count]); // 包含 count 依赖

  // 注意：每次 count 改变，函数会重新创建
  // 这可能不是你想要的行为
};
```

#### 解决方案 2：使用 useRef

```typescript
// ✅ 解决方案 2：使用 useRef 保存最新值
const Component = () => {
  const [count, setCount] = useState(0);
  const countRef = useRef(count);

  // 保持 ref 同步
  useEffect(() => {
    countRef.current = count;
  }, [count]);

  const delayedLog = useCallback(() => {
    setTimeout(() => {
      console.log('Count:', countRef.current); // 总是最新值
    }, 3000);
  }, []); // 空依赖项
};
```

#### 解决方案 3：使用函数式更新

```typescript
// ✅ 解决方案 3：使用 setState 的函数式更新
const Component = () => {
  const [count, setCount] = useState(0);

  const delayedIncrement = useCallback(() => {
    setTimeout(() => {
      // 使用函数式更新获取最新值
      setCount((prevCount) => {
        console.log('Count:', prevCount);
        return prevCount + 1;
      });
    }, 3000);
  }, []); // 空依赖项
};
```

### 调试技巧总结

```typescript
// 1. 使用 console.log 追踪函数创建
const handler = useCallback(() => {
  console.log('Handler created at:', Date.now());
  // ...
}, [deps]);

// 2. 使用 useEffect 监控依赖项变化
useEffect(() => {
  console.log('Dependencies changed:', deps);
}, [deps]);

// 3. 使用 React DevTools Profiler
// - 查看组件渲染次数
// - 识别不必要的重新渲染
// - 验证优化效果

// 4. 添加函数名（方便调试）
const handler = useCallback(
  function namedHandler() {
    // 在调用栈中可以看到函数名
  },
  [deps],
);

// 5. 临时禁用 useCallback 对比性能
// const handler = useCallback(...); // 优化版本
// const handler = () => {}; // 未优化版本
// 对比两者的性能差异
```

## 9. 与其他 Hooks 的配合使用

### useCallback + useState

最常见的组合，用于创建状态更新函数：

```typescript
const FormComponent = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [errors, setErrors] = useState({});

  // ✅ 使用函数式更新，不需要依赖当前状态
  const updateName = useCallback((newName: string) => {
    setName(newName);
    // 清除相关错误
    setErrors(prev => {
      const { name, ...rest } = prev;
      return rest;
    });
  }, []); // 空依赖项

  // ✅ 需要读取当前状态时，添加到依赖项
  const updateEmail = useCallback((newEmail: string) => {
    setEmail(newEmail);
    // 验证邮箱并设置错误
    if (!newEmail.includes('@')) {
      setErrors(prev => ({ ...prev, email: 'Invalid email' }));
    }
  }, []); // 不需要依赖项，因为使用函数式更新

  return (
    <Box flexDirection="column">
      <TextInput value={name} onChange={updateName} />
      <TextInput value={email} onChange={updateEmail} />
      {errors.email && <Text color="red">{errors.email}</Text>}
    </Box>
  );
};
```

### useCallback + useContext

将 useCallback 与 Context 结合，避免 Context 值变化导致的重新渲染：

```typescript
// 创建 Context
interface AppContextValue {
  user: User;
  updateUser: (user: User) => void;
  logout: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

// Provider 组件
const AppProvider = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);

  // ✅ 使用 useCallback 稳定函数引用
  const updateUser = useCallback((newUser: User) => {
    setUser(newUser);
  }, []);

  const logout = useCallback(() => {
    setUser(null);
  }, []);

  // ✅ 使用 useMemo 稳定 context 值
  const value = useMemo(
    () => ({ user, updateUser, logout }),
    [user, updateUser, logout]
  );

  return (
    <AppContext.Provider value={value}>
      {children}
    </AppContext.Provider>
  );
};

// 使用 Context 的组件
const UserProfile = () => {
  const { user, updateUser } = useContext(AppContext)!;

  // ✅ updateUser 是稳定的，这个 callback 不会频繁重新创建
  const handleNameChange = useCallback((name: string) => {
    updateUser({ ...user!, name });
  }, [user, updateUser]);

  return <TextInput value={user?.name} onChange={handleNameChange} />;
};
```

### useCallback + useEffect

这是一个需要特别注意的组合：

```typescript
const DataFetcher = ({ userId }: { userId: string }) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);

  // ✅ 使用 useCallback 创建稳定的 fetch 函数
  const fetchUserData = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(`/api/users/${userId}`);
      const result = await response.json();
      setData(result);
    } finally {
      setLoading(false);
    }
  }, [userId]); // 依赖 userId

  // ✅ fetchUserData 作为 useEffect 的依赖
  useEffect(() => {
    fetchUserData();
  }, [fetchUserData]); // userId 改变时重新获取

  // ✅ 也可以暴露给外部手动刷新
  return (
    <Box flexDirection="column">
      {loading ? <Text>Loading...</Text> : <Text>{data?.name}</Text>}
      <Text onPress={fetchUserData}>Refresh</Text>
    </Box>
  );
};
```

### useCallback + useRef

useRef 和 useCallback 的配合可以解决许多棘手的问题：

```typescript
const SearchComponent = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const abortControllerRef = useRef<AbortController | null>(null);

  // ✅ 使用 useRef 避免依赖项问题
  const search = useCallback(async (searchQuery: string) => {
    // 取消之前的请求
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }

    // 创建新的 AbortController
    const controller = new AbortController();
    abortControllerRef.current = controller;

    try {
      const response = await fetch(
        `/api/search?q=${searchQuery}`,
        { signal: controller.signal }
      );
      const data = await response.json();
      setResults(data);
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search failed:', error);
      }
    }
  }, []); // 空依赖项，因为所有可变数据都在 ref 中

  // 防抖搜索
  useEffect(() => {
    const timer = setTimeout(() => {
      if (query) {
        search(query);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [query, search]);

  // 清理函数
  useEffect(() => {
    return () => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }
    };
  }, []);

  return (
    <Box flexDirection="column">
      <TextInput value={query} onChange={setQuery} />
      {results.map(item => (
        <Text key={item.id}>{item.name}</Text>
      ))}
    </Box>
  );
};
```

### 综合示例：购物车

一个完整的示例，展示多个 Hooks 的协作：

```typescript
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartContextValue {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  total: number;
}

const CartContext = createContext<CartContextValue | null>(null);

const CartProvider = ({ children }) => {
  const [items, setItems] = useState<CartItem[]>([]);

  // ✅ useCallback: 添加商品
  const addItem = useCallback((item: CartItem) => {
    setItems(prev => {
      const existing = prev.find(i => i.id === item.id);
      if (existing) {
        return prev.map(i =>
          i.id === item.id
            ? { ...i, quantity: i.quantity + item.quantity }
            : i
        );
      }
      return [...prev, item];
    });
  }, []);

  // ✅ useCallback: 移除商品
  const removeItem = useCallback((id: string) => {
    setItems(prev => prev.filter(item => item.id !== id));
  }, []);

  // ✅ useCallback: 更新数量
  const updateQuantity = useCallback((id: string, quantity: number) => {
    setItems(prev =>
      prev.map(item =>
        item.id === id ? { ...item, quantity } : item
      )
    );
  }, []);

  // ✅ useCallback: 清空购物车
  const clearCart = useCallback(() => {
    setItems([]);
  }, []);

  // ✅ useMemo: 计算总价
  const total = useMemo(() => {
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }, [items]);

  // ✅ useMemo: 稳定 context 值
  const value = useMemo(
    () => ({
      items,
      addItem,
      removeItem,
      updateQuantity,
      clearCart,
      total,
    }),
    [items, addItem, removeItem, updateQuantity, clearCart, total]
  );

  // ✅ useEffect: 持久化到 localStorage
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(items));
  }, [items]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

// 使用购物车的组件
const ProductItem = ({ product }) => {
  const { addItem } = useContext(CartContext)!;

  // ✅ useCallback: 添加到购物车
  const handleAddToCart = useCallback(() => {
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
    });
  }, [product, addItem]);

  return (
    <Box>
      <Text>{product.name} - ${product.price}</Text>
      <Text onPress={handleAddToCart}>Add to Cart</Text>
    </Box>
  );
};

const CartSummary = () => {
  const { items, total, clearCart } = useContext(CartContext)!;

  return (
    <Box flexDirection="column">
      <Text>Cart ({items.length} items)</Text>
      <Text>Total: ${total.toFixed(2)}</Text>
      <Text onPress={clearCart}>Clear Cart</Text>
    </Box>
  );
};
```

## 10. 最佳实践总结

### 何时使用 useCallback

✅ **应该使用：**

1. 传递给使用 `React.memo` 优化的子组件
2. 作为其他 Hook（useEffect、useMemo 等）的依赖项
3. 传递给自定义 Hook
4. 函数会被频繁创建且创建成本高
5. 函数被用于外部库或系统 API

❌ **不需要使用：**

1. 简单的事件处理器（除非传递给优化的子组件）
2. 函数不被传递给其他组件或 Hook
3. 组件很少重新渲染
4. 过早优化（先测量再优化）

### 如何正确设置依赖项

```typescript
// ✅ 规则 1：包含所有使用的外部变量
const handler = useCallback(() => {
  console.log(a, b, c); // 使用了 a, b, c
}, [a, b, c]); // 全部包含在依赖项中

// ✅ 规则 2：setState 函数不需要包含
const handler = useCallback(() => {
  setValue((prev) => prev + 1); // setValue 是稳定的
}, []); // 不需要包含 setValue

// ✅ 规则 3：ref.current 不需要包含
const ref = useRef();
const handler = useCallback(() => {
  console.log(ref.current); // ref 是稳定的
}, []); // 不需要包含 ref

// ✅ 规则 4：常量不需要包含
const CONSTANT = 100;
const handler = useCallback(() => {
  return value * CONSTANT;
}, [value]); // 不需要包含 CONSTANT

// ✅ 规则 5：只依赖对象的特定属性
const handler = useCallback(() => {
  return config.timeout; // 只使用 timeout 属性
}, [config.timeout]); // 只依赖 timeout，不是整个 config

// ✅ 规则 6：听从 ESLint 的警告
// 始终遵循 react-hooks/exhaustive-deps 规则
```

### 性能优化的权衡

```typescript
// 💡 记住：性能优化的目标是让应用更快，而不是使用更多 Hook

// ❌ 过度优化
const OverOptimized = () => {
  // 所有函数都用了 useCallback，代码难以阅读
  const fn1 = useCallback(() => {}, []);
  const fn2 = useCallback(() => {}, []);
  const fn3 = useCallback(() => {}, []);
  // ...
};

// ✅ 平衡优化
const Balanced = () => {
  // 只在必要时使用 useCallback
  const expensiveHandler = useCallback(() => {
    // 传递给优化的子组件
  }, [deps]);

  // 简单函数不需要优化
  const simpleHandler = () => {};
};

// 💡 优化决策流程：
// 1. 是否存在性能问题？ -> 没有 -> 不优化
// 2. 使用 Profiler 定位问题 -> 不是渲染问题 -> 不使用 useCallback
// 3. 函数是否传递给子组件？ -> 是 -> 子组件是否优化？ -> 是 -> 使用 useCallback
// 4. 验证优化效果
```

### 代码可读性 vs 性能优化

```typescript
// 原则：可读性优先，性能优化次之

// ❌ 难以理解的优化
const Component = () => {
  const a = useCallback(() => {}, []);
  const b = useCallback(() => a(), [a]);
  const c = useCallback(() => b(), [b]);
  const d = useCallback(() => c(), [c]);
  // 复杂的依赖链，难以维护
};

// ✅ 清晰的结构
const Component = () => {
  // 基础函数
  const handleBasicAction = useCallback(() => {
    // 清晰的逻辑
  }, [deps]);

  // 组合函数，清楚地说明依赖关系
  const handleComplexAction = useCallback(() => {
    handleBasicAction();
    // 额外的逻辑
  }, [handleBasicAction]);

  // 代码清晰，依赖关系明确
};

// 💡 提示：
// - 添加注释说明为什么使用 useCallback
// - 使用有意义的函数名
// - 保持依赖项列表简短
// - 避免过深的函数依赖链
```

### 常用模式总结

```typescript
// 模式 1：事件处理器
const EventHandler = () => {
  const handleClick = useCallback((id: string) => {
    // 处理点击
  }, []);

  return <Button onClick={() => handleClick('123')} />;
};

// 模式 2：表单处理
const FormHandler = () => {
  const [form, setForm] = useState({});

  const handleFieldChange = useCallback((field: string, value: any) => {
    setForm(prev => ({ ...prev, [field]: value }));
  }, []);

  return <Input onChange={(val) => handleFieldChange('name', val)} />;
};

// 模式 3：API 调用
const ApiCaller = () => {
  const fetchData = useCallback(async (id: string) => {
    const data = await api.fetch(id);
    return data;
  }, []);

  useEffect(() => {
    fetchData('123');
  }, [fetchData]);
};

// 模式 4：Context 提供器
const ContextProvider = ({ children }) => {
  const [state, setState] = useState();

  const actions = useMemo(() => ({
    action1: useCallback(() => {}, []),
    action2: useCallback(() => {}, []),
  }), []);

  return <Context.Provider value={{ state, ...actions }} />;
};
```

## 11. 练习题

通过以下练习巩固你对 useCallback 的理解：

### 练习 1：基础使用

创建一个计数器组件，使用 useCallback 优化增加和减少函数：

```typescript
// 要求：
// 1. 使用 useState 管理 count 状态
// 2. 创建 increment 和 decrement 函数，使用 useCallback 缓存
// 3. 两个函数都不依赖 count（提示：使用函数式更新）

const Counter = () => {
  // 你的代码...
};
```

<details>
<summary>查看答案</summary>

```typescript
const Counter = () => {
  const [count, setCount] = useState(0);

  const increment = useCallback(() => {
    setCount(prev => prev + 1);
  }, []);

  const decrement = useCallback(() => {
    setCount(prev => prev - 1);
  }, []);

  return (
    <Box flexDirection="column">
      <Text>Count: {count}</Text>
      <Text onPress={increment}>Increment</Text>
      <Text onPress={decrement}>Decrement</Text>
    </Box>
  );
};
```

</details>

### 练习 2：依赖项管理

创建一个搜索组件，正确管理依赖项：

```typescript
// 要求：
// 1. query 状态存储搜索词
// 2. results 状态存储搜索结果
// 3. 创建 search 函数，使用 useCallback
// 4. search 函数应该正确依赖 query
// 5. 使用 useEffect 在 query 改变时自动搜索

const SearchComponent = () => {
  // 你的代码...
};
```

<details>
<summary>查看答案</summary>

```typescript
const SearchComponent = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const search = useCallback(async () => {
    if (!query) {
      setResults([]);
      return;
    }

    const response = await fetch(`/api/search?q=${query}`);
    const data = await response.json();
    setResults(data);
  }, [query]);

  useEffect(() => {
    search();
  }, [search]);

  return (
    <Box flexDirection="column">
      <TextInput value={query} onChange={setQuery} />
      {results.map(item => (
        <Text key={item.id}>{item.name}</Text>
      ))}
    </Box>
  );
};
```

</details>

### 练习 3：避免闭包陷阱

修复以下代码中的闭包问题：

```typescript
// 问题代码：
const TimerComponent = () => {
  const [count, setCount] = useState(0);

  const startTimer = useCallback(() => {
    setInterval(() => {
      // ❌ 这里的 count 永远是初始值 0
      console.log('Current count:', count);
      setCount(count + 1);
    }, 1000);
  }, []);

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Text onPress={startTimer}>Start Timer</Text>
    </Box>
  );
};

// 要求：修复代码，让 setInterval 中能访问到最新的 count 值
```

<details>
<summary>查看答案</summary>

```typescript
// 解决方案 1：使用函数式更新
const TimerComponent = () => {
  const [count, setCount] = useState(0);
  const countRef = useRef(count);

  useEffect(() => {
    countRef.current = count;
  }, [count]);

  const startTimer = useCallback(() => {
    setInterval(() => {
      // 从 ref 获取最新值
      console.log('Current count:', countRef.current);
      // 使用函数式更新
      setCount(prev => prev + 1);
    }, 1000);
  }, []);

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Text onPress={startTimer}>Start Timer</Text>
    </Box>
  );
};

// 解决方案 2：添加依赖项并清理
const TimerComponent = () => {
  const [count, setCount] = useState(0);
  const [isRunning, setIsRunning] = useState(false);

  useEffect(() => {
    if (!isRunning) return;

    const timer = setInterval(() => {
      console.log('Current count:', count);
      setCount(count + 1);
    }, 1000);

    return () => clearInterval(timer);
  }, [count, isRunning]);

  const startTimer = useCallback(() => {
    setIsRunning(true);
  }, []);

  return (
    <Box>
      <Text>Count: {count}</Text>
      <Text onPress={startTimer}>Start Timer</Text>
    </Box>
  );
};
```

</details>

### 练习 4：Context 优化

创建一个优化的 TodoList Context：

```typescript
// 要求：
// 1. 创建 TodoContext 和 Provider
// 2. 使用 useCallback 优化所有操作函数
// 3. 使用 useMemo 优化 context 值
// 4. 实现 addTodo、removeTodo、toggleTodo 函数

interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

// 你的代码...
```

<details>
<summary>查看答案</summary>

```typescript
interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

interface TodoContextValue {
  todos: Todo[];
  addTodo: (text: string) => void;
  removeTodo: (id: string) => void;
  toggleTodo: (id: string) => void;
}

const TodoContext = createContext<TodoContextValue | null>(null);

export const TodoProvider = ({ children }) => {
  const [todos, setTodos] = useState<Todo[]>([]);

  const addTodo = useCallback((text: string) => {
    setTodos(prev => [
      ...prev,
      { id: Date.now().toString(), text, completed: false },
    ]);
  }, []);

  const removeTodo = useCallback((id: string) => {
    setTodos(prev => prev.filter(todo => todo.id !== id));
  }, []);

  const toggleTodo = useCallback((id: string) => {
    setTodos(prev =>
      prev.map(todo =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  }, []);

  const value = useMemo(
    () => ({ todos, addTodo, removeTodo, toggleTodo }),
    [todos, addTodo, removeTodo, toggleTodo]
  );

  return <TodoContext.Provider value={value}>{children}</TodoContext.Provider>;
};

export const useTodos = () => {
  const context = useContext(TodoContext);
  if (!context) {
    throw new Error('useTodos must be used within TodoProvider');
  }
  return context;
};
```

</details>

## 12. 总结

### 核心要点回顾

1. **useCallback 的作用**
   - 缓存函数引用，避免不必要的重新创建
   - 只有在依赖项改变时才创建新函数

2. **使用场景**
   - 传递给优化的子组件（React.memo）
   - 作为其他 Hook 的依赖项
   - 复杂的事件处理器

3. **依赖项数组**
   - 包含函数中使用的所有外部变量
   - setState 函数和 ref 不需要包含
   - 遵循 ESLint 规则

4. **常见错误**
   - 忘记添加依赖项
   - 依赖项过多
   - 闭包陷阱

5. **性能考虑**
   - 不要过早优化
   - 平衡可读性和性能
   - 使用 Profiler 测量效果

### 何时使用 useCallback

✅ **使用情况：**

- 函数传递给 React.memo 包装的组件
- 函数作为 useEffect、useMemo 等的依赖
- 函数传递给自定义 Hook
- 复杂的事件处理逻辑

❌ **不需要使用：**

- 简单的内部函数
- 组件很少重新渲染
- 函数不被传递或依赖
- 过早优化

### 学习资源推荐

**官方文档：**

- [React useCallback 文档](https://react.dev/reference/react/useCallback)
- [React useMemo 文档](https://react.dev/reference/react/useMemo)
- [React 性能优化指南](https://react.dev/learn/render-and-commit)

**进阶阅读：**

- 在 Gemini CLI 项目中查找更多 useCallback 的实际使用
- 阅读 `packages/cli/src/ui/hooks/` 目录下的其他自定义 Hook
- 学习 `useReducer` 和 `useRef` 与 useCallback 的配合

**实践建议：**

1. 在实际项目中练习使用 useCallback
2. 使用 React DevTools Profiler 分析性能
3. 对比优化前后的性能差异
4. 阅读优秀开源项目的代码

### 下一步学习

掌握了 useCallback 之后，建议学习：

1. **useMemo**：缓存计算结果，与 useCallback 相辅相成
2. **useReducer**：管理复杂状态，减少 useCallback 依赖项
3. **React.memo**：配合 useCallback 优化子组件
4. **性能分析工具**：学习使用 React DevTools Profiler

---

**恭喜你完成了 useCallback 的学习！** 🎉

通过本教程，你应该已经掌握了：

- useCallback 的基本概念和工作原理
- 如何正确使用 useCallback 优化组件
- 依赖项数组的管理技巧
- 常见错误和解决方案
- 与其他 Hooks 的配合使用

继续实践，在实际项目中应用这些知识，你会越来越熟练！
