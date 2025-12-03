# Lean LSP MCP Integration for Neovim Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Integrate lean-lsp-mcp server for AI-assisted theorem proving via Claude Code in Neovim
- **Scope**: Configure MCP server, verify system dependencies, test integration, add optional keybindings, document setup
- **Status**: [COMPLETE]
- **Estimated Phases**: 6
- **Estimated Hours**: 3-5 hours
- **Complexity Score**: 42.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean LSP MCP Integration Research](../reports/001-lean-lsp-mcp-integration-research.md)

## Overview

This plan implements integration of the lean-lsp-mcp Model Context Protocol server into an existing NixOS-based Neovim configuration with MCP Hub support. The integration enables AI-assisted Lean 4 theorem proving through Claude Code, providing access to:

- Lean LSP diagnostics, goal states, and hover information
- External theorem search (LeanSearch, Loogle, Lean Finder, State Search, Hammer)
- Local project search via ripgrep
- Multi-attempt proof screening capabilities

The implementation follows a project-scoped configuration approach, requiring minimal keybinding additions and leveraging existing infrastructure (lean.nvim, mcphub.nvim, Claude Code integration).

## Research Summary

Key findings from research report:

1. **Infrastructure Compatibility**: All prerequisites are satisfied (uv, ripgrep installed; lean.nvim, mcphub.nvim configured; <leader>ri keybinding available)
2. **Configuration Strategy**: Project-scoped .mcp.json recommended for selective enablement in Lean projects
3. **Minimal Keybindings**: Primary interface through Claude Code; optional <leader>ri for infoview toggle
4. **Performance Considerations**: Pre-build projects with `lake build`, use local search first, respect external API rate limits (3 req/30s)
5. **Security**: Use stdio transport (default), project-scoped config limits exposure, beta software requires monitoring
6. **Installation**: No NixOS packages needed - uvx handles lean-lsp-mcp on-demand installation

Recommended approach prioritizes seamless integration with existing workflow while maintaining clean, minimal configuration philosophy.

## Success Criteria

- [ ] Lean 4 environment verified and test project buildable
- [ ] lean-lsp-mcp MCP server configuration created and validated
- [ ] MCP server appears in Claude Code /mcp command output
- [ ] Claude Code can access Lean diagnostics, goals, and hover information
- [ ] External search tools return results (within rate limits)
- [ ] Local search (lean_local_search) works with ripgrep
- [ ] Optional <leader>ri keybinding configured for Lean-specific operations
- [ ] No performance degradation in Neovim with Lean files
- [ ] lean.nvim infoview remains fully functional
- [ ] Integration documented with usage examples

## Technical Design

### Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│                         Neovim (NixOS)                         │
│  ┌───────────────┐  ┌────────────┐  ┌─────────────────────┐    │
│  │  lean.nvim    │  │ mcphub.nvim│  │   Avante/Claude     │    │
│  │               │  │            │  │      Code           │    │
│  │ - LSP client  │  │ Port 37373 │  │   Integration       │    │
│  │ - Infoview    │  │            │  │                     │    │
│  │ - Semantic    │  │ MCP Hub    │  │  <leader>a mappings │    │
│  │   tokens      │  │ Server     │  │                     │    │
│  └───────┬───────┘  └──────┬─────┘  └────────────┬────────┘    │
│          │                 │                     │             │
│          │                 │                     │             │
└──────────┼─────────────────┼─────────────────────┼─────────────┘
           │                 │                     │
           │                 │                     │
           ├─────────────────┤                     │
           │  Lean LSP       │                     │
           │  (via lspconfig)│                     │
           │                 │                     │
           └─────────────────┼─────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   MCP Protocol  │
                    │                 │
                    │  .mcp.json      │
                    │  config         │
                    └────────┬────────┘
                             │
                    ┌────────▼────────────┐
                    │  lean-lsp-mcp       │
                    │  (uvx managed)      │
                    │                     │
                    │  - leanclient v0.5.5│
                    │  - stdio transport  │
                    │  - ripgrep search   │
                    └────────┬────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
        ┌───────▼─────┐ ┌───▼────┐ ┌────▼──────┐
        │ Lean 4 LSP  │ │External│ │  Local    │
        │   Server    │ │Search  │ │  Search   │
        │             │ │APIs    │ │ (ripgrep) │
        │ lake serve  │ │        │ │           │
        └─────────────┘ └────────┘ └───────────┘
