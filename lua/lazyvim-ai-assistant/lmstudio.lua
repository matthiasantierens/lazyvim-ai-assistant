-- LM Studio connectivity helper
-- Checks if LM Studio is running and provides status notifications

local M = {}

-- Cached connection state (nil = not yet checked)
M._is_running = nil

--- Get the LM Studio URL from config or use default
---@return string
local function get_url()
  local ok, main = pcall(require, "lazyvim-ai-assistant")
  if ok then
    return main.get_lmstudio_url()
  end
  return "http://localhost:1234"
end

--- Check if LM Studio is responding
--- Uses a quick curl request with 300ms timeout to minimize startup delay
---@return boolean
function M.check()
  local url = get_url()
  -- Sanitize URL to prevent shell injection
  local safe_url = vim.fn.shellescape(url .. "/v1/models")
  local cmd = string.format(
    "curl -s -o /dev/null -w '%%{http_code}' --connect-timeout 0.3 %s 2>/dev/null",
    safe_url
  )
  local ok, handle = pcall(io.popen, cmd)
  if ok and handle then
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
