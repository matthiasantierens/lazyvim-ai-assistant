# lazyvim-ai-assistant

**Local-first AI coding assistant with cloud fallback for LazyVim**

Use your local LM Studio for private, offline AI coding assistance. When LM Studio isn't running, automatically fall back to GitHub Copilot — no config changes needed, no interruptions to your workflow.

**v2.0.0** introduces an OpenCode-inspired **Plan/Build mode** for agentic workflows, plus context management, custom prompts, session persistence, and improved diff handling.

## Features

### Core Features
- **Local-first**: Uses LM Studio (localhost:1234) when available
- **Graceful fallback**: Seamlessly switches to GitHub Copilot when LM Studio is offline
- **Unified keybindings**: Same shortcuts work with both backends
- **Autocomplete**: Ghost text suggestions with `<S-Tab>` / `<A-a>` to accept
- **Chat**: Context-aware chat with automatic buffer inclusion
- **Code actions**: Review, explain, fix, refactor, test, document, optimize, debug
- **Inline diffs**: See and accept/reject AI-suggested changes
- **Zero config switching**: Just start/stop LM Studio, restart Neovim

### v2.0.0 Features
- **Plan/Build Mode**: Toggle between analysis-only (Plan) and full development (Build) modes
- **Context Management**: Smart file picker integration and project context awareness
- **Custom Prompts**: Load project-specific prompts from `.ai/prompts/`
- **Session Persistence**: Save and restore chat sessions across Neovim restarts
- **Improved Diff**: Hunk-based navigation and AI change undo

## How It Works

| LM Studio Status | Autocomplete | Chat |
|------------------|--------------|------|
| Running | Minuet → LM Studio | CodeCompanion → LM Studio |
| Not Running | Copilot (Claude Haiku 4.5) | CodeCompanion → Copilot (Claude Sonnet 4.5) |

## Requirements

