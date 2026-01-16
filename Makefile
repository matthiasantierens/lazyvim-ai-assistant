# Makefile for lazyvim-ai-assistant testing
# Uses mini.test framework from mini.nvim

.PHONY: deps test test_file lint clean help

# Default target
help:
	@echo "lazyvim-ai-assistant test runner"
	@echo ""
	@echo "Usage:"
	@echo "  make deps       - Download test dependencies (mini.nvim)"
	@echo "  make test       - Run all tests"
	@echo "  make test_file  - Run single test file (FILE=tests/test_agent.lua)"
	@echo "  make lint       - Run luacheck linter (if installed)"
	@echo "  make clean      - Remove test dependencies"
	@echo ""
	@echo "Examples:"
	@echo "  make deps && make test"
	@echo "  make test_file FILE=tests/test_agent.lua"

# Directory for dependencies
DEPS_DIR := deps
MINI_DIR := $(DEPS_DIR)/mini.nvim

# Download mini.nvim for testing
deps:
	@echo "Downloading test dependencies..."
	@mkdir -p $(DEPS_DIR)
	@if [ ! -d "$(MINI_DIR)" ]; then \
		echo "Cloning mini.nvim..."; \
		git clone --depth 1 https://github.com/echasnovski/mini.nvim $(MINI_DIR); \
	else \
		echo "mini.nvim already exists, updating..."; \
		cd $(MINI_DIR) && git pull; \
	fi
	@echo "Dependencies ready!"

# Run all tests
test: deps
	@echo "Running all tests..."
	nvim --headless -u scripts/minimal_init.lua \
		-c "lua MiniTest.run()" \
		-c "qa!"

# Run a specific test file
# Usage: make test_file FILE=tests/test_agent.lua
test_file: deps
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE not specified"; \
		echo "Usage: make test_file FILE=tests/test_agent.lua"; \
		exit 1; \
	fi
	@echo "Running tests in $(FILE)..."
	nvim --headless -u scripts/minimal_init.lua \
		-c "lua MiniTest.run_file('$(FILE)')" \
		-c "qa!"

# Run tests with verbose output
test_verbose: deps
	@echo "Running all tests (verbose)..."
	nvim --headless -u scripts/minimal_init.lua \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })" \
		-c "qa!"

# Run luacheck linter (optional - requires luacheck installed)
lint:
	@if command -v luacheck &> /dev/null; then \
		echo "Running luacheck..."; \
		luacheck lua/ tests/ --globals vim MiniTest; \
	else \
		echo "luacheck not installed. Install with: luarocks install luacheck"; \
	fi

# Clean up dependencies
clean:
	@echo "Removing test dependencies..."
	rm -rf $(DEPS_DIR)
	@echo "Clean complete!"

# Watch mode - rerun tests on file changes (requires entr)
watch: deps
	@if command -v entr &> /dev/null; then \
		echo "Watching for changes... (Ctrl+C to stop)"; \
		find lua tests -name "*.lua" | entr -c make test; \
	else \
		echo "entr not installed. Install with: brew install entr"; \
	fi