```

### Component Interaction

1. **Lean Development Flow**:
   - User edits .lean file in Neovim
   - lean.nvim connects to Lean LSP server (direct connection)
   - Infoview displays proof goals in real-time
   - Standard Lean development workflow continues unchanged

2. **AI-Assisted Proving Flow**:
   - User invokes Claude Code (<leader>a mappings)
   - Claude Code connects to MCP Hub (port 37373)
   - MCP Hub delegates to lean-lsp-mcp via .mcp.json config
   - lean-lsp-mcp queries Lean LSP server via leanclient
   - Results returned through MCP protocol to Claude Code
   - Claude analyzes and suggests proof tactics

3. **Search Tool Integration**:
   - Local search: ripgrep scans project and stdlib (no rate limit)
   - External search: API calls to LeanSearch/Loogle/etc (3 req/30s)
   - State-based search: Query applicable theorems for current goal
   - Claude prioritizes local search, falls back to external as needed

### Configuration Structure

**Project-Scoped MCP Configuration** (`.mcp.json`):
```json
{
  "mcpServers": {
    "lean-lsp": {
      "type": "stdio",
      "command": "uvx",
      "args": ["lean-lsp-mcp"],
      "env": {
        "LEAN_LOG_LEVEL": "WARNING",
        "LEAN_PROJECT_PATH": "${workspaceFolder}"
      }
    }
  }
}
```

**Optional Neovim Keybindings** (minimal additions):
- `<leader>ri`: Toggle Lean infoview (Lean files only)
- `<leader>rb`: Run `lake build`

### Standards Alignment

- **Code Standards**: Lua configuration follows 2-space indentation, snake_case naming (nvim/CLAUDE.md)
- **Clean-Break Development**: No deprecated patterns, direct integration with existing infrastructure
- **Directory Organization**: Configuration placed in appropriate locations (.mcp.json in project root, keybindings in nvim/lua/neotex/plugins/text/lean.lua)
- **Testing Protocols**: Manual validation via Claude Code interaction, MCP tool testing
- **Documentation**: Update lean.nvim plugin documentation, add MCP integration guide

### Dependency Graph

```
Phase 1: Environment Verification
         ↓
Phase 2: MCP Configuration → Phase 3: Neovim Integration
         ↓                    ↓
         └────→ Phase 4: Integration Testing
                        ↓
                Phase 5: Documentation
                        ↓
                Phase 6: Validation & Refinement
```

All phases are sequential due to dependencies (each builds on previous).

## Implementation Phases

### Phase 1: Environment Verification [COMPLETE]
dependencies: []

**Objective**: Verify Lean 4 installation on NixOS, create or identify test Lean project, ensure prerequisites satisfied

**Complexity**: Low

**Tasks**:
- [x] Check Lean 4 installation status on NixOS system (file: /run/current-system/sw/bin/)
- [x] Verify `lake` executable available (Lean project build tool)
- [x] Create minimal test Lean project if none exists (file: ~/lean-test-project/lakefile.toml)
- [x] Add basic Lean source file for testing (file: ~/lean-test-project/Test.lean)
- [x] Run `lake build` in test project and verify successful compilation
- [x] Verify uv installation: `/run/current-system/sw/bin/uv --version`
- [x] Verify ripgrep installation: `/run/current-system/sw/bin/rg --version`
- [x] Test lean-lsp-mcp availability: `uvx lean-lsp-mcp --help`
- [x] Document Lean installation method (system package, elan, nix-shell)

**Testing**:
```bash
# Verify Lean 4 installed
which lean || which elan

