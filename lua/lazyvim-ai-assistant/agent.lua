-- Agent mode management for lazyvim-ai-assistant
-- Provides Plan/Build mode toggle similar to OpenCode

local M = {}

-- Mode constants
M.MODES = {
  BUILD = "build",
  PLAN = "plan",
}

-- Current mode state (default to build)
M._mode = M.MODES.BUILD

-- System prompts for each mode
M.system_prompts = {
  [M.MODES.BUILD] = [[You are an expert coding assistant with full access to development tools.

You can:
- Read and analyze files
- Create and edit files
- Run shell commands
- Search the codebase

When the user asks you to make changes, implement them directly using the available tools.
Be proactive and thorough. After making changes, verify they work correctly.]],

  [M.MODES.PLAN] = [[You are an expert coding assistant in PLANNING MODE.

IMPORTANT: You are in read-only mode. You can analyze code and search the codebase, but you CANNOT:
- Create or edit files
- Run shell commands that modify anything
- Make any changes to the codebase

Your role is to:
1. Analyze the code and understand the current state
2. Create a detailed step-by-step plan for what changes would be needed
3. Explain the reasoning behind each step
4. Identify potential risks or considerations
5. Suggest tests or verification steps

When explaining your plan, be specific about:
- Which files would need to be modified
- What exact changes would be made
- The order of operations
- Any dependencies between changes

Format your response as a clear, numbered plan that the user can review before switching to Build mode to implement.]],
}

--- Get the current mode
---@return string
function M.get_mode()
  return M._mode
end

--- Set the mode
---@param mode string "build" or "plan"
---@return boolean success
function M.set_mode(mode)
  if mode ~= M.MODES.BUILD and mode ~= M.MODES.PLAN then
    vim.notify("Invalid mode: " .. tostring(mode) .. ". Use 'build' or 'plan'.", vim.log.levels.ERROR)
    return false
  end

  local old_mode = M._mode
  M._mode = mode

  if old_mode ~= mode then
    local mode_display = mode == M.MODES.BUILD and "BUILD" or "PLAN"
    local icon = mode == M.MODES.BUILD and "" or ""
    vim.notify(icon .. " Switched to " .. mode_display .. " mode", vim.log.levels.INFO)

    -- Trigger an event for other modules to react
    vim.api.nvim_exec_autocmds("User", {
      pattern = "AIAgentModeChanged",
      data = { mode = mode, old_mode = old_mode },
    })
  end

  return true
end

--- Toggle between build and plan modes
---@return string new_mode
function M.toggle_mode()
  local new_mode = M._mode == M.MODES.BUILD and M.MODES.PLAN or M.MODES.BUILD
  M.set_mode(new_mode)
  return new_mode
end

--- Get the system prompt for the current mode
---@return string
function M.get_system_prompt()
  return M.system_prompts[M._mode]
end

--- Get the system prompt for a specific mode
---@param mode string "build" or "plan"
---@return string|nil
function M.get_system_prompt_for_mode(mode)
  return M.system_prompts[mode]
end

--- Check if current mode is build mode
---@return boolean
function M.is_build_mode()
  return M._mode == M.MODES.BUILD
end

--- Check if current mode is plan mode
---@return boolean
function M.is_plan_mode()
  return M._mode == M.MODES.PLAN
end

--- Get tools configuration based on current mode
--- Returns a table of tool settings for CodeCompanion
---@return table
function M.get_tools_config()
  if M.is_build_mode() then
    -- Build mode: all tools enabled
    return {
      ["read_file"] = true,
      ["create_file"] = true,
      ["insert_edit_into_file"] = true,
      ["file_search"] = true,
      ["grep_search"] = true,
      ["cmd_runner"] = true,
    }
  else
    -- Plan mode: read-only tools only
    return {
      ["read_file"] = true,
      ["create_file"] = false,
      ["insert_edit_into_file"] = false,
      ["file_search"] = true,
      ["grep_search"] = true,
      ["cmd_runner"] = false,
    }
  end
end

--- Get the display string for lualine
---@return string
function M.get_lualine_display()
  local mode = M._mode == M.MODES.BUILD and "BUILD" or "PLAN"
  return "[" .. mode .. "]"
end

--- Get the highlight group for the current mode
---@return string
function M.get_mode_highlight()
  if M.is_build_mode() then
    return "DiagnosticOk" -- Green
  else
    return "DiagnosticWarn" -- Yellow
  end
end

--- Initialize agent mode from config
---@param config table|nil
function M.setup(config)
  config = config or {}
  local default_mode = config.default_mode or M.MODES.BUILD

  if default_mode == M.MODES.BUILD or default_mode == M.MODES.PLAN then
    M._mode = default_mode
  else
    vim.notify("Invalid default_mode in config: " .. tostring(default_mode), vim.log.levels.WARN)
    M._mode = M.MODES.BUILD
  end
end

--- Create user commands for mode switching
function M.create_commands()
  vim.api.nvim_create_user_command("AIBuildMode", function()
    M.set_mode(M.MODES.BUILD)
  end, { desc = "Switch to AI Build mode (full tool access)" })

  vim.api.nvim_create_user_command("AIPlanMode", function()
    M.set_mode(M.MODES.PLAN)
  end, { desc = "Switch to AI Plan mode (read-only analysis)" })

  vim.api.nvim_create_user_command("AIToggleMode", function()
    M.toggle_mode()
  end, { desc = "Toggle between AI Build and Plan modes" })

  vim.api.nvim_create_user_command("AIMode", function()
    local mode = M._mode == M.MODES.BUILD and "BUILD" or "PLAN"
    vim.notify("Current AI mode: " .. mode, vim.log.levels.INFO)
  end, { desc = "Show current AI mode" })
end

return M
