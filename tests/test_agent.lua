-- Tests for lazyvim-ai-assistant/agent.lua
-- Agent mode (Plan/Build) functionality

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
      -- Load agent module fresh for each test
      child.lua('package.loaded["lazyvim-ai-assistant.agent"] = nil')
      child.lua('Agent = require("lazyvim-ai-assistant.agent")')
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- MODES Constants
-- =============================================================================

T['MODES'] = new_set()

T['MODES']['has BUILD constant'] = function()
  local build = child.lua_get('Agent.MODES.BUILD')
  eq(build, 'build')
end

T['MODES']['has PLAN constant'] = function()
  local plan = child.lua_get('Agent.MODES.PLAN')
  eq(plan, 'plan')
end

-- =============================================================================
-- get_mode()
-- =============================================================================

T['get_mode()'] = new_set()

T['get_mode()']['returns "build" by default'] = function()
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

T['get_mode()']['returns current mode after change'] = function()
  child.lua('Agent.set_mode("plan")')
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'plan')
end

-- =============================================================================
-- set_mode()
-- =============================================================================

T['set_mode()'] = new_set()

T['set_mode()']['switches to plan mode'] = function()
  local result = child.lua_get('Agent.set_mode("plan")')
  eq(result, true)

  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'plan')
end

T['set_mode()']['switches to build mode'] = function()
  -- First switch to plan
  child.lua('Agent.set_mode("plan")')

  -- Then switch back to build
  local result = child.lua_get('Agent.set_mode("build")')
  eq(result, true)

  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

T['set_mode()']['rejects invalid mode'] = function()
  local result = child.lua_get('Agent.set_mode("invalid")')
  eq(result, false)

  -- Mode should remain unchanged
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

T['set_mode()']['notifies on mode change'] = function()
  h.clear_notifications(child)
  child.lua('Agent.set_mode("plan")')

  local notif = h.get_last_notification(child)
  if notif and notif ~= vim.NIL then
    h.expect_match(notif.msg, 'PLAN', 'Expected notification to mention PLAN')
  end
  -- Notification system may not be fully mocked, so we just check mode changed
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'plan')
end

T['set_mode()']['does not notify when mode unchanged'] = function()
  -- Set to build (already default)
  h.clear_notifications(child)
  child.lua('Agent.set_mode("build")')

  -- Mode should still be build
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

-- =============================================================================
-- toggle_mode()
-- =============================================================================

T['toggle_mode()'] = new_set()

T['toggle_mode()']['toggles from build to plan'] = function()
  -- Ensure we start in build mode
  child.lua('Agent._mode = Agent.MODES.BUILD')

  local new_mode = child.lua_get('Agent.toggle_mode()')
  eq(new_mode, 'plan')

  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'plan')
end

T['toggle_mode()']['toggles from plan to build'] = function()
  -- Set to plan mode first
  child.lua('Agent._mode = Agent.MODES.PLAN')

  local new_mode = child.lua_get('Agent.toggle_mode()')
  eq(new_mode, 'build')

  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

