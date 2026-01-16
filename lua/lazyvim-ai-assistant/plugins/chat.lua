-- CodeCompanion configuration
-- Chat and inline code assistance with LM Studio or Copilot fallback

--- Get config values
local function get_config()
  local config = _G.lazyvim_ai_assistant_config or {}
  return {
    lmstudio_url = (config.lmstudio or {}).url or "http://localhost:1234",
    lmstudio_model = (config.lmstudio or {}).model or "qwen2.5-coder-14b-instruct-mlx",
    copilot_chat_model = (config.copilot or {}).chat_model or "claude-sonnet-4.5",
  }
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local lmstudio = require("lazyvim-ai-assistant.lmstudio")
      local help = require("lazyvim-ai-assistant.help")
      local cfg = get_config()
      local use_lmstudio = lmstudio.is_running()

      -- Notify which chat backend is active
      vim.defer_fn(function()
        if use_lmstudio then
          vim.notify("Chat: Using LM Studio", vim.log.levels.INFO)
        else
          vim.notify("Chat: Using Copilot (" .. cfg.copilot_chat_model .. ")", vim.log.levels.INFO)
        end
      end, 200)

      -- Determine adapter config based on LM Studio availability
      local chat_adapter = use_lmstudio and "lmstudio" or {
        name = "copilot",
        model = cfg.copilot_chat_model,
      }

      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = chat_adapter,
            variables = {
              ["buffer"] = {
                opts = {
                  -- LM Studio: "watch" (lighter, sends only changes)
                  -- Copilot: "pin" (full buffer, better context)
                  default_params = use_lmstudio and "watch" or "pin",
                },
              },
            },
          },
          inline = {
            adapter = chat_adapter,
            keymaps = {
              accept_change = { modes = { n = "<leader>da" } },
              reject_change = { modes = { n = "<leader>dr" } },
            },
          },
        },
        display = {
          diff = {
            enabled = true,
            provider = "inline",
            provider_opts = {
              inline = {
                layout = "float",
                opts = {
                  show_keymap_hints = true,
                  dim = 25,
                  context_lines = 3,
                  show_removed = true,
                  full_width_removed = true,
                },
              },
            },
          },
        },
        prompt_library = {
          ["Code Review"] = {
            interaction = "chat",
            description = "Review code for bugs, issues, and improvements",
            opts = {
              alias = "review",
              auto_submit = true,
              is_slash_cmd = true,
              modes = { "v" },
              stop_context_insertion = true,
            },
            prompts = {
              {
                role = "system",
                content = [[When asked to review code, follow these steps:

1. Identify potential bugs or logic errors
2. Check for security vulnerabilities
3. Evaluate code readability and maintainability
4. Suggest performance improvements if applicable
5. Note any missing error handling
6. Recommend best practices for the language/framework

Be concise but thorough. Focus on actionable feedback.]],
              },
              {
                role = "user",
                content = function(context)
                  local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                  return "Please review this " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
                end,
              },
            },
          },
        },
        adapters = {
          http = {
            lmstudio = function()
              return require("codecompanion.adapters.http").extend("openai_compatible", {
                name = "lmstudio",
                formatted_name = "LM Studio",
                env = {
                  url = cfg.lmstudio_url,
                  api_key = "dummy",
                  chat_url = "/v1/chat/completions",
                  models_endpoint = "/v1/models",
                },
                schema = {
                  model = {
                    default = cfg.lmstudio_model,
                  },
                },
              })
            end,
          },
        },
      })
    end,
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Toggle CodeCompanion Chat" },
      { "<leader>aa", ":'<,'>CodeCompanionChat<cr>", mode = "v", desc = "Chat with selection" },
      { "<leader>aA", ":'<,'>CodeCompanionChat Add<cr>", mode = "v", desc = "Add selection to chat" },
      { "<leader>ar", ":'<,'>CodeCompanion /review<cr>", mode = "v", desc = "Review code" },
      { "<leader>ae", ":'<,'>CodeCompanion /explain<cr>", mode = "v", desc = "Explain code" },
      { "<leader>af", ":'<,'>CodeCompanion /fix<cr>", mode = "v", desc = "Fix code" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = "n", desc = "Inline prompt" },
      { "<leader>ai", ":'<,'>CodeCompanion<cr>", mode = "v", desc = "Inline prompt with selection" },
      { "<leader>dD", "<cmd>CodeCompanionChat diff<cr>", mode = "n", desc = "Super Diff view" },
      {
        "<leader>ah",
        function()
          require("lazyvim-ai-assistant.help").show()
        end,
        mode = "n",
        desc = "AI keybindings help",
      },
    },
  },
}
