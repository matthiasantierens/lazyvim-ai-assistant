-- Help display for AI keybindings
-- Shows all available keybindings in a floating window

local M = {}

--- Show help in a floating window
function M.show()
  local lmstudio = require("lazyvim-ai-assistant.lmstudio")
  local is_lmstudio = lmstudio.is_running()

  local backend_status = is_lmstudio
      and "LM Studio (local)"
    or "Copilot (cloud)"

  local lines = {
    "                    AI Assistant Keybindings                     ",
    "─────────────────────────────────────────────────────────────────",
    "",
    " BACKEND STATUS",
    "   Current: " .. backend_status,
    "   LM Studio running  -> Autocomplete: Minuet, Chat: LM Studio",
    "   LM Studio offline  -> Autocomplete: Copilot, Chat: Copilot",
    "   :LMStudioReconnect   Re-check connection (restart nvim after)",
    "",
    "─────────────────────────────────────────────────────────────────",
    " AUTOCOMPLETE (Copilot / Minuet)",
    "─────────────────────────────────────────────────────────────────",
    "   <S-Tab>    Accept suggestion",
    "   <A-a>      Accept suggestion (alternative)",
    "   <A-l>      Accept line only",
    "   <A-]>      Next suggestion",
    "   <A-[>      Previous suggestion",
    "   <A-e>      Dismiss suggestion",
    "   <A-y>      Trigger minuet completion (blink.cmp)",
    "",
    "─────────────────────────────────────────────────────────────────",
    " CHAT (CodeCompanion)",
    "─────────────────────────────────────────────────────────────────",
    "   <leader>aa   Toggle chat (normal) / Chat with selection (visual)",
    "   <leader>aA   Add selection to existing chat (visual)",
    "   <leader>ai   Inline prompt (normal) / with selection (visual)",
    "   <leader>ar   Review code (visual)",
    "   <leader>ae   Explain code (visual)",
    "   <leader>af   Fix code (visual)",
    "   <leader>ah   Show this help",
    "",
    "─────────────────────────────────────────────────────────────────",
    " DIFF (Inline code changes)",
    "─────────────────────────────────────────────────────────────────",
    "   <leader>da   Accept diff change",
    "   <leader>dr   Reject diff change",
    "   <leader>dD   Super Diff view (all changes across files)",
    "",
    "─────────────────────────────────────────────────────────────────",
    " COMMANDS",
    "─────────────────────────────────────────────────────────────────",
    "   :LMStudioReconnect   Re-check LM Studio connection",
    "   :Copilot setup       Authenticate with GitHub Copilot",
    "",
    "                    Press 'q' or <Esc> to close                  ",
  }

  -- Calculate window dimensions
  local width = 69
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " AI Assistant Help ",
    title_pos = "center",
  })

  -- Set window options
  vim.api.nvim_set_option_value("winhl", "Normal:Normal,FloatBorder:FloatBorder", { win = win })
  vim.api.nvim_set_option_value("cursorline", false, { win = win })

  -- Close on q or Escape
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })
end

-- Create user command
vim.api.nvim_create_user_command("AIHelp", function()
  M.show()
end, { desc = "Show AI Assistant keybindings help" })

return M
