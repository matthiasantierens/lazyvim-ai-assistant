-- CodeCompanion configuration
-- Chat and inline code assistance with LM Studio or Copilot fallback
-- v2.0.0: Added Plan/Build mode, tool groups, and extended prompt library

--- Get config values from central module
local function get_config()
  local main = require("lazyvim-ai-assistant")
  return {
    lmstudio_url = main.get_lmstudio_url(),
    lmstudio_model = main.get_lmstudio_model(),
    copilot_chat_model = main.get_copilot_chat_model(),
  }
end

--- Get the prompt library with all built-in prompts
local function get_prompt_library()
  return {
    -- Existing prompts
    ["Code Review"] = {
      interaction = "chat",
      description = "Review code for bugs, issues, and improvements",
      opts = {
        index = 1,
        is_slash_cmd = true,
        alias = "review",
        auto_submit = true,
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

    -- New prompts for v2.0.0
    ["Refactor"] = {
      interaction = "chat",
      description = "Refactor selected code for better quality",
      opts = {
        index = 2,
        is_slash_cmd = true,
        alias = "refactor",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert code refactoring assistant. When refactoring code:

1. Improve code readability and maintainability
2. Apply SOLID principles where appropriate
3. Reduce code duplication (DRY)
4. Simplify complex logic
5. Use appropriate design patterns
6. Maintain the same functionality - do not change behavior
7. Keep the same public API unless asked otherwise

Explain the changes you're making and why they improve the code.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Please refactor this " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
          end,
        },
      },
    },

    ["Write Tests"] = {
      interaction = "chat",
      description = "Generate tests for selected code",
      opts = {
        index = 3,
        is_slash_cmd = true,
        alias = "test",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert test writer. When generating tests:

1. Write comprehensive unit tests covering:
   - Happy path scenarios
   - Edge cases
   - Error handling
   - Boundary conditions
2. Use the appropriate testing framework for the language
3. Follow testing best practices (AAA pattern: Arrange, Act, Assert)
4. Include descriptive test names that explain what is being tested
5. Mock external dependencies appropriately
6. Aim for high code coverage

Generate tests that are maintainable and clearly document expected behavior.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Please write tests for this " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
          end,
        },
      },
    },

    ["Document"] = {
      interaction = "chat",
      description = "Add documentation to selected code",
      opts = {
        index = 4,
        is_slash_cmd = true,
        alias = "doc",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert technical documentation writer. When documenting code:

1. Add clear, concise documentation comments
2. Document function/method parameters and return values
3. Include usage examples where helpful
4. Explain complex logic or algorithms
5. Use the appropriate documentation format for the language:
   - JSDoc for JavaScript/TypeScript
   - Docstrings for Python
   - XML comments for C#
   - Javadoc for Java
   - LuaDoc for Lua
6. Document any side effects or important behaviors
7. Keep documentation up-to-date with the code

Return the code with added documentation.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Please add documentation to this " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
          end,
        },
      },
    },

    ["Optimize"] = {
      interaction = "chat",
      description = "Optimize code for performance",
      opts = {
        index = 5,
        is_slash_cmd = true,
        alias = "optimize",
        auto_submit = true,
      },
      prompts = {
        {
          role = "system",
          content = [[You are a performance optimization expert. When optimizing code:

1. Identify performance bottlenecks
2. Analyze time and space complexity
3. Suggest algorithmic improvements
4. Optimize memory usage
5. Reduce unnecessary operations
6. Consider caching strategies
7. Profile-guided recommendations when applicable
8. Balance readability with performance

Explain the performance impact of each change with Big-O notation where relevant.
Only suggest optimizations that provide meaningful improvements.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Please optimize this " .. context.filetype .. " code for better performance:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
          end,
        },
      },
    },

    ["Debug"] = {
      interaction = "chat",
      description = "Help debug code issues",
      opts = {
        index = 6,
        is_slash_cmd = true,
        alias = "debug",
        auto_submit = false, -- Don't auto-submit so user can describe the issue
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert debugger. When helping debug code:

1. Analyze the code for potential issues
2. Look for common bug patterns:
   - Off-by-one errors
   - Null/undefined references
   - Race conditions
   - Memory leaks
   - Logic errors
   - Type mismatches
3. Ask clarifying questions about the error or unexpected behavior
4. Suggest debugging strategies (logging, breakpoints, etc.)
5. Explain the root cause when found
6. Provide a fix with explanation

Be systematic and thorough in your analysis.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "I need help debugging this " .. context.filetype .. " code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```\n\nDescribe the issue you're experiencing:"
          end,
        },
      },
    },

    -- =========================================================================
    -- INLINE PROMPTS (show diff in source file)
    -- =========================================================================

    ["Optimize Inline"] = {
      interaction = "inline",
      description = "Optimize code (shows diff)",
      opts = {
        index = 10,
        is_slash_cmd = true,
        alias = "oi",
        auto_submit = true,
        placement = "replace",
      },
      prompts = {
        {
          role = "system",
          content = [[You are a performance optimization expert. Return ONLY the optimized code.
Do NOT include any explanations, comments about changes, or markdown formatting.
Do NOT wrap the code in backticks or code blocks.
Return the raw code only, ready to replace the original.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Optimize this " .. context.filetype .. " code for better performance:\n\n" .. code
          end,
        },
      },
    },

    ["Refactor Inline"] = {
      interaction = "inline",
      description = "Refactor code (shows diff)",
      opts = {
        index = 11,
        is_slash_cmd = true,
        alias = "ri",
        auto_submit = true,
        placement = "replace",
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert code refactoring assistant. Return ONLY the refactored code.
Do NOT include any explanations, comments about changes, or markdown formatting.
Do NOT wrap the code in backticks or code blocks.
Return the raw code only, ready to replace the original.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Refactor this " .. context.filetype .. " code for better quality:\n\n" .. code
          end,
        },
      },
    },

    ["Fix Inline"] = {
      interaction = "inline",
      description = "Fix code (shows diff)",
      opts = {
        index = 12,
        is_slash_cmd = true,
        alias = "fi",
        auto_submit = true,
        placement = "replace",
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert debugger. Return ONLY the fixed code.
Do NOT include any explanations, comments about changes, or markdown formatting.
Do NOT wrap the code in backticks or code blocks.
Return the raw code only, ready to replace the original.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Fix any bugs or issues in this " .. context.filetype .. " code:\n\n" .. code
          end,
        },
      },
    },

    ["Document Inline"] = {
      interaction = "inline",
      description = "Add documentation (shows diff)",
      opts = {
        index = 13,
        is_slash_cmd = true,
        alias = "di",
        auto_submit = true,
        placement = "replace",
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert technical documentation writer. Return ONLY the code with added documentation.
Use the appropriate documentation format for the language (JSDoc, docstrings, LuaDoc, etc.).
Do NOT include any explanations outside the code or markdown formatting.
Do NOT wrap the code in backticks or code blocks.
Return the raw code only, ready to replace the original.]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Add documentation to this " .. context.filetype .. " code:\n\n" .. code
          end,
        },
      },
    },

    ["Write Tests Inline"] = {
      interaction = "inline",
      description = "Generate tests (new file)",
      opts = {
        index = 14,
        is_slash_cmd = true,
        alias = "ti",
        auto_submit = true,
        ---@return number|nil
        pre_hook = function()
          -- Detect test directory and create appropriate test file
          local current_file = vim.fn.expand("%:t:r") -- filename without extension
          local current_ext = vim.fn.expand("%:e") -- extension
          local current_dir = vim.fn.expand("%:p:h") -- directory

          -- Common test directory patterns
          local test_dirs = { "tests", "test", "spec", "__tests__" }
          local project_root = vim.fn.getcwd()

          local test_dir = nil
          for _, dir in ipairs(test_dirs) do
            if vim.fn.isdirectory(project_root .. "/" .. dir) == 1 then
              test_dir = project_root .. "/" .. dir
              break
            end
          end

          -- Generate test filename based on language conventions
          local test_filename
          if current_ext == "lua" then
            test_filename = "test_" .. current_file .. ".lua"
          elseif current_ext == "py" then
            test_filename = "test_" .. current_file .. ".py"
          elseif current_ext == "ts" or current_ext == "tsx" then
            test_filename = current_file .. ".test.ts"
          elseif current_ext == "js" or current_ext == "jsx" then
            test_filename = current_file .. ".test.js"
          else
            test_filename = current_file .. "_test." .. current_ext
          end

          -- Create buffer with suggested path
          local test_path
          if test_dir then
            test_path = test_dir .. "/" .. test_filename
          else
            test_path = current_dir .. "/" .. test_filename
          end

          local bufnr = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_buf_set_name(bufnr, test_path)
          vim.api.nvim_set_current_buf(bufnr)
          vim.api.nvim_set_option_value("filetype", current_ext, { buf = bufnr })

          return bufnr
        end,
      },
      prompts = {
        {
          role = "system",
          content = [[You are an expert test writer. Generate comprehensive unit tests for the provided code.
Return ONLY the test code without any explanations or markdown formatting.
Do NOT wrap the code in backticks or code blocks.
Use the appropriate testing framework for the language:
- Lua: mini.test or busted
- Python: pytest
- JavaScript/TypeScript: Jest or Vitest
- Other: standard testing conventions

Include tests for:
- Happy path scenarios
- Edge cases
- Error handling]],
        },
        {
          role = "user",
          content = function(context)
            local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
            return "Write tests for this " .. context.filetype .. " code:\n\n" .. code
          end,
        },
      },
    },
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
      local agent = require("lazyvim-ai-assistant.agent")
      local cfg = get_config()
      local use_lmstudio = lmstudio.is_running()

      -- Initialize agent mode
      local main_config = require("lazyvim-ai-assistant").get_config()
      if main_config.agent then
        agent.setup(main_config.agent)
      end

      -- Create agent commands
      agent.create_commands()

      -- Notify which chat backend is active
      vim.defer_fn(function()
        local main_cfg = require("lazyvim-ai-assistant").get_config()
        local chat_cfg = main_cfg.chat or {}

        if chat_cfg.show_backend_notification ~= false then
          local auto_buffer = chat_cfg.auto_include_buffer ~= false
          local buffer_note = auto_buffer and " (with file context)" or ""

          if use_lmstudio then
            vim.notify("Chat: Using LM Studio" .. buffer_note, vim.log.levels.INFO)
          else
            vim.notify("Chat: Using Copilot (" .. cfg.copilot_chat_model .. ")" .. buffer_note, vim.log.levels.INFO)
          end
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
            -- Tool groups for agentic workflows
            tools = {
              groups = {
                ["full_stack"] = {
                  description = "Full development tools: file operations and command execution",
                  system_prompt = agent.get_system_prompt_for_mode(agent.MODES.BUILD),
                  tools = {
                    "cmd_runner",
                    "insert_edit_into_file",
                    "create_file",
                    "read_file",
                    "file_search",
                    "grep_search",
                  },
                },
                ["read_only"] = {
                  description = "Read-only tools for analysis and planning",
                  system_prompt = agent.get_system_prompt_for_mode(agent.MODES.PLAN),
                  tools = {
                    "read_file",
                    "file_search",
                    "grep_search",
                  },
                },
              },
              opts = {
                system_prompt = {
                  enabled = true,
                },
              },
            },
            keymaps = {
              -- Toggle mode with Tab in chat buffer
              toggle_mode = {
                modes = { n = "<Tab>" },
                callback = function()
                  agent.toggle_mode()
                end,
                description = "Toggle Plan/Build mode",
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
                layout = "vertical",
                opts = {
                  show_keymap_hints = true,
                  show_removed = true,
                },
              },
            },
          },
          chat = {
            -- Show mode in chat window
            window = {
              layout = "vertical",
              width = 0.4,
            },
          },
        },
        prompt_library = get_prompt_library(),
        adapters = {
          http = {
            lmstudio = function()
              return require("codecompanion.adapters").extend("openai_compatible", {
                name = "lmstudio",
                formatted_name = "LM Studio",
                env = {
                  url = cfg.lmstudio_url,
                  api_key = "lm-studio",
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

      -- Set up autocmd to update chat based on mode changes
      vim.api.nvim_create_autocmd("User", {
        pattern = "AIAgentModeChanged",
        callback = function(ev)
          local mode = ev.data and ev.data.mode
          if mode then
            -- Notify the chat about mode change
            -- This could be extended to modify the active chat's tool access
            vim.notify("AI mode changed to: " .. mode:upper(), vim.log.levels.DEBUG)
          end
        end,
      })
    end,
    keys = {
      -- Chat keymaps
      {
        "<leader>aa",
        function()
          local main = require("lazyvim-ai-assistant")
          local chat_cfg = main.get_config().chat or {}
          local auto_include = chat_cfg.auto_include_buffer ~= false
          local sync_mode = chat_cfg.buffer_sync_mode or "diff"

          local codecompanion = require("codecompanion")
          local last_chat = codecompanion.last_chat()

          if last_chat then
            vim.cmd("CodeCompanionChat Toggle")
          else
            if auto_include then
              vim.cmd("CodeCompanionChat #buffer{" .. sync_mode .. "}")
            else
              vim.cmd("CodeCompanionChat")
            end
          end
        end,
        mode = "n",
        desc = "Toggle CodeCompanion Chat",
      },
      { "<leader>aa", ":'<,'>CodeCompanionChat<cr>", mode = "v", desc = "Chat with selection" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", mode = "n", desc = "New chat (no file context)" },
      { "<leader>aA", ":'<,'>CodeCompanionChat Add<cr>", mode = "v", desc = "Add selection to chat" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = "n", desc = "Inline prompt" },
      { "<leader>ai", ":'<,'>CodeCompanion<cr>", mode = "v", desc = "Inline prompt with selection" },
      { "<leader>dD", "<cmd>CodeCompanionChat diff<cr>", mode = "n", desc = "Super Diff view" },

      -- Code Actions - Inline (show diff in source file)
      { "<leader>ao", ":'<,'>CodeCompanion /oi<cr>", mode = "v", desc = "Optimize (inline diff)" },
      { "<leader>af", ":'<,'>CodeCompanion /fi<cr>", mode = "v", desc = "Fix (inline diff)" },
      { "<leader>ad", ":'<,'>CodeCompanion /di<cr>", mode = "v", desc = "Document (inline diff)" },
      { "<leader>at", ":'<,'>CodeCompanion /ti<cr>", mode = "v", desc = "Write tests (new file)" },
      { "<leader>aR", ":'<,'>CodeCompanion /ri<cr>", mode = "v", desc = "Refactor (inline diff)" },

      -- Code Actions - Chat (opens discussion)
      { "<leader>aO", ":'<,'>CodeCompanion /optimize<cr>", mode = "v", desc = "Optimize (chat)" },
      { "<leader>aT", ":'<,'>CodeCompanion /test<cr>", mode = "v", desc = "Write tests (chat)" },

      -- Code Actions - Chat only (no inline version)
      { "<leader>ar", ":'<,'>CodeCompanion /review<cr>", mode = "v", desc = "Review code" },
      { "<leader>ae", ":'<,'>CodeCompanion /explain<cr>", mode = "v", desc = "Explain code" },
      { "<leader>aD", ":'<,'>CodeCompanion /debug<cr>", mode = "v", desc = "Debug code" },
      { "<leader>aD", "<cmd>CodeCompanion /debug<cr>", mode = "n", desc = "Debug (describe issue)" },

      -- Agent mode keymaps
      {
        "<leader>ab",
        function()
          require("lazyvim-ai-assistant.agent").set_mode("build")
        end,
        mode = "n",
        desc = "Switch to Build mode",
      },
      {
        "<leader>ap",
        function()
          require("lazyvim-ai-assistant.agent").set_mode("plan")
        end,
        mode = "n",
        desc = "Switch to Plan mode",
      },

      -- Help
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
