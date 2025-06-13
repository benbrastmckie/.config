# Scripts Directory

This directory contains utility scripts for maintaining and troubleshooting the Neovim configuration, particularly focused on plugin management and MCP (Model Context Protocol) integration.

## Available Scripts

### 📊 check_plugins.lua

**Purpose**: Analyzes and reports on the current plugin configuration, showing plugins organized by category.

**Usage**:
```bash
# Run from command line
nvim --headless -c "luafile scripts/check_plugins.lua" -c "qa!"

# Or from within Neovim
:luafile scripts/check_plugins.lua
```

**What it does**:
- Counts total loaded plugins
- Categorizes plugins by type (coding, editor, LSP, tools, UI, extras)
- Shows plugin loading structure and organization
- Useful for configuration auditing and plugin management

**When to use**:
- After making changes to plugin configuration
- To verify plugin loading and organization
- For debugging plugin-related issues
- When documenting your configuration

---

### 🔄 force_mcp_restart.lua

**Purpose**: Forces a complete restart of MCP Hub and Avante integration, ensuring proper tool connectivity.

**Usage**:
```vim
# From within Neovim
:luafile scripts/force_mcp_restart.lua

# Or use the command (available after avante_mcp.lua is loaded)
:MCPForceReload
```

**What it does**:
- Loads MCPHub plugin via lazy.nvim
- Loads Avante extension for MCP integration
- Reloads Avante configuration with fresh MCP tools
- Tests MCP Hub connectivity
- Reports available MCP tools and connection status

**When to use**:
- When MCP tools stop working in Avante
- After updating MCP server configurations
- When troubleshooting tool integration issues
- After Neovim restart if MCP integration seems broken

**Output example**:
```
🔄 Forcing MCP Hub and Avante restart...
📦 Loading MCPHub plugin...
🔌 Loading Avante extension...
✅ Avante extension loaded
⚙️  Reloading Avante configuration...
✅ Avante configuration reloaded with MCP tools
🛠️  Available MCP tools:
   1. context7_resolve
   2. context7_docs
   3. tavily_search
🌐 Testing MCP Hub connectivity...
✅ MCP Hub is responding
🎉 MCP integration restart complete!
```

---

### 🧪 test_mcp_integration.lua

**Purpose**: Comprehensive testing of MCP integration components to verify proper setup and functionality.

**Usage**:
```bash
# From command line
nvim --headless -c "luafile scripts/test_mcp_integration.lua" -c "qa!"

# Or from within Neovim
:luafile scripts/test_mcp_integration.lua
```

**What it does**:
- Tests MCPHub plugin loading
- Verifies hub instance availability
- Tests Avante extension loading
- Checks MCP tools function availability
- Validates Avante configuration
- Tests MCP server connectivity on port 37373

**When to use**:
- During initial setup to verify everything works
- When troubleshooting MCP integration issues
- After configuration changes
- To diagnose connection problems

**Output example**:
```
=== MCP Integration Test ===
✅ MCPHub plugin loaded successfully
✅ MCPHub instance available
✅ Avante extension loaded successfully
✅ Avante extension module available
✅ MCP tools function available
✅ Avante plugin loaded
✅ Avante config available
✅ Custom tools configured in Avante
✅ Custom tools function executed successfully

=== MCP Server Status ===
✅ MCP Hub responding on port 37373

=== Test Complete ===
```

---

### 🔧 test_mcp_tools.lua

**Purpose**: Directly tests individual MCP tools (Context7 and Tavily) to verify they're working correctly.

**Usage**:
```bash
# From command line
nvim --headless -c "luafile scripts/test_mcp_tools.lua" -c "qa!"

# Or from within Neovim
:luafile scripts/test_mcp_tools.lua
```

**What it does**:
- Tests Context7 library resolution (queries React documentation)
- Tests Tavily search functionality (searches for "react 2025 news")
- Provides real-time feedback on tool responses
- Validates actual tool functionality, not just configuration

**When to use**:
- To verify specific MCP tools are working
- When Context7 or Tavily seem unresponsive
- To test tool responses and formatting
- For debugging tool-specific issues

**Output example**:
```
🧪 Testing MCP tools integration...
✅ MCP Hub is available and initialized

📚 Testing Context7 (resolve React library)...
✅ Context7 working! Result:
{"libraryId": "react", "status": "resolved"}

🔍 Testing Tavily (search 'react 2025 news')...
✅ Tavily working! Result:
{"results": [...], "query": "react 2025 news"}

🎉 MCP tools test complete!
```

## Script Categories

### 🔍 Diagnostic Scripts
- `check_plugins.lua` - Plugin configuration analysis
- `test_mcp_integration.lua` - MCP integration testing
- `test_mcp_tools.lua` - Individual tool testing

### 🛠️ Maintenance Scripts  
- `force_mcp_restart.lua` - MCP integration restart and repair

## Integration with Main Configuration

These scripts are referenced and used by the main configuration:

### Commands Available in Neovim

The following commands are available after loading the AI configuration:

```vim
:MCPForceReload          " Uses force_mcp_restart.lua functionality
:MCPHubDiagnose         " Similar to test_mcp_integration.lua
:MCPTest                " Uses test_mcp_integration.lua
```

### Related Documentation

- **Main AI Documentation**: [`lua/neotex/plugins/ai/README.md`](../lua/neotex/plugins/ai/README.md) - Comprehensive AI integration guide
- **MCP Integration**: [`lua/neotex/plugins/ai/README.md#mcp-tool-integration`](../lua/neotex/plugins/ai/README.md#mcp-tool-integration) - Detailed MCP setup and usage
- **Troubleshooting**: [`lua/neotex/plugins/ai/README.md#troubleshooting`](../lua/neotex/plugins/ai/README.md#troubleshooting) - Common issues and solutions

### Usage in Configuration Files

These scripts are used by:
- `lua/neotex/plugins/ai/util/avante_mcp.lua` - Uses force_mcp_restart.lua logic
- `lua/neotex/plugins/ai/mcp-hub.lua` - MCP integration setup
- Various troubleshooting commands and functions

## Best Practices

1. **Run diagnostic scripts first** when troubleshooting issues
2. **Use force_mcp_restart.lua** as the primary fix for MCP integration problems
3. **Test individual tools** with test_mcp_tools.lua when specific tools aren't working
4. **Check plugin organization** with check_plugins.lua after configuration changes

## When Scripts Fail

If scripts report errors:

1. **Check Prerequisites**:
   - MCPHub plugin is installed (`lua/neotex/plugins/ai/mcp-hub.lua`)
   - Avante is properly configured (`lua/neotex/plugins/ai/avante.lua`)
   - MCP servers are configured in `~/.config/mcphub/servers.json`

2. **Try in Order**:
   - Run `test_mcp_integration.lua` to identify the problem
   - Use `force_mcp_restart.lua` to attempt repair
   - Test specific tools with `test_mcp_tools.lua`
   - Check overall plugin health with `check_plugins.lua`

3. **Check Log Files**:
   - Neovim messages: `:messages`
   - MCPHub logs: May be in `/tmp/mcp-hub.log` or similar
   - Debug mode: Use `:MCPDebugToggle` for verbose logging

## Script Development

When adding new scripts to this directory:

1. **Follow naming convention**: `action_target.lua` (e.g., `test_mcp_tools.lua`)
2. **Add documentation** to this README
3. **Include usage examples** and expected output
4. **Reference from main configuration** when appropriate
5. **Use consistent error handling** and user feedback