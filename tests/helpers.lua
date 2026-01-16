-- Test helpers for lazyvim-ai-assistant
-- Provides common utilities and assertions for all test files

local Helpers = {}

-- Create child Neovim process for isolated testing
Helpers.new_child = function()
  return MiniTest.new_child_neovim()
end

-- Shorthand for equality assertion
Helpers.eq = MiniTest.expect.equality

-- Shorthand for no equality assertion
Helpers.neq = MiniTest.expect.no_equality

-- Assert value is truthy
Helpers.expect_truthy = function(value, msg)
  if not value then
    error(msg or ('Expected truthy value, got: ' .. vim.inspect(value)))
  end
end

-- Assert value is falsy
Helpers.expect_falsy = function(value, msg)
  if value then
    error(msg or ('Expected falsy value, got: ' .. vim.inspect(value)))
  end
end

-- Assert string contains substring
Helpers.expect_match = function(str, pattern, msg)
  if not str or not str:match(pattern) then
    error(msg or string.format('Expected "%s" to match pattern "%s"', tostring(str), pattern))
  end
end

-- Start child Neovim with minimal config
Helpers.child_start = function(child)
  child.restart({ '-u', 'scripts/minimal_init.lua', '--headless' })
  -- Set reasonable window size
  child.o.lines = 24
  child.o.columns = 80
end

-- Stop child Neovim
Helpers.child_stop = function(child)
  child.stop()
end

-- Load the plugin in child process
Helpers.load_plugin = function(child)
  child.lua([[
    -- Clear any cached modules
    for name, _ in pairs(package.loaded) do
      if name:match('^lazyvim%-ai%-assistant') then
        package.loaded[name] = nil
      end
    end
  ]])
end

-- Setup the plugin with optional config in child process
Helpers.setup_plugin = function(child, config)
  Helpers.load_plugin(child)
  child.lua('require("lazyvim-ai-assistant").setup(...)', { config or {} })
end

-- Reset agent mode to default (build)
Helpers.reset_agent_mode = function(child)
  child.lua([[
    local agent = require('lazyvim-ai-assistant.agent')
    agent._mode = agent.MODES.BUILD
  ]])
end

-- Clear notifications in child process
Helpers.clear_notifications = function(child)
  child.lua('_clear_test_notifications()')
end

-- Get last notification from child process
Helpers.get_last_notification = function(child)
  return child.lua_get('_get_last_notification()')
end

-- Get all notifications from child process
Helpers.get_notifications = function(child)
  return child.lua_get('_G._test_notifications or {}')
end

-- Create a temporary file with content
Helpers.create_temp_file = function(child, filename, content)
  child.lua(string.format([[
    local file = io.open(%q, 'w')
    if file then
      file:write(%q)
      file:close()
    end
  ]], filename, content))
end

-- Remove a temporary file
Helpers.remove_temp_file = function(child, filename)
  child.lua(string.format('os.remove(%q)', filename))
end

-- Create a temporary directory
Helpers.create_temp_dir = function(child, dirname)
  child.lua(string.format('vim.fn.mkdir(%q, "p")', dirname))
end

-- Remove a temporary directory
Helpers.remove_temp_dir = function(child, dirname)
  child.lua(string.format('vim.fn.delete(%q, "rf")', dirname))
end

-- Check if command exists
Helpers.command_exists = function(child, cmd_name)
  child.lua(string.format('_cmd_check_name = %q', cmd_name))
  return child.lua_get('vim.api.nvim_get_commands({})[_cmd_check_name] ~= nil')
end

-- Execute a command and capture any errors
Helpers.safe_cmd = function(child, cmd)
  child.lua(string.format('_safe_cmd_ok, _safe_cmd_err = pcall(vim.cmd, %q)', cmd))
  local ok = child.lua_get('_safe_cmd_ok')
  local err = child.lua_get('_safe_cmd_err')
  return { ok = ok, err = err }
end

-- Create new test set with common hooks
Helpers.new_test_set = function(child, opts)
  opts = opts or {}
  return MiniTest.new_set({
    hooks = {
      pre_case = function()
        Helpers.child_start(child)
        Helpers.clear_notifications(child)
        if opts.setup_plugin ~= false then
          Helpers.setup_plugin(child, opts.config)
        end
        if opts.pre_case then
          opts.pre_case()
        end
      end,
      post_case = function()
        if opts.post_case then
          opts.post_case()
        end
      end,
      post_once = function()
        Helpers.child_stop(child)
      end,
    },
  })
end

return Helpers
