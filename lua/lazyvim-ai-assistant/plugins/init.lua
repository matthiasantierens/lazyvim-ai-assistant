-- Plugin aggregator for lazyvim-ai-assistant
-- Import this to get all plugin configurations
-- v2.0.0: Added history plugin for session persistence

return {
  { import = "lazyvim-ai-assistant.plugins.autocomplete" },
  { import = "lazyvim-ai-assistant.plugins.chat" },
  { import = "lazyvim-ai-assistant.plugins.blink" },
  { import = "lazyvim-ai-assistant.plugins.lualine" },
  { import = "lazyvim-ai-assistant.plugins.history" }, -- v2.0.0: Session persistence
}
