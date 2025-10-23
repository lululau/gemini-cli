# React useEffect 完全指南

## 目录

- [什么是 useEffect](#什么是-useeffect)
- [基础概念](#基础概念)
- [useEffect 的三种形式](#useeffect-的三种形式)
- [依赖数组详解](#依赖数组详解)
- [清理函数](#清理函数)
- [常见使用场景](#常见使用场景)
- [最佳实践](#最佳实践)
- [常见错误与陷阱](#常见错误与陷阱)
- [进阶技巧](#进阶技巧)

---

## 什么是 useEffect

`useEffect` 是 React 中用于处理**副作用（Side Effects）**的 Hook。

### 什么是副作用？

在 React 中，**副作用**指的是那些不直接参与渲染、但需要与外部世界交互的操作，例如：

- 数据获取（API 调用）
- 订阅（WebSocket、事件监听）
- 手动修改 DOM
- 定时器（setTimeout、setInterval）
- 日志记录
- 本地存储操作

### 为什么需要 useEffect？

React 组件的渲染应该是**纯函数**：给定相同的 props 和 state，应该返回相同的 JSX。而副作用操作不符合这个规则，所以 React 提供了
`useEffect` 来专门处理这些操作。

---

## 基础概念

### 基本语法

```typescript
useEffect(() => {
  // 副作用代码

  return () => {
    // 清理代码（可选）
  };
}, [依赖项数组]);
```

### 参数说明

1. **第一个参数**：一个函数，包含副作用代码
2. **第二个参数**：依赖数组（可选），控制副作用何时执行

### 执行时机

`useEffect` 在以下时机执行：

1. **首次渲染后**：组件挂载（mount）时
2. **更新后**：当依赖项发生变化时
3. **组件卸载前**：执行清理函数（如果有）

---

## useEffect 的三种形式

### 1. 无依赖数组：每次渲染都执行

```typescript
import { useState, useEffect } from 'react';

function CounterEveryRender() {
  const [count, setCount] = useState(0);
  const [name, setName] = useState('');

  // ⚠️ 每次渲染都会执行
  useEffect(() => {
    console.log('组件渲染了！count:', count, 'name:', name);
  });

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>增加</button>

      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="输入名字"
      />
    </div>
  );
}
```

**特点**：

- 每次组件重新渲染时都会执行
- 通常**不推荐**使用，因为性能开销大
- 适用场景：调试、日志记录

---

### 2. 空依赖数组：仅在挂载时执行一次

```typescript
import { useState, useEffect } from 'react';

function DataFetcher() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  // ✅ 仅在组件挂载时执行一次
  useEffect(() => {
    console.log('组件挂载了，开始获取数据...');

    fetch('https://api.example.com/data')
      .then(response => response.json())
      .then(data => {
        setData(data);
        setLoading(false);
      })
      .catch(error => {
        console.error('获取数据失败:', error);
        setLoading(false);
      });
  }, []); // 空数组 = 仅执行一次

  if (loading) return <div>加载中...</div>;

  return <div>数据: {JSON.stringify(data)}</div>;
}
```

**特点**：

- 相当于类组件的 `componentDidMount`
- 最常用的形式之一
- 适用场景：初始化数据、订阅事件、设置定时器

---

### 3. 有依赖数组：依赖变化时执行

```typescript
import { useState, useEffect } from 'react';

function SearchBox() {
  const [searchTerm, setSearchTerm] = useState('');
  const [results, setResults] = useState([]);

  // ✅ 当 searchTerm 变化时执行
  useEffect(() => {
    if (searchTerm === '') {
      setResults([]);
      return;
    }

    console.log('搜索词变化了:', searchTerm);

    // 模拟 API 调用
    const fetchResults = async () => {
      const response = await fetch(`https://api.example.com/search?q=${searchTerm}`);
      const data = await response.json();
      setResults(data);
    };

    fetchResults();
  }, [searchTerm]); // 仅在 searchTerm 变化时执行

  return (
    <div>
      <input
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        placeholder="搜索..."
      />
      <ul>
        {results.map(item => (
          <li key={item.id}>{item.name}</li>
        ))}
      </ul>
    </div>
  );
}
```

**特点**：

- 精确控制副作用的执行时机
- 性能最优
- 适用场景：响应特定状态的变化

---

## 依赖数组详解

### 依赖数组的工作原理

React 使用 `Object.is()` 比较依赖项的**引用相等性**：

```typescript
function DependencyExample() {
  const [count, setCount] = useState(0);
  const [user, setUser] = useState({ name: 'Alice' });

  useEffect(() => {
    console.log('Effect 执行了');
  }, [count]); // 只有 count 变化时才执行

  // ❌ 错误：每次渲染都会创建新对象
  useEffect(() => {
    console.log('这个会每次都执行！');
  }, [{ name: 'Alice' }]); // 每次都是新对象，引用不同

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

### 多个依赖项

```typescript
function MultiDependency() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [fullName, setFullName] = useState('');

  // ✅ 当 firstName 或 lastName 变化时执行
  useEffect(() => {
    setFullName(`${firstName} ${lastName}`.trim());
  }, [firstName, lastName]);

  return (
    <div>
      <input
        value={firstName}
        onChange={(e) => setFirstName(e.target.value)}
        placeholder="名"
      />
      <input
        value={lastName}
        onChange={(e) => setLastName(e.target.value)}
        placeholder="姓"
      />
      <p>全名: {fullName}</p>
    </div>
  );
}
```

### 对象和数组作为依赖

```typescript
import { useState, useEffect, useMemo } from 'react';

function ObjectDependency() {
  const [userId, setUserId] = useState(1);

  // ❌ 错误：每次渲染都创建新对象
  const config = { userId, api: 'v1' };

  useEffect(() => {
    console.log('这会每次都执行！');
  }, [config]); // config 每次都是新对象

  // ✅ 方案1：使用 useMemo 缓存对象
  const memoizedConfig = useMemo(
    () => ({ userId, api: 'v1' }),
    [userId]
  );

  useEffect(() => {
    console.log('只在 userId 变化时执行');
  }, [memoizedConfig]);

  // ✅ 方案2：直接依赖原始值
  useEffect(() => {
    const config = { userId, api: 'v1' };
    console.log('使用配置:', config);
  }, [userId]); // 直接依赖 userId

  return <div>User ID: {userId}</div>;
}
```

### 函数作为依赖

```typescript
import { useState, useEffect, useCallback } from 'react';

function FunctionDependency() {
  const [count, setCount] = useState(0);

  // ❌ 错误：每次渲染都创建新函数
  const fetchData = () => {
    console.log('Fetching data for count:', count);
  };

  useEffect(() => {
    fetchData();
  }, [fetchData]); // fetchData 每次都是新函数，导致无限循环！

  // ✅ 方案1：使用 useCallback 缓存函数
  const memoizedFetchData = useCallback(() => {
    console.log('Fetching data for count:', count);
  }, [count]);

  useEffect(() => {
    memoizedFetchData();
  }, [memoizedFetchData]);

  // ✅ 方案2：将函数定义在 effect 内部
  useEffect(() => {
    const fetchData = () => {
      console.log('Fetching data for count:', count);
    };
    fetchData();
  }, [count]); // 只依赖 count

  return <button onClick={() => setCount(count + 1)}>Count: {count}</button>;
}
```

---

## 清理函数

### 为什么需要清理？

某些副作用需要在组件卸载或下次 effect 执行前进行清理，以避免：

- 内存泄漏
- 事件监听器累积
- 定时器继续运行

### 基本清理示例

```typescript
import { useState, useEffect } from 'react';

function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    console.log('设置定时器');

    const intervalId = setInterval(() => {
      setSeconds(prev => prev + 1);
    }, 1000);

    // ✅ 清理函数：组件卸载时清除定时器
    return () => {
      console.log('清除定时器');
      clearInterval(intervalId);
    };
  }, []); // 空依赖数组

  return <div>已运行 {seconds} 秒</div>;
}

function App() {
  const [showTimer, setShowTimer] = useState(true);

  return (
    <div>
      <button onClick={() => setShowTimer(!showTimer)}>
        {showTimer ? '隐藏' : '显示'}计时器
      </button>
      {showTimer && <Timer />}
    </div>
  );
}
```

### 事件监听清理

```typescript
import { useState, useEffect } from 'react';

function WindowSize() {
  const [size, setSize] = useState({
    width: window.innerWidth,
    height: window.innerHeight
  });

  useEffect(() => {
    const handleResize = () => {
      setSize({
        width: window.innerWidth,
        height: window.innerHeight
      });
    };

    // 添加事件监听
    window.addEventListener('resize', handleResize);
    console.log('添加了 resize 监听器');

    // ✅ 清理函数：移除事件监听
    return () => {
      window.removeEventListener('resize', handleResize);
      console.log('移除了 resize 监听器');
    };
  }, []); // 只在挂载/卸载时执行

  return (
    <div>
      窗口大小: {size.width} x {size.height}
    </div>
  );
}
```

### WebSocket 清理

```typescript
import { useState, useEffect } from 'react';

function ChatRoom({ roomId }: { roomId: string }) {
  const [messages, setMessages] = useState<string[]>([]);

  useEffect(() => {
    // 连接 WebSocket
    const socket = new WebSocket(`wss://chat.example.com/${roomId}`);

    socket.onopen = () => {
      console.log('WebSocket 连接已建立');
    };

    socket.onmessage = (event) => {
      setMessages(prev => [...prev, event.data]);
    };

    socket.onerror = (error) => {
      console.error('WebSocket 错误:', error);
    };

    // ✅ 清理函数：关闭 WebSocket
    return () => {
      console.log('关闭 WebSocket 连接');
      socket.close();
    };
  }, [roomId]); // 当 roomId 变化时，关闭旧连接，建立新连接

  return (
    <div>
      <h2>聊天室: {roomId}</h2>
      <ul>
        {messages.map((msg, index) => (
          <li key={index}>{msg}</li>
        ))}
      </ul>
    </div>
  );
}
```

### 异步操作清理（防止内存泄漏）

```typescript
import { useState, useEffect } from 'react';

function UserProfile({ userId }: { userId: number }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isCancelled = false; // 标记请求是否已取消

    const fetchUser = async () => {
      setLoading(true);
      try {
        const response = await fetch(`https://api.example.com/users/${userId}`);
        const data = await response.json();

        // ✅ 只有在未取消时才更新状态
        if (!isCancelled) {
          setUser(data);
          setLoading(false);
        }
      } catch (error) {
        if (!isCancelled) {
          console.error('获取用户失败:', error);
          setLoading(false);
        }
      }
    };

    fetchUser();

    // ✅ 清理函数：标记请求已取消
    return () => {
      isCancelled = true;
      console.log('取消了用户请求');
    };
  }, [userId]); // 当 userId 变化时，取消旧请求

  if (loading) return <div>加载中...</div>;
  return <div>用户: {user?.name}</div>;
}
```

### 清理函数的执行顺序

```typescript
function CleanupOrder({ value }: { value: number }) {
  useEffect(() => {
    console.log(`1. Effect 执行，value = ${value}`);

    return () => {
      console.log(`2. 清理函数执行，value = ${value}`);
    };
  }, [value]);

  return <div>Value: {value}</div>;
}

// 当 value 从 1 变为 2 时，控制台输出：
// 1. Effect 执行，value = 1
// 2. 清理函数执行，value = 1  // 先清理旧的 effect
// 1. Effect 执行，value = 2    // 再执行新的 effect
```

---

## 常见使用场景

### 1. 数据获取（Data Fetching）

```typescript
import { useState, useEffect } from 'react';

interface Post {
  id: number;
  title: string;
  body: string;
}

function BlogPosts() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    const fetchPosts = async () => {
      try {
        setLoading(true);
        setError(null);

        const response = await fetch('https://jsonplaceholder.typicode.com/posts');
        if (!response.ok) {
          throw new Error('网络请求失败');
        }

        const data = await response.json();

        if (!isCancelled) {
          setPosts(data.slice(0, 5)); // 只显示前5篇
          setLoading(false);
        }
      } catch (err) {
        if (!isCancelled) {
          setError(err instanceof Error ? err.message : '未知错误');
          setLoading(false);
        }
      }
    };

    fetchPosts();

    return () => {
      isCancelled = true;
    };
  }, []);

  if (loading) return <div>加载中...</div>;
  if (error) return <div>错误: {error}</div>;

  return (
    <div>
      <h2>博客文章</h2>
      <ul>
        {posts.map(post => (
          <li key={post.id}>
            <h3>{post.title}</h3>
            <p>{post.body}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### 2. 防抖搜索（Debounced Search）

```typescript
import { useState, useEffect } from 'react';

function DebouncedSearch() {
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedTerm, setDebouncedTerm] = useState('');
  const [results, setResults] = useState<string[]>([]);

  // 防抖：延迟更新 debouncedTerm
  useEffect(() => {
    const timerId = setTimeout(() => {
      setDebouncedTerm(searchTerm);
    }, 500); // 500ms 延迟

    // 清理：用户继续输入时取消上一个定时器
    return () => {
      clearTimeout(timerId);
    };
  }, [searchTerm]);

  // 当 debouncedTerm 变化时才搜索
  useEffect(() => {
    if (debouncedTerm === '') {
      setResults([]);
      return;
    }

    const searchAPI = async () => {
      console.log('搜索:', debouncedTerm);
      // 模拟 API 调用
      const mockResults = [
        `结果1: ${debouncedTerm}`,
        `结果2: ${debouncedTerm}`,
        `结果3: ${debouncedTerm}`
      ];
      setResults(mockResults);
    };

    searchAPI();
  }, [debouncedTerm]);

  return (
    <div>
      <input
        type="text"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        placeholder="输入搜索词（防抖 500ms）"
      />
      <ul>
        {results.map((result, index) => (
          <li key={index}>{result}</li>
        ))}
      </ul>
    </div>
  );
}
```

### 3. 文档标题更新

```typescript
import { useState, useEffect } from 'react';

function PageTitle() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    // 更新文档标题
    document.title = `点击次数: ${count}`;

    // 可选：清理函数重置标题
    return () => {
      document.title = '我的应用';
    };
  }, [count]);

  return (
    <div>
      <p>你点击了 {count} 次</p>
      <button onClick={() => setCount(count + 1)}>点击</button>
    </div>
  );
}
```

### 4. 本地存储同步

```typescript
import { useState, useEffect } from 'react';

function usePersistentState<T>(key: string, initialValue: T) {
  // 从 localStorage 读取初始值
  const [state, setState] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error('读取 localStorage 失败:', error);
      return initialValue;
    }
  });

  // 当 state 变化时，保存到 localStorage
  useEffect(() => {
    try {
      window.localStorage.setItem(key, JSON.stringify(state));
    } catch (error) {
      console.error('保存到 localStorage 失败:', error);
    }
  }, [key, state]);

  return [state, setState] as const;
}

// 使用示例
function TodoApp() {
  const [todos, setTodos] = usePersistentState<string[]>('todos', []);
  const [input, setInput] = useState('');

  const addTodo = () => {
    if (input.trim()) {
      setTodos([...todos, input]);
      setInput('');
    }
  };

  return (
    <div>
      <h2>待办事项（自动保存）</h2>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyPress={(e) => e.key === 'Enter' && addTodo()}
      />
      <button onClick={addTodo}>添加</button>
      <ul>
        {todos.map((todo, index) => (
          <li key={index}>{todo}</li>
        ))}
      </ul>
    </div>
  );
}
```

### 5. 键盘快捷键

```typescript
import { useEffect } from 'react';

function KeyboardShortcuts() {
  useEffect(() => {
    const handleKeyPress = (event: KeyboardEvent) => {
      // Ctrl+K 或 Cmd+K
      if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
        event.preventDefault();
        console.log('快捷键 Ctrl+K 被按下');
        // 执行搜索等操作
      }

      // ESC 键
      if (event.key === 'Escape') {
        console.log('ESC 被按下');
        // 关闭模态框等
      }
    };

    window.addEventListener('keydown', handleKeyPress);

    return () => {
      window.removeEventListener('keydown', handleKeyPress);
    };
  }, []);

  return <div>按 Ctrl+K 或 ESC 试试</div>;
}
```

### 6. 在线/离线状态检测

```typescript
import { useState, useEffect } from 'react';

function OnlineStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => {
      console.log('网络已连接');
      setIsOnline(true);
    };

    const handleOffline = () => {
      console.log('网络已断开');
      setIsOnline(false);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return (
    <div style={{
      padding: '10px',
      backgroundColor: isOnline ? '#90EE90' : '#FFB6C1'
    }}>
      {isOnline ? '🟢 在线' : '🔴 离线'}
    </div>
  );
}
```

### 7. 滚动位置监听

```typescript
import { useState, useEffect } from 'react';

function ScrollToTop() {
  const [showButton, setShowButton] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 300) {
        setShowButton(true);
      } else {
        setShowButton(false);
      }
    };

    window.addEventListener('scroll', handleScroll);

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  };

  return (
    <>
      {showButton && (
        <button
          onClick={scrollToTop}
          style={{
            position: 'fixed',
            bottom: '20px',
            right: '20px',
            padding: '10px 20px'
          }}
        >
          回到顶部 ↑
        </button>
      )}
    </>
  );
}
```

---

## 最佳实践

### 1. 每个 Effect 只做一件事

```typescript
// ❌ 不好：一个 effect 做多件事
function BadExample() {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    // 获取用户信息
    fetchUser().then(setUser);

    // 获取文章
    fetchPosts().then(setPosts);

    // 设置定时器
    const timer = setInterval(() => {
      console.log('tick');
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  return <div>...</div>;
}

// ✅ 好：每个 effect 独立
function GoodExample() {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);

  // Effect 1: 获取用户
  useEffect(() => {
    fetchUser().then(setUser);
  }, []);

  // Effect 2: 获取文章
  useEffect(() => {
    fetchPosts().then(setPosts);
  }, []);

  // Effect 3: 定时器
  useEffect(() => {
    const timer = setInterval(() => {
      console.log('tick');
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return <div>...</div>;
}
```

### 2. 正确处理异步操作

```typescript
// ❌ 错误：直接在 effect 中使用 async
useEffect(async () => {
  const data = await fetchData(); // ❌ 错误！
  setData(data);
}, []);

// ✅ 正确：在内部定义异步函数
useEffect(() => {
  const loadData = async () => {
    const data = await fetchData();
    setData(data);
  };

  loadData();
}, []);

// ✅ 或者使用 IIFE
useEffect(() => {
  (async () => {
    const data = await fetchData();
    setData(data);
  })();
}, []);
```

### 3. 避免不必要的依赖

```typescript
function Counter() {
  const [count, setCount] = useState(0);

  // ❌ 不好：依赖 count
  useEffect(() => {
    const timer = setInterval(() => {
      setCount(count + 1); // 依赖 count
    }, 1000);
    return () => clearInterval(timer);
  }, [count]); // 每次 count 变化都重新设置定时器

  // ✅ 好：使用函数式更新
  useEffect(() => {
    const timer = setInterval(() => {
      setCount(prev => prev + 1); // 不依赖 count
    }, 1000);
    return () => clearInterval(timer);
  }, []); // 只设置一次定时器

  return <div>{count}</div>;
}
```

### 4. 使用自定义 Hook 封装复用逻辑

```typescript
// 自定义 Hook：数据获取
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await fetch(url);
        const json = await response.json();

        if (!isCancelled) {
          setData(json);
          setLoading(false);
        }
      } catch (err) {
        if (!isCancelled) {
          setError(err instanceof Error ? err.message : '未知错误');
          setLoading(false);
        }
      }
    };

    fetchData();

    return () => {
      isCancelled = true;
    };
  }, [url]);

  return { data, loading, error };
}

// 使用
function UserList() {
  const { data: users, loading, error } = useFetch<User[]>('/api/users');

  if (loading) return <div>加载中...</div>;
  if (error) return <div>错误: {error}</div>;

  return (
    <ul>
      {users?.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### 5. 使用 ESLint 插件

安装并配置 `eslint-plugin-react-hooks`：

```bash
npm install eslint-plugin-react-hooks --save-dev
```

```json
// .eslintrc.json
{
  "plugins": ["react-hooks"],
  "rules": {
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn"
  }
}
```

这会帮助你捕获：

- 依赖数组缺失的问题
- Hook 调用顺序错误
- 其他常见错误

---

## 常见错误与陷阱

### 1. 无限循环

```typescript
// ❌ 错误：导致无限循环
function InfiniteLoop() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    setCount(count + 1); // 修改 state
  }, [count]); // 依赖 count，导致无限循环

  return <div>{count}</div>;
}

// ✅ 解决方案1：移除依赖
useEffect(() => {
  setCount(prev => prev + 1);
}, []); // 只执行一次

// ✅ 解决方案2：添加条件
useEffect(() => {
  if (count < 10) {
    setCount(count + 1);
  }
}, [count]);
```

### 2. 闭包陷阱

```typescript
function ClosureTrap() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      console.log(count); // ❌ 永远打印 0（闭包）
      setCount(count + 1); // ❌ count 永远是 0
    }, 1000);

    return () => clearInterval(timer);
  }, []); // 空依赖数组，count 被"冻结"在 0

  return <div>{count}</div>;
}

