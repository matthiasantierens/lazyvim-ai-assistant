# Roadmap - v2.0.0

This document outlines the planned features for lazyvim-ai-assistant v2.0.0, bringing an OpenCode-inspired Plan/Build agentic workflow to Neovim.

## Vision

Transform lazyvim-ai-assistant from a simple AI chat/autocomplete plugin into a full **agentic coding assistant** with:

- **Plan/Build modes** - Toggle between analysis and execution
- **Enhanced context management** - Smart file and project awareness
- **Extensible prompt library** - Project-specific custom prompts
- **Session persistence** - Never lose your AI conversations
- **Improved diff experience** - Granular control over AI changes

---

## Release Summary

| Feature | Priority | Status |
|---------|----------|--------|
| Plan/Build Mode | High | Planned |
| Context Management | High | Planned |
| Prompt Library | Medium | Planned |
| Session Persistence | Medium | Planned |
| Improved Inline Editing | Medium | Planned |

---

## Feature Details

### 1. Plan/Build Mode (Agent Mode)

**Inspiration**: OpenCode's Tab-to-toggle Plan/Build workflow

**Description**: Switch between two distinct modes of operation:

| Mode | Purpose | Tools Available |
|------|---------|-----------------|
| **Build** (default) | Full development work | All tools: file edit, bash, search, etc. |
| **Plan** | Analysis & planning only | Read-only: file read, grep, search |

**Implementation**:

- New module: `lua/lazyvim-ai-assistant/agent.lua`
- Mode state tracking with toggle functionality
- Mode-specific system prompts:
  - **Plan**: "Analyze and suggest changes. Do NOT make modifications. Explain step-by-step what you would do."
  - **Build**: Standard development assistant with full tool access
- Visual indicator in lualine showing current mode
- Configurable default mode

**Keybindings**:

| Key | Context | Action |
|-----|---------|--------|
| `<Tab>` | Chat buffer | Toggle Plan/Build mode |
| `<leader>ap` | Normal | Switch to Plan mode |
| `<leader>ab` | Normal | Switch to Build mode |

**Status Line**:
- Build mode: `󰚩 LM [BUILD]` (green)
- Plan mode: `󰚩 LM [PLAN]` (yellow)

**Configuration**:

```lua
agent = {
  default_mode = "build",      -- "build" or "plan"
  show_mode_indicator = true,  -- Show mode in lualine
}
```

---

### 2. Context Management

**Goal**: Better file and project context handling with intuitive `@file` references

**Features**:

#### File Picker Integration
- `/file` slash command opens telescope/fzf-lua picker
- Select multiple files to add to context
- Fuzzy search across project files

#### Project Context
- Auto-detect project type (package.json, Cargo.toml, pyproject.toml, etc.)
- `/project` command adds project structure summary
- Smart context pruning to stay within token limits

#### Variables
- `#selection` - Current visual selection
- `#git` - Git status and recent changes summary
- `#buffer{watch}` - Auto-refresh on file changes (existing)

**Implementation**:

- New module: `lua/lazyvim-ai-assistant/context.lua`
- Slash commands registered in CodeCompanion
- Telescope/fzf-lua integration with fallback

**Keybindings**:

| Key | Mode | Action |
|-----|------|--------|
| `<leader>ac` | Normal/Visual | Add file(s) to context via picker |

**Configuration**:

```lua
context = {
  auto_project = true,         -- Auto-detect and include project info
  max_file_size = 100000,      -- Max file size for context (bytes)
  picker = "auto",             -- "telescope", "fzf", or "auto"
}
```

---

### 3. Prompt Library

**Goal**: Extensible, project-specific prompt templates

**Built-in Prompts**:

| Slash Command | Description | Mode |
|---------------|-------------|------|
| `/review` | Code review (existing) | Visual |
| `/explain` | Explain code (existing) | Visual |
| `/fix` | Fix code issues (existing) | Visual |
| `/refactor` | Refactor selected code | Visual |
| `/test` | Generate tests for code | Visual |
| `/doc` | Document code/function | Visual |
| `/optimize` | Suggest performance improvements | Visual |
| `/debug` | Help debug an issue | Normal/Visual |

**Custom Prompts**:

Load custom prompts from `.ai/prompts/` in project directory.

**Prompt Format** (`.ai/prompts/migration.md`):

```markdown
---
name: Database Migration
description: Generate database migration for schema changes
alias: migration
modes: [v]
auto_submit: false
---

You are a database expert. When asked to create a migration:

1. Analyze the current schema from the provided context
2. Identify the changes needed
3. Generate a reversible migration with both up and down methods
4. Include proper error handling and transaction support
5. Add comments explaining each change

Use the project's migration framework conventions.
```

**Implementation**:

