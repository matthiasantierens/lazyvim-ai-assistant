-- Autocomplete configuration
-- LM Studio via minuet.nvim with Copilot fallback
-- v2.0.0: Added is_enabled check and configurable context limits

--- Get config values from central module
local function get_config()
  local main = require("lazyvim-ai-assistant")
  return {
    lmstudio_url = main.get_lmstudio_url(),
    lmstudio_model = main.get_lmstudio_model(),
    copilot_model = main.get_copilot_autocomplete_model(),
    -- v2.0.0: New autocomplete settings
    context_window = main.get_autocomplete_context_window(),
    n_completions = main.get_autocomplete_n_completions(),
    max_tokens = main.get_autocomplete_max_tokens(),
  }
end

--- Check if AI assistant is enabled
local function is_ai_enabled()
  local main = require("lazyvim-ai-assistant")
  return main.is_enabled()
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

      -- Check if AI is globally enabled
      local ai_enabled = is_ai_enabled()

      require("copilot").setup({
        suggestion = {
          enabled = use_copilot and ai_enabled,
          auto_trigger = use_copilot and ai_enabled,
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
      if use_copilot and ai_enabled then
        vim.keymap.set("i", "<S-Tab>", function()
          -- Check if AI is still enabled at runtime
          if not is_ai_enabled() then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
            return
          end
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
      if use_copilot and ai_enabled then
        vim.defer_fn(function()
          vim.notify("Autocomplete: Using Copilot (" .. cfg.copilot_model .. ")", vim.log.levels.INFO)
        end, 100)
      elseif not ai_enabled then
        vim.defer_fn(function()
          vim.notify("Autocomplete: AI disabled (saving tokens)", vim.log.levels.INFO)
        end, 100)
      end

      -- Listen for enable/disable events
      vim.api.nvim_create_autocmd("User", {
        pattern = { "AIAssistantEnabled", "AIAssistantDisabled" },
        callback = function(ev)
          local enabled = ev.match == "AIAssistantEnabled"
          local copilot_ok, copilot_suggestion = pcall(require, "copilot.suggestion")
          if copilot_ok and use_copilot then
            -- Toggle Copilot suggestions based on AI enabled state
            if enabled then
              copilot_suggestion.toggle_auto_trigger()
            else
              copilot_suggestion.dismiss()
            end
          end
        end,
      })
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

      -- Check if AI is globally enabled
      local ai_enabled = is_ai_enabled()

      if ai_enabled then
        vim.defer_fn(function()
          vim.notify("Autocomplete: Using LM Studio", vim.log.levels.INFO)
        end, 100)
      else
        vim.defer_fn(function()
          vim.notify("Autocomplete: AI disabled (saving tokens)", vim.log.levels.INFO)
        end, 100)
      end

      require("minuet").setup({
        -- Use OpenAI-compatible provider for LM Studio
        provider = "openai_compatible",
        -- Timeout in seconds - keeps UI responsive
        request_timeout = 3,
        -- Throttle requests to avoid overwhelming local LLM
        throttle = 1000,
        -- Debounce to reduce request frequency
        debounce = 400,
        -- v2.0.0: Configurable completion settings (defaults reduced for cost savings)
        n_completions = cfg.n_completions,
        context_window = cfg.context_window,
        -- Reduce notifications to warnings only
        notify = "warn",
        -- v2.0.0: Check if AI is enabled before making requests
        -- Note: enable_predicates replaced 'enabled' in minuet v0.8.0
        enable_predicates = {
          function()
            return is_ai_enabled()
          end,
        },

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
              -- v2.0.0: Configurable max_tokens (default reduced from 256 to 128)
              max_tokens = cfg.max_tokens,
              top_p = 0.9,
            },
          },
        },

        -- Virtual text (ghost text) configuration
        virtualtext = {
          -- Auto-trigger for all file types (set specific ones to limit)
          auto_trigger_ft = ai_enabled and { "*" } or {},
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
          enable_auto_complete = ai_enabled,
        },
      })

      -- Add Shift+Tab as alternative accept key for Minuet
      vim.keymap.set("i", "<S-Tab>", function()
        -- Check if AI is still enabled at runtime
        if not is_ai_enabled() then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
          return
        end
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
