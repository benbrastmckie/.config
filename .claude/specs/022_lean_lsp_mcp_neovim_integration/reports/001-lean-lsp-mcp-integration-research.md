# Lean LSP MCP Integration Research Report

## Executive Summary

This report documents comprehensive research on integrating lean-lsp-mcp (a Model Context Protocol server for Lean theorem proving) into a NixOS-based Neovim setup with existing MCP Hub infrastructure. The integration will enable AI-assisted theorem proving through Claude Code via MCP tools while maintaining minimal keybinding overhead.

## Research Findings

### 1. Project Overview: lean-lsp-mcp

**Repository**: https://github.com/oOo0oOo/lean-lsp-mcp
**Latest Version**: v0.14.1 (Released: 2025-11-20)
**License**: MIT
**Primary Dependency**: leanclient v0.5.5

lean-lsp-mcp is an MCP server that provides agentic interaction with the Lean theorem prover via the Language Server Protocol. It exposes Lean's powerful theorem proving capabilities to AI assistants through a standardized MCP interface.

#### Key Features

1. **Rich LSP Integration**
   - File outline generation (imports, declarations, type signatures)
   - Diagnostic messages (errors, warnings, infos)
   - Goal state inspection at cursor position
   - Hover documentation retrieval
   - Code completion suggestions
   - Multi-attempt proof screening

2. **External Search Tools** (Rate-limited: 3 requests/30 seconds)
   - LeanSearch: Natural language theorem search
   - Loogle: Search by constant, lemma name, type, conclusion
   - Lean Finder: Semantic search for Mathlib theorems
   - Lean State Search: Applicable theorems for current proof goals
   - Lean Hammer: Premise search based on proof state

3. **Local Search**
   - lean_local_search: Search local project and stdlib (requires ripgrep)

4. **Project Management**
   - lean_build: Rebuild project and restart LSP server

### 2. Current Environment Analysis

#### Existing Infrastructure

**Neovim Lean Setup** (`/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua`):
- Plugin: Julian/lean.nvim (actively maintained)
- LSP: Uses vim.lsp.config directly (Neovim 0.11+)
- Infoview: Auto-open enabled, buffer exclusion configured
- Semantic tokens: Protected error handling implemented
- Event-triggered loading: BufReadPre/BufNewFile for .lean files

**MCP Hub Integration** (`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/mcp-hub.lua`):
- Plugin: ravitemer/mcphub.nvim
- Port: 37373
- Config location: ~/.config/mcphub/servers.json
- Avante integration: Enabled with auto-approval
- Environment detection: NixOS-aware with bundled binary fallback
- Lazy loading: Triggered by User AvantePreLoad event

**Existing MCP Servers** (from ~/.config/mcphub/servers.json):
- fetch (mcp-server-fetch)
- git (mcp-server-git)
- brave-search
- agentql
- context7-mcp
- github
- tavily

**Keybinding Availability**:
- `<leader>ri` is currently UNASSIGNED (verified in which-key.lua)
- `<leader>r` group exists for "run" operations
- Lean-specific mappings would fit well in `<leader>r` namespace

**NixOS Status**:
- uv package manager: INSTALLED at /run/current-system/sw/bin/uv
- ripgrep: INSTALLED at /run/current-system/sw/bin/rg (aliased as rg, not ripgrep)
- NixOS detection: Multiple indicators present (/etc/NIXOS, NIX_STORE, nix executable)

### 3. Integration Architecture

#### MCP Configuration Approach

**Option 1: Project-Scoped Configuration (RECOMMENDED)**
- File: `~/.config/.mcp.json` (in Lean project root)
- Scope: Specific to Lean development projects
- Advantages:
  - Only loads when working in Lean projects
  - Isolated from other development workflows
  - Easy to version control with Lean project
  - Follows Claude Code best practices

**Option 2: User-Scoped Configuration**
- File: `~/.claude.json` or `~/.config/mcphub/servers.json`
- Scope: Global across all projects
- Advantages:
  - Available system-wide
  - Single configuration point
  - Works with existing MCP Hub setup

**Option 3: Hybrid Configuration**
- MCP Hub servers.json: For shared MCP servers (fetch, git, etc.)
- Project .mcp.json: For Lean-specific MCP server
- Advantages:
  - Clean separation of concerns
  - Per-project Lean configuration
  - Centralized non-Lean MCP tools

