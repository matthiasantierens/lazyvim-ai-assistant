-- lazyvim-ai-assistant
-- Local-first AI coding assistant with Copilot fallback for LazyVim
-- v2.0.0: Added Plan/Build mode, tools, context limiting, enable/disable toggle

local M = {}

-- Runtime state (not persisted in config)
M._enabled = true

-- Default configuration
M.config = {
  -- Global enable/disable toggle - set to false to completely disable all AI features
  enabled = true,

  -- LM Studio settings (local AI)
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },

  -- Copilot settings (cloud fallback)
  -- Using gpt-4o-mini as default for cost efficiency
  copilot = {
    autocomplete_model = "gpt-4o-mini",
    chat_model = "gpt-4o-mini",
  },

  -- Chat behavior settings
  chat = {
    auto_include_buffer = true, -- Include current file when opening new chat
    buffer_sync_mode = "diff", -- "diff" (changes only) or "all" (full content)
    show_backend_notification = true, -- Show "Using LM Studio/Copilot" on startup
    max_buffer_lines = 1000, -- Truncate buffer context after N lines (nil = no limit)
    trim_whitespace = true, -- Remove consecutive blank lines from context
  },

  -- v2.0.0: Agent mode settings (Plan/Build)
  agent = {
    default_mode = "build", -- "build" or "plan"
    show_mode_indicator = true, -- Show mode in lualine
  },

  -- v2.0.0: Context management settings with limiting options for cost savings
  context = {
    auto_project = true, -- Auto-detect project type
    max_file_size = 100000, -- Max file size for context (bytes)
    picker = "auto", -- "telescope", "fzf", or "auto"
    max_context_lines = 500, -- Truncate files after N lines (nil = no limit)
    exclude_patterns = { -- File patterns to exclude from context
      "*.min.js",
      "*.min.css",
      "*.lock",
      "package-lock.json",
      "*.png",
      "*.jpg",
      "*.gif",
      "*.ico",
      "*.woff",
      "*.woff2",
      "*.ttf",
      "*.eot",
    },
  },

  -- v2.0.0: Autocomplete settings for cost control
  autocomplete = {
    context_window = 4000, -- Characters of context before cursor (default was 8000)
    n_completions = 1, -- Number of suggestions to request (default was 2)
    max_tokens = 128, -- Max tokens per completion (default was 256)
  },

  -- v2.0.0: Custom prompts settings
  prompts = {
    project_dir = ".ai/prompts", -- Project-local prompts directory
    load_builtin = true, -- Load built-in prompts
  },

  -- v2.0.0: Session persistence settings
  history = {
    enabled = true, -- Enable session persistence
    auto_save = true, -- Auto-save on chat close
    max_sessions = 50, -- Max stored sessions
  },

  -- v2.0.0: Tool settings
  tools = {
    fetch_webpage = {
      enabled = true, -- Enable the fetch_webpage tool
      adapter = "jina", -- Adapter to use (jina is free, no API key needed)
    },
  },
}

--- Validate configuration values and warn on invalid options
---@param opts table|nil User config options
---@return table Validated config
local function validate_config(opts)
  if not opts then
    return {}
  end

  -- Validate enabled (boolean)
  if opts.enabled ~= nil and type(opts.enabled) ~= "boolean" then
    vim.notify(
      "[lazyvim-ai-assistant] Invalid 'enabled' value. Must be boolean. Using true.",
      vim.log.levels.WARN
    )
    opts.enabled = true
  end

  -- Validate buffer_sync_mode
  if opts.chat and opts.chat.buffer_sync_mode then
    local valid = { diff = true, all = true }
    if not valid[opts.chat.buffer_sync_mode] then
      vim.notify(
        "[lazyvim-ai-assistant] Invalid buffer_sync_mode '" .. tostring(opts.chat.buffer_sync_mode) .. "'. Using 'diff'.",
        vim.log.levels.WARN
      )
      opts.chat.buffer_sync_mode = "diff"
    end
  end

  -- Validate picker
  if opts.context and opts.context.picker then
    local valid = { auto = true, telescope = true, fzf = true }
    if not valid[opts.context.picker] then
      vim.notify(
        "[lazyvim-ai-assistant] Invalid picker '" .. tostring(opts.context.picker) .. "'. Using 'auto'.",
        vim.log.levels.WARN
      )
      opts.context.picker = "auto"
    end
  end

  -- Validate agent default_mode
  if opts.agent and opts.agent.default_mode then
    local valid = { build = true, plan = true }
    if not valid[opts.agent.default_mode] then
      vim.notify(
        "[lazyvim-ai-assistant] Invalid default_mode '" .. tostring(opts.agent.default_mode) .. "'. Using 'build'.",
        vim.log.levels.WARN
      )
      opts.agent.default_mode = "build"
    end
  end

  return opts
end

--- Setup the AI assistant with optional configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  opts = validate_config(opts or {})
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Initialize enabled state from config
  M._enabled = M.config.enabled ~= false

  -- Initialize submodules that need setup
  local agent = require("lazyvim-ai-assistant.agent")
  agent.setup(M.config.agent)
  agent.create_commands()

  local context = require("lazyvim-ai-assistant.context")
  context.setup(M.config.context)
  context.create_commands()

  local prompts = require("lazyvim-ai-assistant.prompts")
  prompts.setup(M.config.prompts)
  prompts.create_commands()

  local diff = require("lazyvim-ai-assistant.diff")
  diff.setup()
  diff.create_commands()
  diff.create_keymaps()

  -- Create enable/disable commands
  M.create_commands()
