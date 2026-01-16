-- Lualine status indicator for LM Studio and Agent Mode
-- Shows when LM Studio is active and current AI mode (Plan/Build)
-- v2.0.0: Shows "AI OFF" when AI assistant is disabled

return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- Ensure sections exist
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- v2.0.0: Add AI disabled indicator (highest priority - shows first)
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return "AI OFF"
        end,
        cond = function()
          local main_ok, main = pcall(require, "lazyvim-ai-assistant")
          return main_ok and not main.is_enabled()
        end,
        color = { fg = "#f38ba8" }, -- Red for disabled
      })

      -- Add LM Studio status with mode indicator to lualine
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local lmstudio = require("lazyvim-ai-assistant.lmstudio")
          local agent = require("lazyvim-ai-assistant.agent")

          if not lmstudio.is_running() then
            return ""
          end

          -- Get current mode display
          local mode_display = agent.get_lualine_display()
          return "LM " .. mode_display
        end,
        cond = function()
          -- Only show when LM Studio is reachable AND AI is enabled
          local main_ok, main = pcall(require, "lazyvim-ai-assistant")
          if not main_ok or not main.is_enabled() then
            return false
          end
          return require("lazyvim-ai-assistant.lmstudio").is_running()
        end,
        color = function()
          local agent = require("lazyvim-ai-assistant.agent")
          if agent.is_build_mode() then
            return { fg = "#a6e3a1" } -- Green for build mode
          else
            return { fg = "#f9e2af" } -- Yellow for plan mode
          end
        end,
      })

      -- Also add a Copilot mode indicator when using Copilot
      table.insert(opts.sections.lualine_x, 3, {
        function()
          local agent = require("lazyvim-ai-assistant.agent")
          local mode_display = agent.get_lualine_display()
          return " CP " .. mode_display
        end,
        cond = function()
          -- Only show when using Copilot (LM Studio not running) AND AI is enabled
          local main_ok, main = pcall(require, "lazyvim-ai-assistant")
          if not main_ok or not main.is_enabled() then
            return false
          end
          return not require("lazyvim-ai-assistant.lmstudio").is_running()
        end,
        color = function()
          local agent = require("lazyvim-ai-assistant.agent")
          if agent.is_build_mode() then
            return { fg = "#a6e3a1" } -- Green for build mode
          else
            return { fg = "#f9e2af" } -- Yellow for plan mode
          end
        end,
      })
    end,
  },
}
