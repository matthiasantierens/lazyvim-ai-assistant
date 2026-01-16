-- Context management for lazyvim-ai-assistant
-- Provides file picker integration, project context, and smart context handling

local M = {}

-- Project type definitions with their marker files
M.project_types = {
  nodejs = { markers = { "package.json" }, name = "Node.js" },
  python = { markers = { "pyproject.toml", "setup.py", "requirements.txt" }, name = "Python" },
  rust = { markers = { "Cargo.toml" }, name = "Rust" },
  go = { markers = { "go.mod" }, name = "Go" },
  lua = { markers = { ".luarc.json", "stylua.toml" }, name = "Lua" },
  ruby = { markers = { "Gemfile" }, name = "Ruby" },
  java = { markers = { "pom.xml", "build.gradle" }, name = "Java" },
  dotnet = { markers = { "*.csproj", "*.sln" }, name = ".NET" },
  php = { markers = { "composer.json" }, name = "PHP" },
}

--- Detect the project type based on marker files
---@return table|nil { type = string, name = string }
function M.detect_project_type()
  local cwd = vim.fn.getcwd()

  for type_key, type_def in pairs(M.project_types) do
    for _, marker in ipairs(type_def.markers) do
      local pattern = cwd .. "/" .. marker
      local files = vim.fn.glob(pattern, false, true)
      if #files > 0 then
        return { type = type_key, name = type_def.name }
      end
    end
  end

  return nil
end

--- Get project structure summary
---@param max_depth number|nil Maximum directory depth (default 3)
---@return string
function M.get_project_structure(max_depth)
  max_depth = max_depth or 3
  local cwd = vim.fn.getcwd()
  local lines = { "Project Structure:", "```" }

  -- Use find command to get directory structure
  local cmd = string.format("find %s -maxdepth %d -type f -name '*.lua' -o -type f -name '*.py' -o -type f -name '*.js' -o -type f -name '*.ts' -o -type f -name '*.go' -o -type f -name '*.rs' 2>/dev/null | head -50", vim.fn.shellescape(cwd), max_depth)
  local ok, handle = pcall(io.popen, cmd)
  if ok and handle then
    local result = handle:read("*a")
    handle:close()

    for line in result:gmatch("[^\n]+") do
      -- Make paths relative
      local relative = line:gsub("^" .. vim.pesc(cwd) .. "/", "")
      table.insert(lines, "  " .. relative)
    end
  end

  table.insert(lines, "```")

  -- Add project type info
  local project_type = M.detect_project_type()
  if project_type then
    table.insert(lines, 1, "Project Type: " .. project_type.name)
  end

  return table.concat(lines, "\n")
end

--- Read file content with size limit
---@param filepath string
---@param max_size number|nil Maximum file size in bytes (default 100000)
---@return string|nil content, string|nil error
function M.read_file(filepath, max_size)
  max_size = max_size or 100000

  local stat = vim.loop.fs_stat(filepath)
  if not stat then
    return nil, "File not found: " .. filepath
  end

  if stat.size > max_size then
    return nil, string.format("File too large: %s (%d bytes, max %d)", filepath, stat.size, max_size)
  end

  local file = io.open(filepath, "r")
  if not file then
    return nil, "Cannot open file: " .. filepath
  end

  local content = file:read("*a")
  file:close()

  return content
end

--- Get git status summary
---@return string
function M.get_git_summary()
  local lines = { "Git Status:", "```" }

  -- Check if in git repo
  local ok, handle = pcall(io.popen, "git rev-parse --is-inside-work-tree 2>/dev/null")
  if ok and handle then
    local result = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if result ~= "true" then
      return "Not a git repository"
    end
  else
    return "Git not available"
  end

  -- Get current branch
  ok, handle = pcall(io.popen, "git branch --show-current 2>/dev/null")
  if ok and handle then
    local branch = handle:read("*a"):gsub("%s+", "")
    handle:close()
    table.insert(lines, "Branch: " .. branch)
  end

  -- Get status summary
  ok, handle = pcall(io.popen, "git status --short 2>/dev/null | head -20")
  if ok and handle then
    local status = handle:read("*a")
    handle:close()
    if status and #status > 0 then
      table.insert(lines, "Changes:")
      for line in status:gmatch("[^\n]+") do
        table.insert(lines, "  " .. line)
      end
    else
      table.insert(lines, "Working tree clean")
    end
  end

  table.insert(lines, "```")
  return table.concat(lines, "\n")
