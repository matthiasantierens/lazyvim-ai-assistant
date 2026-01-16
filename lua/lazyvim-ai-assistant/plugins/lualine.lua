-- Lualine status indicator for LM Studio and Agent Mode
-- Shows when LM Studio is active and current AI mode (Plan/Build)

return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- Ensure sections exist
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- Add LM Studio status with mode indicator to lualine
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local lmstudio = require("lazyvim-ai-assistant.lmstudio")
          local agent = require("lazyvim-ai-assistant.agent")

          if not lmstudio.is_running() then
            return ""
          end

          -- Get current mode display
          local mode_display = agent.get_lualine_display()
          return "󰚩 LM " .. mode_display
        end,
        cond = function()
          -- Only show when LM Studio is reachable
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
      table.insert(opts.sections.lualine_x, 2, {
        function()
          local agent = require("lazyvim-ai-assistant.agent")
          local mode_display = agent.get_lualine_display()
          return " CP " .. mode_display
        end,
        cond = function()
          -- Only show when using Copilot (LM Studio not running)
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