- New module: `lua/lazyvim-ai-assistant/prompts.lua`
- Markdown front-matter parsing for metadata
- Auto-registration as CodeCompanion slash commands
- Hot-reload when prompt files change

**Configuration**:

```lua
prompts = {
  project_dir = ".ai/prompts", -- Project-local prompts directory
  load_builtin = true,         -- Load built-in prompts
}
```

---

### 4. Session Persistence

**Goal**: Save and restore chat history across Neovim restarts

**Approach**: Integrate `codecompanion-history.nvim` plugin

**Features**:

- Auto-save chat sessions on close
- Browse and restore previous sessions
- Session metadata (timestamp, summary, file context)
- Delete old sessions

**Commands**:

| Command | Description |
|---------|-------------|
| `:AISessions` | Browse saved sessions (telescope/fzf) |
| `:AISave [name]` | Manually save current session |
| `:AIDelete` | Delete selected session |

**Keybindings**:

| Key | Mode | Action |
|-----|------|--------|
| `<leader>as` | Normal | Browse/restore sessions |

**Configuration**:

```lua
history = {
  enabled = true,              -- Enable session persistence
  auto_save = true,            -- Auto-save on chat close
  max_sessions = 50,           -- Max stored sessions
}
```

**Dependency**:

```lua
"ravitemer/codecompanion-history.nvim"
```

---

### 5. Improved Inline Editing

**Goal**: Better diff preview with granular control

**Features**:

#### Hunk-based Operations
- Accept/reject individual hunks, not just all-or-nothing
- Navigate between hunks in a diff

#### Enhanced Undo
- Track AI change snapshots
- Undo specific AI changes without affecting manual edits
- Integration with native undo tree

#### Preview Options
- Floating diff (current, default)
- Side-by-side diff option
- Line numbers in diff view

**Implementation**:

- New module: `lua/lazyvim-ai-assistant/diff.lua`
- Hunk tracking and navigation
- Snapshot management for undo

**Keybindings**:

| Key | Action |
|-----|--------|
| `<leader>da` | Accept all changes (existing) |
| `<leader>dr` | Reject all changes (existing) |
| `<leader>dh` | Accept current hunk |
| `<leader>dn` | Next hunk |
| `<leader>dp` | Previous hunk |
| `<leader>du` | Undo last AI change |

---

## File Structure

```
lua/lazyvim-ai-assistant/
├── init.lua              # Configuration (updated)
├── lmstudio.lua          # LM Studio connectivity
├── health.lua            # Health checks (updated)
├── help.lua              # Help window (updated)
├── agent.lua             # NEW: Plan/Build mode logic
├── context.lua           # NEW: Context management
├── prompts.lua           # NEW: Custom prompt loading
├── diff.lua              # NEW: Enhanced diff utilities
└── plugins/
    ├── init.lua          # Plugin aggregator (updated)
    ├── autocomplete.lua  # Autocomplete config
    ├── chat.lua          # Chat config (major updates)
    ├── blink.lua         # Blink.cmp integration
    ├── lualine.lua       # Status line (updated)
    └── history.lua       # NEW: Session persistence
```

---

## Configuration Schema (v2.0.0)

```lua
require("lazyvim-ai-assistant").setup({
  -- Existing (v1.0.0)
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },

  -- NEW in v2.0.0
  agent = {
    default_mode = "build",      -- "build" or "plan"
    show_mode_indicator = true,  -- Show mode in lualine
  },
  context = {
    auto_project = true,         -- Auto-detect project type
    max_file_size = 100000,      -- Max file size for context (bytes)
    picker = "auto",             -- "telescope", "fzf", or "auto"
  },
  prompts = {
    project_dir = ".ai/prompts", -- Project-local prompts
    load_builtin = true,         -- Load built-in prompts
  },
  history = {
    enabled = true,              -- Enable session persistence
    auto_save = true,            -- Auto-save on chat close
    max_sessions = 50,           -- Max stored sessions
  },
})
```

---

## Dependencies

### Required (existing)
- `nvim-lua/plenary.nvim`
- `nvim-treesitter/nvim-treesitter`
- `olimorris/codecompanion.nvim`
- `zbirenbaum/copilot.lua`
- `milanglacier/minuet-ai.nvim`

### New in v2.0.0
- `ravitemer/codecompanion-history.nvim` - Session persistence

### Optional (recommended)
- `nvim-telescope/telescope.nvim` - File picker
- `ibhagwan/fzf-lua` - Alternative file picker
- `nvim-lualine/lualine.nvim` - Status line indicator

---

## Keybindings Summary (v2.0.0)

### Agent Mode
| Key | Context | Action |
|-----|---------|--------|
| `<Tab>` | Chat buffer | Toggle Plan/Build mode |
| `<leader>ap` | Normal | Switch to Plan mode |
| `<leader>ab` | Normal | Switch to Build mode |

