-- Help display for AI keybindings
-- Shows all available keybindings in a floating window
-- v2.0.0: Added Plan/Build mode, new prompts, context, and session keybindings

local M = {}

--- Show help in a floating window
function M.show()
  -- Safely require modules
  local ok, lmstudio = pcall(require, "lazyvim-ai-assistant.lmstudio")
  local is_lmstudio = ok and lmstudio.is_running() or false

  local agent_ok, agent = pcall(require, "lazyvim-ai-assistant.agent")
  local mode = agent_ok and agent.get_mode() or "build"
  local mode_display = mode == "build" and "BUILD" or "PLAN"

  local backend_status = is_lmstudio and "LM Studio (local)" or "Copilot (cloud)"

  local lines = {
    "                    AI Assistant Keybindings (v2.0)                ",
    "====================================================================",
    "",
    " STATUS",
    "   Backend: " .. backend_status,
    "   Mode:    " .. mode_display .. (mode == "build" and " (full tools)" or " (read-only)"),
    "",
    "====================================================================",
    " AGENT MODE (Plan/Build)",
    "====================================================================",
    "   <Tab>        Toggle Plan/Build mode (in chat buffer)",
    "   <leader>ab   Switch to Build mode (full tool access)",
    "   <leader>ap   Switch to Plan mode (read-only analysis)",
    "",
    "   :AIBuildMode   Switch to Build mode",
    "   :AIPlanMode    Switch to Plan mode",
    "   :AIToggleMode  Toggle between modes",
    "   :AIMode        Show current mode",
    "",
    "====================================================================",
    " AUTOCOMPLETE (Copilot / Minuet)",
    "====================================================================",
    "   <S-Tab>    Accept suggestion",
    "   <A-a>      Accept suggestion (alternative)",
    "   <A-l>      Accept line only",
    "   <A-]>      Next suggestion",
    "   <A-[>      Previous suggestion",
    "   <A-e>      Dismiss suggestion",
    "   <A-y>      Trigger minuet completion (blink.cmp)",
    "",
    "====================================================================",
    " CHAT (CodeCompanion)",
    "====================================================================",
    "   <leader>aa   Toggle chat (n) / Chat with selection (v)",
    "   <leader>aA   Add selection to existing chat (v)",
    "   <leader>ai   Inline prompt (n) / with selection (v)",
    "   <leader>ah   Show this help",
    "",
    " Code Actions (visual mode):",
    "   <leader>ar   Review code",
    "   <leader>ae   Explain code",
    "   <leader>af   Fix code",
    "   <leader>aR   Refactor code",
    "   <leader>at   Write tests",
    "   <leader>ad   Document code",
    "   <leader>ao   Optimize code",
    "   <leader>aD   Debug code (n/v)",
    "",
    "====================================================================",
    " CONTEXT & SESSIONS",
    "====================================================================",
    "   <leader>ac   Add file(s) to context (file picker)",
    "   <leader>as   Browse/restore chat sessions",
    "",
    "   :AIContext project   Show project structure",
    "   :AIContext git       Show git status",
    "   :AIContext file      Pick files to show",
    "   :AISessions          Browse saved sessions",
    "   :AISave [name]       Save current session",
    "",
    "====================================================================",
    " DIFF (Inline code changes)",
    "====================================================================",
    "   <leader>da   Accept all diff changes",
    "   <leader>dr   Reject all diff changes",
    "   <leader>dh   Accept current hunk only",
    "   <leader>dn   Next diff hunk",
    "   <leader>dp   Previous diff hunk",
    "   <leader>du   Undo last AI change",
    "   <leader>dD   Super Diff view (all changes)",
    "",
    "====================================================================",
    " CUSTOM PROMPTS",
    "====================================================================",
    "   :AIPrompts list      List loaded prompts",
    "   :AIPrompts reload    Reload prompts from .ai/prompts/",
    "   :AIPrompts init      Create example prompt file",
    "   :AIPrompts dir       Show prompts directory",
    "",
    "====================================================================",
    " OTHER COMMANDS",
    "====================================================================",
    "   :LMStudioReconnect   Re-check LM Studio connection",
    "   :Copilot auth        Authenticate with GitHub Copilot",
    "   :AIUndo              Undo last AI change",
    "   :AISnapshots         List AI change snapshots",
    "",
    "                    Press 'q' or <Esc> to close                     ",
  }

  -- Calculate window dimensions dynamically
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = width + 2 -- Add some padding
  local height = math.min(#lines, vim.o.lines - 4) -- Cap height
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
