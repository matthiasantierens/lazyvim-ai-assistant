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

T['default config']['has chat section'] = function()
  local result = child.lua_get('M.config.chat')
  h.expect_truthy(result)
  eq(result.auto_include_buffer, true)
  eq(result.buffer_sync_mode, 'diff')
  eq(result.show_backend_notification, true)
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

T['copilot getters']['get_copilot_autocomplete_model returns gpt-4o-mini'] = function()
  local result = child.lua_get('M.get_copilot_autocomplete_model()')
  eq(result, 'gpt-4o-mini')
end

T['copilot getters']['get_copilot_chat_model returns gpt-4o-mini'] = function()
  local result = child.lua_get('M.get_copilot_chat_model()')
  eq(result, 'gpt-4o-mini')
end

-- =============================================================================
-- Chat getters
-- =============================================================================

T['chat getters'] = new_set()

T['chat getters']['get_chat_auto_include_buffer returns true by default'] = function()
  local result = child.lua_get('M.get_chat_auto_include_buffer()')
  eq(result, true)
end

T['chat getters']['get_chat_buffer_sync_mode returns diff by default'] = function()
  local result = child.lua_get('M.get_chat_buffer_sync_mode()')
  eq(result, 'diff')
end

T['chat getters']['get_chat_show_backend_notification returns true by default'] = function()
  local result = child.lua_get('M.get_chat_show_backend_notification()')
  eq(result, true)
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

T['setup() merging']['overrides chat settings'] = function()
  child.lua('M.setup({ chat = { auto_include_buffer = false, buffer_sync_mode = "all" } })')
  local result = child.lua_get('M.config.chat')
  eq(result.auto_include_buffer, false)
  eq(result.buffer_sync_mode, 'all')
end

T['setup() merging']['chat getters work with overridden config'] = function()
  child.lua('M.setup({ chat = { auto_include_buffer = false } })')
  local result = child.lua_get('M.get_chat_auto_include_buffer()')
  eq(result, false)
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

-- =============================================================================
-- Config validation
-- =============================================================================

T['config validation'] = new_set()

T['config validation']['corrects invalid buffer_sync_mode'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    -- Mock submodules to avoid full setup
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ chat = { buffer_sync_mode = "invalid_mode" } })
    _mode = M.get_chat_buffer_sync_mode()
  ]])
  local mode = child.lua_get('_mode')
  eq(mode, 'diff')
end

T['config validation']['corrects invalid picker'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ context = { picker = "invalid_picker" } })
    _picker = M.get_config().context.picker
  ]])
  local picker = child.lua_get('_picker')
  eq(picker, 'auto')
end

T['config validation']['corrects invalid agent default_mode'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ agent = { default_mode = "invalid_mode" } })
    _mode = M.get_config().agent.default_mode
  ]])
  local mode = child.lua_get('_mode')
  eq(mode, 'build')
end

T['config validation']['accepts valid buffer_sync_mode values'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ chat = { buffer_sync_mode = "all" } })
    _mode = M.get_chat_buffer_sync_mode()
  ]])
  local mode = child.lua_get('_mode')
  eq(mode, 'all')
end

T['config validation']['accepts valid picker values'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ context = { picker = "telescope" } })
    _picker = M.get_config().context.picker
  ]])
  local picker = child.lua_get('_picker')
  eq(picker, 'telescope')
end

-- =============================================================================
-- v2.0.0: Enable/Disable functionality
-- =============================================================================

T['enable/disable'] = new_set()

T['enable/disable']['is_enabled returns true by default'] = function()
  local result = child.lua_get('M.is_enabled()')
  eq(result, true)
end

T['enable/disable']['disable sets enabled to false'] = function()
  child.lua('M.disable()')
  local result = child.lua_get('M.is_enabled()')
  eq(result, false)
end

T['enable/disable']['enable sets enabled to true'] = function()
  child.lua('M.disable()')
  child.lua('M.enable()')
  local result = child.lua_get('M.is_enabled()')
  eq(result, true)
end

T['enable/disable']['toggle switches state'] = function()
  local initial = child.lua_get('M.is_enabled()')
  eq(initial, true)
  child.lua('M.toggle()')
  local after_toggle = child.lua_get('M.is_enabled()')
  eq(after_toggle, false)
  child.lua('M.toggle()')
  local after_second = child.lua_get('M.is_enabled()')
  eq(after_second, true)
end

T['enable/disable']['setup with enabled=false disables AI'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ enabled = false })
    _enabled = M.is_enabled()
  ]])
  local enabled = child.lua_get('_enabled')
  eq(enabled, false)