#### Recommended Configuration Structure

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

**Environment Variables**:
- `LEAN_LOG_LEVEL`: "INFO" | "WARNING" | "ERROR" | "NONE" (default: "INFO")
- `LEAN_PROJECT_PATH`: Auto-detected or set explicitly
- `LEAN_STATE_SEARCH_URL`: Optional self-hosted premise-search instance
- `LEAN_HAMMER_URL`: Optional self-hosted Lean Hammer instance

### 4. Installation Requirements

#### System Dependencies (NixOS)

**Already Satisfied**:
- uv (Python package manager): /run/current-system/sw/bin/uv
- ripgrep: /run/current-system/sw/bin/rg

**Lean Project Requirements**:
- Lean 4 installation (not verified in current environment)
- lakefile.toml in project root
- Project must build successfully: `lake build`

**MCP Server Installation**:
```bash
# No installation needed - uvx handles on-demand installation
# Server will auto-install when first invoked by Claude Code
```

#### Neovim Integration

**No Additional Neovim Plugins Required**:
- lean.nvim: Already installed and configured
- mcphub.nvim: Already installed with Avante integration
- LSP infrastructure: Already configured via lspconfig.lua

### 5. Workflow Integration

#### AI-Assisted Theorem Proving Flow

1. **Development Context**
   - User opens .lean file in Neovim
   - lean.nvim initializes LSP connection
   - Infoview auto-opens with proof goals

2. **Claude Code Interaction**
   - User invokes Claude Code in Neovim (existing <leader>a mappings)
   - MCP Hub connects to lean-lsp-mcp server
   - Claude gains access to:
     - Current file diagnostics
     - Proof goal states
     - Term/hover information
     - Theorem search capabilities

3. **Proof Development**
   - Claude suggests proof tactics via MCP tools
   - User can query:
     - "What theorems are available for this goal?" (lean_state_search)
     - "Find similar proofs in Mathlib" (lean_leansearch, lean_loogle)
     - "What's the error on line 42?" (lean_diagnostic_messages)
     - "Show me the goal at this position" (lean_goal)

4. **Multi-Attempt Screening**
   - Claude can test multiple proof approaches via lean_multi_attempt
   - Returns goal states and diagnostics for each attempt
   - User selects most promising approach

#### Keybinding Strategy

**Recommendation: Minimal Direct Keybindings**

Given the preference for minimal keybindings and existing Claude Code integration, direct keybindings for lean-lsp-mcp tools are NOT recommended. Instead:

**Primary Interface**: Claude Code via MCP
- Use existing `<leader>a` mappings to invoke Claude/Avante
- Claude accesses lean-lsp-mcp tools automatically via MCP
- Natural language queries eliminate need for tool-specific keybindings

**Optional Convenience Binding** (`<leader>ri`):
- Purpose: Quick Lean infoview refresh or project rebuild
- Implementation: Direct lean.nvim functionality, NOT MCP wrapper
- Rationale: Faster than invoking Claude for simple operations

**Alternative Bindings** (if needed):
- `<leader>rl`: Lean LSP restart (reuse existing LSP pattern from `<leader>is`)
- `<leader>rb`: Lean build (lake build) - useful before MCP session

### 6. Security and Performance Considerations

#### Security

**MCP Security Concerns** (from lean-lsp-mcp README):
- File system access: MCP server can read Lean project files
- No input/output validation: Research tool in beta status
- No sensitive data handling: Limited to Lean source code
- Bearer token auth: Available for streamable-http/sse transports (not needed for stdio)

**Mitigation**:
- Use stdio transport (default) - no network exposure
- Project-scoped configuration limits scope to Lean projects
- Regular security audits via GitHub repository monitoring

#### Performance

**Rate Limiting**:
- External tools: 3 requests/30 seconds per tool
- Affects: leansearch, loogle, leanfinder, lean_state_search, hammer_premise
- Local tools: No rate limiting (file operations, diagnostics)

**Optimization Strategies**:
1. Pre-build projects: Run `lake build` before MCP session
   - Avoids timeout during lake serve startup
   - Critical for large Mathlib-dependent projects

2. Use local search first: lean_local_search (ripgrep-based)
   - No rate limits
   - Faster than external services
   - Reduces hallucinations via local confirmation

3. Batch operations: Use lean_multi_attempt for proof screening
   - Tests multiple tactics in one request
   - More efficient than sequential attempts

