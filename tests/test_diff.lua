-- Tests for lazyvim-ai-assistant/diff.lua
-- Diff utilities: snapshots, undo, hunk navigation

local h = require('tests.helpers')
local new_set = MiniTest.new_set
local eq = h.eq

-- Create child Neovim process
local child = MiniTest.new_child_neovim()

-- Main test set
local T = new_set({
  hooks = {
    pre_case = function()
      h.child_start(child)
      h.clear_notifications(child)
      -- Load diff module fresh
      child.lua('package.loaded["lazyvim-ai-assistant.diff"] = nil')
      child.lua('Diff = require("lazyvim-ai-assistant.diff")')
      child.lua('Diff._snapshots = {}')  -- Reset snapshots for each test
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- save_snapshot()
-- =============================================================================

T['save_snapshot()'] = new_set()

T['save_snapshot()']['adds snapshot to list'] = function()
  child.lua('_count_before = #Diff._snapshots')
  child.lua('Diff.save_snapshot(0, "Test snapshot")')
  child.lua('_count_after = #Diff._snapshots')
  local before = child.lua_get('_count_before')
  local after = child.lua_get('_count_after')
  eq(before, 0)
  eq(after, 1)
end

T['save_snapshot()']['stores correct description'] = function()
  child.lua('Diff.save_snapshot(0, "My Description")')
  local result = child.lua_get('Diff._snapshots[1].description')
  eq(result, 'My Description')
end

T['save_snapshot()']['stores buffer content'] = function()
  child.lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line1", "line2", "line3"})')
  child.lua('Diff.save_snapshot(0, "Test")')
  local lines = child.lua_get('Diff._snapshots[1].lines')
  eq(lines[1], 'line1')
  eq(lines[2], 'line2')
  eq(lines[3], 'line3')
end

T['save_snapshot()']['stores timestamp'] = function()
  child.lua('Diff.save_snapshot(0, "Test")')
  local result = child.lua_get('Diff._snapshots[1].timestamp')
  h.expect_truthy(result > 0)
end

T['save_snapshot()']['stores cursor position'] = function()
  child.lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {"line1", "line2"})')
  child.lua('vim.api.nvim_win_set_cursor(0, {2, 3})')
  child.lua('Diff.save_snapshot(0, "Test")')
  local cursor = child.lua_get('Diff._snapshots[1].cursor')
  eq(cursor[1], 2)
  eq(cursor[2], 3)
end

T['save_snapshot()']['limits snapshots to max_snapshots'] = function()
  child.lua('Diff._max_snapshots = 5')
  child.lua('for i = 1, 10 do Diff.save_snapshot(0, "Snapshot " .. i) end')
  local count = child.lua_get('#Diff._snapshots')
  eq(count, 5)
end

T['save_snapshot()']['removes oldest when limit exceeded'] = function()
  child.lua('Diff._max_snapshots = 3')
  child.lua('for i = 1, 5 do Diff.save_snapshot(0, "Snapshot " .. i) end')
  local desc = child.lua_get('Diff._snapshots[1].description')
  eq(desc, 'Snapshot 3')
end

T['save_snapshot()']['uses default description if none provided'] = function()
  child.lua('Diff.save_snapshot(0)')
  local result = child.lua_get('Diff._snapshots[1].description')
  eq(result, 'AI change')
end

-- =============================================================================
-- get_snapshots()
-- =============================================================================

T['get_snapshots()'] = new_set()

T['get_snapshots()']['returns empty table initially'] = function()
  local result = child.lua_get('Diff.get_snapshots()')
  eq(#result, 0)
end

T['get_snapshots()']['returns all stored snapshots'] = function()
  child.lua('Diff.save_snapshot(0, "First")')
  child.lua('Diff.save_snapshot(0, "Second")')
  local count = child.lua_get('#Diff.get_snapshots()')
  eq(count, 2)
end

-- =============================================================================
-- clear_snapshots()
-- =============================================================================

T['clear_snapshots()'] = new_set()

T['clear_snapshots()']['removes all snapshots'] = function()
  child.lua('Diff.save_snapshot(0, "First")')
  child.lua('Diff.save_snapshot(0, "Second")')
  child.lua('Diff.clear_snapshots()')
  local count = child.lua_get('#Diff._snapshots')
  eq(count, 0)
end

-- =============================================================================
-- undo_last_change()
-- =============================================================================

T['undo_last_change()'] = new_set()

T['undo_last_change()']['returns false when no snapshots'] = function()
  local result = child.lua_get('Diff.undo_last_change()')
  eq(result, false)
end

T['undo_last_change()']['restores buffer content'] = function()
  -- Set initial content
  child.lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {"original line"})')
  child.lua('Diff.save_snapshot(0, "Before change")')

  -- Make a change
  child.lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {"modified line"})')

  -- Undo
  child.lua('Diff.undo_last_change()')

  local lines = child.lua_get('vim.api.nvim_buf_get_lines(0, 0, -1, false)')
  eq(lines[1], 'original line')
end

T['undo_last_change()']['returns true on success'] = function()
  child.lua('vim.api.nvim_buf_set_lines(0, 0, -1, false, {"content"})')
  child.lua('Diff.save_snapshot(0, "Test")')
  local result = child.lua_get('Diff.undo_last_change()')
  eq(result, true)
end

T['undo_last_change()']['removes snapshot from list'] = function()
  child.lua('Diff.save_snapshot(0, "First")')
  child.lua('Diff.save_snapshot(0, "Second")')
  child.lua('_before = #Diff._snapshots')
  child.lua('Diff.undo_last_change()')
  child.lua('_after = #Diff._snapshots')
  local before = child.lua_get('_before')
  local after = child.lua_get('_after')
  eq(before, 2)
  eq(after, 1)
end

-- =============================================================================
-- next_hunk() / prev_hunk()
-- =============================================================================

T['hunk navigation'] = new_set()

T['hunk navigation']['next_hunk function exists'] = function()
  local exists = child.lua_get('type(Diff.next_hunk) == "function"')
  eq(exists, true)
end

T['hunk navigation']['prev_hunk function exists'] = function()
  local exists = child.lua_get('type(Diff.prev_hunk) == "function"')
  eq(exists, true)
end

-- =============================================================================
-- accept_hunk()
-- =============================================================================

T['accept_hunk()'] = new_set()

T['accept_hunk()']['function exists'] = function()
  local exists = child.lua_get('type(Diff.accept_hunk) == "function"')
  eq(exists, true)
end

-- =============================================================================
-- setup()
-- =============================================================================

T['setup()'] = new_set()

T['setup()']['sets max_snapshots from config'] = function()
  child.lua('Diff.setup({ max_snapshots = 100 })')
  local result = child.lua_get('Diff._max_snapshots')
  eq(result, 100)
end

T['setup()']['uses default max_snapshots when not specified'] = function()
  child.lua('Diff.setup({})')
  local result = child.lua_get('Diff._max_snapshots')
  eq(result, 20)
end

-- =============================================================================
-- create_commands()
-- =============================================================================

T['create_commands()'] = new_set()

T['create_commands()']['creates AIUndo command'] = function()
  child.lua('Diff.create_commands()')
  local exists = h.command_exists(child, 'AIUndo')
  eq(exists, true)
end

T['create_commands()']['creates AISnapshots command'] = function()
  child.lua('Diff.create_commands()')
  local exists = h.command_exists(child, 'AISnapshots')
  eq(exists, true)
end

T['create_commands()']['creates AIClearSnapshots command'] = function()
  child.lua('Diff.create_commands()')
  local exists = h.command_exists(child, 'AIClearSnapshots')
  eq(exists, true)
end

-- =============================================================================
-- create_keymaps()
-- =============================================================================

T['create_keymaps()'] = new_set()

T['create_keymaps()']['does not error'] = function()
  child.lua('_ok = pcall(Diff.create_keymaps)')
  local ok = child.lua_get('_ok')
  eq(ok, true)
end

return T