end

-- =============================================================================
-- v2.0.0: Context limiting getters
-- =============================================================================

T['context limiting'] = new_set()

T['context limiting']['get_max_context_lines returns default'] = function()
  local result = child.lua_get('M.get_max_context_lines()')
  eq(result, 500)
end

T['context limiting']['get_exclude_patterns returns default array'] = function()
  local result = child.lua_get('M.get_exclude_patterns()')
  h.expect_truthy(result)
  h.expect_truthy(#result > 0)
end

T['context limiting']['get_max_buffer_lines returns default'] = function()
  local result = child.lua_get('M.get_max_buffer_lines()')
  eq(result, 1000)
end

T['context limiting']['get_trim_whitespace returns true by default'] = function()
  local result = child.lua_get('M.get_trim_whitespace()')
  eq(result, true)
end

T['context limiting']['max_context_lines can be overridden'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ context = { max_context_lines = 1000 } })
    _lines = M.get_max_context_lines()
  ]])
  local lines = child.lua_get('_lines')
  eq(lines, 1000)
end

T['context limiting']['exclude_patterns can be overridden'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ context = { exclude_patterns = { "*.test.js" } } })
    _patterns = M.get_exclude_patterns()
  ]])
  local patterns = child.lua_get('_patterns')
  eq(patterns[1], '*.test.js')
end

-- =============================================================================
-- v2.0.0: Autocomplete config getters
-- =============================================================================

T['autocomplete config'] = new_set()

T['autocomplete config']['get_autocomplete_context_window returns default'] = function()
  local result = child.lua_get('M.get_autocomplete_context_window()')
  eq(result, 4000)
end

T['autocomplete config']['get_autocomplete_n_completions returns default'] = function()
  local result = child.lua_get('M.get_autocomplete_n_completions()')
  eq(result, 1)
end

T['autocomplete config']['get_autocomplete_max_tokens returns default'] = function()
  local result = child.lua_get('M.get_autocomplete_max_tokens()')
  eq(result, 128)
end

T['autocomplete config']['autocomplete settings can be overridden'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({
      autocomplete = {
        context_window = 8000,
        n_completions = 3,
        max_tokens = 512
      }
    })
    _ctx = M.get_autocomplete_context_window()
    _n = M.get_autocomplete_n_completions()
    _max = M.get_autocomplete_max_tokens()
  ]])
  eq(child.lua_get('_ctx'), 8000)
  eq(child.lua_get('_n'), 3)
  eq(child.lua_get('_max'), 512)
end

-- =============================================================================
-- v2.0.0: Tools config getters
-- =============================================================================

T['tools config'] = new_set()

T['tools config']['default config has tools section'] = function()
  local result = child.lua_get('M.config.tools')
  h.expect_truthy(result)
  h.expect_truthy(result.fetch_webpage)
end

T['tools config']['is_fetch_webpage_enabled returns true by default'] = function()
  local result = child.lua_get('M.is_fetch_webpage_enabled()')
  eq(result, true)
end

T['tools config']['get_fetch_webpage_adapter returns jina by default'] = function()
  local result = child.lua_get('M.get_fetch_webpage_adapter()')
  eq(result, 'jina')
end

T['tools config']['fetch_webpage enabled can be overridden'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ tools = { fetch_webpage = { enabled = false } } })
    _enabled = M.is_fetch_webpage_enabled()
  ]])
  local enabled = child.lua_get('_enabled')
  eq(enabled, false)
end

T['tools config']['fetch_webpage adapter can be overridden'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    M.setup({ tools = { fetch_webpage = { adapter = "custom_adapter" } } })
    _adapter = M.get_fetch_webpage_adapter()
  ]])
  local adapter = child.lua_get('_adapter')
  eq(adapter, 'custom_adapter')
end

T['tools config']['getters handle missing tools config gracefully'] = function()
  child.lua([[
    package.loaded["lazyvim-ai-assistant"] = nil
    package.loaded["lazyvim-ai-assistant.agent"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.context"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.prompts"] = { setup = function() end, create_commands = function() end }
    package.loaded["lazyvim-ai-assistant.diff"] = { setup = function() end, create_commands = function() end, create_keymaps = function() end }
    local M = require("lazyvim-ai-assistant")
    -- Manually remove tools config to test graceful handling
    M.config.tools = nil
    _enabled = M.is_fetch_webpage_enabled()
    _adapter = M.get_fetch_webpage_adapter()
  ]])
  -- Should return defaults when config is missing
  eq(child.lua_get('_enabled'), true)
  eq(child.lua_get('_adapter'), 'jina')
end

return T
