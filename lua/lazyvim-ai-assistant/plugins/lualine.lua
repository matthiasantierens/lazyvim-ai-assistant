-- Lualine status indicator for LM Studio
-- Shows when LM Studio is active

return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- Add LM Studio status to lualine
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local ok, minuet = pcall(require, "minuet.virtualtext")
          if ok and minuet then
            return "󰚩 LM"
          end
          return ""
        end,
        cond = function()
          -- Only show when LM Studio is reachable
          return require("lazyvim-ai-assistant.lmstudio").is_running()
        end,
        color = { fg = "#89b4fa" },
      })
    end,
  },
}
