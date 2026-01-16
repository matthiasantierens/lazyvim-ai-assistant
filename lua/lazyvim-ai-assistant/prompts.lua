-- Custom prompt loading for lazyvim-ai-assistant
-- Loads prompts from .ai/prompts/ directory in project root

local M = {}

-- Cache for loaded prompts
M._prompts = {}

--- Parse YAML-like front matter from markdown content
---@param content string
---@return table|nil metadata, string body
function M.parse_front_matter(content)
  -- Check for front matter delimiter
  if not content:match("^%-%-%-\n") then
    return nil, content
  end

  -- Find the end of front matter
  local _, end_pos = content:find("\n%-%-%-\n", 4)
  if not end_pos then
    return nil, content
  end

  local front_matter = content:sub(5, end_pos - 4)
  local body = content:sub(end_pos + 1)

  -- Parse simple YAML-like front matter
  local metadata = {}
  for line in front_matter:gmatch("[^\n]+") do
    local key, value = line:match("^([%w_]+):%s*(.+)$")
    if key and value then
      -- Handle arrays like [v, n]
      if value:match("^%[") then
        local items = {}
        for item in value:gmatch("[%w_]+") do
          table.insert(items, item)
        end
        metadata[key] = items
      -- Handle booleans
      elseif value == "true" then
        metadata[key] = true
      elseif value == "false" then
        metadata[key] = false
      -- Handle numbers
      elseif tonumber(value) then
        metadata[key] = tonumber(value)
      else
        -- String value (remove quotes if present)
        metadata[key] = value:gsub("^[\"']", ""):gsub("[\"']$", "")
      end
    end
  end

  return metadata, body
end

--- Load a single prompt file
---@param filepath string
---@return table|nil prompt
function M.load_prompt_file(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local metadata, body = M.parse_front_matter(content)
  if not metadata then
    vim.notify("Prompt file missing front matter: " .. filepath, vim.log.levels.WARN)
    return nil
  end

  -- Validate required fields
  if not metadata.name then
    vim.notify("Prompt file missing 'name' in front matter: " .. filepath, vim.log.levels.WARN)
    return nil
  end

  -- Build CodeCompanion prompt structure
  local prompt = {
    strategy = metadata.strategy or "chat",
    description = metadata.description or metadata.name,
    opts = {
      is_slash_cmd = true,
      short_name = metadata.alias or metadata.name:lower():gsub("%s+", "_"),
      auto_submit = metadata.auto_submit ~= false, -- Default true
    },
    prompts = {
      {
        role = "system",
        content = body:gsub("^%s+", ""):gsub("%s+$", ""), -- Trim whitespace
      },
    },
  }

  -- Handle modes
  if metadata.modes then
    local mode_map = { v = "v", n = "n", i = "i" }
    local modes = {}
    for _, m in ipairs(metadata.modes) do
      if mode_map[m] then
        table.insert(modes, mode_map[m])
      end
    end
    if #modes > 0 then
      -- If visual mode, add code context
      if vim.tbl_contains(modes, "v") then
        table.insert(prompt.prompts, {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Apply this to the following " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
          end,
        })
      end
    end
  end

  return prompt
end

--- Get the prompts directory path
---@return string
function M.get_prompts_dir()
  local config = require("lazyvim-ai-assistant").get_config()
  local dir = config.prompts and config.prompts.project_dir or ".ai/prompts"

  -- Make absolute if relative
  if not dir:match("^/") then
    dir = vim.fn.getcwd() .. "/" .. dir
  end

  return dir
end

--- Load all prompts from the prompts directory
---@return table<string, table> prompts
function M.load_prompts()
  local prompts_dir = M.get_prompts_dir()
  local prompts = {}

  -- Check if directory exists
  if vim.fn.isdirectory(prompts_dir) ~= 1 then
    return prompts
  end

  -- Find all .md files in the prompts directory
  local files = vim.fn.glob(prompts_dir .. "/*.md", false, true)

  for _, filepath in ipairs(files) do
    local prompt = M.load_prompt_file(filepath)
    if prompt then
      prompts[prompt.opts.short_name] = prompt
    end
  end

  M._prompts = prompts
  return prompts
end

--- Get all loaded prompts
---@return table<string, table>
function M.get_prompts()
  return M._prompts
end

--- Reload prompts from disk
function M.reload()
  M.load_prompts()
  vim.notify("Reloaded " .. vim.tbl_count(M._prompts) .. " custom prompts", vim.log.levels.INFO)
end

--- Create the prompts directory if it doesn't exist
function M.ensure_prompts_dir()
  local dir = M.get_prompts_dir()
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.fn.mkdir(dir, "p")
    return true
  end
  return false
end

--- Create an example prompt file
function M.create_example_prompt()
  M.ensure_prompts_dir()

  local example_path = M.get_prompts_dir() .. "/example.md"

  -- Don't overwrite existing
  if vim.fn.filereadable(example_path) == 1 then
    vim.notify("Example prompt already exists: " .. example_path, vim.log.levels.INFO)
    return
  end

  local example_content = [[---
name: Example Prompt
description: An example custom prompt template
alias: example
modes: [v]
auto_submit: true
---

You are a helpful coding assistant. When the user provides code:

1. Analyze the code carefully
2. Provide helpful suggestions
3. Be concise but thorough

Remember to follow the project's coding conventions.
]]

  local file = io.open(example_path, "w")
  if file then
    file:write(example_content)
    file:close()
    vim.notify("Created example prompt: " .. example_path, vim.log.levels.INFO)
  else
    vim.notify("Failed to create example prompt", vim.log.levels.ERROR)
  end
end

--- Setup prompts module
---@param config table|nil
function M.setup(config)
  config = config or {}

  -- Load prompts on setup
  if config.load_builtin ~= false then
    M.load_prompts()
  end
end

--- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command("AIPrompts", function(opts)
    local args = opts.args

    if args == "reload" then
      M.reload()
    elseif args == "list" then
      local prompts = M.get_prompts()
      if vim.tbl_count(prompts) == 0 then
        print("No custom prompts loaded. Create prompts in: " .. M.get_prompts_dir())
      else
        print("Custom prompts:")
        for name, prompt in pairs(prompts) do
          print(string.format("  /%s - %s", name, prompt.description))
        end
      end
    elseif args == "init" then
      M.create_example_prompt()
    elseif args == "dir" then
      print("Prompts directory: " .. M.get_prompts_dir())
    else
      print("Usage: :AIPrompts [reload|list|init|dir]")
    end
  end, {
    nargs = "?",
    complete = function()
      return { "reload", "list", "init", "dir" }
    end,
    desc = "Manage AI custom prompts",
  })
end

return M
