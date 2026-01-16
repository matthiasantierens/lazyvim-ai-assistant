-- Health check for lazyvim-ai-assistant
-- Run with :checkhealth lazyvim-ai-assistant

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
  }

  for _, dep in ipairs(optional_deps) do
    local ok = pcall(require, dep.name)
    if ok then
      vim.health.ok(dep.display .. " is installed")
    else
      vim.health.info(dep.display .. " is not installed (" .. dep.note .. ")")
    end
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

  -- Configuration info
  vim.health.start("Configuration")
  local config_ok, main = pcall(require, "lazyvim-ai-assistant")
  if config_ok then
    local config = main.get_config()
    vim.health.info("LM Studio URL: " .. config.lmstudio.url)
    vim.health.info("LM Studio Model: " .. config.lmstudio.model)
    vim.health.info("Copilot Autocomplete Model: " .. config.copilot.autocomplete_model)
    vim.health.info("Copilot Chat Model: " .. config.copilot.chat_model)
  else
    vim.health.error("Failed to load configuration")
  end
end

return M
