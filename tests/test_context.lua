-- Tests for lazyvim-ai-assistant/context.lua
-- Context management: project detection, file reading, git summary

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
      -- Load context module fresh
      child.lua('package.loaded["lazyvim-ai-assistant.context"] = nil')
      child.lua('Context = require("lazyvim-ai-assistant.context")')
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- project_types constant
-- =============================================================================

T['project_types'] = new_set()

T['project_types']['has nodejs definition'] = function()
  local result = child.lua_get('Context.project_types.nodejs')
  h.expect_truthy(result)
  eq(result.name, 'Node.js')
  h.expect_truthy(vim.tbl_contains(result.markers, 'package.json'))
end

T['project_types']['has python definition'] = function()
  local result = child.lua_get('Context.project_types.python')
  h.expect_truthy(result)
  eq(result.name, 'Python')
end

T['project_types']['has rust definition'] = function()
  local result = child.lua_get('Context.project_types.rust')
  h.expect_truthy(result)
  eq(result.name, 'Rust')
end

T['project_types']['has go definition'] = function()
  local result = child.lua_get('Context.project_types.go')
  h.expect_truthy(result)
  eq(result.name, 'Go')
end

T['project_types']['has lua definition'] = function()
  local result = child.lua_get('Context.project_types.lua')
  h.expect_truthy(result)
  eq(result.name, 'Lua')
end

-- =============================================================================
-- detect_project_type()
-- =============================================================================

T['detect_project_type()'] = new_set()

T['detect_project_type()']['returns table with type and name when found'] = function()
  -- The test repo itself should be detected as Lua
  child.lua('_proj = Context.detect_project_type()')
  local proj = child.lua_get('_proj')
  -- May return nil if no project markers found, or a table if found
  if proj ~= vim.NIL then
    h.expect_truthy(proj.type)
    h.expect_truthy(proj.name)
  end
end

-- =============================================================================
-- read_file()
-- =============================================================================

T['read_file()'] = new_set()

T['read_file()']['returns nil and error for nonexistent file'] = function()
  child.lua('_content, _err = Context.read_file("/nonexistent/file.txt")')
  local content = child.lua_get('_content')
  local has_err = child.lua_get('_err ~= nil')
  eq(content, vim.NIL)
  eq(has_err, true)
end

T['read_file()']['reads existing file content'] = function()
  -- Create a temp file, read it, then clean up
  child.lua([[
    local tmpfile = '/tmp/test_context_read.txt'
    local f = io.open(tmpfile, 'w')
    f:write('test content')
    f:close()
    _content, _err = Context.read_file(tmpfile)
    os.remove(tmpfile)
  ]])
  local content = child.lua_get('_content')
  local err = child.lua_get('_err')
  eq(content, 'test content')
  eq(err, vim.NIL)
end

T['read_file()']['respects max_size parameter'] = function()
  child.lua([[
    local tmpfile = '/tmp/test_context_large.txt'
    local f = io.open(tmpfile, 'w')
    f:write(string.rep('x', 1000))
    f:close()
    _content, _err = Context.read_file(tmpfile, 100)  -- Max 100 bytes
    os.remove(tmpfile)
  ]])
  local content = child.lua_get('_content')
  local has_err = child.lua_get('_err ~= nil')
  eq(content, vim.NIL)
  eq(has_err, true)
end

-- =============================================================================
-- get_git_summary()
-- =============================================================================

T['get_git_summary()'] = new_set()

T['get_git_summary()']['returns a string'] = function()
  local result_type = child.lua_get('type(Context.get_git_summary())')
  eq(result_type, 'string')
end

T['get_git_summary()']['contains git status header or not-a-repo message'] = function()
  local result = child.lua_get('Context.get_git_summary()')
  -- Should contain either "Git Status:" or "Not a git repository"
  local has_status = result:match('Git Status') or result:match('Not a git')
  h.expect_truthy(has_status)
end

-- =============================================================================
-- get_project_structure()
-- =============================================================================

T['get_project_structure()'] = new_set()

T['get_project_structure()']['returns a string'] = function()
  local result_type = child.lua_get('type(Context.get_project_structure())')
  eq(result_type, 'string')
end

T['get_project_structure()']['contains structure header'] = function()
  local result = child.lua_get('Context.get_project_structure()')
  h.expect_match(result, 'Project Structure')
end

T['get_project_structure()']['respects max_depth parameter'] = function()
  local result = child.lua_get('Context.get_project_structure(1)')
  -- Should return a string (depth limits output)
  h.expect_truthy(#result > 0)
end

-- =============================================================================
-- get_available_picker()
-- =============================================================================

T['get_available_picker()'] = new_set()

T['get_available_picker()']['returns nil when no picker available'] = function()
  -- Mock config without pickers
  child.lua([[
    package.loaded['lazyvim-ai-assistant'] = {
      get_config = function()
        return { context = { picker = 'auto' } }
      end
    }
    package.loaded['telescope'] = nil
    package.loaded['fzf-lua'] = nil
    package.loaded['lazyvim-ai-assistant.context'] = nil
    Context = require('lazyvim-ai-assistant.context')
  ]])
  local result = child.lua_get('Context.get_available_picker()')
  eq(result, vim.NIL)
end

-- =============================================================================
-- format_file_for_context()
-- =============================================================================

T['format_file_for_context()'] = new_set()

T['format_file_for_context()']['includes file header'] = function()
  child.lua([[
    local tmpfile = '/tmp/test_format.lua'
    local f = io.open(tmpfile, 'w')
    f:write('local x = 1')
    f:close()
    _formatted = Context.format_file_for_context(tmpfile)
    os.remove(tmpfile)
  ]])
  local result = child.lua_get('_formatted')
  h.expect_match(result, 'File:')
  h.expect_match(result, 'test_format.lua')
end

T['format_file_for_context()']['wraps content in code fence'] = function()
  child.lua([[
    local tmpfile = '/tmp/test_format2.txt'
    local f = io.open(tmpfile, 'w')
    f:write('content here')
    f:close()
    _formatted = Context.format_file_for_context(tmpfile)
    os.remove(tmpfile)
  ]])
  local result = child.lua_get('_formatted')
  h.expect_match(result, '```')
  h.expect_match(result, 'content here')
end

T['format_file_for_context()']['returns error message for nonexistent file'] = function()
  local result = child.lua_get('Context.format_file_for_context("/nonexistent/file.txt")')
  h.expect_match(result, 'Error')
end

-- =============================================================================
-- get_visual_selection()
-- =============================================================================

T['get_visual_selection()'] = new_set()

T['get_visual_selection()']['returns nil in normal mode'] = function()
  local result = child.lua_get('Context.get_visual_selection()')
  eq(result, vim.NIL)
end

-- =============================================================================
-- setup()
-- =============================================================================

T['setup()'] = new_set()

T['setup()']['stores config'] = function()
  child.lua('Context.setup({ test_key = "test_value" })')
  local result = child.lua_get('Context._config.test_key')
  eq(result, 'test_value')
end

T['setup()']['works with empty config'] = function()
  child.lua('_ok = pcall(function() Context.setup({}) end)')
  local ok = child.lua_get('_ok')
  eq(ok, true)
end

-- =============================================================================
-- create_commands()
-- =============================================================================

T['create_commands()'] = new_set()

T['create_commands()']['creates AIContext command'] = function()
  child.lua('Context.create_commands()')
  local exists = h.command_exists(child, 'AIContext')
  eq(exists, true)
end

return T
