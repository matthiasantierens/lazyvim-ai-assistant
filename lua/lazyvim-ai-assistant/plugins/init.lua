-- Plugin aggregator for lazyvim-ai-assistant
-- Import this to get all plugin configurations

return {
  { import = "lazyvim-ai-assistant.plugins.autocomplete" },
  { import = "lazyvim-ai-assistant.plugins.chat" },
  { import = "lazyvim-ai-assistant.plugins.blink" },
  { import = "lazyvim-ai-assistant.plugins.lualine" },
}