end

--- Get the current configuration
---@return table
function M.get_config()
  return M.config
end

-- LM Studio getters
--- Get LM Studio URL from config
---@return string
function M.get_lmstudio_url()
  return M.config.lmstudio.url
end

--- Get LM Studio model from config
---@return string
function M.get_lmstudio_model()
  return M.config.lmstudio.model
end

-- Copilot getters
--- Get Copilot autocomplete model from config
---@return string
function M.get_copilot_autocomplete_model()
  return M.config.copilot.autocomplete_model
end

--- Get Copilot chat model from config
---@return string
function M.get_copilot_chat_model()
  return M.config.copilot.chat_model
end

-- Chat getters
--- Get chat auto-include buffer setting
---@return boolean
function M.get_chat_auto_include_buffer()
  local chat = M.config.chat or {}
  return chat.auto_include_buffer ~= false
end

--- Get chat buffer sync mode
---@return string "diff" or "all"
function M.get_chat_buffer_sync_mode()
  return (M.config.chat or {}).buffer_sync_mode or "diff"
end

--- Get chat show backend notification setting
---@return boolean
function M.get_chat_show_backend_notification()
  local chat = M.config.chat or {}
  return chat.show_backend_notification ~= false
end

-- v2.0.0: Agent mode getters
--- Get current agent mode
---@return string "build" or "plan"
function M.get_agent_mode()
  return require("lazyvim-ai-assistant.agent").get_mode()
end

--- Check if in build mode
---@return boolean
function M.is_build_mode()
  return require("lazyvim-ai-assistant.agent").is_build_mode()
end

--- Check if in plan mode
---@return boolean
function M.is_plan_mode()
  return require("lazyvim-ai-assistant.agent").is_plan_mode()
end

-- v2.0.0: Global enable/disable functions

--- Check if AI assistant is enabled
---@return boolean
function M.is_enabled()
  return M._enabled
end

--- Enable AI assistant
function M.enable()
  M._enabled = true
  vim.notify("AI Assistant enabled", vim.log.levels.INFO)
  -- Trigger event for other modules to react
  vim.api.nvim_exec_autocmds("User", { pattern = "AIAssistantEnabled" })
end

--- Disable AI assistant (saves tokens by preventing all AI calls)
function M.disable()
  M._enabled = false
  vim.notify("AI Assistant disabled (saving tokens)", vim.log.levels.INFO)
  -- Trigger event for other modules to react
  vim.api.nvim_exec_autocmds("User", { pattern = "AIAssistantDisabled" })
end

--- Toggle AI assistant enabled state
---@return boolean new_state
function M.toggle()
  if M._enabled then
    M.disable()
  else
    M.enable()
  end
  return M._enabled
end

-- v2.0.0: Context config getters

--- Get max context lines setting
---@return number|nil
function M.get_max_context_lines()
  return (M.config.context or {}).max_context_lines
end

--- Get exclude patterns for context
---@return table
function M.get_exclude_patterns()
  return (M.config.context or {}).exclude_patterns or {}
end

--- Get max buffer lines for chat context
---@return number|nil
function M.get_max_buffer_lines()
  return (M.config.chat or {}).max_buffer_lines
end

--- Get trim whitespace setting
---@return boolean
function M.get_trim_whitespace()
  local chat = M.config.chat or {}
  return chat.trim_whitespace ~= false
end

-- v2.0.0: Autocomplete config getters

--- Get autocomplete context window size
---@return number
function M.get_autocomplete_context_window()
  return (M.config.autocomplete or {}).context_window or 4000
end

--- Get number of completions to request
---@return number
function M.get_autocomplete_n_completions()
  return (M.config.autocomplete or {}).n_completions or 1
end

--- Get max tokens for autocomplete
---@return number
function M.get_autocomplete_max_tokens()
  return (M.config.autocomplete or {}).max_tokens or 128
end

-- v2.0.0: Tools config getters

--- Check if fetch_webpage tool is enabled
---@return boolean
function M.is_fetch_webpage_enabled()
  local tools = M.config.tools or {}
  local fetch = tools.fetch_webpage or {}
  return fetch.enabled ~= false
end

--- Get fetch_webpage adapter
---@return string
function M.get_fetch_webpage_adapter()
  local tools = M.config.tools or {}
  local fetch = tools.fetch_webpage or {}
  return fetch.adapter or "jina"
end

--- Create user commands for enable/disable
function M.create_commands()
  vim.api.nvim_create_user_command("AIEnable", function()
    M.enable()
  end, { desc = "Enable AI Assistant" })

  vim.api.nvim_create_user_command("AIDisable", function()
    M.disable()
  end, { desc = "Disable AI Assistant (save tokens)" })

  vim.api.nvim_create_user_command("AIToggle", function()
    M.toggle()
  end, { desc = "Toggle AI Assistant on/off" })

  vim.api.nvim_create_user_command("AIStatus", function()
    local status = M._enabled and "ENABLED" or "DISABLED"
    local lmstudio_ok, lmstudio = pcall(require, "lazyvim-ai-assistant.lmstudio")
    local backend = (lmstudio_ok and lmstudio.is_running()) and "LM Studio" or "Copilot"
    local agent_ok, agent = pcall(require, "lazyvim-ai-assistant.agent")
    local mode = agent_ok and agent.get_mode():upper() or "BUILD"

    vim.notify(string.format(
      "AI Assistant: %s | Backend: %s | Mode: %s",
      status, backend, mode
    ), vim.log.levels.INFO)
  end, { desc = "Show AI Assistant status" })
end

return M
