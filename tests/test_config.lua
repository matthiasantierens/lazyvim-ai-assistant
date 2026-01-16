-- Tests for lazyvim-ai-assistant configuration
-- Tests init.lua: setup, config merging, and getters

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
      -- Clear and reload module
      child.lua([[
        for name, _ in pairs(package.loaded) do
          if name:match('^lazyvim%-ai%-assistant') then
            package.loaded[name] = nil
          end
        end
        M = require('lazyvim-ai-assistant')
      ]])
    end,
    post_once = function()
      h.child_stop(child)
    end,
  },
})

-- =============================================================================
-- Default configuration
-- =============================================================================

T['default config'] = new_set()

T['default config']['has lmstudio section'] = function()
  local result = child.lua_get('M.config.lmstudio')
  h.expect_truthy(result)
  h.expect_truthy(result.url)
  h.expect_truthy(result.model)
end

T['default config']['has copilot section'] = function()
  local result = child.lua_get('M.config.copilot')
  h.expect_truthy(result)
  h.expect_truthy(result.autocomplete_model)
  h.expect_truthy(result.chat_model)
end

T['default config']['has agent section'] = function()
  local result = child.lua_get('M.config.agent')
  h.expect_truthy(result)
  eq(result.default_mode, 'build')
  eq(result.show_mode_indicator, true)
end

T['default config']['has context section'] = function()
  local result = child.lua_get('M.config.context')
  h.expect_truthy(result)
  eq(result.auto_project, true)
  eq(result.picker, 'auto')
end

T['default config']['has prompts section'] = function()
  local result = child.lua_get('M.config.prompts')
  h.expect_truthy(result)
  eq(result.project_dir, '.ai/prompts')
  eq(result.load_builtin, true)
end

T['default config']['has history section'] = function()
  local result = child.lua_get('M.config.history')
  h.expect_truthy(result)
  eq(result.enabled, true)
  eq(result.auto_save, true)
end

-- =============================================================================
-- get_config()
-- =============================================================================

T['get_config()'] = new_set()

T['get_config()']['returns full config'] = function()
  local result = child.lua_get('M.get_config()')
  h.expect_truthy(result.lmstudio)
  h.expect_truthy(result.copilot)
  h.expect_truthy(result.agent)
end

-- =============================================================================
-- LM Studio getters
-- =============================================================================

T['lmstudio getters'] = new_set()

T['lmstudio getters']['get_lmstudio_url returns default'] = function()
  local result = child.lua_get('M.get_lmstudio_url()')
  eq(result, 'http://localhost:1234')
end

T['lmstudio getters']['get_lmstudio_model returns default'] = function()
  local result = child.lua_get('M.get_lmstudio_model()')
  h.expect_match(result, 'qwen')
end

-- =============================================================================
-- Copilot getters
-- =============================================================================

T['copilot getters'] = new_set()

T['copilot getters']['get_copilot_autocomplete_model returns default'] = function()
  local result = child.lua_get('M.get_copilot_autocomplete_model()')
  h.expect_match(result, 'claude')
end

T['copilot getters']['get_copilot_chat_model returns default'] = function()
  local result = child.lua_get('M.get_copilot_chat_model()')
  h.expect_match(result, 'sonnet')
end

-- =============================================================================
-- setup() config merging
-- =============================================================================

T['setup() merging'] = new_set()

T['setup() merging']['overrides lmstudio url'] = function()
  child.lua('M.setup({ lmstudio = { url = "http://custom:5000" } })')
  local result = child.lua_get('M.get_lmstudio_url()')
  eq(result, 'http://custom:5000')
end

T['setup() merging']['preserves unspecified lmstudio values'] = function()
  child.lua('M.setup({ lmstudio = { url = "http://custom:5000" } })')
  local result = child.lua_get('M.get_lmstudio_model()')
  h.expect_match(result, 'qwen')  -- Default preserved
end

T['setup() merging']['overrides copilot models'] = function()
  child.lua('M.setup({ copilot = { chat_model = "gpt-4" } })')
  local result = child.lua_get('M.get_copilot_chat_model()')
  eq(result, 'gpt-4')
end

T['setup() merging']['overrides agent default_mode'] = function()
  child.lua('M.setup({ agent = { default_mode = "plan" } })')
  local result = child.lua_get('M.config.agent.default_mode')
  eq(result, 'plan')
end

T['setup() merging']['overrides context settings'] = function()
  child.lua('M.setup({ context = { max_file_size = 50000, picker = "telescope" } })')
  local result = child.lua_get('M.config.context')
  eq(result.max_file_size, 50000)
  eq(result.picker, 'telescope')
end

T['setup() merging']['overrides prompts settings'] = function()
  child.lua('M.setup({ prompts = { project_dir = "custom/prompts" } })')
  local result = child.lua_get('M.config.prompts.project_dir')
  eq(result, 'custom/prompts')
end

T['setup() merging']['overrides history settings'] = function()
  child.lua('M.setup({ history = { enabled = false, max_sessions = 100 } })')
  local result = child.lua_get('M.config.history')
  eq(result.enabled, false)
  eq(result.max_sessions, 100)
end

T['setup() merging']['works with empty config'] = function()
  child.lua('_ok = pcall(function() M.setup({}) end)')
  local ok = child.lua_get('_ok')
  eq(ok, true)
end

T['setup() merging']['works with nil config'] = function()
  child.lua('_ok = pcall(function() M.setup() end)')
  local ok = child.lua_get('_ok')
  eq(ok, true)
end

-- =============================================================================
-- Agent mode delegation
-- =============================================================================

T['agent mode'] = new_set()

T['agent mode']['get_agent_mode delegates to agent module'] = function()
  local result = child.lua_get('M.get_agent_mode()')
  eq(result, 'build')  -- Default mode
end

T['agent mode']['is_build_mode returns true by default'] = function()
  local result = child.lua_get('M.is_build_mode()')
  eq(result, true)
end

T['agent mode']['is_plan_mode returns false by default'] = function()
  local result = child.lua_get('M.is_plan_mode()')
  eq(result, false)
end

return T