- [LazyVim](https://www.lazyvim.org/) (Neovim distribution)
- [Node.js](https://nodejs.org/) (required for GitHub Copilot)
- [LM Studio](https://lmstudio.ai/) (optional, for local AI)
- [GitHub Copilot](https://github.com/features/copilot) subscription (for fallback)

## Installation

Add to your LazyVim config (`lua/plugins/ai-assistant.lua`):

```lua
return {
  {
    "matthiasantierens/lazyvim-ai-assistant",
    dependencies = {
      "zbirenbaum/copilot.lua",
      "milanglacier/minuet-ai.nvim",
      "olimorris/codecompanion.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- v2.0.0 optional dependencies
      "ravitemer/codecompanion-history.nvim", -- Session persistence
      "nvim-telescope/telescope.nvim",        -- File picker (or fzf-lua)
    },
    import = "lazyvim-ai-assistant.plugins",
  },
}
```

### First-time Setup

1. **Authenticate with GitHub Copilot:**
   ```vim
   :Copilot auth
   ```

2. **Set up LM Studio** (optional, see below)

## LM Studio Setup

[LM Studio](https://lmstudio.ai/) lets you run LLMs locally on your machine.

### 1. Install LM Studio

Download from [lmstudio.ai](https://lmstudio.ai/) and install.

### 2. Download a Model

Recommended models for code completion:

| Model | Size | Notes |
|-------|------|-------|
| `qwen2.5-coder-14b-instruct` | ~14GB | Default, good balance |
| `qwen2.5-coder-7b-instruct` | ~7GB | Faster, less VRAM |
| `codellama-13b-instruct` | ~13GB | Alternative |

In LM Studio:
1. Go to the **Search** tab
2. Search for your preferred model
3. Download the GGUF or MLX version (MLX for Apple Silicon)

### 3. Start the Local Server

1. Go to the **Local Server** tab in LM Studio
2. Load your downloaded model
3. Click **Start Server**
4. Verify it's running at `http://localhost:1234`

### 4. Verify Connection

In Neovim, run:
```vim
:LMStudioReconnect
```

You should see: `LM Studio: Connected`

### 5. Restart Neovim

The AI backend is determined at startup. Restart Neovim to switch between LM Studio and Copilot.

## Keybindings

Press `<leader>ah` in Neovim to show all keybindings anytime.

### Plan/Build Mode (v2.0.0)

| Shortcut | Action |
|----------|--------|
| `<Tab>` (in chat) | Toggle Plan/Build mode |
| `<leader>ab` | Switch to Build mode (full tools) |
| `<leader>ap` | Switch to Plan mode (read-only) |

### Autocomplete (Copilot / Minuet)

| Shortcut | Action |
|----------|--------|
| `<S-Tab>` | Accept suggestion |
| `<A-a>` | Accept suggestion (alternative) |
| `<A-l>` | Accept line only |
| `<A-]>` | Next suggestion |
| `<A-[>` | Previous suggestion |
| `<A-e>` | Dismiss suggestion |
| `<A-y>` | Trigger minuet completion (blink.cmp) |

### Chat (CodeCompanion)

| Shortcut | Mode | Action |
|----------|------|--------|
| `<leader>aa` | Normal | Toggle chat |
| `<leader>aa` | Visual | Chat with selection |
| `<leader>aA` | Visual | Add selection to existing chat |
| `<leader>ai` | Normal | Inline prompt |
| `<leader>ai` | Visual | Inline prompt with selection |
| `<leader>ah` | Normal | Show help (keybindings) |

### Code Actions (Visual Mode)

| Shortcut | Action |
|----------|--------|
| `<leader>ar` | Review code |
| `<leader>ae` | Explain code |
| `<leader>af` | Fix code |
| `<leader>aR` | Refactor code |
| `<leader>at` | Write tests |
| `<leader>ad` | Document code |
| `<leader>ao` | Optimize code |
| `<leader>aD` | Debug code |

### Context & Sessions (v2.0.0)

| Shortcut | Action |
|----------|--------|
| `<leader>ac` | Add file(s) to context |
| `<leader>as` | Browse/restore sessions |

### Diff (Inline code changes)

| Shortcut | Action |
|----------|--------|
| `<leader>da` | Accept all diff changes |
| `<leader>dr` | Reject all diff changes |
| `<leader>dh` | Accept current hunk |
| `<leader>dn` | Next diff hunk |
| `<leader>dp` | Previous diff hunk |
| `<leader>du` | Undo last AI change |
| `<leader>dD` | Super Diff view (all changes) |

## Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `:LMStudioReconnect` | Re-check LM Studio connection |
| `:AIHelp` | Show keybindings help window |
| `:Copilot auth` | Authenticate with GitHub Copilot |

### Agent Mode Commands (v2.0.0)

| Command | Description |
|---------|-------------|
| `:AIBuildMode` | Switch to Build mode |
| `:AIPlanMode` | Switch to Plan mode |
| `:AIToggleMode` | Toggle between modes |
| `:AIMode` | Show current mode |

### Context Commands (v2.0.0)

| Command | Description |
|---------|-------------|
| `:AIContext project` | Show project structure |
| `:AIContext git` | Show git status summary |
| `:AIContext file` | Pick files to add to context |

### Session Commands (v2.0.0)

| Command | Description |
|---------|-------------|
| `:AISessions` | Browse saved sessions |
| `:AISave [name]` | Save current session |
| `:AIDelete` | Delete a session |

### Prompt Commands (v2.0.0)

| Command | Description |
|---------|-------------|
| `:AIPrompts list` | List loaded custom prompts |
| `:AIPrompts reload` | Reload prompts from disk |
| `:AIPrompts init` | Create example prompt file |
| `:AIPrompts dir` | Show prompts directory |

### Diff Commands (v2.0.0)

| Command | Description |
|---------|-------------|
| `:AIUndo` | Undo last AI change |
| `:AISnapshots` | List AI change snapshots |
| `:AIClearSnapshots` | Clear all snapshots |

## Configuration

Default configuration (customize in your setup):

```lua
require("lazyvim-ai-assistant").setup({
  -- LM Studio settings
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },

  -- Copilot settings
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },

  -- v2.0.0: Agent mode settings
  agent = {
    default_mode = "build",      -- "build" or "plan"
    show_mode_indicator = true,  -- Show mode in lualine
  },

  -- v2.0.0: Context management
  context = {
    auto_project = true,         -- Auto-detect project type
    max_file_size = 100000,      -- Max file size for context (bytes)
    picker = "auto",             -- "telescope", "fzf", or "auto"
  },

  -- v2.0.0: Custom prompts
  prompts = {
    project_dir = ".ai/prompts", -- Project-local prompts directory
    load_builtin = true,         -- Load built-in prompts
  },

  -- v2.0.0: Session persistence
  history = {
    enabled = true,              -- Enable session persistence
    auto_save = true,            -- Auto-save on chat close
    max_sessions = 50,           -- Max stored sessions
  },
})
```

## Custom Prompts

Create project-specific prompts in `.ai/prompts/` directory.

### Prompt Format

Create a markdown file (e.g., `.ai/prompts/migration.md`):

```markdown
---
name: Database Migration
description: Generate database migration for schema changes
alias: migration
modes: [v]
auto_submit: true
---

You are a database expert. When asked to create a migration:

1. Analyze the current schema from the provided context
2. Identify the changes needed
3. Generate a reversible migration with both up and down methods
4. Include proper error handling and transaction support

Use the project's migration framework conventions.
```

### Front Matter Options

| Field | Description | Default |
|-------|-------------|---------|
| `name` | Display name (required) | - |
| `description` | Short description | name |
| `alias` | Slash command name | name (lowercase) |
| `modes` | Vim modes: `[v]`, `[n]`, `[v, n]` | `[v]` |
| `auto_submit` | Auto-send to AI | `true` |

### Initialize Example

Run `:AIPrompts init` to create an example prompt file.

## Testing

The plugin includes a comprehensive test suite using [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md).

### Running Tests

```bash
# Install test dependencies (mini.nvim)
make deps

# Run all tests
make test

# Run a specific test file
make test_file FILE=tests/test_agent.lua

# Run tests with verbose output
make test_verbose

# Watch mode - rerun on file changes (requires entr)
make watch

# Clean up dependencies
make clean
```

### Test Structure

```
tests/
├── helpers.lua          # Shared test utilities
├── test_agent.lua       # Agent mode tests (34 tests)
├── test_prompts.lua     # Prompt parsing tests (18 tests)
├── test_context.lua     # Context management tests (22 tests)
├── test_diff.lua        # Diff/snapshot tests (24 tests)
├── test_config.lua      # Configuration tests (23 tests)
└── test_integration.lua # Integration tests (25 tests)

scripts/
└── minimal_init.lua     # Minimal Neovim config for testing
```

Total: **146 tests** covering all v2.0.0 modules.

## Troubleshooting

### LM Studio not detected

1. Ensure LM Studio is running with a model loaded
2. Check the server is started (Local Server tab → Start Server)
3. Verify the URL: `curl http://localhost:1234/v1/models`
4. Run `:LMStudioReconnect` to refresh status
5. Restart Neovim after starting LM Studio

### Copilot not working

1. Run `:Copilot auth` to authenticate
2. Check `:Copilot status` for issues
3. Ensure you have an active GitHub Copilot subscription

### Visual selection not sent to chat

Make sure you're using the correct keybinding:
- `<leader>aa` in visual mode sends selection to new chat
- `<leader>aA` adds selection to existing chat
- `<leader>ai` in visual mode sends selection to inline prompt

### Plan mode not restricting tools

Plan mode configures CodeCompanion with read-only tools. If the AI still tries to make changes, it's working correctly - the tools are simply not available in plan mode.

### Health Check

Run `:checkhealth lazyvim-ai-assistant` to diagnose issues.

## License

MIT
