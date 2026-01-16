-- lazyvim-ai-assistant
-- Local-first AI coding assistant with Copilot fallback for LazyVim
-- v2.0.0: Added Plan/Build mode, context management, prompt library, and session persistence

local M = {}

-- Default configuration
M.config = {
  -- LM Studio settings (local AI)
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },

  -- Copilot settings (cloud fallback)
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },

  -- Chat behavior settings
  chat = {
    auto_include_buffer = true, -- Include current file when opening new chat
    buffer_sync_mode = "diff", -- "diff" (changes only) or "all" (full content)
    show_backend_notification = true, -- Show "Using LM Studio/Copilot" on startup
  },

  -- v2.0.0: Agent mode settings (Plan/Build)
  agent = {
    default_mode = "build", -- "build" or "plan"
    show_mode_indicator = true, -- Show mode in lualine
  },

  -- v2.0.0: Context management settings
  context = {
    auto_project = true, -- Auto-detect project type
    max_file_size = 100000, -- Max file size for context (bytes)
    picker = "auto", -- "telescope", "fzf", or "auto"
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
}

--- Validate configuration values and warn on invalid options
---@param opts table|nil User config options
---@return table Validated config
local function validate_config(opts)
  if not opts then
    return {}
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

return M
