# Changelog

All notable changes to lazyvim-ai-assistant will be documented in this file.

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
