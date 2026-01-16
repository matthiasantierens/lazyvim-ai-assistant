-- Health check for lazyvim-ai-assistant
-- Run with :checkhealth lazyvim-ai-assistant
-- v2.0.0: Added checks for new modules and features

local M = {}

function M.check()
  vim.health.start("lazyvim-ai-assistant")

  -- Check LM Studio connectivity
  local lmstudio_ok, lmstudio = pcall(require, "lazyvim-ai-assistant.lmstudio")
  if lmstudio_ok then
    if lmstudio.is_running() then
      vim.health.ok("LM Studio is reachable at " .. require("lazyvim-ai-assistant").get_lmstudio_url())
    else
      vim.health.warn("LM Studio is not running (using Copilot fallback)")
    end
  else
    vim.health.error("Failed to load lmstudio module: " .. tostring(lmstudio))
  end

  -- Check agent mode (v2.0.0)
  vim.health.start("Agent Mode (v2.0.0)")
  local agent_ok, agent = pcall(require, "lazyvim-ai-assistant.agent")
  if agent_ok then
    local mode = agent.get_mode()
    local mode_display = mode == "build" and "BUILD (full tool access)" or "PLAN (read-only)"
    vim.health.ok("Agent module loaded - Current mode: " .. mode_display)
  else
    vim.health.error("Failed to load agent module: " .. tostring(agent))
  end

  -- Check required dependencies
  vim.health.start("Required dependencies")

  local required_deps = {
    { name = "copilot", display = "zbirenbaum/copilot.lua" },
    { name = "codecompanion", display = "olimorris/codecompanion.nvim" },
    { name = "plenary", display = "nvim-lua/plenary.nvim" },
  }

  for _, dep in ipairs(required_deps) do
    local ok = pcall(require, dep.name)
    if ok then
      vim.health.ok(dep.display .. " is installed")
    else
      vim.health.error(dep.display .. " is not installed")
    end
  end

  -- Check optional dependencies
  vim.health.start("Optional dependencies")

  local optional_deps = {
    { name = "minuet", display = "milanglacier/minuet-ai.nvim", note = "Required for LM Studio autocomplete" },
    { name = "blink.cmp", display = "saghen/blink.cmp", note = "For completion menu integration" },
    { name = "lualine", display = "nvim-lualine/lualine.nvim", note = "For status line indicator" },
    { name = "telescope", display = "nvim-telescope/telescope.nvim", note = "For file picker (context)" },
    { name = "fzf-lua", display = "ibhagwan/fzf-lua", note = "Alternative file picker" },
    { name = "codecompanion-history", display = "ravitemer/codecompanion-history.nvim", note = "For session persistence" },
  }

  for _, dep in ipairs(optional_deps) do
    local ok = pcall(require, dep.name)
    if ok then
      vim.health.ok(dep.display .. " is installed")
    else
      vim.health.info(dep.display .. " is not installed (" .. dep.note .. ")")
    end
  end

  -- Check v2.0.0 modules
  vim.health.start("v2.0.0 Modules")

  local v2_modules = {
    { name = "lazyvim-ai-assistant.agent", display = "Agent (Plan/Build mode)" },
    { name = "lazyvim-ai-assistant.context", display = "Context management" },
    { name = "lazyvim-ai-assistant.prompts", display = "Custom prompts" },
    { name = "lazyvim-ai-assistant.diff", display = "Diff utilities" },
  }

  for _, mod in ipairs(v2_modules) do
    local ok = pcall(require, mod.name)
    if ok then
      vim.health.ok(mod.display .. " module loaded")
    else
      vim.health.warn(mod.display .. " module failed to load")
    end
  end

  -- Check custom prompts directory (v2.0.0)
  vim.health.start("Custom Prompts")
  local prompts_ok, prompts = pcall(require, "lazyvim-ai-assistant.prompts")
  if prompts_ok then
    local prompts_dir = prompts.get_prompts_dir()
    if vim.fn.isdirectory(prompts_dir) == 1 then
      local loaded = prompts.get_prompts()
      local count = vim.tbl_count(loaded)
      vim.health.ok("Prompts directory exists: " .. prompts_dir)
      vim.health.info("Loaded " .. count .. " custom prompt(s)")
    else
      vim.health.info("Prompts directory not found: " .. prompts_dir)
      vim.health.info("Create it with :AIPrompts init")
    end
  else
    vim.health.warn("Prompts module not available")
  end

  -- Check external tools
  vim.health.start("External tools")

  -- Check curl
  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl is available")
  else
    vim.health.error("curl is not available (required for LM Studio connectivity check)")
  end

  -- Check node (for Copilot)
  if vim.fn.executable("node") == 1 then
    local handle = io.popen("node --version 2>/dev/null")
    if handle then
      local version = handle:read("*a"):gsub("%s+", "")
      handle:close()
      vim.health.ok("Node.js is available (" .. version .. ")")
    else
      vim.health.ok("Node.js is available")
    end
  else
    vim.health.warn("Node.js is not available (required for GitHub Copilot)")
  end

  -- Check git (for context)
  if vim.fn.executable("git") == 1 then
    vim.health.ok("git is available (for context management)")
  else
    vim.health.info("git is not available (some context features may not work)")
  end

  -- Configuration info
  vim.health.start("Configuration")
  local config_ok, main = pcall(require, "lazyvim-ai-assistant")
  if config_ok then
    local config = main.get_config()

    -- LM Studio config
    vim.health.info("LM Studio URL: " .. config.lmstudio.url)
    vim.health.info("LM Studio Model: " .. config.lmstudio.model)

    -- Copilot config
    vim.health.info("Copilot Autocomplete Model: " .. config.copilot.autocomplete_model)
    vim.health.info("Copilot Chat Model: " .. config.copilot.chat_model)

    -- v2.0.0 config
    if config.agent then
      vim.health.info("Default Agent Mode: " .. (config.agent.default_mode or "build"))
    end
    if config.context then
      vim.health.info("Context Picker: " .. (config.context.picker or "auto"))
    end
    if config.history then
      vim.health.info("Session History: " .. (config.history.enabled ~= false and "enabled" or "disabled"))
    end
  else
    vim.health.error("Failed to load configuration")
  end
end

return M