**Resource Usage**:
- Lean LSP server: Memory-intensive for large projects
- leanclient: Python subprocess overhead
- MCP Hub: Minimal overhead (port 37373 localhost)

### 7. Testing and Validation Strategy

#### Pre-Integration Validation

**Phase 1: Lean Environment Setup**
1. Verify Lean 4 installation on NixOS
2. Create test Lean project with lakefile.toml
3. Confirm `lake build` succeeds
4. Test lean.nvim functionality in Neovim

**Phase 2: MCP Server Testing**
1. Test uvx lean-lsp-mcp invocation manually
2. Verify server starts without errors
3. Check LEAN_LOG_LEVEL environment variable handling
4. Confirm ripgrep detection for local search

**Phase 3: Claude Code Integration**
1. Add lean-lsp MCP server to project .mcp.json
2. Restart Claude Code session
3. Verify MCP connection via /mcp command
4. Test basic MCP tools:
   - lean_file_outline on test .lean file
   - lean_diagnostic_messages with intentional error
   - lean_goal at specific line/column

**Phase 4: Workflow Validation**
1. Open Lean file in Neovim
2. Invoke Claude Code via existing mappings
3. Request theorem proof assistance
4. Verify Claude can:
   - Access current file diagnostics
   - Retrieve proof goals
   - Search for relevant theorems
   - Suggest proof tactics

#### Success Criteria

- [ ] MCP server appears in /mcp command output
- [ ] Claude can read Lean file diagnostics
- [ ] Claude can retrieve proof goals at cursor
- [ ] External search tools return results (respecting rate limits)
- [ ] Local search works with ripgrep
- [ ] No performance degradation in Neovim
- [ ] lean.nvim infoview remains functional
- [ ] MCP tools only load in Lean projects (if project-scoped)

### 8. Alternative Approaches Considered

#### Option A: Direct LSP Integration (REJECTED)
- **Approach**: Expose lean.nvim LSP methods via Neovim keybindings
- **Rejection Reason**:
  - Requires many new keybindings
  - Duplicates lean.nvim functionality
  - No AI integration benefits
  - Violates "minimal keybindings" constraint

#### Option B: Custom Neovim MCP Plugin (REJECTED)
- **Approach**: Create nvim-lean-mcp plugin similar to nvim-mcp projects
- **Rejection Reason**:
  - Reinvents lean-lsp-mcp functionality
  - Maintenance overhead
  - lean-lsp-mcp already provides all needed tools
  - Existing MCP Hub integration sufficient

#### Option C: Jupyter-Style REPL Integration (REJECTED)
- **Approach**: Integrate Lean REPL similar to Jupyter notebook workflow
- **Rejection Reason**:
  - Lean already has excellent infoview
  - lean.nvim provides superior interactive experience
  - MCP integration complements, doesn't replace lean.nvim
  - REPL not idiomatic for theorem proving

### 9. Recommended Implementation Plan

#### Phase 1: Environment Preparation
1. Verify Lean 4 installed on NixOS system
2. Create test Lean project or identify existing project
3. Run `lake build` to ensure project compiles
4. Document Lean project location for LEAN_PROJECT_PATH

#### Phase 2: MCP Configuration
1. Choose configuration scope (project vs. user)
2. Create .mcp.json in appropriate location
3. Add lean-lsp server configuration with uvx command
4. Set LEAN_LOG_LEVEL to "WARNING" for cleaner output
5. Optionally set LEAN_PROJECT_PATH if auto-detection fails

#### Phase 3: Neovim Integration (Optional Keybindings)
1. Add `<leader>ri` mapping for Lean-specific operations:
   ```lua
   { "<leader>ri", "<cmd>lua require('lean').infoview.toggle()<CR>",
     desc = "lean infoview", icon = "󰘦",
     cond = function() return vim.bo.filetype == "lean" end }
   ```
2. Consider `<leader>rb` for lean build if needed
3. Update which-key documentation comments

#### Phase 4: Testing and Validation
1. Restart Claude Code / Neovim session
2. Open test Lean file
3. Verify MCP server connection
4. Test core MCP tools interactively
5. Request Claude assistance with proof

#### Phase 5: Documentation and Refinement
1. Document MCP tools in project documentation
2. Create example Claude prompts for theorem proving
3. Monitor performance and adjust LEAN_LOG_LEVEL if needed
4. Fine-tune configuration based on usage patterns