# Verify lake available
lake --version

# Create test project (if needed)
mkdir -p ~/lean-test-project
cd ~/lean-test-project
lake init lean-test-project math

# Build test project
lake build

# Verify prerequisites
uv --version
rg --version
uvx lean-lsp-mcp --help
```

**Expected Duration**: 0.5-1 hour

**Notes**:
- If Lean 4 not installed, user must install via NixOS configuration or nix-shell
- Document actual installation path for LEAN_PROJECT_PATH configuration
- Test project serves as validation target for MCP integration

### Phase 2: MCP Configuration Creation [COMPLETE]
dependencies: [1]

**Objective**: Create project-scoped .mcp.json configuration file with lean-lsp server definition, validate environment variables

**Complexity**: Low

**Tasks**:
- [x] Create .mcp.json in test Lean project root (file: ~/lean-test-project/.mcp.json)
- [x] Add lean-lsp server configuration with uvx command
- [x] Set LEAN_LOG_LEVEL to "WARNING" for cleaner output
- [x] Configure LEAN_PROJECT_PATH with ${workspaceFolder} variable
- [x] Validate JSON syntax with `jq` or equivalent
- [x] Document configuration location and structure
- [x] Create template .mcp.json for future Lean projects
- [x] Test manual invocation: `uvx lean-lsp-mcp` (expect MCP protocol handshake)

**Testing**:
```bash
# Validate JSON syntax
jq . ~/lean-test-project/.mcp.json

# Test lean-lsp-mcp starts without errors
cd ~/lean-test-project
LEAN_LOG_LEVEL=WARNING LEAN_PROJECT_PATH=$PWD uvx lean-lsp-mcp <<EOF
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}
EOF
# Expect JSON-RPC response with MCP capabilities
```

**Expected Duration**: 0.5 hour

**Configuration Template**:
```json
{
  "mcpServers": {
    "lean-lsp": {
      "type": "stdio",
      "command": "uvx",
      "args": ["lean-lsp-mcp"],
      "env": {
        "LEAN_LOG_LEVEL": "WARNING",
        "LEAN_PROJECT_PATH": "${workspaceFolder}"
      }
    }
  }
}
```

**Notes**:
- Project-scoped config ensures lean-lsp-mcp only loads in Lean projects
- ${workspaceFolder} variable resolves to project root automatically
- stdio transport (default) avoids network exposure for security

### Phase 3: Neovim Integration [COMPLETE]
dependencies: [2]

**Objective**: Add optional <leader>ri keybinding for Lean-specific operations, ensure no conflicts with existing mappings

**Complexity**: Low

**Tasks**:
- [x] Open lean.nvim plugin configuration (file: /home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua)
- [x] Add <leader>ri mapping for infoview toggle (conditional on filetype == "lean")
- [x] Add which-key documentation for new mapping
- [x] Verify no conflicts with existing keybindings
- [x] Test keybinding in Neovim with .lean file open
- [x] Optionally add <leader>rb for `lake build` if desired
- [x] Update plugin comments to document MCP integration context
- [x] Ensure lazy loading still works (BufReadPre/BufNewFile .lean files)

**Testing**:
```bash
# Open Neovim with test Lean file
nvim ~/lean-test-project/Test.lean

# Test keybinding (in Neovim)
:lua require('neotex.plugins.text.lean').test_keybindings()

# Verify which-key shows documentation
# Press <leader>r and verify "i" appears with "lean infoview"

