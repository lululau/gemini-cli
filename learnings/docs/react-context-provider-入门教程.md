# React Context Provider 入门教程 - 基于 Gemini CLI 实战解析

## 教程目标

本教程基于 Gemini
CLI 项目中的真实代码，为 React 和 Ink 初学者提供一份全面的 Context
Provider 入门教程。通过分析实际项目中的 Context 实现，您将学会从基础概念到高级模式的完整 Context
API 使用方法。

## 1. Context API 基础概念

### 什么是 Context API 以及为什么需要它

在 React 应用中，数据通常通过 props 从父组件传递到子组件。但当组件树变得复杂时，您可能需要将数据传递给深层嵌套的组件，这就产生了"props
drilling"问题。

**传统 props drilling 问题的演示：**

```typescript
// 传统方式 - 需要层层传递 props
const App = () => {
  const userSettings = { theme: 'dark', language: 'en' };
  return <Layout settings={userSettings} />;
};

const Layout = ({ settings }) => {
  return <Sidebar settings={settings} />;
};

const Sidebar = ({ settings }) => {
  return <UserProfile settings={settings} />;
};

const UserProfile = ({ settings }) => {
  return <Text color={settings.theme === 'dark' ? 'white' : 'black'}>
    Welcome!
  </Text>;
};
```

**使用 Context API 的解决方案：**

```typescript
// Context 方式 - 直接访问数据
const SettingsContext = createContext();

const App = () => {
  const userSettings = { theme: 'dark', language: 'en' };
  return (
    <SettingsContext.Provider value={userSettings}>
      <Layout />
    </SettingsContext.Provider>
  );
};

const UserProfile = () => {
  const settings = useContext(SettingsContext);
  return <Text color={settings.theme === 'dark' ? 'white' : 'black'}>
    Welcome!
  </Text>;
};
```

### Context 的三个核心概念

1. **createContext**: 创建一个 Context 对象
2. **Provider**: 提供数据的组件
3. **Consumer/useContext**: 消费数据的方式

```typescript
// 1. 创建 Context
const MyContext = createContext(defaultValue);

// 2. 提供数据
<MyContext.Provider value={data}>
  <ChildComponents />
</MyContext.Provider>

// 3. 消费数据
const data = useContext(MyContext);
```

## 2. 创建第一个 Context

让我们从一个简单的例子开始，创建一个主题 Context：

### 使用 createContext 创建 Context

```typescript
import { createContext, useContext } from 'react';

// 定义主题类型
interface Theme {
  primaryColor: string;
  backgroundColor: string;
  textColor: string;
}

// 创建 Context，提供默认值
const ThemeContext = createContext<Theme | undefined>(undefined);
```

### Provider 组件的基本结构

```typescript
interface ThemeProviderProps {
  children: React.ReactNode;
}

const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const theme: Theme = {
    primaryColor: '#007acc',
    backgroundColor: '#1e1e1e',
    textColor: '#ffffff',
  };

  return (
    <ThemeContext.Provider value={theme}>
      {children}
    </ThemeContext.Provider>
  );
};
```

### 自定义 Hook 的创建和使用

```typescript
// 自定义 Hook 提供类型安全和错误检查
const useTheme = (): Theme => {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

// 在组件中使用
const MyComponent = () => {
  const theme = useTheme();
  return (
    <Box backgroundColor={theme.backgroundColor}>
      <Text color={theme.textColor}>Hello, World!</Text>
    </Box>
  );
};
```

## 3. Gemini CLI 中的 SettingsContext 深度解析

让我们分析 Gemini CLI 中最简单的 Context 实现：

```typescript
// packages/cli/src/ui/contexts/SettingsContext.tsx
import React, { useContext } from 'react';
import type { LoadedSettings } from '../../config/settings.js';

export const SettingsContext = React.createContext<LoadedSettings | undefined>(
  undefined,
);

export const useSettings = () => {
  const context = useContext(SettingsContext);
  if (context === undefined) {
    throw new Error('useSettings must be used within a SettingsProvider');
  }
  return context;
};
```

### 分析 SettingsContext 的实现

**关键特点：**