// ✅ 解决方案1：使用函数式更新
useEffect(() => {
  const timer = setInterval(() => {
    setCount(prev => {
      console.log(prev); // ✅ 正确的值
      return prev + 1;
    });
  }, 1000);
  return () => clearInterval(timer);
}, []);

// ✅ 解决方案2：添加依赖（但会频繁重建定时器）
useEffect(() => {
  const timer = setInterval(() => {
    console.log(count);
    setCount(count + 1);
  }, 1000);
  return () => clearInterval(timer);
}, [count]);

// ✅ 解决方案3：使用 useRef
function BetterSolution() {
  const [count, setCount] = useState(0);
  const countRef = useRef(count);

  useEffect(() => {
    countRef.current = count; // 保持最新值
  });

  useEffect(() => {
    const timer = setInterval(() => {
      console.log(countRef.current); // ✅ 始终是最新值
      setCount(countRef.current + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return <div>{count}</div>;
}
```

### 3. 忘记清理副作用

```typescript
// ❌ 错误：未清理事件监听器
function NoCleanup() {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    // ❌ 缺少清理函数
  }, []);

  return <div>X: {position.x}, Y: {position.y}</div>;
}

// ✅ 正确：添加清理函数
useEffect(() => {
  const handleMouseMove = (e: MouseEvent) => {
    setPosition({ x: e.clientX, y: e.clientY });
  };

  window.addEventListener('mousemove', handleMouseMove);

  return () => {
    window.removeEventListener('mousemove', handleMouseMove);
  };
}, []);
```

### 4. 竞态条件（Race Condition）

```typescript
// ❌ 问题：快速切换用户时，可能显示错误的数据
function UserProfile({ userId }: { userId: number }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetchUser(userId).then(setUser); // ❌ 没有处理竞态
  }, [userId]);

  return <div>{user?.name}</div>;
}

// 如果 userId 从 1 → 2 → 3，可能的执行顺序：
// 1. 请求 userId=1
// 2. 请求 userId=2
// 3. 请求 userId=3
// 4. userId=3 的响应返回 ✅
// 5. userId=1 的响应返回 ❌（覆盖了正确的数据！）

// ✅ 解决方案：使用取消标记
useEffect(() => {
  let isCancelled = false;

  fetchUser(userId).then(data => {
    if (!isCancelled) {
      setUser(data);
    }
  });

  return () => {
    isCancelled = true;
  };
}, [userId]);

// ✅ 或者使用 AbortController（现代浏览器）
useEffect(() => {
  const controller = new AbortController();

  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(res => res.json())
    .then(setUser)
    .catch(err => {
      if (err.name !== 'AbortError') {
        console.error(err);
      }
    });

  return () => {
    controller.abort();
  };
}, [userId]);
```

### 5. 依赖数组遗漏

```typescript
// ❌ 错误：遗漏依赖
function SearchBox() {
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('all');
  const [results, setResults] = useState([]);

  useEffect(() => {
    search(query, category).then(setResults);
  }, [query]); // ❌ 遗漏了 category

  // 当 category 变化时不会重新搜索！
}

// ✅ 正确：包含所有依赖
useEffect(() => {
  search(query, category).then(setResults);
}, [query, category]);
```

---

## 进阶技巧

### 1. 条件执行 Effect

```typescript
function ConditionalEffect({ shouldFetch, userId }: Props) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    // 方法1：早期返回
    if (!shouldFetch) {
      return;
    }

    fetchUser(userId).then(setUser);
  }, [shouldFetch, userId]);

  // 方法2：条件性的 useEffect（不推荐，违反 Hook 规则）
  // if (shouldFetch) {
  //   useEffect(() => { ... }); // ❌ 错误！
  // }

  return <div>{user?.name}</div>;
}
```

### 2. 组合多个 Effect

```typescript
function Dashboard({ userId }: { userId: number }) {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);
  const [comments, setComments] = useState([]);

  // Effect 1: 获取用户
  useEffect(() => {
    fetchUser(userId).then(setUser);
  }, [userId]);

  // Effect 2: 获取文章（依赖用户）
  useEffect(() => {
    if (!user) return;

    fetchPosts(user.id).then(setPosts);
  }, [user]);

  // Effect 3: 获取评论（依赖文章）
  useEffect(() => {
    if (posts.length === 0) return;

    const postIds = posts.map(p => p.id);
    fetchComments(postIds).then(setComments);
  }, [posts]);

  return (
    <div>
      <h1>{user?.name}</h1>
      <p>文章: {posts.length}</p>
      <p>评论: {comments.length}</p>
    </div>
  );
}
```

### 3. 使用 useReducer 替代复杂状态

```typescript
import { useReducer, useEffect } from 'react';

