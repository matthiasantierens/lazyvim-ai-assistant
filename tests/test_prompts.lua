-- Tests for lazyvim-ai-assistant/prompts.lua
-- Custom prompt loading and parsing functionality

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
      -- Load prompts module fresh
      child.lua('package.loaded["lazyvim-ai-assistant.prompts"] = nil')
      child.lua('Prompts = require("lazyvim-ai-assistant.prompts")')
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- parse_front_matter()
-- =============================================================================

T['parse_front_matter()'] = new_set()

T['parse_front_matter()']['extracts name correctly'] = function()
  child.lua('_test_content = "---\\nname: Test Prompt\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local name = child.lua_get('_meta.name')
  eq(name, 'Test Prompt')
end

T['parse_front_matter()']['extracts description'] = function()
  child.lua('_test_content = "---\\nname: Test\\ndescription: A test description\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local desc = child.lua_get('_meta.description')
  eq(desc, 'A test description')
end

T['parse_front_matter()']['extracts alias'] = function()
  child.lua('_test_content = "---\\nname: Test\\nalias: my_alias\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local alias = child.lua_get('_meta.alias')
  eq(alias, 'my_alias')
end

T['parse_front_matter()']['parses modes array'] = function()
  child.lua('_test_content = "---\\nname: Test\\nmodes: [v, n]\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local modes = child.lua_get('_meta.modes')
  eq(modes[1], 'v')
  eq(modes[2], 'n')
end

T['parse_front_matter()']['parses boolean auto_submit true'] = function()
  child.lua('_test_content = "---\\nname: Test\\nauto_submit: true\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local auto = child.lua_get('_meta.auto_submit')
  eq(auto, true)
end

T['parse_front_matter()']['parses boolean auto_submit false'] = function()
  child.lua('_test_content = "---\\nname: Test\\nauto_submit: false\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local auto = child.lua_get('_meta.auto_submit')
  eq(auto, false)
end

T['parse_front_matter()']['returns nil metadata for content without front matter'] = function()
  child.lua('_test_content = "No front matter here\\nJust body content"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local meta = child.lua_get('_meta')
  eq(meta, vim.NIL)
end

T['parse_front_matter()']['returns body content after front matter'] = function()
  child.lua('_test_content = "---\\nname: Test\\n---\\nThis is the body content\\nwith multiple lines"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local body = child.lua_get('_body')
  h.expect_match(body, 'This is the body')
  h.expect_match(body, 'multiple lines')
end

T['parse_front_matter()']['handles missing end delimiter'] = function()
  child.lua('_test_content = "---\\nname: Test\\nNo end delimiter"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local meta = child.lua_get('_meta')
  -- Should return nil metadata since front matter is malformed
  eq(meta, vim.NIL)
end

T['parse_front_matter()']['parses numeric values'] = function()
  child.lua('_test_content = "---\\nname: Test\\npriority: 42\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local priority = child.lua_get('_meta.priority')
  eq(priority, 42)
end

T['parse_front_matter()']['removes quotes from string values'] = function()
  child.lua('_test_content = "---\\nname: \\"Quoted Name\\"\\n---\\nBody"')
  child.lua('_meta, _body = Prompts.parse_front_matter(_test_content)')
  local name = child.lua_get('_meta.name')
  eq(name, 'Quoted Name')
end

-- =============================================================================
-- get_prompts_dir()
-- =============================================================================

T['get_prompts_dir()'] = new_set()

T['get_prompts_dir()']['returns default path'] = function()
  -- Mock the config
  child.lua([[
    package.loaded['lazyvim-ai-assistant'] = {
      get_config = function()
        return { prompts = { project_dir = '.ai/prompts' } }
      end
    }
  ]])
  child.lua('package.loaded["lazyvim-ai-assistant.prompts"] = nil')
  child.lua('Prompts = require("lazyvim-ai-assistant.prompts")')
  local dir = child.lua_get('Prompts.get_prompts_dir()')
  h.expect_match(dir, '.ai/prompts')
end

T['get_prompts_dir()']['respects config override'] = function()
  child.lua([[
    package.loaded['lazyvim-ai-assistant'] = {
      get_config = function()
        return { prompts = { project_dir = 'custom/prompts/dir' } }
      end
    }
  ]])
  child.lua('package.loaded["lazyvim-ai-assistant.prompts"] = nil')
  child.lua('Prompts = require("lazyvim-ai-assistant.prompts")')
  local dir = child.lua_get('Prompts.get_prompts_dir()')
  h.expect_match(dir, 'custom/prompts/dir')
end

-- =============================================================================
-- get_prompts()
-- =============================================================================

T['get_prompts()'] = new_set()

T['get_prompts()']['returns empty table initially'] = function()
  child.lua('Prompts._prompts = {}')
  local result = child.lua_get('Prompts.get_prompts()')
  eq(vim.tbl_count(result), 0)
end

T['get_prompts()']['returns loaded prompts'] = function()
  child.lua('Prompts._prompts = { test = { name = "Test Prompt" } }')
  local result = child.lua_get('Prompts.get_prompts()')
  h.expect_truthy(result.test)
  eq(result.test.name, 'Test Prompt')
end

-- =============================================================================
-- load_prompt_file()
-- =============================================================================

T['load_prompt_file()'] = new_set()

T['load_prompt_file()']['returns nil for non-existent file'] = function()
  local result = child.lua_get('Prompts.load_prompt_file("/nonexistent/file.md")')
  eq(result, vim.NIL)
end

-- =============================================================================
-- setup()
-- =============================================================================

T['setup()'] = new_set()

T['setup()']['accepts config without error'] = function()
  child.lua('_ok, _err = pcall(function() Prompts.setup({ load_builtin = false }) end)')
  local ok = child.lua_get('_ok')
  eq(ok, true)
end

-- =============================================================================
-- create_commands()
-- =============================================================================

T['create_commands()'] = new_set()

T['create_commands()']['creates AIPrompts command'] = function()
  child.lua('Prompts.create_commands()')
  local exists = h.command_exists(child, 'AIPrompts')
  eq(exists, true)
end

return T
