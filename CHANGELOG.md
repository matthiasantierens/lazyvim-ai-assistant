# Changelog

All notable changes to lazyvim-ai-assistant will be documented in this file.

## [2.0.0] - 2025-01-16

### Major Features

#### Plan/Build Mode (Agent Mode)
- **Plan mode**: Read-only analysis mode for planning without making changes
- **Build mode**: Full development mode with all tools enabled (default)
- Toggle between modes with `<Tab>` in chat buffer
- Visual indicator in lualine showing current mode (`[BUILD]` / `[PLAN]`)
- Mode-specific system prompts for appropriate AI behavior
- Commands: `:AIBuildMode`, `:AIPlanMode`, `:AIToggleMode`, `:AIMode`

#### Context Management
- File picker integration (telescope/fzf-lua) for adding files to context
- Project structure detection and summary
- Git status integration
- Commands: `:AIContext project`, `:AIContext git`, `:AIContext file`

#### Custom Prompts
- Load project-specific prompts from `.ai/prompts/` directory
- Markdown-based prompt format with YAML front matter
- Auto-registration as slash commands
- Commands: `:AIPrompts list`, `:AIPrompts reload`, `:AIPrompts init`

#### Session Persistence
- Save and restore chat sessions across Neovim restarts
- Integration with codecompanion-history.nvim
- Browse, save, and delete sessions
- Commands: `:AISessions`, `:AISave`, `:AIDelete`

#### Improved Inline Editing
- Hunk-based diff navigation (`<leader>dn`, `<leader>dp`)
- Accept individual hunks (`<leader>dh`)
- AI change snapshots for undo (`<leader>du`)
- Commands: `:AIUndo`, `:AISnapshots`, `:AIClearSnapshots`

#### Chat Improvements
- **Auto-include buffer context**: Opening a new chat with `<leader>aa` now automatically includes the current file
- New `chat` configuration section with `auto_include_buffer`, `buffer_sync_mode`, `show_backend_notification`
- Startup notification shows "(with file context)" when auto-include is enabled

#### Inline Code Actions with Diff Preview
- Code actions now show inline diffs in the source file by default
- `<leader>ao` optimizes code and shows diff (accept with `<leader>da`, reject with `<leader>dr`)
- `<leader>af` fixes code with inline diff
- `<leader>ad` adds documentation with inline diff
- `<leader>at` generates tests in a new file (auto-detects test directory)
- `<leader>aR` refactors code with inline diff
- Uppercase variants (`<leader>aO`, `<leader>aT`) open chat for discussion instead

### Fixed
- Fixed CodeCompanion adapter registration for updated API (adapters now under `adapters.http`)
- Fixed prompt library format for CodeCompanion API change (`strategy` → `interaction`, `short_name` → `alias`)

### New Built-in Prompts
- `/refactor` - Refactor selected code
- `/test` - Generate tests for code
- `/doc` - Document code/function
- `/optimize` - Suggest performance improvements
- `/debug` - Help debug code issues

### New Keybindings
- `<Tab>` (chat) - Toggle Plan/Build mode
- `<leader>ab` - Switch to Build mode
- `<leader>ap` - Switch to Plan mode
- `<leader>an` - New chat without file context
- `<leader>aF` - Add files to context
- `<leader>as` - Browse sessions
- `<leader>aR` - Refactor code (visual)
- `<leader>at` - Write tests (visual)
- `<leader>ad` - Document code (visual)
- `<leader>ao` - Optimize code (visual)
- `<leader>aD` - Debug code (normal/visual)
- `<leader>dh` - Accept current hunk
- `<leader>dn` - Next diff hunk
- `<leader>dp` - Previous diff hunk
- `<leader>du` - Undo last AI change

### New Configuration Options
```lua
chat = {
  auto_include_buffer = true,
  buffer_sync_mode = "diff",
  show_backend_notification = true,
},
agent = {
  default_mode = "build",
  show_mode_indicator = true,
},
context = {
  auto_project = true,
  max_file_size = 100000,
  picker = "auto",
},
prompts = {
  project_dir = ".ai/prompts",
  load_builtin = true,
},
history = {
  enabled = true,
  auto_save = true,
  max_sessions = 50,
},
```

### New Dependencies
- `ravitemer/codecompanion-history.nvim` (optional) - Session persistence

### Technical
- New modules: `agent.lua`, `context.lua`, `prompts.lua`, `diff.lua`
- Enhanced health checks for v2.0.0 features
- Expanded help window with all new keybindings
- Updated lualine component with mode indicator
- Tool groups for agentic workflows in CodeCompanion

---

## [1.0.0] - 2025-01-16

### Features

- Local-first AI coding assistant with automatic Copilot fallback
- Autocomplete via Minuet (LM Studio) or Copilot with unified keybindings
- Chat via CodeCompanion with automatic backend switching
- Code actions: review, explain, and fix code with visual selections
- Inline diff support with accept/reject keybindings
- Help window (`:AIHelp` or `<leader>ah`) showing all keybindings
- Health check support (`:checkhealth lazyvim-ai-assistant`)
- Status line indicator for lualine showing LM Studio connection
- Blink.cmp integration for completion menu

### Technical

- Centralized configuration management
- Reduced LM Studio connection check timeout (300ms) for faster startup
- URL sanitization for shell commands
- Dynamic help window sizing