1. **类型安全**: 使用 TypeScript 定义了 `LoadedSettings` 类型
2. **错误处理**: 在自定义 Hook 中检查 Context 是否存在
3. **简洁设计**: 只提供数据，不管理状态

### 理解 LoadedSettings 类型

`LoadedSettings` 包含用户的所有配置信息：

```typescript
interface LoadedSettings {
  user: Settings; // 用户设置
  system: Settings; // 系统设置
  merged: Settings; // 合并后的设置
  setValue: (scope: SettingScope, key: string, value: any) => Promise<void>;
  deleteValue: (scope: SettingScope, key: string) => Promise<void>;
}
```

### 在组件中使用 SettingsContext

```typescript
const MyComponent = () => {
  const settings = useSettings();

  return (
    <Box>
      <Text>Theme: {settings.merged.ui?.theme || 'default'}</Text>
      <Text>Debug Mode: {settings.merged.general?.debugMode ? 'On' : 'Off'}</Text>
    </Box>
  );
};
```

## 4. 复杂 Context：VimModeProvider 案例研究

VimModeProvider 展示了如何在 Context 中管理状态：

```typescript
// packages/cli/src/ui/contexts/VimModeContext.tsx
export type VimMode = 'NORMAL' | 'INSERT';

interface VimModeContextType {
  vimEnabled: boolean;
  vimMode: VimMode;
  toggleVimEnabled: () => Promise<boolean>;
  setVimMode: (mode: VimMode) => void;
}

const VimModeContext = createContext<VimModeContextType | undefined>(undefined);

export const VimModeProvider = ({
  children,
  settings,
}: {
  children: React.ReactNode;
  settings: LoadedSettings;
}) => {
  // 从设置中获取初始状态
  const initialVimEnabled = settings.merged.general?.vimMode ?? false;
  const [vimEnabled, setVimEnabled] = useState(initialVimEnabled);
  const [vimMode, setVimMode] = useState<VimMode>(
    initialVimEnabled ? 'NORMAL' : 'INSERT',
  );

  // 监听设置变化
  useEffect(() => {
    const enabled = settings.merged.general?.vimMode ?? false;
    setVimEnabled(enabled);
    if (enabled) {
      setVimMode('NORMAL');
    }
  }, [settings.merged.general?.vimMode]);

  // 切换 Vim 模式的函数
  const toggleVimEnabled = useCallback(async () => {
    const newValue = !vimEnabled;
    setVimEnabled(newValue);
    if (newValue) {
      setVimMode('NORMAL');
    }
    // 持久化到设置中
    await settings.setValue(SettingScope.User, 'general.vimMode', newValue);
    return newValue;
  }, [vimEnabled, settings]);

  const value = {
    vimEnabled,
    vimMode,
    toggleVimEnabled,
    setVimMode,
  };

  return (
    <VimModeContext.Provider value={value}>
      {children}
    </VimModeContext.Provider>
  );
};
```

### 关键学习点

1. **状态管理**: 使用 `useState` 管理本地状态
2. **副作用处理**: 使用 `useEffect` 监听外部变化
3. **性能优化**: 使用 `useCallback` 避免不必要的重新渲染
4. **异步操作**: 在 Context 中处理异步的设置保存
5. **依赖注入**: 通过 props 接收外部依赖（settings）

## 5. 高级 Context：SessionStatsProvider 解析

SessionStatsProvider 展示了复杂状态管理的 Context 设计：

