# Agent Instructions for lazyvim-ai-assistant

## Project Overview

A Neovim plugin for LazyVim that provides local-first AI coding assistance using LM Studio, with automatic fallback to GitHub Copilot when LM Studio isn't running.

**Target Users**: LazyVim users who want AI assistance with privacy (local) and reliability (cloud fallback).

**Key Features**:
- Local-first AI via LM Studio with automatic Copilot fallback
- Plan/Build mode for agentic workflows
- Auto-include buffer context in chat
- Custom prompts from `.ai/prompts/`
- Session persistence across Neovim restarts

## Architecture

```
lazyvim-ai-assistant/
├── lua/lazyvim-ai-assistant/
│   ├── init.lua              # Entry point, config, setup
│   ├── plugins/              # Lazy.nvim plugin specs
│   │   ├── init.lua          # Plugin loader
│   │   ├── chat.lua          # CodeCompanion integration
│   │   ├── autocomplete.lua  # Copilot/Minuet setup
│   │   ├── blink.lua         # Completion menu
│   │   ├── lualine.lua       # Status line component
│   │   └── history.lua       # Session persistence
│   ├── agent.lua             # Plan/Build mode logic
│   ├── context.lua           # File picker, project info
│   ├── prompts.lua           # Custom prompt loading
│   ├── diff.lua              # Inline diff, snapshots
│   ├── lmstudio.lua          # LM Studio connection
│   └── help.lua              # Keybinding help window
├── tests/                    # mini.test test suite
├── scripts/
│   └── minimal_init.lua      # Minimal config for testing
└── Makefile                  # Test runner
```

## Key Files

| File | Purpose |
|------|---------|
| `init.lua` | Main config, `setup()`, getters |
| `plugins/chat.lua` | CodeCompanion adapter, keymaps, prompt library |
| `plugins/autocomplete.lua` | Copilot + Minuet backend switching |
| `agent.lua` | Plan/Build mode: `set_mode()`, `toggle_mode()` |
| `lmstudio.lua` | Connection check: `is_running()`, `check()` |
| `context.lua` | `pick_files()`, `get_project_structure()` |
| `prompts.lua` | `load_from_directory()`, `parse_prompt()` |
| `diff.lua` | `accept_hunk()`, `create_snapshot()` |

## Configuration Structure

```lua
M.config = {
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },
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
}
```

## Development Setup

### Prerequisites
- Neovim >= 0.9.0
- LazyVim distribution
- Node.js (for GitHub Copilot)
- LM Studio (optional, for local AI)

### Installation for Development

1. Clone the repository:
   ```bash
   git clone https://github.com/matthiasantierens/lazyvim-ai-assistant.git
   cd lazyvim-ai-assistant
   ```

2. Install test dependencies:
   ```bash
   make deps
   ```

3. For local testing, add to your LazyVim config (`lua/plugins/ai-assistant.lua`):
   ```lua
   return {
     {
       dir = "/path/to/lazyvim-ai-assistant",
       dependencies = {
         "zbirenbaum/copilot.lua",
         "milanglacier/minuet-ai.nvim",
         "olimorris/codecompanion.nvim",
         "nvim-lua/plenary.nvim",
         "nvim-treesitter/nvim-treesitter",
       },
       import = "lazyvim-ai-assistant.plugins",
     },
   }
   ```

### First-Time Setup
1. Authenticate with GitHub Copilot: `:Copilot auth`
2. (Optional) Start LM Studio with a model loaded
3. Restart Neovim

## Testing

### Run All Tests
```bash
make test
```

### Run Specific Test File
```bash
make test_file FILE=tests/test_agent.lua
```

### Test Structure
| File | Tests | Coverage |
|------|-------|----------|
| `test_agent.lua` | 34 | Plan/Build mode |
| `test_config.lua` | 29 | Configuration, getters |
| `test_context.lua` | 22 | Context management |
| `test_diff.lua` | 24 | Diff, snapshots |
| `test_prompts.lua` | 18 | Prompt parsing |
| `test_integration.lua` | 25 | End-to-end flows |

**Total: 152 tests**

### Test Helpers
Located in `tests/helpers.lua`:
- `child_start(child)` - Start child Neovim process
- `child_stop(child)` - Stop child process
- `eq(a, b)` - Assert equality
- `expect_match(str, pattern)` - Assert pattern match

## Coding Conventions

### Module Pattern
```lua
local M = {}

---@param arg1 string Description of argument
---@return boolean Success status
function M.public_function(arg1)
  -- implementation
end

return M
```

### Documentation
- Use LuaDoc annotations (`---@param`, `---@return`, `---@class`)
- Add brief description comment above each public function

### Keybindings
- `<leader>a` prefix for AI features
- `<leader>d` prefix for diff features

### Adding New Features
1. Add config option to `init.lua` with default value
2. Add getter function if external access needed
3. Implement feature in appropriate module
4. Add keybinding to `plugins/chat.lua` if needed
5. Update `help.lua` with new keybinding
6. Add tests to appropriate test file
7. Update README.md and CHANGELOG.md

## Useful Commands

| Command | Description |
|---------|-------------|
| `:AIHelp` | Show keybinding help window |
| `:LMStudioReconnect` | Re-check LM Studio connection |
| `:AIMode` | Show current Plan/Build mode |
| `:checkhealth lazyvim-ai-assistant` | Run health checks |
