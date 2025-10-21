# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Development
- `npm run build` - Build the entire project
- `npm run build:packages` - Build all workspace packages
- `npm run build:sandbox` - Build the sandbox environment
- `npm run build:vscode` - Build VS Code companion
- `npm run start` - Start development server
- `npm run debug` - Start with debug mode

### Testing
- `npm run test` - Run all tests in parallel across workspaces
- `npm run test:integration:all` - Run all integration tests (none, docker, podman)
- `npm run test:integration:sandbox:none` - Run integration tests without sandbox
- `npm run test:integration:sandbox:docker` - Run integration tests with Docker sandbox
- `npm run test:e2e` - Run end-to-end tests
- `npm run test:ci` - Run CI tests with no warnings allowed
- `npm run test:scripts` - Run script-specific tests

### Code Quality
- `npm run lint` - Lint TypeScript files and integration tests
- `npm run lint:fix` - Fix linting issues automatically
- `npm run lint:ci` - Lint with zero warnings (CI mode)
- `npm run format` - Format code with Prettier
- `npm run typecheck` - Type check all workspaces
- `npm run preflight` - Complete pre-commit checks (clean, ci, format, lint:ci, build, typecheck, test:ci)

### Single Test Commands
- Use vitest directly for single tests: `vitest run --run path/to/test.test.ts`
- For integration tests, run with specific sandbox environment variables

## Architecture Overview

This is a monorepo workspace with the following structure:

### Core Packages
- **`packages/cli/`** - Frontend CLI interface, handles user input, display rendering, history, and UI theming
- **`packages/core/`** - Backend orchestration, Gemini API client, prompt construction, tool registration and execution
- **`packages/a2a-server/`** - A2A (Agent-to-Agent) server implementation
- **`packages/vscode-ide-companion/`** - VS Code extension companion
- **`packages/test-utils/`** - Shared testing utilities

### Tool System
The core package includes an extensible tool system in `packages/core/src/tools/`:
- File system operations (read, write, edit files)
- Shell command execution
- Web fetching and Google Search integration
- User approval required for write operations

### Interaction Flow
1. CLI package receives user input
2. CLI sends request to Core package
3. Core constructs Gemini API prompt with available tools
4. Gemini API responds with tool calls or direct answers
5. Core executes tools (with user approval for write operations)
6. Core sends tool results back to Gemini API
7. Final response flows from Core to CLI to user

## Key Technologies
- **TypeScript** with strict configuration
- **Node.js 20+** required
- **Vitest** for testing
- **ESBuild** for bundling
- **Prettier + ESLint** for code quality
- **Husky + lint-staged** for git hooks

## Configuration Files
- Root package.json manages workspace-level commands
- Individual packages have their own package.json files
- TypeScript configuration uses strict mode with modern target (ES2022)
- Supports both CommonJS and ES modules via NodeNext resolution

## Authentication Methods
The CLI supports three authentication methods:
1. **OAuth with Google Account** - Recommended for individual developers
2. **Gemini API Key** - For specific model control
3. **Vertex AI** - For enterprise teams

## Testing Strategy
- Unit tests run in individual packages
- Integration tests run against real file system and shell operations
- E2E tests simulate complete user workflows
- Tests can run with different sandbox environments (none, docker, podman)