```typescript
// packages/cli/src/ui/contexts/SessionContext.tsx
export interface SessionStatsState {
  sessionMetrics: SessionMetrics;
  modelMetrics: Record<string, ModelMetrics>;
  toolCallStats: ToolCallStats;
  recordToolCallDecision: (decision: ToolCallDecision) => void;
  recordModelUsage: (model: string, metrics: Partial<ModelMetrics>) => void;
  // ... 更多方法
}

export const SessionStatsProvider: React.FC<{
  children: React.ReactNode;
}> = ({ children }) => {
  // 多个相关状态
  const [sessionMetrics, setSessionMetrics] = useState<SessionMetrics>({
    startTime: Date.now(),
    totalInteractions: 0,
    totalErrors: 0,
  });

  const [modelMetrics, setModelMetrics] = useState<Record<string, ModelMetrics>>({});
  const [toolCallStats, setToolCallStats] = useState<ToolCallStats>({
    totalCalls: 0,
    acceptedCalls: 0,
    rejectedCalls: 0,
    modifiedCalls: 0,
  });

  // 使用 useMemo 计算派生状态
  const derivedStats = useMemo(() => {
    const totalTokens = Object.values(modelMetrics).reduce(
      (sum, metrics) => sum + metrics.tokens.total,
      0
    );
    return { totalTokens };
  }, [modelMetrics]);

  // 复杂的状态更新函数
  const recordModelUsage = useCallback((model: string, metrics: Partial<ModelMetrics>) => {
    setModelMetrics(prev => ({
      ...prev,
      [model]: {
        ...prev[model],
        ...metrics,
      },
    }));
  }, []);

  const value: SessionStatsState = {
    sessionMetrics,
    modelMetrics,
    toolCallStats,
    derivedStats,
    recordModelUsage,
    // ... 其他方法
  };

  return (
    <SessionStatsContext.Provider value={value}>
      {children}
    </SessionStatsContext.Provider>
  );
};
```

### 复杂状态管理的关键技巧

1. **状态分组**: 将相关的状态组织在一起
2. **计算属性**: 使用 `useMemo` 计算派生状态
3. **状态更新**: 使用函数式更新避免状态竞争
4. **性能优化**: 合理使用 `useCallback` 和 `useMemo`

## 6. Provider 嵌套模式深入解析

### 为什么需要嵌套 Providers

在 Gemini CLI 中，我们看到了这样的嵌套结构：

```typescript
const AppWrapper = () => {
  const kittyProtocolStatus = useKittyKeyboardProtocol();
  return (
    <SettingsContext.Provider value={settings}>
      <KeypressProvider
        kittyProtocolEnabled={kittyProtocolStatus.enabled}
        config={config}
        debugKeystrokeLogging={settings.merged.general?.debugKeystrokeLogging}
      >
        <SessionStatsProvider>
          <VimModeProvider settings={settings}>
            <AppContainer
              config={config}
              settings={settings}
              startupWarnings={startupWarnings}
              version={version}
              initializationResult={initializationResult}
            />
          </VimModeProvider>
        </SessionStatsProvider>
      </KeypressProvider>
    </SettingsContext.Provider>
  );
};
```

### 嵌套顺序的重要性

嵌套顺序决定了数据的可用性：

1. **SettingsContext** (最外层) - 提供基础配置
2. **KeypressProvider** - 需要访问 settings 中的键盘配置
3. **SessionStatsProvider** - 独立的统计功能
4. **VimModeProvider** - 需要访问 settings 来获取 Vim 配置

### 数据依赖关系的处理

```typescript
// VimModeProvider 依赖 SettingsContext
const VimModeProvider = ({ children, settings }) => {
  // 可以直接使用传入的 settings
  // 或者使用 useSettings() Hook
  const contextSettings = useSettings(); // 这样也可以

  // ...
};
```

### AppWrapper 组件的设计模式

AppWrapper 采用了"配置集中化"的模式：

```typescript
const AppWrapper = () => {
  // 1. 在顶层获取所有需要的数据
  const kittyProtocolStatus = useKittyKeyboardProtocol();

  // 2. 通过 Props 和 Context 分发数据
  return (
    <SettingsContext.Provider value={settings}>
      {/* 通过 Props 传递特定配置 */}
      <KeypressProvider kittyProtocolEnabled={kittyProtocolStatus.enabled}>
        {/* 嵌套其他 Providers */}
        <SessionStatsProvider>
          {/* 传递依赖的数据 */}
          <VimModeProvider settings={settings}>
            <AppContainer {...otherProps} />
          </VimModeProvider>
        </SessionStatsProvider>
      </KeypressProvider>
    </SettingsContext.Provider>
  );
};
```

## 7. 实际代码解析：startInteractiveUI 中的 Provider 结构

让我们逐层分析 `startInteractiveUI` 函数中的 Provider 结构：