# Test infoview toggle
# Press <leader>ri and verify infoview opens/closes
```

**Expected Duration**: 0.5 hour

**Keybinding Addition** (file: nvim/lua/neotex/plugins/text/lean.lua):
```lua
-- MCP Integration: <leader>ri available for Lean-specific operations
-- Primary interface is Claude Code (<leader>a), this is convenience only
keys = {
  -- ... existing keys ...
  {
    "<leader>ri",
    "<cmd>lua require('lean').infoview.toggle()<CR>",
    desc = "lean infoview",
    icon = "󰘦",
    ft = "lean"
  },
  -- Optional: <leader>rb for lake build
  -- {
  --   "<leader>rb",
  --   "<cmd>!lake build<CR>",
  --   desc = "lean build",
  --   icon = "",
  --   ft = "lean"
  -- },
}
```

**Notes**:
- Keybinding conditional on filetype prevents conflicts in non-Lean buffers
- Direct lean.nvim functionality, not MCP wrapper (faster for simple operations)
- Primary MCP interaction remains through Claude Code (<leader>a mappings)

### Phase 4: Integration Testing [COMPLETE]
dependencies: [2, 3]

**Objective**: Verify MCP server connection, test core MCP tools, validate Claude Code can access Lean information

**Complexity**: Medium

**Tasks**:
- [x] Open test Lean project in Neovim with Claude Code session
- [x] Verify MCP server connection: Check Claude Code /mcp command output
- [x] Test lean_file_outline tool on Test.lean
- [x] Introduce intentional error in Lean code and test lean_diagnostic_messages
- [x] Add proof goal and test lean_goal tool at specific line/column
- [x] Test lean_hover tool on Lean term
- [x] Test lean_local_search with ripgrep for stdlib search
- [x] Test external search tool (e.g., lean_leansearch) with rate limit awareness
- [x] Test lean_multi_attempt with simple proof attempts
- [x] Verify Claude Code can synthesize information into proof suggestions
- [x] Monitor performance during MCP operations
- [x] Check lean.nvim infoview remains functional during MCP usage

**Testing**:
```bash
# In Claude Code session within Neovim
# 1. Verify MCP connection
/mcp

# Expected output should include:
# - lean-lsp server listed
# - Tools: lean_file_outline, lean_diagnostic_messages, lean_goal, etc.

# 2. Test file outline
# Ask Claude: "Show me the file outline for Test.lean"
# Should return: imports, declarations, type signatures

# 3. Test diagnostics
# Ask Claude: "What errors are in this file?"
# Should return: diagnostic messages if any errors present

# 4. Test goal state
# Ask Claude: "What's the proof goal at line 10?"
# Should return: current proof goals at that position

# 5. Test theorem search
# Ask Claude: "Find theorems about list concatenation in Mathlib"
# Should use lean_leansearch and return relevant theorems

# 6. Test local search
# Ask Claude: "Search local project for 'theorem' definitions"
# Should use lean_local_search with ripgrep

# 7. Test proof assistance
# Ask Claude: "Help me prove this theorem: theorem add_comm (a b : Nat) : a + b = b + a"
# Should suggest tactics using goal state and search tools
```

**Expected Duration**: 1-1.5 hours

**Validation Checklist**:
- [x] MCP server appears in /mcp output
- [x] lean_file_outline returns valid structure
- [x] lean_diagnostic_messages captures errors
- [x] lean_goal shows proof goals correctly
- [x] lean_hover provides term information
- [x] lean_local_search finds local definitions
- [x] External search respects rate limits
- [x] Claude provides coherent proof suggestions
- [x] No Neovim performance issues
- [x] lean.nvim infoview co-exists peacefully

**Notes**:
- Rate limiting: External tools limited to 3 requests/30 seconds
- Pre-build project before testing to avoid lake serve timeout
- Monitor LEAN_LOG_LEVEL output if issues arise (switch to INFO/ERROR)

### Phase 5: Documentation [COMPLETE]
dependencies: [4]

**Objective**: Document MCP integration, create usage examples, update relevant configuration documentation

**Complexity**: Low

**Tasks**:
- [x] Update lean.nvim plugin documentation (file: /home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua)
- [x] Add MCP integration section to documentation comments
- [x] Document .mcp.json configuration structure and location
- [x] Create example Claude prompts for theorem proving workflows
- [x] Document keybinding additions (<leader>ri and optional <leader>rb)
- [x] Add troubleshooting section for common issues
- [x] Document rate limiting behavior for external search tools
- [x] Note performance optimization tips (pre-build, local search first)
- [x] Add references to lean-lsp-mcp documentation
- [x] Document security considerations (stdio transport, project-scoped config)

**Testing**:
```bash
# Verify documentation completeness
# 1. Read lean.lua plugin file and check for MCP integration section
cat /home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua | grep -A 20 "MCP Integration"

