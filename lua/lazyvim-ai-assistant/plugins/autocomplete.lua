-- Autocomplete configuration
-- LM Studio via minuet.nvim with Copilot fallback

--- Get config values from central module
local function get_config()
  local main = require("lazyvim-ai-assistant")
  return {
    lmstudio_url = main.get_lmstudio_url(),
    lmstudio_model = main.get_lmstudio_model(),
    copilot_model = main.get_copilot_autocomplete_model(),
  }
end

return {
  -- Copilot for fallback autocomplete
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      local lmstudio = require("lazyvim-ai-assistant.lmstudio")
      local cfg = get_config()
      local use_copilot = not lmstudio.is_running()

      require("copilot").setup({
        suggestion = {
          enabled = use_copilot,
          auto_trigger = use_copilot,
          keymap = {
            accept = "<A-a>",
            accept_line = "<A-l>",
            next = "<A-]>",
            prev = "<A-[>",
            dismiss = "<A-e>",
          },
        },
        panel = { enabled = false },
        filetypes = { ["*"] = true },
        copilot_model = cfg.copilot_model,
      })

      -- Add Shift+Tab as alternative accept key for Copilot
      if use_copilot then
        vim.keymap.set("i", "<S-Tab>", function()
          local suggestion = require("copilot.suggestion")
          if suggestion.is_visible() then
            suggestion.accept()
          else
            -- Fallback to normal Shift+Tab behavior (dedent or previous item)
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
          end
        end, { desc = "Accept Copilot suggestion or fallback" })
      end

      -- Notify which autocomplete backend is active
      if use_copilot then
        vim.defer_fn(function()
          vim.notify("Autocomplete: Using Copilot (" .. cfg.copilot_model .. ")", vim.log.levels.INFO)
        end, 100)
      end
    end,
  },

  -- Minuet for LM Studio (only when LM Studio is running)
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cond = function()
      return require("lazyvim-ai-assistant.lmstudio").is_running()
    end,
    config = function()
      local cfg = get_config()

      vim.defer_fn(function()
        vim.notify("Autocomplete: Using LM Studio", vim.log.levels.INFO)
      end, 100)

      require("minuet").setup({
        -- Use OpenAI-compatible provider for LM Studio
        provider = "openai_compatible",
        -- Timeout in seconds - keeps UI responsive
        request_timeout = 3,
        -- Throttle requests to avoid overwhelming local LLM
        throttle = 1000,
        -- Debounce to reduce request frequency
        debounce = 400,
        -- Number of completion suggestions to request
        n_completions = 2,
        -- Context window size (characters, not tokens)
        context_window = 8000,
        -- Reduce notifications to warnings only
        notify = "warn",

        -- Custom prompt to avoid markdown formatting
        default_template = {
          template = [[<|system|>
You are a code completion assistant. Complete the code at <cursorPosition>.
CRITICAL RULES:
- Output ONLY raw code, no explanations
- NEVER use markdown code fences (``` or ```yaml etc)
- NEVER add comments explaining your completion
- Match the existing indentation exactly
- Keep completions short (1-3 lines)
<|end|>
<|user|>
File type: {{language}}
<contextBeforeCursor>
{{context_before_cursor}}
<cursorPosition>
<contextAfterCursor>
{{context_after_cursor}}
<|end|>
<|assistant|>
]],
          prompt = "",
          guidelines = "",
          n_completion_template = "",
        },

        provider_options = {
          openai_compatible = {
            -- LM Studio endpoint
            end_point = cfg.lmstudio_url .. "/v1/chat/completions",
            -- Model running in LM Studio
            model = cfg.lmstudio_model,
            -- Name shown in completion menu
            name = "LM Studio",
            -- Use any non-empty env var as placeholder (LM Studio doesn't need auth)
            api_key = "TERM",
            -- Enable streaming for faster first tokens
            stream = true,
            optional = {
              max_tokens = 256,
              top_p = 0.9,
            },
          },
        },

        -- Virtual text (ghost text) configuration
        virtualtext = {
          -- Auto-trigger for all file types (set specific ones to limit)
          auto_trigger_ft = { "*" },
          -- Disable in certain file types
          auto_trigger_ignore_ft = { "TelescopePrompt", "neo-tree", "NvimTree", "lazy", "mason" },
          keymap = {
            -- Accept whole completion
            accept = "<A-a>",
            -- Accept one line
            accept_line = "<A-l>",
            -- Cycle to next completion
            next = "<A-]>",
            -- Cycle to prev completion
            prev = "<A-[>",
            -- Dismiss completion
            dismiss = "<A-e>",
          },
          -- Show virtual text even when completion menu is visible
          show_on_completion_menu = false,
        },

        -- Enable blink.cmp integration
        blink = {
          enable_auto_complete = true,
        },
      })

      -- Add Shift+Tab as alternative accept key for Minuet
      vim.keymap.set("i", "<S-Tab>", function()
        local has_minuet, minuet = pcall(require, "minuet.virtualtext")
        if has_minuet and minuet.action.is_visible() then
          minuet.action.accept()
        else
          -- Fallback to normal Shift+Tab behavior
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
        end
      end, { desc = "Accept Minuet suggestion or fallback" })
    end,
  },
}