end

--- Get available picker (telescope or fzf-lua)
---@return string|nil picker_name
function M.get_available_picker()
  local config = require("lazyvim-ai-assistant").get_config()
  local picker_pref = config.context and config.context.picker or "auto"

  if picker_pref == "telescope" then
    if pcall(require, "telescope") then
      return "telescope"
    end
  elseif picker_pref == "fzf" then
    if pcall(require, "fzf-lua") then
      return "fzf"
    end
  else
    -- Auto-detect
    if pcall(require, "telescope") then
      return "telescope"
    elseif pcall(require, "fzf-lua") then
      return "fzf"
    end
  end

  return nil
end

--- Open file picker and return selected files
---@param callback function Called with list of selected file paths
function M.pick_files(callback)
  local picker = M.get_available_picker()

  if picker == "telescope" then
    require("telescope.builtin").find_files({
      prompt_title = "Add Files to AI Context",
      attach_mappings = function(prompt_bufnr, map)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Override default select to get file path
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            callback({ selection.value or selection[1] })
          end
        end)

        return true
      end,
    })
  elseif picker == "fzf" then
    require("fzf-lua").files({
      prompt = "Add Files to AI Context> ",
      actions = {
        ["default"] = function(selected)
          if selected and #selected > 0 then
            callback(selected)
          end
        end,
      },
    })
  else
    vim.notify("No file picker available. Install telescope.nvim or fzf-lua.", vim.log.levels.WARN)
    callback({})
  end
end

--- Format file content for context
---@param filepath string
---@return string
function M.format_file_for_context(filepath)
  local content, err = M.read_file(filepath)
  if err then
    return "Error reading " .. filepath .. ": " .. err
  end

  -- Detect filetype from extension
  local ext = filepath:match("%.([^%.]+)$") or ""
  local filetype = vim.filetype.match({ filename = filepath }) or ext

  local relative_path = filepath:gsub("^" .. vim.pesc(vim.fn.getcwd()) .. "/", "")

  return string.format("File: %s\n```%s\n%s\n```", relative_path, filetype, content)
end

--- Get current visual selection
---@return string|nil
function M.get_visual_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  if #lines == 0 then
    return nil
  end

  -- Adjust for partial line selection
  if #lines == 1 then
    lines[1] = lines[1]:sub(start_pos[3], end_pos[3])
  else
    lines[1] = lines[1]:sub(start_pos[3])
    lines[#lines] = lines[#lines]:sub(1, end_pos[3])
  end

  return table.concat(lines, "\n")
end

--- Setup context module
---@param config table|nil
function M.setup(config)
  config = config or {}
  -- Store config for later use
  M._config = config
end

--- Create user commands for context management
function M.create_commands()
  vim.api.nvim_create_user_command("AIContext", function(opts)
    local args = opts.args

    if args == "project" then
      local structure = M.get_project_structure()
      print(structure)
    elseif args == "git" then
      local git = M.get_git_summary()
      print(git)
    elseif args == "file" then
      M.pick_files(function(files)
        for _, file in ipairs(files) do
          local formatted = M.format_file_for_context(file)
          print(formatted)
        end
      end)
    else
      print("Usage: :AIContext [project|git|file]")
    end
  end, {
    nargs = "?",
    complete = function()
      return { "project", "git", "file" }
    end,
    desc = "AI context management",
  })
end

return M