### 10. Technical Dependencies and Compatibility

#### Version Compatibility Matrix

| Component | Current Version | Required Version | Status |
|-----------|----------------|------------------|--------|
| lean-lsp-mcp | v0.14.1 | >= v0.14.0 | Compatible |
| leanclient | v0.5.5 | >= v0.5.0 | Auto-installed |
| uv | System installed | Latest | Ready |
| ripgrep | System installed | Any | Ready |
| Neovim | 0.11+ (inferred) | 0.10+ | Compatible |
| lean.nvim | Latest | Any | Configured |
| mcphub.nvim | Latest | Any | Configured |
| MCP protocol | v1.21.2 | >= v1.0 | Compatible |

#### NixOS-Specific Considerations

**Package Installation Strategy**:
- **uv**: Already in system path via NixOS configuration
- **lean-lsp-mcp**: On-demand via uvx (no NixOS package needed)
- **Lean 4**: Requires explicit NixOS package or nix-shell
- **ripgrep**: Already installed (critical for lean_local_search)

**Nix Shell Integration** (if Lean not globally installed):
```nix
# Example shell.nix for Lean development
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    lean4
    elan  # Lean version manager
    uv    # Python package manager
    ripgrep
  ];

  shellHook = ''
    export LEAN_PROJECT_PATH=$PWD
    export LEAN_LOG_LEVEL=WARNING
  '';
}
```

### 11. Risk Assessment and Mitigation

#### Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Lean project build failures | Medium | High | Pre-build with lake build before MCP session |
| Rate limit throttling | Medium | Medium | Prioritize local search, batch operations |
| MCP server crashes | Low | Medium | LEAN_LOG_LEVEL=WARNING, monitor logs |
| Performance degradation | Low | Low | Project-scoped config, lazy loading |
| Security vulnerabilities | Low | Medium | Monitor GitHub, use stdio transport |
| Version incompatibilities | Low | High | Pin versions in documentation |

#### Contingency Plans

**If MCP Server Fails to Start**:
1. Check uvx installation: `uvx --version`
2. Verify Lean project structure (lakefile.toml present)
3. Review logs with LEAN_LOG_LEVEL=INFO
4. Confirm LEAN_PROJECT_PATH points to project root
5. Test manual invocation: `uvx lean-lsp-mcp --help`

**If Performance Issues Arise**:
1. Reduce LEAN_LOG_LEVEL to ERROR or NONE
2. Move to project-scoped configuration
3. Disable auto-load via MCP Hub (manual invocation only)
4. Consider self-hosted search instances (reduce external API calls)

**If Integration Conflicts Occur**:
1. Verify lean.nvim LSP not conflicting with MCP LSP
2. Check port 37373 not blocked/in use
3. Review MCP Hub auto-approval settings
4. Test with minimal .mcp.json configuration

### 12. Future Enhancement Opportunities

#### Short-Term Enhancements (0-3 months)
1. **Custom Claude Prompts**: Create project-specific prompts for common Lean patterns
2. **Proof Templates**: Develop reusable proof structure templates via Claude
3. **Local Search Optimization**: Fine-tune ripgrep patterns for Mathlib
4. **Keybinding Refinement**: Add mappings if usage patterns emerge

#### Medium-Term Enhancements (3-6 months)
1. **Self-Hosted Search Services**: Deploy premise-search and Lean Hammer locally
2. **Custom MCP Tools**: Extend lean-lsp-mcp with project-specific tools
3. **Proof Analytics**: Track proof success rates and common tactics
4. **Integration Testing**: Automated tests for MCP tool functionality

#### Long-Term Enhancements (6+ months)
1. **Lean 4 Skill Development**: Create Claude Code skill for Lean theorem proving
2. **Collaborative Proving**: Multi-user MCP integration for shared proving sessions
3. **Proof Library Integration**: Custom MCP server for organization-specific theorems
4. **Performance Optimization**: Contribute upstream improvements to lean-lsp-mcp

### 13. Related Projects and Ecosystem

