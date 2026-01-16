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
end

--- Get the current configuration
---@return table
function M.get_config()
  return M.config
end

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

return M