```typescript
export async function startInteractiveUI(
  config: Config,
  settings: LoadedSettings,
  startupWarnings: string[],
  workspaceRoot: string = process.cwd(),
  initializationResult: InitializationResult,
) {
  // 1. 终端设置
  if (!config.getScreenReader()) {
    process.stdout.write('\x1b[?7l'); // 禁用自动换行
    registerCleanup(() => {
      process.stdout.write('\x1b[?7h'); // 恢复换行
    });
  }

  // 2. 获取版本信息和设置窗口标题
  const version = await getCliVersion();
  setWindowTitle(basename(workspaceRoot), settings);

  // 3. 创建 AppWrapper 组件
  const AppWrapper = () => {
    const kittyProtocolStatus = useKittyKeyboardProtocol();
    return (
      <SettingsContext.Provider value={settings}>
        <KeypressProvider
          kittyProtocolEnabled={kittyProtocolStatus.enabled}
          config={config}
          debugKeystrokeLogging={settings.merged.general?.debugKeystrokeLogging}
        >
          <SessionStatsProvider>
            <VimModeProvider settings={settings}>
              <AppContainer
                config={config}
                settings={settings}
                startupWarnings={startupWarnings}
                version={version}
                initializationResult={initializationResult}
              />
            </VimModeProvider>
          </SessionStatsProvider>
        </KeypressProvider>
      </SettingsContext.Provider>
    );
  };

  // 4. 渲染应用
  const instance = render(
    process.env['DEBUG'] ? (
      <React.StrictMode>
        <AppWrapper />
      </React.StrictMode>
    ) : (
      <AppWrapper />
    ),
    {
      exitOnCtrlC: false,
      isScreenReaderEnabled: config.getScreenReader(),
    },
  );

  // 5. 设置清理函数
  registerCleanup(() => instance.unmount());
}
```

### 逐层分析每个 Provider 的作用

#### 第一层：SettingsContext.Provider

```typescript
<SettingsContext.Provider value={settings}>
```

- **作用**: 提供全局的用户设置
- **数据**: 用户配置、主题、快捷键等
- **依赖**: 无（最基础的数据）

#### 第二层：KeypressProvider

```typescript
<KeypressProvider
  kittyProtocolEnabled={kittyProtocolStatus.enabled}
  config={config}
  debugKeystrokeLogging={settings.merged.general?.debugKeystrokeLogging}
>
```

- **作用**: 处理键盘输入和快捷键
- **数据**: 键盘事件、快捷键映射
- **依赖**: 需要 settings 中的键盘配置

#### 第三层：SessionStatsProvider

```typescript
<SessionStatsProvider>
```

- **作用**: 管理会话统计信息
- **数据**: 使用时间、命令次数、错误统计
- **依赖**: 独立运行，不依赖其他 Context

#### 第四层：VimModeProvider

```typescript
<VimModeProvider settings={settings}>
```

- **作用**: 管理 Vim 模式状态
- **数据**: Vim 是否启用、当前模式（NORMAL/INSERT）
- **依赖**: 需要 settings 来获取 Vim 配置

### Provider 之间的数据流向

```
用户操作
    ↓
KeypressProvider 捕获键盘事件
    ↓
根据 VimModeProvider 的状态决定如何处理
    ↓
SessionStatsProvider 记录统计信息
    ↓
所有 Provider 的状态变化触发 UI 更新
```

### 错误边界和错误处理

每个 Context 都有自己的错误处理机制：

```typescript
export const useSettings = () => {
  const context = useContext(SettingsContext);
  if (context === undefined) {
    throw new Error('useSettings must be used within a SettingsProvider');
  }
  return context;
};
```

这种模式确保：

1. **类型安全**: TypeScript 会检查 Context 的使用
2. **运行时安全**: 如果在错误的地方使用会抛出明确的错误
3. **调试友好**: 错误信息清楚地说明了问题所在

## 8. 最佳实践和常见陷阱

### Context 的适用场景

**适合使用 Context 的情况：**

- 全局配置（主题、语言、用户设置）
- 用户认证状态
- 应用级别的状态（如购物车、通知）
- 深层组件需要的数据

**不适合使用 Context 的情况：**

- 频繁变化的数据（会导致大量重新渲染）
- 只有少数组件需要的数据
- 简单的父子组件通信

### 避免过度使用 Context