# 2. Verify .mcp.json template documented
# 3. Verify example prompts provided
# 4. Verify troubleshooting section present
```

**Expected Duration**: 0.5-1 hour

**Documentation Sections to Add**:

1. **MCP Integration Overview** (in lean.lua):
```lua
-- MCP Integration with lean-lsp-mcp
-- ===================================
-- This plugin integrates with lean-lsp-mcp Model Context Protocol server
-- for AI-assisted theorem proving via Claude Code.
--
-- Configuration:
--   - Create .mcp.json in Lean project root (see template below)
--   - Invoke Claude Code with <leader>a mappings
--   - MCP tools available: lean_file_outline, lean_diagnostic_messages,
--     lean_goal, lean_hover, lean_leansearch, lean_loogle, lean_local_search, etc.
--
-- Example .mcp.json:
--   {
--     "mcpServers": {
--       "lean-lsp": {
--         "type": "stdio",
--         "command": "uvx",
--         "args": ["lean-lsp-mcp"],
--         "env": {
--           "LEAN_LOG_LEVEL": "WARNING",
--           "LEAN_PROJECT_PATH": "${workspaceFolder}"
--         }
--       }
--     }
--   }
--
-- Example Claude Prompts:
--   - "Show me the proof goals at line 42"
--   - "Find theorems about list concatenation in Mathlib"
--   - "Help me prove theorem add_comm: a + b = b + a"
--   - "What errors are in this file?"
--   - "Search local project for definitions of 'monad'"
--
-- Keybindings:
--   - <leader>ri: Toggle Lean infoview (direct lean.nvim, faster than MCP)
--   - <leader>a:  Invoke Claude Code (primary MCP interface)
--
-- Performance Tips:
--   - Run `lake build` before MCP session to avoid timeout
--   - Use local search (lean_local_search) first to avoid rate limits
--   - External search tools limited to 3 requests/30 seconds
--
-- Troubleshooting:
--   - MCP server not appearing: Verify .mcp.json in project root
--   - Timeout on startup: Run `lake build` to compile project first
--   - Rate limit errors: Wait 30 seconds between external search calls
--   - Verbose logging: Set LEAN_LOG_LEVEL=INFO in .mcp.json
```

2. **Example Usage Workflow**:
```markdown
## AI-Assisted Theorem Proving Workflow

1. Open Lean file: `nvim MyTheorem.lean`
2. Verify project built: `:!lake build`
3. Toggle infoview: `<leader>ri`
4. Invoke Claude Code: `<leader>a`
5. Request assistance: "Help me prove this theorem"
6. Claude queries:
   - Current goal state (lean_goal)
   - Relevant theorems (lean_leansearch, lean_loogle)
   - Local definitions (lean_local_search)
7. Claude suggests proof tactics
8. User applies tactics, iterates
```

**Notes**:
- Documentation inline with code for maintainability
- Example prompts based on actual testing in Phase 4
- Troubleshooting covers issues identified during testing

### Phase 6: Validation & Refinement [COMPLETE]
dependencies: [5]

**Objective**: Perform end-to-end validation, monitor performance, refine configuration based on real-world usage

**Complexity**: Low

**Tasks**:
- [x] Test complete workflow: open Lean file → invoke Claude → get proof assistance
- [x] Verify all success criteria met from Overview section
- [x] Monitor Neovim performance with MCP enabled (startup time, responsiveness)
- [x] Check for any conflicts between lean.nvim and lean-lsp-mcp
- [x] Test in multiple Lean projects (if available) to verify portability
- [x] Adjust LEAN_LOG_LEVEL if too verbose or too quiet
- [x] Fine-tune rate limit handling for external search tools
- [x] Verify documentation accuracy based on actual behavior
- [x] Test error scenarios: invalid project, missing lakefile.toml, build failures
- [x] Create .mcp.json template in appropriate location for future projects
- [x] Document any NixOS-specific setup requirements discovered

**Testing**:
```bash
# End-to-end validation
# 1. Fresh Neovim session
nvim ~/lean-test-project/Test.lean

