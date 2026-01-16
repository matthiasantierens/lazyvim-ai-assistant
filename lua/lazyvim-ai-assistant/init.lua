-- lazyvim-ai-assistant
-- Local-first AI coding assistant with Copilot fallback for LazyVim

local M = {}

-- Default configuration
M.config = {
  lmstudio = {
    url = "http://localhost:1234",
    model = "qwen2.5-coder-14b-instruct-mlx",
  },
  copilot = {
    autocomplete_model = "claude-haiku-4.5",
    chat_model = "claude-sonnet-4.5",
  },
}

--- Setup the AI assistant with optional configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Make config available globally for plugins
  _G.lazyvim_ai_assistant_config = M.config
end

--- Get the current configuration
---@return table
function M.get_config()
  return M.config
end

return M