### Context
| Key | Mode | Action |
|-----|------|--------|
| `<leader>ac` | Normal/Visual | Add file(s) to context |

### Sessions
| Key | Mode | Action |
|-----|------|--------|
| `<leader>as` | Normal | Browse/restore sessions |

### Diff (enhanced)
| Key | Action |
|-----|--------|
| `<leader>da` | Accept all changes |
| `<leader>dr` | Reject all changes |
| `<leader>dh` | Accept current hunk |
| `<leader>dn` | Next hunk |
| `<leader>dp` | Previous hunk |
| `<leader>du` | Undo last AI change |

### Existing (unchanged)
| Key | Mode | Action |
|-----|------|--------|
| `<leader>aa` | Normal/Visual | Toggle chat / Chat with selection |
| `<leader>aA` | Visual | Add selection to chat |
| `<leader>ai` | Normal/Visual | Inline prompt |
| `<leader>ar` | Visual | Review code |
| `<leader>ae` | Visual | Explain code |
| `<leader>af` | Visual | Fix code |
| `<leader>ah` | Normal | Show help |

---

## Implementation Phases

### Phase 1: Plan/Build Mode (Core)
- [ ] Create `agent.lua` module
- [ ] Add mode toggle functionality
- [ ] Configure tool groups for each mode
- [ ] Update lualine with mode indicator
- [ ] Add keybindings
- [ ] Update help window

### Phase 2: Context Management
- [ ] Create `context.lua` module
- [ ] Implement `/file` slash command with picker
- [ ] Implement `/project` slash command
- [ ] Add `#selection` and `#git` variables
- [ ] Add keybindings

### Phase 3: Prompt Library
- [ ] Create `prompts.lua` module
- [ ] Add built-in prompts (refactor, test, doc, optimize, debug)
- [ ] Implement markdown prompt loading from `.ai/prompts/`
- [ ] Auto-register as slash commands

### Phase 4: Session Persistence
- [ ] Create `history.lua` plugin wrapper
- [ ] Configure codecompanion-history.nvim
- [ ] Add commands (`:AISessions`, `:AISave`, `:AIDelete`)
- [ ] Add keybindings

### Phase 5: Improved Inline Editing
- [ ] Create `diff.lua` module
- [ ] Implement hunk navigation
- [ ] Implement partial accept
- [ ] Add undo snapshot management
- [ ] Add keybindings

### Phase 6: Polish
- [ ] Update README.md
- [ ] Update CHANGELOG.md
- [ ] Update health checks
- [ ] Testing and bug fixes

### Phase 7: Testing Framework (Completed)
- [x] Setup mini.test infrastructure
- [x] Create minimal Neovim init for isolated testing
- [x] Create test helpers module
- [x] Write unit tests for `agent.lua`
- [x] Write unit tests for `prompts.lua`
- [x] Write unit tests for `context.lua`
- [x] Write unit tests for `diff.lua`
- [x] Write configuration tests
- [x] Write integration tests
- [x] Create Makefile for test runner

---

## Testing

The plugin includes a comprehensive test suite using [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md).

### Running Tests

```bash
# Install test dependencies
make deps

# Run all tests
make test

# Run a specific test file
make test_file FILE=tests/test_agent.lua

# Run tests with verbose output
make test_verbose

# Watch mode (requires entr)
make watch
```

### Test Structure

```
tests/
├── helpers.lua          # Shared test utilities
├── test_agent.lua       # Agent mode tests (~30 tests)
├── test_prompts.lua     # Prompt parsing tests (~15 tests)
├── test_context.lua     # Context management tests (~20 tests)
├── test_diff.lua        # Diff/snapshot tests (~25 tests)
├── test_config.lua      # Configuration tests (~20 tests)
└── test_integration.lua # Integration tests (~20 tests)

scripts/
└── minimal_init.lua     # Minimal Neovim config for testing
```

### Writing Tests

Tests use the mini.test framework with child Neovim processes for isolation:

```lua
local h = require('tests.helpers')
local T = MiniTest.new_set()

T['my_function()']['does something'] = function()
  local result = child.lua_get([[return MyModule.my_function()]])
  h.eq(result, expected_value)
end

return T
```

---

## Breaking Changes

None planned. v2.0.0 is fully backward compatible with v1.0.0 configuration.

---

## Future Considerations (Post v2.0.0)

- **MCP (Model Context Protocol)** support for external tool servers
- **Multiple provider support** (Ollama, OpenAI API, Anthropic API)
- **Workflow automation** (multi-step predefined workflows)
- **Team sharing** (share prompts and sessions)
- **Voice input** integration