```typescript
// ❌ 不好的做法 - 为每个小状态创建 Context
const CounterContext = createContext();
const ToggleContext = createContext();
const InputContext = createContext();

// ✅ 好的做法 - 将相关状态组合
const UIStateContext = createContext({
  counter: 0,
  isToggled: false,
  inputValue: '',
});
```

### 性能优化技巧

#### 1. 拆分 Context

```typescript
// ❌ 单个大 Context 会导致不必要的重新渲染
const AppContext = createContext({
  user: userState,
  ui: uiState,
  data: dataState,
});

// ✅ 拆分成多个小 Context
const UserContext = createContext(userState);
const UIContext = createContext(uiState);
const DataContext = createContext(dataState);
```

#### 2. 使用 useMemo 优化 Provider 的 value

```typescript
const MyProvider = ({ children }) => {
  const [state, setState] = useState(initialState);

  // ✅ 使用 useMemo 避免每次渲染都创建新对象
  const value = useMemo(() => ({
    state,
    setState,
  }), [state]);

  return (
    <MyContext.Provider value={value}>
      {children}
    </MyContext.Provider>
  );
};
```

#### 3. 使用 useCallback 优化函数

```typescript
const MyProvider = ({ children }) => {
  const [state, setState] = useState(initialState);

  // ✅ 使用 useCallback 避免函数重新创建
  const updateState = useCallback((newValue) => {
    setState(newValue);
  }, []);

  const value = useMemo(() => ({
    state,
    updateState,
  }), [state, updateState]);

  return (
    <MyContext.Provider value={value}>
      {children}
    </MyContext.Provider>
  );
};
```

### 常见错误和解决方案

#### 1. 忘记提供 Provider

```typescript
// ❌ 错误：在没有 Provider 的地方使用 Context
const MyComponent = () => {
  const data = useContext(MyContext); // 会得到 undefined
  return <Text>{data.value}</Text>; // 运行时错误
};

// ✅ 解决方案：添加错误检查
const useMyContext = () => {
  const context = useContext(MyContext);
  if (context === undefined) {
    throw new Error('useMyContext must be used within MyProvider');
  }
  return context;
};
```

#### 2. Context 值频繁变化导致性能问题

```typescript
// ❌ 每次渲染都创建新对象
const MyProvider = ({ children }) => {
  const [count, setCount] = useState(0);

  return (
    <MyContext.Provider value={{ count, setCount }}>
      {children}
    </MyContext.Provider>
  );
};

// ✅ 使用 useMemo 优化
const MyProvider = ({ children }) => {
  const [count, setCount] = useState(0);

  const value = useMemo(() => ({ count, setCount }), [count]);

  return (
    <MyContext.Provider value={value}>
      {children}
    </MyContext.Provider>
  );
};
```

### 测试 Context 的方法

```typescript
import { render } from '@testing-library/react';
import { MyProvider, useMyContext } from './MyContext';

// 创建测试组件
const TestComponent = () => {
  const { value, setValue } = useMyContext();
  return (
    <div>
      <span data-testid="value">{value}</span>
      <button onClick={() => setValue('new value')}>
        Update
      </button>
    </div>
  );
};

// 测试 Context
test('MyContext provides and updates value', () => {
  const { getByTestId, getByText } = render(
    <MyProvider>
      <TestComponent />
    </MyProvider>
  );

  expect(getByTestId('value')).toHaveTextContent('initial value');

  fireEvent.click(getByText('Update'));

  expect(getByTestId('value')).toHaveTextContent('new value');
});
```

## 9. 动手实践：创建自己的 Context

让我们从零开始创建一个主题 Context，并集成到 Ink 应用中：

### 第一步：定义主题类型和 Context

```typescript
// theme/types.ts
export interface Theme {
  name: string;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    text: string;
    error: string;
    success: string;
  };
  spacing: {
    small: number;
    medium: number;
    large: number;
  };
}

export const themes: Record<string, Theme> = {
  dark: {
    name: 'dark',
    colors: {
      primary: '#007acc',
      secondary: '#6c757d',
      background: '#1e1e1e',
      text: '#ffffff',
      error: '#dc3545',
      success: '#28a745',
    },
    spacing: {
      small: 1,
      medium: 2,
      large: 4,
    },
  },
  light: {
    name: 'light',
    colors: {
      primary: '#0066cc',
      secondary: '#6c757d',
      background: '#ffffff',
      text: '#000000',
      error: '#dc3545',
      success: '#28a745',
    },
    spacing: {
      small: 1,
      medium: 2,
      large: 4,
    },
  },
};
```