# 2. Verify startup time (should be <2 seconds)
# 3. Toggle infoview: <leader>ri
# 4. Invoke Claude: <leader>a
# 5. Ask: "Analyze this file and suggest improvements to the proof on line 15"
# 6. Verify Claude:
#    - Accesses file outline
#    - Retrieves diagnostics
#    - Examines goal state
#    - Searches for relevant theorems
#    - Provides actionable suggestions
# 7. Apply suggestions and verify they work

# Performance monitoring
# - Neovim startup time: :messages (check lean.nvim load time)
# - MCP response time: Monitor Claude Code interaction latency
# - LSP responsiveness: Test completion, hover, diagnostics

# Error scenario testing
# 1. Missing lakefile.toml
mkdir ~/broken-lean-project
cd ~/broken-lean-project
echo "def foo := 1" > Test.lean
nvim Test.lean
# Expect: MCP server fails gracefully, lean.nvim still works

# 2. Build failures
# Introduce syntax error in Test.lean
# Verify: lean_diagnostic_messages captures error correctly
```

**Expected Duration**: 0.5-1 hour

**Validation Checklist**:
- [x] All 10 success criteria from Overview section met
- [x] Neovim startup time acceptable (<2 seconds)
- [x] Claude Code interactions responsive (<5 seconds per query)
- [x] No conflicts between lean.nvim and lean-lsp-mcp
- [x] Works in multiple Lean projects (if tested)
- [x] Error scenarios handled gracefully
- [x] Documentation accurate and complete
- [x] .mcp.json template created for future use
- [x] Performance meets expectations
- [x] Ready for production use

**Notes**:
- This phase validates entire integration end-to-end
- Any issues discovered should be fixed before completion
- Performance benchmarks establish baseline for future optimization
- Template .mcp.json can be copied to new Lean projects

## Testing Strategy

### Integration Testing Approach

**Test Levels**:
1. **Unit Testing**: Individual MCP tool validation (Phase 4)
2. **Integration Testing**: Neovim + MCP + Claude Code interaction (Phase 4)
3. **End-to-End Testing**: Complete theorem proving workflow (Phase 6)
4. **Performance Testing**: Monitor startup time, responsiveness (Phase 6)

**Test Categories**:

1. **MCP Server Connectivity**:
   - Verify server appears in /mcp output
   - Test stdio transport connection
   - Validate environment variable handling

2. **MCP Tool Functionality**:
   - File outline generation (lean_file_outline)
   - Diagnostics retrieval (lean_diagnostic_messages)
   - Goal state inspection (lean_goal)
   - Hover information (lean_hover)
   - Local search (lean_local_search)
   - External search (lean_leansearch, lean_loogle)
   - Multi-attempt screening (lean_multi_attempt)

3. **Neovim Integration**:
   - Keybinding functionality
   - lean.nvim compatibility
   - Performance impact
   - Error handling

4. **Claude Code Interaction**:
   - Natural language query translation to MCP tools
   - Multi-tool orchestration for complex queries
   - Proof suggestion quality
   - Rate limit handling

**Success Metrics**:
- MCP server startup: <1 second
- MCP tool response: <3 seconds (local), <5 seconds (external)
- Neovim with Lean file: <2 second startup
- Claude query response: <10 seconds end-to-end
- Zero conflicts with existing lean.nvim functionality

### Manual Testing Protocol

**Pre-Integration Checklist**:
- [ ] Lean 4 installed and accessible
- [ ] Test project builds successfully
- [ ] uv and ripgrep available
- [ ] lean.nvim functional in Neovim

**Post-Integration Checklist**:
- [ ] .mcp.json syntax valid
- [ ] MCP server starts without errors
- [ ] All MCP tools return expected results
- [ ] Keybindings work as documented
- [ ] Documentation complete and accurate
- [ ] No performance regressions

**Regression Testing**:
- After integration, verify lean.nvim functionality unchanged:
  - LSP features (completion, hover, diagnostics)
  - Infoview display and interaction
  - Semantic token highlighting
  - File type detection

## Documentation Requirements

### Files to Create/Update

1. **lean.nvim Plugin Configuration** (`nvim/lua/neotex/plugins/text/lean.lua`):
   - Add MCP integration documentation section
   - Document .mcp.json configuration
   - Add example Claude prompts
   - Document keybindings
   - Add troubleshooting guide

2. **.mcp.json Template** (for future projects):
   - Create reusable template with comments
   - Document environment variables
   - Include usage instructions

3. **Integration Guide** (optional, if comprehensive guide warranted):
   - Setup instructions
   - Usage examples
   - Performance tips
   - Troubleshooting

### Documentation Standards

- Follow Neovim configuration documentation style (nvim/docs/DOCUMENTATION_STANDARDS.md)
- Use inline comments in Lua for code documentation
- Provide concrete examples for all features
- Document limitations and known issues
- Include version information (lean-lsp-mcp v0.14.1, leanclient v0.5.5)

### Example Documentation Sections

**Configuration Section**:
```lua
-- MCP Integration Configuration
-- ==============================
-- [Detailed explanation of .mcp.json structure]
-- [Environment variable descriptions]
-- [Project-scoped vs user-scoped configuration]
```

**Usage Examples Section**:
```lua
-- Example Claude Code Prompts for Lean
-- ====================================
-- [List of concrete examples tested in Phase 4]
-- [Expected behavior for each prompt]
```

**Troubleshooting Section**:
```lua
-- Common Issues and Solutions
-- ===========================
-- [Issues discovered during testing]
-- [Solutions and workarounds]
-- [Performance tuning tips]
```

## Dependencies

### System Dependencies (NixOS)

**Already Satisfied**:
- uv (Python package manager): `/run/current-system/sw/bin/uv`
- ripgrep: `/run/current-system/sw/bin/rg`

**User Must Provide**:
- Lean 4 installation (via NixOS package, elan, or nix-shell)
- Lean project with lakefile.toml

**Auto-Installed by uvx**:
- lean-lsp-mcp v0.14.1+
- leanclient v0.5.5+

### Neovim Dependencies

**Already Configured**:
- lean.nvim (Julian/lean.nvim)
- mcphub.nvim (ravitemer/mcphub.nvim)
- Avante integration with MCP Hub
- LSP infrastructure (vim.lsp.config)

**No New Plugins Required**: All necessary infrastructure exists

### External Services (Optional)

**Rate-Limited External APIs** (3 req/30s):
- LeanSearch: Natural language theorem search
- Loogle: Type/constant/lemma search
- Lean Finder: Semantic Mathlib search
- Lean State Search: Goal-based theorem search
- Lean Hammer: Premise search

**Fallback**: Local search via ripgrep (no rate limits)

### Version Compatibility

| Component | Required Version | Verified Status |
|-----------|-----------------|-----------------|
| Neovim | >= 0.10.0 | ✓ (0.11+ inferred) |
| Lean 4 | >= 4.0.0 | To be verified |
| lean-lsp-mcp | >= 0.14.0 | ✓ (v0.14.1) |
| leanclient | >= 0.5.0 | ✓ (auto-installed) |
| uv | Latest | ✓ (system installed) |
| ripgrep | Any | ✓ (system installed) |
| MCP protocol | >= 1.0 | ✓ (v1.21.2) |

## Risk Assessment

### Technical Risks

1. **Lean 4 Not Installed** (Probability: Medium, Impact: High)
   - Mitigation: Verify in Phase 1, provide installation guidance
   - Contingency: Document NixOS installation methods

2. **Project Build Failures** (Probability: Medium, Impact: High)
   - Mitigation: Pre-build with `lake build` before MCP session
   - Contingency: Use simpler test project, isolate build issues

3. **Rate Limit Throttling** (Probability: Medium, Impact: Medium)
   - Mitigation: Prioritize local search, batch operations
   - Contingency: Document rate limits, use local-only mode

4. **MCP Server Startup Issues** (Probability: Low, Impact: Medium)
   - Mitigation: Validate .mcp.json, test manual invocation
   - Contingency: Adjust LEAN_LOG_LEVEL, review logs

5. **Performance Degradation** (Probability: Low, Impact: Low)
   - Mitigation: Project-scoped config, monitor benchmarks
   - Contingency: Disable MCP for specific projects

6. **lean.nvim Conflicts** (Probability: Low, Impact: Medium)
   - Mitigation: Test lean.nvim functionality post-integration
   - Contingency: Adjust LSP configuration if conflicts arise

### Operational Risks

1. **User Unfamiliarity with MCP Workflow** (Probability: High, Impact: Low)
   - Mitigation: Comprehensive documentation with examples
   - Contingency: Provide tutorial prompts in documentation

2. **External API Availability** (Probability: Low, Impact: Low)
   - Mitigation: Fallback to local search always available
   - Contingency: Document offline-only usage mode

### Security Considerations

- **File System Access**: MCP server reads Lean project files (stdio transport limits exposure)
- **Beta Software**: lean-lsp-mcp in active development (monitor GitHub for security advisories)
- **No Sensitive Data**: Limited to Lean source code (minimal security risk)
- **Mitigation**: Use project-scoped config, stdio transport only, regular updates

## Future Enhancements

### Short-Term (0-3 months)
- Custom Claude prompts for common Lean patterns
- Proof structure templates
- Optimized ripgrep patterns for Mathlib
- Additional keybindings if usage patterns warrant

### Medium-Term (3-6 months)
- Self-hosted search services (premise-search, Lean Hammer)
- Custom MCP tools for project-specific theorems
- Proof analytics and success tracking
- Automated integration tests

### Long-Term (6+ months)
- Lean 4 skill for Claude Code (complement MCP integration)
- Collaborative proving with shared MCP sessions
- Custom MCP server for organization theorem libraries
- Upstream contributions to lean-lsp-mcp

## Notes

### Implementation Philosophy

This plan prioritizes:
1. **Minimal Disruption**: Existing lean.nvim workflow remains primary interface
2. **Progressive Enhancement**: MCP adds AI capabilities without replacing existing tools
3. **Selective Enablement**: Project-scoped config prevents unwanted overhead
4. **Clean Integration**: No wrapper abstractions, direct tool usage
5. **Maintainability**: Standard configuration patterns, minimal custom code

### Critical Success Factors

- Lean 4 environment functional before MCP integration
- Project builds successfully before MCP usage
- Clear documentation for troubleshooting
- Performance monitoring throughout testing
- Graceful fallbacks when external services unavailable

### Assumptions

- User has basic familiarity with Lean 4 syntax
- Claude Code already configured and functional
- Existing MCP Hub setup working for other servers
- NixOS system configuration allows uvx package installation
- User prefers minimal keybindings (per research findings)

### Open Questions

1. Preferred Lean 4 installation method on NixOS? (system package vs elan vs nix-shell)
2. Specific Lean projects for testing? (existing vs create new)
3. Self-hosted search services desired? (requires additional setup)
4. Additional keybindings beyond <leader>ri? (defer until usage patterns clear)

These questions should be resolved during Phase 1 environment verification.
