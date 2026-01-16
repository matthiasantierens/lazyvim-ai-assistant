-- LM Studio connectivity helper
-- Checks if LM Studio is running and provides status notifications

local M = {}

-- Cached connection state (nil = not yet checked)
M._is_running = nil

--- Get the LM Studio URL from config or use default
---@return string
local function get_url()
  local config = _G.lazyvim_ai_assistant_config or {}
  local lmstudio = config.lmstudio or {}
  return lmstudio.url or "http://localhost:1234"
end

--- Check if LM Studio is responding
--- Uses a quick curl request with 1 second timeout
---@return boolean
function M.check()
  local url = get_url()
  local handle = io.popen(
    "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 " .. url .. "/v1/models 2>/dev/null"
  )
  if handle then
    local result = handle:read("*a")
    handle:close()
    M._is_running = (result == "200")
  else
    M._is_running = false
  end
  return M._is_running
end

--- Get cached connection status, or check if not yet cached
---@return boolean
function M.is_running()
  if M._is_running == nil then
    return M.check()
  end
  return M._is_running
end

--- Refresh connection status and notify user
---@return boolean
function M.refresh()
  M.check()
  M.notify_status()
  return M._is_running
end

--- Show notification about current LM Studio status
function M.notify_status()
  if M._is_running then
    vim.notify("LM Studio: Connected", vim.log.levels.INFO)
  else
    vim.notify("LM Studio: Not running (using Copilot fallback)", vim.log.levels.WARN)
  end
end

-- Create user command for reconnection
vim.api.nvim_create_user_command("LMStudioReconnect", function()
  M.refresh()
  vim.notify("Note: Restart Neovim to switch AI providers", vim.log.levels.INFO)
end, { desc = "Re-check LM Studio connection status" })

return M