### 第二步：创建 ThemeContext

```typescript
// theme/ThemeContext.tsx
import React, { createContext, useContext, useState, useCallback, useMemo } from 'react';
import { Theme, themes } from './types';

interface ThemeContextType {
  currentTheme: Theme;
  themeName: string;
  availableThemes: string[];
  setTheme: (themeName: string) => void;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

interface ThemeProviderProps {
  children: React.ReactNode;
  initialTheme?: string;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({
  children,
  initialTheme = 'dark',
}) => {
  const [themeName, setThemeName] = useState(initialTheme);

  const setTheme = useCallback((newThemeName: string) => {
    if (themes[newThemeName]) {
      setThemeName(newThemeName);
      // 这里可以添加持久化逻辑
      localStorage.setItem('theme', newThemeName);
    }
  }, []);

  const toggleTheme = useCallback(() => {
    const newTheme = themeName === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
  }, [themeName, setTheme]);

  const value = useMemo(() => ({
    currentTheme: themes[themeName],
    themeName,
    availableThemes: Object.keys(themes),
    setTheme,
    toggleTheme,
  }), [themeName, setTheme, toggleTheme]);

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (context === undefined) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};
```

### 第三步：创建主题化的组件

```typescript
// components/ThemedBox.tsx
import React from 'react';
import { Box, Text } from 'ink';
import { useTheme } from '../theme/ThemeContext';

interface ThemedBoxProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'error' | 'success';
  padding?: 'small' | 'medium' | 'large';
}

export const ThemedBox: React.FC<ThemedBoxProps> = ({
  children,
  variant = 'primary',
  padding = 'medium',
}) => {
  const { currentTheme } = useTheme();

  return (
    <Box
      borderStyle="round"
      borderColor={currentTheme.colors[variant]}
      padding={currentTheme.spacing[padding]}
    >
      {children}
    </Box>
  );
};

export const ThemedText: React.FC<{
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'error' | 'success';
}> = ({ children, variant = 'primary' }) => {
  const { currentTheme } = useTheme();

  return (
    <Text color={currentTheme.colors[variant]}>
      {children}
    </Text>
  );
};
```

### 第四步：创建主题切换器

```typescript
// components/ThemeToggler.tsx
import React from 'react';
import { Box, Text } from 'ink';
import { useTheme } from '../theme/ThemeContext';

export const ThemeToggler: React.FC = () => {
  const { themeName, availableThemes, setTheme, toggleTheme } = useTheme();

  return (
    <Box flexDirection="column">
      <Text>Current theme: {themeName}</Text>
      <Text>Press 't' to toggle theme</Text>
      <Box>
        {availableThemes.map((theme) => (
          <Text
            key={theme}
            color={theme === themeName ? 'green' : 'gray'}
          >
            {theme}{theme === themeName ? ' (active)' : ''}
          </Text>
        ))}
      </Box>
    </Box>
  );
};
```

### 第五步：集成到 Ink 应用中

```typescript
// App.tsx
import React, { useEffect } from 'react';
import { render, useInput } from 'ink';
import { ThemeProvider, useTheme } from './theme/ThemeContext';
import { ThemedBox, ThemedText } from './components/ThemedBox';
import { ThemeToggler } from './components/ThemeToggler';

const AppContent: React.FC = () => {
  const { toggleTheme, currentTheme } = useTheme();

  useInput((input, key) => {
    if (input === 't') {
      toggleTheme();
    }
    if (key.ctrl && input === 'c') {
      process.exit(0);
    }
  });

  return (
    <Box
      flexDirection="column"
      padding={2}
      backgroundColor={currentTheme.colors.background}
    >
      <ThemedText variant="primary">
        Welcome to the Themed Ink App!
      </ThemedText>

      <ThemedBox variant="success" padding="medium">
        <ThemedText variant="success">
          This is a success message
        </ThemedText>
      </ThemedBox>

      <ThemedBox variant="error" padding="small">
        <ThemedText variant="error">
          This is an error message
        </ThemedText>
      </ThemedBox>

      <ThemeToggler />

      <Text color="gray">
        Press Ctrl+C to exit
      </Text>
    </Box>
  );
};

const App: React.FC = () => {
  return (
    <ThemeProvider initialTheme="dark">
      <AppContent />
    </ThemeProvider>
  );
};

// 启动应用
render(<App />);
```

