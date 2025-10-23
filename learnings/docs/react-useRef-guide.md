# React useRef 完全指南

## 目录

1. [什么是 useRef](#什么是-useref)
2. [useRef 与 useState 的区别](#useref-与-usestate-的区别)
3. [useRef 的两大应用场景](#useref-的两大应用场景)
4. [实战示例](#实战示例)
5. [常见陷阱与注意事项](#常见陷阱与注意事项)
6. [最佳实践](#最佳实践)

---

## 什么是 useRef

`useRef`
是 React 提供的一个 Hook，它返回一个可变的 ref 对象，这个对象在组件的整个生命周期内保持不变。

### 基本语法

```jsx
const refContainer = useRef(initialValue);
```

返回的 ref 对象有一个 `current` 属性，可以通过 `refContainer.current`
访问和修改。

### 核心特点

1. **持久化存储**：ref 对象在组件重新渲染时保持不变
2. **不触发重渲染**：修改 `ref.current` 不会导致组件重新渲染
3. **同步更新**：修改 `ref.current` 是同步的，立即生效

---

## useRef 与 useState 的区别

这是初学者最容易混淆的地方，让我们通过对比来理解：

### 对比表格

| 特性       | useState           | useRef               |
| ---------- | ------------------ | -------------------- |
| 触发重渲染 | ✅ 是              | ❌ 否                |
| 更新时机   | 异步（批处理）     | 同步（立即）         |
| 使用场景   | 存储影响 UI 的数据 | 存储不影响 UI 的数据 |
| 访问方式   | 直接访问变量       | 通过 `.current` 访问 |

### 示例对比

```jsx
import React, { useState, useRef } from 'react';

function ComparisonDemo() {
  const [count, setCount] = useState(0);
  const countRef = useRef(0);

  const handleStateClick = () => {
    setCount(count + 1);
    console.log('State count:', count); // 输出旧值（异步更新）
    // 组件会重新渲染
  };

  const handleRefClick = () => {
    countRef.current += 1;
    console.log('Ref count:', countRef.current); // 输出新值（同步更新）
    // 组件不会重新渲染
  };

  return (
    <div>
      <p>State Count: {count}</p>
      <p>Ref Count: {countRef.current}</p>
      <button onClick={handleStateClick}>增加 State</button>
      <button onClick={handleRefClick}>增加 Ref</button>
    </div>
  );
}
```

**关键观察**：

- 点击 "增加 State" 按钮，界面立即更新
- 点击 "增加 Ref" 按钮，界面不更新（但值确实改变了）

---

## useRef 的两大应用场景

### 场景一：访问 DOM 元素

这是 `useRef` 最常见的用途，类似于 Vue 中的 `$refs`。

#### 示例 1：聚焦输入框

```jsx
import React, { useRef } from 'react';

function FocusInput() {
  const inputRef = useRef(null);

  const handleFocus = () => {
    // 直接操作 DOM
    inputRef.current.focus();
  };

  return (
    <div>
      <input ref={inputRef} type="text" placeholder="点击按钮聚焦我" />
      <button onClick={handleFocus}>聚焦输入框</button>
    </div>
  );
}
```

**解释**：

1. `useRef(null)` 初始化 ref，初始值为 `null`
2. 通过 `ref={inputRef}` 将 ref 绑定到 DOM 元素
3. React 会自动将 DOM 元素赋值给 `inputRef.current`
4. 可以调用原生 DOM 方法如 `focus()`

#### 示例 2：测量元素尺寸

```jsx
import React, { useRef, useState } from 'react';

function MeasureElement() {
  const divRef = useRef(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

  const measureSize = () => {
    if (divRef.current) {
      const { width, height } = divRef.current.getBoundingClientRect();
      setDimensions({ width, height });
    }
  };

  return (
    <div>
      <div
        ref={divRef}
        style={{
          width: '300px',
          height: '200px',
          background: 'lightblue',
        }}
      >
        调整窗口大小后点击按钮
      </div>
      <button onClick={measureSize}>测量尺寸</button>
      <p>宽度: {dimensions.width}px</p>
      <p>高度: {dimensions.height}px</p>
    </div>
  );
}
```

#### 示例 3：滚动到指定位置

```jsx
import React, { useRef } from 'react';

function ScrollToSection() {
  const section1Ref = useRef(null);
  const section2Ref = useRef(null);
  const section3Ref = useRef(null);

  const scrollToSection = (ref) => {
    ref.current.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    });
  };

  return (
    <div>
      <nav style={{ position: 'fixed', top: 0, background: 'white' }}>
        <button onClick={() => scrollToSection(section1Ref)}>章节 1</button>
        <button onClick={() => scrollToSection(section2Ref)}>章节 2</button>
        <button onClick={() => scrollToSection(section3Ref)}>章节 3</button>
      </nav>

      <div style={{ marginTop: '50px' }}>
        <section
          ref={section1Ref}
          style={{ height: '100vh', background: '#ffcccc' }}
        >
          <h2>章节 1</h2>
        </section>
        <section
          ref={section2Ref}
          style={{ height: '100vh', background: '#ccffcc' }}
        >
          <h2>章节 2</h2>
        </section>
        <section
          ref={section3Ref}
          style={{ height: '100vh', background: '#ccccff' }}
        >
          <h2>章节 3</h2>
        </section>
      </div>
    </div>
  );
}
```

### 场景二：存储可变值（不触发重渲染）

#### 示例 4：保存上一次的值

```jsx
import React, { useState, useRef, useEffect } from 'react';

function UsePrevious(value) {
  const prevRef = useRef();

  useEffect(() => {
    prevRef.current = value;
  }, [value]);

  return prevRef.current;
}

function Counter() {
  const [count, setCount] = useState(0);
  const prevCount = UsePrevious(count);

  return (
    <div>
      <p>当前值: {count}</p>
      <p>上一次的值: {prevCount}</p>
      <button onClick={() => setCount(count + 1)}>增加</button>
      <button onClick={() => setCount(count - 1)}>减少</button>
    </div>
  );
}
```

**工作原理**：

1. 首次渲染：`prevRef.current` 是 `undefined`，`count` 是 `0`
2. 点击增加后：渲染时 `prevCount` 还是 `undefined`，`useEffect` 执行后
   `prevRef.current` 变成 `0`
3. 再次点击：渲染时 `prevCount` 是 `0`，`count` 是 `1`

#### 示例 5：定时器引用

```jsx
import React, { useState, useRef, useEffect } from 'react';

function Stopwatch() {
  const [time, setTime] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const intervalRef = useRef(null);

  useEffect(() => {
    if (isRunning) {
      intervalRef.current = setInterval(() => {
        setTime((t) => t + 1);
      }, 1000);
    } else {
      // 清除定时器
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isRunning]);

  const handleStart = () => setIsRunning(true);
  const handleStop = () => setIsRunning(false);
  const handleReset = () => {
    setIsRunning(false);
    setTime(0);
  };

  return (
    <div>
      <h2>秒表: {time} 秒</h2>
      <button onClick={handleStart} disabled={isRunning}>
        开始
      </button>
      <button onClick={handleStop} disabled={!isRunning}>
        停止
      </button>
      <button onClick={handleReset}>重置</button>
    </div>
  );
}
```

**为什么使用 ref 存储定时器 ID？**

- 定时器 ID 不需要触发重渲染
- 需要在多个函数间共享这个 ID
- 如果用普通变量，每次渲染都会重置

#### 示例 6：避免过时的闭包问题

```jsx
import React, { useState, useRef, useEffect } from 'react';

function ChatRoom() {
  const [message, setMessage] = useState('');
  const messageRef = useRef('');

  // 更新 ref，保持最新值
  useEffect(() => {
    messageRef.current = message;
  }, [message]);

  useEffect(() => {
    // 模拟每 3 秒发送一次消息
    const interval = setInterval(() => {
      if (messageRef.current) {
        console.log('发送消息:', messageRef.current);
        // 这里总是能获取到最新的 message 值
      }
    }, 3000);

    return () => clearInterval(interval);
  }, []); // 空依赖数组，但仍能访问最新的 message

  return (
    <div>
      <input
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        placeholder="输入消息"
      />
      <p>当前消息: {message}</p>
    </div>
  );
}
```

#### 示例 7：记录组件渲染次数

```jsx
import React, { useState, useRef, useEffect } from 'react';

function RenderCounter() {
  const [count, setCount] = useState(0);
  const renderCount = useRef(0);

  useEffect(() => {
    renderCount.current += 1;
  });

  return (
    <div>
      <p>计数: {count}</p>
      <p>组件渲染次数: {renderCount.current}</p>
      <button onClick={() => setCount(count + 1)}>增加计数</button>
    </div>
  );
}
```

**注意**：这里不能用 `useState`，因为：

- 如果用 `useState` 记录渲染次数，更新状态会触发重渲染
- 重渲染又会增加渲染次数，导致无限循环

---

## 实战示例

### 综合案例：视频播放器控制

```jsx
import React, { useRef, useState } from 'react';

function VideoPlayer() {
  const videoRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const handlePlayPause = () => {
    if (isPlaying) {
      videoRef.current.pause();
    } else {
      videoRef.current.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleTimeUpdate = () => {
    setCurrentTime(videoRef.current.currentTime);
  };

  const handleLoadedMetadata = () => {
    setDuration(videoRef.current.duration);
  };

  const handleSeek = (e) => {
    const newTime = (e.target.value / 100) * duration;
    videoRef.current.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const handleSpeedChange = (speed) => {
    videoRef.current.playbackRate = speed;
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto' }}>
      <video
        ref={videoRef}
        src="your-video.mp4"
        onTimeUpdate={handleTimeUpdate}
        onLoadedMetadata={handleLoadedMetadata}
        style={{ width: '100%' }}
      />

      <div style={{ marginTop: '10px' }}>
        <button onClick={handlePlayPause}>{isPlaying ? '暂停' : '播放'}</button>

        <div style={{ margin: '10px 0' }}>
          <input
            type="range"
            min="0"
            max="100"
            value={(currentTime / duration) * 100 || 0}
            onChange={handleSeek}
            style={{ width: '100%' }}
          />
          <div>
            {formatTime(currentTime)} / {formatTime(duration)}
          </div>
        </div>

        <div>
          <span>播放速度: </span>
          <button onClick={() => handleSpeedChange(0.5)}>0.5x</button>
          <button onClick={() => handleSpeedChange(1)}>1x</button>
          <button onClick={() => handleSpeedChange(1.5)}>1.5x</button>
          <button onClick={() => handleSpeedChange(2)}>2x</button>
        </div>
      </div>
    </div>
  );
}
```

### 综合案例：自定义输入框（带验证）

```jsx
import React, { useRef, useState, useEffect } from 'react';

function ValidatedInput() {
  const inputRef = useRef(null);
  const [value, setValue] = useState('');
  const [error, setError] = useState('');
  const validationTimerRef = useRef(null);

  const validate = (val) => {
    if (val.length < 3) {
      return '至少需要 3 个字符';
    }
    if (!/^[a-zA-Z0-9]+$/.test(val)) {
      return '只能包含字母和数字';
    }
    return '';
  };

  const handleChange = (e) => {
    const newValue = e.target.value;
    setValue(newValue);

    // 清除之前的定时器
    if (validationTimerRef.current) {
      clearTimeout(validationTimerRef.current);
    }

    // 防抖：500ms 后才验证
    validationTimerRef.current = setTimeout(() => {
      const errorMsg = validate(newValue);
      setError(errorMsg);
    }, 500);
  };

  const handleClear = () => {
    setValue('');
    setError('');
    inputRef.current.focus();
  };

  useEffect(() => {
    // 组件挂载时自动聚焦
    inputRef.current.focus();

    // 清理函数
    return () => {
      if (validationTimerRef.current) {
        clearTimeout(validationTimerRef.current);
      }
    };
  }, []);

  return (
    <div>
      <div>
        <input
          ref={inputRef}
          type="text"
          value={value}
          onChange={handleChange}
          placeholder="输入用户名"
          style={{
            borderColor: error ? 'red' : 'gray',
            padding: '8px',
            fontSize: '16px',
          }}
        />
        <button onClick={handleClear}>清空</button>
      </div>
      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
```

---

## 常见陷阱与注意事项

### 1. ⚠️ 修改 ref 不会触发重渲染

```jsx
// ❌ 错误示例
function BadExample() {
  const countRef = useRef(0);

  const increment = () => {
    countRef.current += 1;
    // 界面不会更新！
  };

  return (
    <div>
      <p>{countRef.current}</p> {/* 不会更新 */}
      <button onClick={increment}>增加</button>
    </div>
  );
}

// ✅ 正确做法：如果需要更新 UI，使用 useState
function GoodExample() {
  const [count, setCount] = useState(0);

  const increment = () => {
    setCount(count + 1);
  };

  return (
    <div>
      <p>{count}</p>
      <button onClick={increment}>增加</button>
    </div>
  );
}
```

### 2. ⚠️ 不要在渲染期间读写 ref.current

```jsx
// ❌ 错误示例
function BadExample() {
  const ref = useRef(0);
  ref.current += 1; // 不要在渲染时修改！

  return <div>{ref.current}</div>;
}

// ✅ 正确做法：在事件处理器或 useEffect 中修改
function GoodExample() {
  const ref = useRef(0);

  useEffect(() => {
    ref.current += 1; // 在副作用中修改
  });

  const handleClick = () => {
    ref.current += 1; // 在事件处理器中修改
  };

  return <button onClick={handleClick}>点击</button>;
}
```

**为什么？**

- 渲染应该是纯函数，不应该有副作用
- 在渲染期间修改 ref 可能导致不可预测的行为

### 3. ⚠️ ref.current 在首次渲染时可能是 null

```jsx
function Example() {
  const divRef = useRef(null);

  // ❌ 危险：首次渲染时 divRef.current 是 null
  const width = divRef.current.offsetWidth;

  // ✅ 正确：先检查是否存在
  const safeWidth = divRef.current?.offsetWidth || 0;

  return <div ref={divRef}>内容</div>;
}
```

### 4. ⚠️ 不要过度使用 ref

```jsx
// ❌ 不好的做法：用 ref 管理应该用 state 的数据
function BadForm() {
  const nameRef = useRef('');
  const emailRef = useRef('');

  return (
    <form>
      <input onChange={(e) => (nameRef.current = e.target.value)} />
      <input onChange={(e) => (emailRef.current = e.target.value)} />
    </form>
  );
}

// ✅ 好的做法：表单数据应该用 state
function GoodForm() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  return (
    <form>
      <input value={name} onChange={(e) => setName(e.target.value)} />
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
    </form>
  );
}
```

---

## 最佳实践

### 1. 何时使用 useRef

✅ **使用 useRef 的场景**：

- 访问 DOM 元素
- 存储定时器 ID、订阅 ID
- 存储上一次的值
- 存储不需要触发渲染的可变值
- 避免闭包陷阱

❌ **不使用 useRef 的场景**：

- 需要触发重渲染的数据 → 用 `useState`
- 只在组件内部使用的临时变量 → 用普通变量
- 需要跨组件共享的状态 → 用 `useContext` 或状态管理库

### 2. 命名约定

```jsx
// 推荐的命名方式
const inputRef = useRef(null); // DOM 元素
const timerIdRef = useRef(null); // 存储 ID
const previousValueRef = useRef(0); // 存储上一次的值
```

### 3. 类型安全（TypeScript）

```typescript
import { useRef } from 'react';

// DOM 元素
const inputRef = useRef<HTMLInputElement>(null);

// 可变值
const countRef = useRef<number>(0);

// 定时器
const timerRef = useRef<NodeJS.Timeout | null>(null);
```

### 4. 清理副作用

```jsx
function Example() {
  const timerRef = useRef(null);

  useEffect(() => {
    timerRef.current = setInterval(() => {
      console.log('tick');
    }, 1000);

    // ✅ 记得清理
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, []);

  return <div>示例</div>;
}
```

### 5. 与 useEffect 配合使用

```jsx
function ScrollToTop() {
  const containerRef = useRef(null);

  useEffect(() => {
    // ✅ 在 useEffect 中操作 DOM
    if (containerRef.current) {
      containerRef.current.scrollTop = 0;
    }
  }, []); // 组件挂载后执行

  return (
    <div ref={containerRef} style={{ height: '500px', overflow: 'auto' }}>
      {/* 内容 */}
    </div>
  );
}
```

---

## 总结

### useRef 的核心特性

1. **返回可变的 ref 对象**，通过 `.current` 访问
2. **不触发重渲染**，适合存储不影响 UI 的数据
3. **在整个组件生命周期内保持不变**

### 两大应用场景

1. **访问 DOM 元素**
   - 聚焦、滚动、测量、动画
   - 集成第三方 DOM 库

2. **存储可变值**
   - 定时器/订阅 ID
   - 上一次的值
   - 避免闭包问题
   - 渲染计数

### 与其他 Hook 的关系

- **vs useState**：ref 不触发渲染，state 触发渲染
- **vs useEffect**：常配合使用，在 effect 中操作 DOM
- **vs useContext**：ref 是组件内部的，context 是跨组件的

### 记忆口诀

> **需要显示，用 State；**  
> **需要引用，用 Ref；**  
> **State 管界面，Ref 管幕后。**

---

## 练习题

试着自己实现以下功能来巩固 `useRef` 的用法：

1. **点击外部关闭弹窗**：使用 ref 检测点击是否在元素外部
2. **自动保存草稿**：使用 ref 存储定时器，每 5 秒自动保存
3. **无限滚动**：使用 ref 检测滚动位置，触底时加载更多
4. **图片懒加载**：使用 ref 和 IntersectionObserver
5. **自定义 Hook**：`useDebounce` 使用 ref 存储定时器

祝学习愉快！🎉