**Complementary Tools**:
- **LeanTool**: Alternative Lean AI integration (https://github.com/GasStationManager/LeanTool)
- **LeanExplore MCP**: Educational Lean exploration (https://www.leanexplore.com/docs/mcp)
- **Lean4 Theorem Proving Skill**: Claude Desktop skill for Lean 4 (https://github.com/cameronfreer/lean4-skills)

**Neovim MCP Integration Examples**:
- **nvim-mcp**: Neovim instance control via MCP (https://github.com/linw1995/nvim-mcp)
- **mcp-neovim-server**: Neovim control using node-client (https://github.com/bigcodegen/mcp-neovim-server)

**Reference Documentation**:
- Lean 4 Manual: https://lean-lang.org/documentation/
- Mathlib Documentation: https://leanprover-community.github.io/mathlib4_docs/
- MCP Specification: https://modelcontextprotocol.io/

### 14. Recommended Next Steps

**Immediate Actions** (Priority 1):
1. Verify Lean 4 installation status on NixOS
2. Identify or create test Lean project with lakefile.toml
3. Test uvx lean-lsp-mcp manual invocation
4. Create project .mcp.json configuration file

**Implementation Actions** (Priority 2):
1. Add lean-lsp-mcp configuration to chosen scope
2. Restart Claude Code session in Lean project
3. Verify MCP server connection via /mcp command
4. Test basic MCP tools with sample queries

**Validation Actions** (Priority 3):
1. Open Lean file and request Claude proof assistance
2. Test external search tools (respect rate limits)
3. Verify local search with ripgrep
4. Monitor performance and adjust configuration

**Documentation Actions** (Priority 4):
1. Document chosen configuration approach
2. Create example Claude prompts for theorem proving
3. Record any environment-specific setup steps
4. Update project documentation with MCP integration details

## Conclusion

The integration of lean-lsp-mcp into the existing Neovim/NixOS environment is highly feasible and well-aligned with current infrastructure:

**Key Strengths**:
- Minimal additional dependencies (uv and ripgrep already installed)
- Seamless integration with existing MCP Hub setup
- No new keybindings required (Claude Code provides interface)
- lean.nvim remains primary Lean interaction method
- Project-scoped configuration enables selective enablement

**Primary Challenges**:
- Lean 4 installation verification needed
- Project build requirements (lake build before use)
- Rate limiting on external search tools
- Beta status of lean-lsp-mcp (security considerations)

**Recommended Approach**:
1. Use project-scoped .mcp.json configuration
2. Rely on Claude Code for MCP tool interaction
3. Keep `<leader>ri` available for future Lean-specific mappings
4. Prioritize local search tools to avoid rate limits
5. Pre-build Lean projects before MCP sessions

The integration will enable powerful AI-assisted theorem proving capabilities while maintaining the clean, minimal configuration philosophy of the current setup.

## References

### Primary Sources
- [lean-lsp-mcp GitHub Repository](https://github.com/oOo0oOo/lean-lsp-mcp)
- [leanclient Documentation](https://leanclient.readthedocs.io)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)

### Configuration Guides
- [Claude Code MCP Configuration](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [Configuring MCP Tools in Claude Code - Scott Spence](https://scottspence.com/posts/configuring-mcp-tools-in-claude-code)
- [Add MCP Servers to Claude Code - MCPcat Guide](https://mcpcat.io/guides/adding-an-mcp-server-to-claude-code/)
- [Claude Code MCP Setup Tips - Cloud Artisan](https://cloudartisan.com/posts/2025-04-12-adding-mcp-servers-claude-code/)

### Related Projects
- [nvim-mcp - Neovim MCP Server](https://github.com/linw1995/nvim-mcp)
- [Neovim LSP MCP Server - LobeHub](https://lobehub.com/mcp/trevorprater-nvim-lsp-mcp)
- [MCP HUB Documentation](https://ravitemer.github.io/mcphub.nvim/)
- [mcp-neovim-server - BigCodeGen](https://github.com/bigcodegen/mcp-neovim-server)

### Additional Resources
- [MCP Protocol Overview - Pragmatic Engineer](https://newsletter.pragmaticengineer.com/p/mcp)
- [Neovim LSP Documentation](https://neovim.io/doc/user/lsp.html)
- [lean.nvim Plugin Repository](https://github.com/Julian/lean.nvim)

---

**Report Generated**: 2025-12-02
**Research Complexity**: 3 (High)
**Target Environment**: NixOS + Neovim 0.11+ + Claude Code + MCP Hub
**Estimated Implementation Time**: 2-4 hours (excluding Lean 4 installation if needed)