interface State {
  loading: boolean;
  data: any;
  error: string | null;
}

type Action =
  | { type: 'FETCH_START' }
  | { type: 'FETCH_SUCCESS'; payload: any }
  | { type: 'FETCH_ERROR'; payload: string };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'FETCH_START':
      return { loading: true, data: null, error: null };
    case 'FETCH_SUCCESS':
      return { loading: false, data: action.payload, error: null };
    case 'FETCH_ERROR':
      return { loading: false, data: null, error: action.payload };
    default:
      return state;
  }
}

function DataFetcher({ url }: { url: string }) {
  const [state, dispatch] = useReducer(reducer, {
    loading: false,
    data: null,
    error: null
  });

  useEffect(() => {
    let isCancelled = false;

    dispatch({ type: 'FETCH_START' });

    fetch(url)
      .then(res => res.json())
      .then(data => {
        if (!isCancelled) {
          dispatch({ type: 'FETCH_SUCCESS', payload: data });
        }
      })
      .catch(error => {
        if (!isCancelled) {
          dispatch({ type: 'FETCH_ERROR', payload: error.message });
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [url]);

  if (state.loading) return <div>加载中...</div>;
  if (state.error) return <div>错误: {state.error}</div>;
  return <div>{JSON.stringify(state.data)}</div>;
}
```

### 4. 性能优化：跳过不必要的 Effect

```typescript
function OptimizedComponent({ userId, config }: Props) {
  const [data, setData] = useState(null);

  // 使用 useMemo 缓存复杂计算的依赖
  const apiUrl = useMemo(
    () => `https://api.example.com/users/${userId}?${new URLSearchParams(config)}`,
    [userId, config]
  );

  useEffect(() => {
    fetchData(apiUrl).then(setData);
  }, [apiUrl]); // 只在 URL 变化时重新请求

  return <div>{JSON.stringify(data)}</div>;
}
```

### 5. 调试 Effect

```typescript
function DebugEffect() {
  const [count, setCount] = useState(0);
  const [name, setName] = useState('');

  useEffect(() => {
    console.log('Effect 执行了');
    console.log('当前 count:', count);
    console.log('当前 name:', name);

    // 使用 debugger 断点
    // debugger;

    return () => {
      console.log('清理函数执行了');
      console.log('清理时的 count:', count);
    };
  }, [count, name]);

  return (
    <div>
      <input value={name} onChange={e => setName(e.target.value)} />
      <button onClick={() => setCount(count + 1)}>Count: {count}</button>
    </div>
  );
}

// 使用自定义 Hook 调试依赖变化
function useWhyDidYouUpdate(name: string, props: any) {
  const previousProps = useRef<any>();

  useEffect(() => {
    if (previousProps.current) {
      const allKeys = Object.keys({ ...previousProps.current, ...props });
      const changedProps: any = {};

      allKeys.forEach(key => {
        if (previousProps.current[key] !== props[key]) {
          changedProps[key] = {
            from: previousProps.current[key],
            to: props[key]
          };
        }
      });

      if (Object.keys(changedProps).length > 0) {
        console.log('[why-did-you-update]', name, changedProps);
      }
    }

    previousProps.current = props;
  });
}

// 使用
function MyComponent({ count, name }: Props) {
  useWhyDidYouUpdate('MyComponent', { count, name });

  useEffect(() => {
    // ... 你的 effect
  }, [count, name]);

  return <div>{count} - {name}</div>;
}
```

---

## 总结

### useEffect 核心要点

1. **三种形式**：
   - 无依赖数组：每次渲染都执行
   - 空依赖数组 `[]`：仅挂载时执行一次
   - 有依赖 `[dep1, dep2]`：依赖变化时执行

2. **清理函数**：
   - 用于清理副作用（事件监听、定时器、订阅等）
   - 在组件卸载前执行
   - 在下次 effect 执行前执行

3. **依赖数组**：
   - 必须包含 effect 中使用的所有响应式值
   - 使用 ESLint 插件检查遗漏
   - 对象/数组/函数需要使用 useMemo/useCallback

4. **常见陷阱**：
   - 无限循环
   - 闭包陷阱
   - 竞态条件
   - 忘记清理
   - 依赖遗漏

5. **最佳实践**：
   - 每个 effect 只做一件事
   - 使用自定义 Hook 封装复用逻辑
   - 正确处理异步操作
   - 避免不必要的依赖

### 何时使用 useEffect

**应该使用**：

- 数据获取
- 订阅/事件监听
- DOM 操作
- 与浏览器 API 交互
- 日志记录

**不应该使用**：

- 计算派生状态（用 useMemo）
- 事件处理（直接在事件处理器中）
- 初始化状态（用 useState 的初始化函数）

### 与类组件生命周期的对应

```typescript
// componentDidMount
useEffect(() => {
  // 挂载时执行
}, []);

// componentDidUpdate
useEffect(() => {
  // 每次更新后执行
});

// componentWillUnmount
useEffect(() => {
  return () => {
    // 卸载前执行
  };
}, []);

// componentDidMount + componentDidUpdate + componentWillUnmount
useEffect(() => {
  // 挂载和更新后执行
  return () => {
    // 卸载前执行
  };
}, [dependency]);
```

---

## 参考资源

- [React 官方文档 - useEffect](https://react.dev/reference/react/useEffect)
- [React 官方文档 - 同步化 Effect](https://react.dev/learn/synchronizing-with-effects)
- [Dan Abramov - useEffect 完全指南](https://overreacted.io/a-complete-guide-to-useeffect/)

---

**最后的建议**：

1. 多练习，理解 effect 的执行时机
2. 使用 ESLint 插件避免常见错误
3. 学会调试依赖数组问题
4. 封装自定义 Hook 提高代码复用性
5. 参考优秀的开源项目学习最佳实践

祝你掌握 useEffect！🚀