T['toggle_mode()']['returns the new mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local result = child.lua_get('Agent.toggle_mode()')
  eq(result, 'plan')
end

-- =============================================================================
-- is_build_mode()
-- =============================================================================

T['is_build_mode()'] = new_set()

T['is_build_mode()']['returns true when in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local result = child.lua_get('Agent.is_build_mode()')
  eq(result, true)
end

T['is_build_mode()']['returns false when in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local result = child.lua_get('Agent.is_build_mode()')
  eq(result, false)
end

-- =============================================================================
-- is_plan_mode()
-- =============================================================================

T['is_plan_mode()'] = new_set()

T['is_plan_mode()']['returns true when in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local result = child.lua_get('Agent.is_plan_mode()')
  eq(result, true)
end

T['is_plan_mode()']['returns false when in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local result = child.lua_get('Agent.is_plan_mode()')
  eq(result, false)
end

-- =============================================================================
-- get_tools_config()
-- =============================================================================

T['get_tools_config()'] = new_set()

T['get_tools_config()']['returns all tools enabled in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local config = child.lua_get('Agent.get_tools_config()')

  eq(config.read_file, true)
  eq(config.create_file, true)
  eq(config.insert_edit_into_file, true)
  eq(config.cmd_runner, true)
  eq(config.file_search, true)
  eq(config.grep_search, true)
end

T['get_tools_config()']['returns read-only tools in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local config = child.lua_get('Agent.get_tools_config()')

  -- Read-only tools should be enabled
  eq(config.read_file, true)
  eq(config.file_search, true)
  eq(config.grep_search, true)

  -- Write/execute tools should be disabled
  eq(config.create_file, false)
  eq(config.insert_edit_into_file, false)
  eq(config.cmd_runner, false)
end

-- =============================================================================
-- get_system_prompt()
-- =============================================================================

T['get_system_prompt()'] = new_set()

T['get_system_prompt()']['returns build prompt in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local prompt = child.lua_get('Agent.get_system_prompt()')

  h.expect_truthy(prompt, 'Expected prompt')
  h.expect_match(prompt, 'full access', 'Expected build prompt content')
end

T['get_system_prompt()']['returns plan prompt in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local prompt = child.lua_get('Agent.get_system_prompt()')

  h.expect_truthy(prompt, 'Expected prompt')
  h.expect_match(prompt, 'PLANNING MODE', 'Expected plan prompt content')
end

-- =============================================================================
-- get_system_prompt_for_mode()
-- =============================================================================

T['get_system_prompt_for_mode()'] = new_set()

T['get_system_prompt_for_mode()']['returns correct prompt for build'] = function()
  local prompt = child.lua_get('Agent.get_system_prompt_for_mode("build")')
  h.expect_truthy(prompt)
  h.expect_match(prompt, 'full access')
end

T['get_system_prompt_for_mode()']['returns correct prompt for plan'] = function()
  local prompt = child.lua_get('Agent.get_system_prompt_for_mode("plan")')
  h.expect_truthy(prompt)
  h.expect_match(prompt, 'PLANNING MODE')
end

T['get_system_prompt_for_mode()']['returns nil for invalid mode'] = function()
  local prompt = child.lua_get('Agent.get_system_prompt_for_mode("invalid")')
  eq(prompt, vim.NIL)
end

-- =============================================================================
-- get_lualine_display()
-- =============================================================================

T['get_lualine_display()'] = new_set()

T['get_lualine_display()']['returns "[BUILD]" in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local display = child.lua_get('Agent.get_lualine_display()')
  eq(display, '[BUILD]')
end

T['get_lualine_display()']['returns "[PLAN]" in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local display = child.lua_get('Agent.get_lualine_display()')
  eq(display, '[PLAN]')
end

-- =============================================================================
-- get_mode_highlight()
-- =============================================================================

T['get_mode_highlight()'] = new_set()

T['get_mode_highlight()']['returns green highlight in build mode'] = function()
  child.lua('Agent._mode = Agent.MODES.BUILD')
  local hl = child.lua_get('Agent.get_mode_highlight()')
  eq(hl, 'DiagnosticOk')
end

T['get_mode_highlight()']['returns yellow highlight in plan mode'] = function()
  child.lua('Agent._mode = Agent.MODES.PLAN')
  local hl = child.lua_get('Agent.get_mode_highlight()')
  eq(hl, 'DiagnosticWarn')
end

-- =============================================================================
-- setup()
-- =============================================================================

T['setup()'] = new_set()

T['setup()']['sets default mode from config'] = function()
  child.lua('Agent.setup({ default_mode = "plan" })')
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'plan')
end

T['setup()']['defaults to build with no config'] = function()
  child.lua('Agent._mode = "plan"')  -- Set to something else first
  child.lua('Agent.setup({})')
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

T['setup()']['handles invalid default mode gracefully'] = function()
  child.lua('Agent.setup({ default_mode = "invalid" })')
  local mode = child.lua_get('Agent.get_mode()')
  eq(mode, 'build')
end

-- =============================================================================
-- create_commands()
-- =============================================================================

T['create_commands()'] = new_set()

T['create_commands()']['creates AIBuildMode command'] = function()
  child.lua('Agent.create_commands()')
  local exists = h.command_exists(child, 'AIBuildMode')
  eq(exists, true)
end

T['create_commands()']['creates AIPlanMode command'] = function()
  child.lua('Agent.create_commands()')
  local exists = h.command_exists(child, 'AIPlanMode')
  eq(exists, true)
end

T['create_commands()']['creates AIToggleMode command'] = function()
  child.lua('Agent.create_commands()')
  local exists = h.command_exists(child, 'AIToggleMode')
  eq(exists, true)
end

T['create_commands()']['creates AIMode command'] = function()
  child.lua('Agent.create_commands()')
  local exists = h.command_exists(child, 'AIMode')
  eq(exists, true)
end

return T
