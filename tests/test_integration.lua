-- Integration tests for lazyvim-ai-assistant
-- Tests commands, keymaps, and module interactions

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
      -- Full setup of the plugin
      child.lua([[
        for name, _ in pairs(package.loaded) do
          if name:match('^lazyvim%-ai%-assistant') then
            package.loaded[name] = nil
          end
        end
        require('lazyvim-ai-assistant').setup({})
      ]])
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- Commands registration
-- =============================================================================

T['commands'] = new_set()

T['commands']['AIBuildMode is registered'] = function()
  local exists = h.command_exists(child, 'AIBuildMode')
  eq(exists, true)
end

T['commands']['AIPlanMode is registered'] = function()
  local exists = h.command_exists(child, 'AIPlanMode')
  eq(exists, true)
end

T['commands']['AIToggleMode is registered'] = function()
  local exists = h.command_exists(child, 'AIToggleMode')
  eq(exists, true)
end

T['commands']['AIMode is registered'] = function()
  local exists = h.command_exists(child, 'AIMode')
  eq(exists, true)
end

T['commands']['AIContext is registered'] = function()
  local exists = h.command_exists(child, 'AIContext')
  eq(exists, true)
end

T['commands']['AIPrompts is registered'] = function()
  local exists = h.command_exists(child, 'AIPrompts')
  eq(exists, true)
end

T['commands']['AIUndo is registered'] = function()
  local exists = h.command_exists(child, 'AIUndo')
  eq(exists, true)
end

T['commands']['AISnapshots is registered'] = function()
  local exists = h.command_exists(child, 'AISnapshots')
  eq(exists, true)
end

T['commands']['AIClearSnapshots is registered'] = function()
  local exists = h.command_exists(child, 'AIClearSnapshots')
  eq(exists, true)
end

-- =============================================================================
-- Command execution
-- =============================================================================

T['command execution'] = new_set()

T['command execution']['AIBuildMode switches to build'] = function()
  -- First switch to plan
  child.lua('require("lazyvim-ai-assistant.agent").set_mode("plan")')
  -- Then use command to switch to build
  child.cmd('AIBuildMode')
  local mode = child.lua_get('require("lazyvim-ai-assistant.agent").get_mode()')
  eq(mode, 'build')
end

T['command execution']['AIPlanMode switches to plan'] = function()
  child.cmd('AIPlanMode')
  local mode = child.lua_get('require("lazyvim-ai-assistant.agent").get_mode()')
  eq(mode, 'plan')
end

T['command execution']['AIToggleMode toggles mode'] = function()
  -- Ensure we're in build mode
  child.lua('require("lazyvim-ai-assistant.agent").set_mode("build")')
  -- Toggle
  child.cmd('AIToggleMode')
  local mode = child.lua_get('require("lazyvim-ai-assistant.agent").get_mode()')
  eq(mode, 'plan')
end

T['command execution']['AIMode shows current mode'] = function()
  local result = h.safe_cmd(child, 'AIMode')
  eq(result.ok, true)
end

-- =============================================================================
-- Module interaction
-- =============================================================================

T['module interaction'] = new_set()

T['module interaction']['agent and init module share state'] = function()
  -- Change mode via agent module
  child.lua('require("lazyvim-ai-assistant.agent").set_mode("plan")')
  -- Check via init module
  local result = child.lua_get('require("lazyvim-ai-assistant").is_plan_mode()')
  eq(result, true)
end

T['module interaction']['init get_agent_mode reflects agent state'] = function()
  child.lua('require("lazyvim-ai-assistant.agent").toggle_mode()')
  local init_mode = child.lua_get('require("lazyvim-ai-assistant").get_agent_mode()')
  local agent_mode = child.lua_get('require("lazyvim-ai-assistant.agent").get_mode()')
  eq(init_mode, agent_mode)
end

-- =============================================================================
-- Snapshot integration
-- =============================================================================

T['snapshot integration'] = new_set()

T['snapshot integration']['snapshots persist across module reloads'] = function()
  child.lua('require("lazyvim-ai-assistant.diff").save_snapshot(0, "Test snapshot")')
  local count = child.lua_get('#require("lazyvim-ai-assistant.diff").get_snapshots()')
  eq(count, 1)
end

T['snapshot integration']['AIUndo command works'] = function()
  child.lua([[
    local diff = require('lazyvim-ai-assistant.diff')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'original'})
    diff.save_snapshot(0, 'Before change')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'modified'})
  ]])
  child.cmd('AIUndo')
  local line = child.lua_get('vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]')
  eq(line, 'original')
end

T['snapshot integration']['AIClearSnapshots clears all'] = function()
  child.lua([[
    local diff = require('lazyvim-ai-assistant.diff')
    diff.save_snapshot(0, 'Snapshot 1')
    diff.save_snapshot(0, 'Snapshot 2')
  ]])
  child.cmd('AIClearSnapshots')
  local count = child.lua_get('#require("lazyvim-ai-assistant.diff").get_snapshots()')
  eq(count, 0)
end

-- =============================================================================
-- Context integration
-- =============================================================================

T['context integration'] = new_set()

T['context integration']['AIContext project does not error'] = function()
  local result = h.safe_cmd(child, 'AIContext project')
  eq(result.ok, true)
end

T['context integration']['AIContext git does not error'] = function()
  local result = h.safe_cmd(child, 'AIContext git')
  eq(result.ok, true)
end

-- =============================================================================
-- Mode-aware functionality
-- =============================================================================

T['mode-aware'] = new_set()

T['mode-aware']['tools config changes with mode'] = function()
  child.lua([[
    local agent = require('lazyvim-ai-assistant.agent')
    agent.set_mode('build')
    _build_tools = agent.get_tools_config()
    agent.set_mode('plan')
    _plan_tools = agent.get_tools_config()
  ]])
  local build_can_edit = child.lua_get('_build_tools.insert_edit_into_file')
  local plan_can_edit = child.lua_get('_plan_tools.insert_edit_into_file')
  eq(build_can_edit, true)
  eq(plan_can_edit, false)
end

T['mode-aware']['system prompt changes with mode'] = function()
  child.lua([[
    local agent = require('lazyvim-ai-assistant.agent')
    agent.set_mode('build')
    _build_prompt = agent.get_system_prompt()
    agent.set_mode('plan')
    _plan_prompt = agent.get_system_prompt()
  ]])
  local build_has_access = child.lua_get('_build_prompt:match("full access") ~= nil')
  local plan_has_planning = child.lua_get('_plan_prompt:match("PLANNING MODE") ~= nil')
  eq(build_has_access, true)
  eq(plan_has_planning, true)
end

-- =============================================================================
-- Error handling
-- =============================================================================

T['error handling'] = new_set()

T['error handling']['invalid mode set returns false'] = function()
  local result = child.lua_get('require("lazyvim-ai-assistant.agent").set_mode("invalid_mode")')
  eq(result, false)
end

T['error handling']['undo with no snapshots is safe'] = function()
  child.lua('require("lazyvim-ai-assistant.diff").clear_snapshots()')
  local result = child.lua_get('require("lazyvim-ai-assistant.diff").undo_last_change()')
  eq(result, false)
end

T['error handling']['reading nonexistent file returns error'] = function()
  child.lua('_content, _err = require("lazyvim-ai-assistant.context").read_file("/nonexistent/path/file.txt")')
  local content = child.lua_get('_content')
  local has_error = child.lua_get('_err ~= nil')
  eq(content, vim.NIL)
  eq(has_error, true)
end

return T
