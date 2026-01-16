-- Minimal init.lua for testing lazyvim-ai-assistant
-- This provides an isolated Neovim environment for running tests

-- Add current plugin directory to runtimepath
vim.cmd([[let &rtp.=','.getcwd()]])

-- Add test dependencies to runtimepath
vim.cmd('set rtp+=deps/mini.nvim')
vim.cmd('set rtp+=deps/plenary.nvim')

-- Disable swap files and other noise
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

-- Set up mini.test only when running in headless mode
if #vim.api.nvim_list_uis() == 0 then
  -- Headless mode - set up for testing
  require('mini.test').setup()
end

-- Mock LM Studio as not running by default (for isolated tests)
-- Tests can override this if needed
package.loaded['lazyvim-ai-assistant.lmstudio'] = {
  _is_running = false,
  is_running = function()
    return false
  end,
  check = function()
    return false
  end,
  refresh = function()
    return false
  end,
}

-- Provide a basic vim.notify that doesn't error in tests
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- Store notifications for test assertions if needed
  _G._test_notifications = _G._test_notifications or {}
  table.insert(_G._test_notifications, {
    msg = msg,
    level = level,
    opts = opts,
  })
  -- Optionally print in non-headless mode for debugging
  if #vim.api.nvim_list_uis() > 0 then
    original_notify(msg, level, opts)
  end
end

-- Helper to clear test notifications
_G._clear_test_notifications = function()
  _G._test_notifications = {}
end

-- Helper to get last notification
_G._get_last_notification = function()
  local notifs = _G._test_notifications or {}
  return notifs[#notifs]
end
