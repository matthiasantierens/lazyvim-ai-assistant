# lazyvim-ai-assistant

**Local-first AI coding assistant with cloud fallback for LazyVim**

Use your local LM Studio for private, offline AI coding assistance. When LM Studio isn't running, automatically fall back to GitHub Copilot — no config changes needed, no interruptions to your workflow.

## Features

- **Local-first**: Uses LM Studio (localhost:1234) when available
- **Graceful fallback**: Seamlessly switches to GitHub Copilot when LM Studio is offline
- **Unified keybindings**: Same shortcuts work with both backends
- **Autocomplete**: Ghost text suggestions with `<S-Tab>` / `<A-a>` to accept
- **Chat**: Context-aware chat with automatic buffer inclusion
- **Code actions**: Review, explain, and fix code with visual selections
- **Inline diffs**: See and accept/reject AI-suggested changes
- **Zero config switching**: Just start/stop LM Studio, restart Neovim

## How It Works

| LM Studio Status | Autocomplete | Chat |
|------------------|--------------|------|
| Running | Minuet → LM Studio | CodeCompanion → LM Studio |
| Not Running | Copilot (Claude Haiku 4.5) | CodeCompanion → Copilot (Claude Sonnet 4.5) |

## Requirements

- [LazyVim](https://www.lazyvim.org/) (Neovim distribution)
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
    },
    import = "lazyvim-ai-assistant.plugins",
  },
}
```

### First-time Setup

1. **Authenticate with GitHub Copilot:**
   ```vim
   :Copilot setup
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

Press `<leader>ah` in Neovim to show this help anytime.

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
| `<leader>ar` | Visual | Review code |
| `<leader>ae` | Visual | Explain code |
| `<leader>af` | Visual | Fix code |
| `<leader>ah` | Normal | Show help (keybindings) |

### Diff (Inline code changes)

| Shortcut | Action |
|----------|--------|
| `<leader>da` | Accept diff change |
| `<leader>dr` | Reject diff change |
| `<leader>dD` | Super Diff view (all changes) |

### Commands

| Command | Action |
|---------|--------|
| `:LMStudioReconnect` | Re-check LM Studio connection |
| `:Copilot setup` | Authenticate with GitHub Copilot |
| `:AIHelp` | Show keybindings help |

## Configuration

Default configuration (customize in your setup):

```lua
require("lazyvim-ai-assistant").setup({
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },
})
```

## Troubleshooting

### LM Studio not detected

1. Ensure LM Studio is running with a model loaded
2. Check the server is started (Local Server tab → Start Server)
3. Verify the URL: `curl http://localhost:1234/v1/models`
4. Run `:LMStudioReconnect` to refresh status
5. Restart Neovim after starting LM Studio

### Copilot not working

1. Run `:Copilot setup` to authenticate
2. Check `:Copilot status` for issues
3. Ensure you have an active GitHub Copilot subscription

### Visual selection not sent to chat

Make sure you're using the correct keybinding:
- `<leader>aa` in visual mode sends selection to new chat
- `<leader>aA` adds selection to existing chat
- `<leader>ai` in visual mode sends selection to inline prompt

## License

MIT