## 10. 进阶话题

### Context 的组合模式

当您有多个相关的 Context 时，可以创建一个组合 Provider：

```typescript
// providers/AppProviders.tsx
import React from 'react';
import { ThemeProvider } from '../theme/ThemeContext';
import { UserProvider } from '../user/UserContext';
import { SettingsProvider } from '../settings/SettingsContext';

interface AppProvidersProps {
  children: React.ReactNode;
}

export const AppProviders: React.FC<AppProvidersProps> = ({ children }) => {
  return (
    <SettingsProvider>
      <UserProvider>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </UserProvider>
    </SettingsProvider>
  );
};

// 使用
const App = () => (
  <AppProviders>
    <MainApp />
  </AppProviders>
);
```

### 多个 Context 的协调

有时候不同的 Context 需要相互协调：

```typescript
// 主题 Context 需要响应用户设置的变化
const ThemeProvider = ({ children }) => {
  const { settings } = useSettings(); // 依赖 SettingsContext
  const [theme, setTheme] = useState(settings.theme);

  useEffect(() => {
    setTheme(settings.theme);
  }, [settings.theme]);

  // ...
};
```

### Context 与其他状态管理库的对比

| 特性     | Context API | Redux    | Zustand  |
| -------- | ----------- | -------- | -------- |
| 学习曲线 | 低          | 高       | 低       |
| 样板代码 | 少          | 多       | 很少     |
| 性能     | 中等        | 高       | 高       |
| 调试工具 | 基础        | 优秀     | 良好     |
| 适用场景 | 中小型应用  | 大型应用 | 中型应用 |

### 在大型应用中的 Context 架构设计

```typescript
// 分层的 Context 架构
const AppProviders = ({ children }) => (
  // 第一层：基础设施层
  <ErrorBoundaryProvider>
    <LoggerProvider>
      <ConfigProvider>

        {/* 第二层：数据层 */}
        <AuthProvider>
          <APIProvider>
            <CacheProvider>

              {/* 第三层：业务层 */}
              <UserProvider>
                <ProjectProvider>
                  <WorkspaceProvider>

                    {/* 第四层：UI 层 */}
                    <ThemeProvider>
                      <LayoutProvider>
                        <NotificationProvider>
                          {children}
                        </NotificationProvider>
                      </LayoutProvider>
                    </ThemeProvider>

                  </WorkspaceProvider>
                </ProjectProvider>
              </UserProvider>

            </CacheProvider>
          </APIProvider>
        </AuthProvider>

      </ConfigProvider>
    </LoggerProvider>
  </ErrorBoundaryProvider>
);
```

## 总结

通过这份详细的教程，我们学习了：

1. **Context API 基础** - 理解了为什么需要 Context 以及如何使用
2. **实际案例分析** - 深入分析了 Gemini CLI 中的真实 Context 实现
3. **最佳实践** - 学会了如何设计高性能、可维护的 Context
4. **实战练习** - 创建了自己的主题 Context 系统
5. **进阶模式** - 了解了复杂应用中的 Context 架构设计

Context API 是 React 中强大的状态管理工具，但需要谨慎使用。通过理解 Gemini
CLI 中的实际应用，您现在应该能够在自己的项目中有效地使用 Context API 了。

记住关键原则：

- **合理使用** - 不要为了使用而使用
- **性能优化** - 使用 useMemo 和 useCallback
- **错误处理** - 总是检查 Context 是否存在
- **类型安全** - 充分利用 TypeScript 的类型系统
- **测试覆盖** - 为 Context 编写完整的测试

希望这份教程能帮助您掌握 React Context API 的精髓！
