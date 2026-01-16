-- Blink.cmp integration for minuet
-- Only loads when LM Studio is running (otherwise minuet.blink module won't exist)

return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "milanglacier/minuet-ai.nvim" },
    cond = function()
      return require("lazyvim-ai-assistant.lmstudio").is_running()
    end,
    opts = {
      -- Add minuet to completion sources
      sources = {
        -- Add minuet to default sources
        -- Note: LazyVim's copilot extra already adds 'copilot' to default
        default = { "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            -- Async is required for LLM-based completion
            async = true,
            -- Timeout should match minuet.config.request_timeout * 1000 (ms)
            timeout_ms = 3000,
            -- Higher score = higher priority
            -- Copilot is 100, so 150 makes LM Studio primary
            score_offset = 150,
          },
        },
      },
      -- Enable ghost text preview of selected completion
      completion = {
        -- Avoid unnecessary requests
        trigger = { prefetch_on_insert = false },
        -- Ghost text configuration
        ghost_text = {
          enabled = true,
          -- Show ghost text with selection in menu
          show_with_selection = true,
        },
      },
      -- Manual completion keymap
      keymap = {
        -- Alt-y to manually trigger minuet completion
        ["<A-y>"] = {
          function(cmp)
            cmp.show({ providers = { "minuet" } })
          end,
          "fallback",
        },
      },
    },
  },
}
