-- Enhanced diff utilities for lazyvim-ai-assistant
-- Provides hunk navigation, partial accepts, and undo management

local M = {}

-- Store snapshots of AI changes for undo functionality
M._snapshots = {}
M._max_snapshots = 20

--- Save a snapshot before AI makes changes
---@param bufnr number Buffer number
---@param description string Description of the change
function M.save_snapshot(bufnr, description)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local snapshot = {
    bufnr = bufnr,
    filename = vim.api.nvim_buf_get_name(bufnr),
    lines = lines,
    description = description or "AI change",
    timestamp = os.time(),
    cursor = vim.api.nvim_win_get_cursor(0),
  }

  table.insert(M._snapshots, snapshot)

  -- Limit snapshot count
  while #M._snapshots > M._max_snapshots do
    table.remove(M._snapshots, 1)
  end
end

--- Undo the last AI change
---@return boolean success
function M.undo_last_change()
  if #M._snapshots == 0 then
    vim.notify("No AI changes to undo", vim.log.levels.INFO)
    return false
  end

  local snapshot = table.remove(M._snapshots)

  -- Find the buffer
  local bufnr = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf) == snapshot.filename then
      bufnr = buf
      break
    end
  end

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Buffer no longer available for undo", vim.log.levels.WARN)
    return false
  end

  -- Restore the content
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, snapshot.lines)

  -- Restore cursor position if in the same buffer
  if bufnr == vim.api.nvim_get_current_buf() then
    pcall(vim.api.nvim_win_set_cursor, 0, snapshot.cursor)
  end

  vim.notify("Undid: " .. snapshot.description, vim.log.levels.INFO)
  return true
end

--- Get list of pending snapshots
---@return table[]
function M.get_snapshots()
  return M._snapshots
end

--- Clear all snapshots
function M.clear_snapshots()
  M._snapshots = {}
end

--- Navigate to next diff hunk
--- Uses built-in diff navigation if available
function M.next_hunk()
  -- Try mini.diff first
  local ok, mini_diff = pcall(require, "mini.diff")
  if ok and mini_diff.goto_hunk then
    mini_diff.goto_hunk("next")
    return
  end

  -- Fallback to ]c motion (standard diff navigation)
  local success = pcall(vim.cmd, "normal! ]c")
  if not success then
    vim.notify("No next hunk found", vim.log.levels.INFO)
  end
end

--- Navigate to previous diff hunk
function M.prev_hunk()
  -- Try mini.diff first
  local ok, mini_diff = pcall(require, "mini.diff")
  if ok and mini_diff.goto_hunk then
    mini_diff.goto_hunk("prev")
    return
  end

  -- Fallback to [c motion (standard diff navigation)
  local success = pcall(vim.cmd, "normal! [c")
  if not success then
    vim.notify("No previous hunk found", vim.log.levels.INFO)
  end
end

--- Accept current hunk only
--- This integrates with CodeCompanion's diff system
function M.accept_hunk()
  -- Try mini.diff apply
  local ok, mini_diff = pcall(require, "mini.diff")
  if ok and mini_diff.do_hunks then
    mini_diff.do_hunks(vim.api.nvim_get_current_buf(), "apply")
    return
  end

  -- Fallback notification
  vim.notify("Hunk-based accept requires mini.diff", vim.log.levels.INFO)
end

--- Reject current hunk only
--- Reverts the current hunk to its original state
function M.reject_hunk()
  -- Try mini.diff reset
  local ok, mini_diff = pcall(require, "mini.diff")
  if ok and mini_diff.do_hunks then
    pcall(mini_diff.do_hunks, vim.api.nvim_get_current_buf(), "reset")
    return
  end

  -- Fallback: try native undo (silently fail if nothing to undo)
  pcall(vim.cmd, "silent! undo")
end

--- Setup diff module
---@param config table|nil
function M.setup(config)
  config = config or {}
  M._max_snapshots = config.max_snapshots or 20
end

--- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command("AIUndo", function()
    M.undo_last_change()
  end, { desc = "Undo last AI change" })

  vim.api.nvim_create_user_command("AISnapshots", function()
    local snapshots = M.get_snapshots()
    if #snapshots == 0 then
      print("No AI change snapshots")
      return
    end

    print("AI Change Snapshots:")
    for i, snap in ipairs(snapshots) do
      local time = os.date("%H:%M:%S", snap.timestamp)
      local filename = vim.fn.fnamemodify(snap.filename, ":t")
      print(string.format("  %d. [%s] %s - %s", i, time, filename, snap.description))
    end
  end, { desc = "List AI change snapshots" })

  vim.api.nvim_create_user_command("AIClearSnapshots", function()
    M.clear_snapshots()
    vim.notify("Cleared all AI snapshots", vim.log.levels.INFO)
  end, { desc = "Clear AI change snapshots" })
end

--- Create keymaps for diff navigation
function M.create_keymaps()
  local opts = { noremap = true, silent = true }

  -- Hunk navigation
  vim.keymap.set("n", "<leader>dn", function()
    M.next_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Next diff hunk" }))

  vim.keymap.set("n", "<leader>dp", function()
    M.prev_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Previous diff hunk" }))

  vim.keymap.set("n", "<leader>dh", function()
    M.accept_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Accept current hunk" }))

  vim.keymap.set("n", "<leader>dR", function()
    M.reject_hunk()
  end, vim.tbl_extend("force", opts, { desc = "Reject current hunk" }))

  vim.keymap.set("n", "<leader>du", function()
    M.undo_last_change()
  end, vim.tbl_extend("force", opts, { desc = "Undo last AI change" }))
end

return M
