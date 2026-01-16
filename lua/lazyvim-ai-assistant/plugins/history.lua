-- Session persistence plugin wrapper
-- Integrates codecompanion-history.nvim for chat session management

return {
  {
    "ravitemer/codecompanion-history.nvim",
    dependencies = {
      "olimorris/codecompanion.nvim",
    },
    lazy = true,
    opts = function()
      local config = require("lazyvim-ai-assistant").get_config()
      local history_config = config.history or {}

      return {
        -- Enable/disable the extension
        enabled = history_config.enabled ~= false,

        -- Auto-save chats when closed
        auto_save = history_config.auto_save ~= false,

        -- Maximum number of saved sessions
        max_sessions = history_config.max_sessions or 50,

        -- Storage location
        save_dir = vim.fn.stdpath("data") .. "/codecompanion-history",

        -- Picker preference (telescope or fzf-lua)
        picker = config.context and config.context.picker or "auto",
      }
    end,
    keys = {
      {
        "<leader>as",
        function()
          -- Try to use the history picker
          local ok, history = pcall(require, "codecompanion-history")
          if ok and history.pick then
            history.pick()
          else
            vim.notify("Session history not available", vim.log.levels.WARN)
          end
        end,
        mode = "n",
        desc = "Browse AI sessions",
      },
    },
    cmd = {
      "AISessions",
      "AISave",
      "AIDelete",
    },
    config = function(_, opts)
      -- Check if history is enabled
      local config = require("lazyvim-ai-assistant").get_config()
      local history_config = config.history or {}

      if history_config.enabled == false then
        return
      end

      -- Setup the plugin
      local ok, history = pcall(require, "codecompanion-history")
      if ok then
        history.setup(opts)
      end

      -- Create custom commands
      vim.api.nvim_create_user_command("AISessions", function()
        local history_ok, hist = pcall(require, "codecompanion-history")
        if history_ok and hist.pick then
          hist.pick()
        else
          vim.notify("Session history not available", vim.log.levels.WARN)
        end
      end, { desc = "Browse AI chat sessions" })

      vim.api.nvim_create_user_command("AISave", function(cmd_opts)
        local history_ok, hist = pcall(require, "codecompanion-history")
        if history_ok and hist.save then
          hist.save(cmd_opts.args ~= "" and cmd_opts.args or nil)
          vim.notify("Session saved", vim.log.levels.INFO)
        else
          vim.notify("Session history not available", vim.log.levels.WARN)
        end
      end, {
        nargs = "?",
        desc = "Save current AI chat session",
      })

      vim.api.nvim_create_user_command("AIDelete", function()
        local history_ok, hist = pcall(require, "codecompanion-history")
        if history_ok and hist.delete then
          hist.delete()
        else
          vim.notify("Session history not available", vim.log.levels.WARN)
        end
      end, { desc = "Delete AI chat session" })
    end,
  },
}
