# Claude Code Requirements-Driven Workflow System Makefile
# Quick deployment for Requirements workflow

.PHONY: help install deploy deploy-commands deploy-agents deploy-skill clean test version all

# Default target
help:
	@echo "Claude Code Requirements-Driven Workflow - Quick Deployment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install         - Install all configurations to Claude Code"
	@echo "  deploy          - Deploy Requirements workflow (commands + agents)"
	@echo "  deploy-commands - Deploy all slash commands"
	@echo "  deploy-agents   - Deploy all agent configurations"
	@echo "  deploy-skill    - Deploy Codex skill (skills/codex → ~/.claude/skills/)"
	@echo "  test            - Test Requirements workflow with sample"
	@echo "  clean           - Clean generated artifacts"
	@echo "  version         - Show version information"
	@echo "  help            - Show this help message"

# Configuration paths
CLAUDE_CONFIG_DIR = ~/.claude
COMMANDS_DIR = commands
AGENTS_DIR = agents
SKILLS_DIR = skills/codex
SPECS_DIR = .claude/specs

# Install all configurations
install: deploy
	@echo "📄 Syncing CLAUDE.md..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)
	@cp ./CLAUDE.md $(CLAUDE_CONFIG_DIR)/CLAUDE.md
	@$(MAKE) deploy-skill
	@echo "✅ Installation complete!"

# Deploy Requirements workflow
deploy:
	@echo "🚀 Deploying Requirements workflow..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)/commands
	@mkdir -p $(CLAUDE_CONFIG_DIR)/agents
	@cp $(COMMANDS_DIR)/*.md $(CLAUDE_CONFIG_DIR)/commands/
	@cp $(AGENTS_DIR)/*.md $(CLAUDE_CONFIG_DIR)/agents/
	@echo "✅ Requirements workflow deployed successfully!"
	@echo ""
	@echo "Available commands:"
	@echo "  /requirements-pilot - Requirements-driven development workflow"
	@echo "  /bugfix            - Bug fix workflow"
	@echo ""
	@echo "Quick Start:"
	@echo "  /requirements-pilot \"implement user authentication with JWT\""

# Deploy all commands
deploy-commands:
	@echo "📦 Deploying all slash commands..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)/commands
	@cp $(COMMANDS_DIR)/*.md $(CLAUDE_CONFIG_DIR)/commands/
	@echo "✅ All commands deployed!"
	@echo "   Available commands:"
	@echo "   - /requirements-pilot (Requirements-driven workflow)"
	@echo "   - /bugfix (Bug fix workflow)"

# Deploy all agents
deploy-agents:
	@echo "🤖 Deploying all agents..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)/agents
	@cp $(AGENTS_DIR)/*.md $(CLAUDE_CONFIG_DIR)/agents/
	@echo "✅ All agents deployed!"
	@echo "   Available agents:"
	@echo "   - requirements-generate"
	@echo "   - requirements-code"
	@echo "   - requirements-testing"
	@echo "   - requirements-review"
	@echo "   - bugfix"
	@echo "   - bugfix-verify"

# Deploy Codex skill
deploy-skill:
	@echo "🛠️ Deploying Codex skill..."
	@mkdir -p $(CLAUDE_CONFIG_DIR)/skills
	@rm -rf $(CLAUDE_CONFIG_DIR)/skills/codex
	@cp -r $(SKILLS_DIR) $(CLAUDE_CONFIG_DIR)/skills/
	@echo "✅ Codex skill deployed to ~/.claude/skills/codex"

# Test Requirements workflow
test:
	@echo "🧪 Testing Requirements workflow..."
	@echo "Run in Claude Code:"
	@echo '/requirements-pilot "Basic CRUD API for products"'

# Clean generated artifacts
clean:
	@echo "🧹 Cleaning artifacts..."
	@rm -rf $(SPECS_DIR)
	@echo "✅ Cleaned!"

# Quick deployment shortcuts
all: deploy

# Version info
version:
	@echo "Claude Code Requirements-Driven Workflow System v4.0"
	@echo "Requirements-Driven Development with Codex Integration"
