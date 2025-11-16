# System Prompts and Configuration Persistence Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: System Prompts and Configuration Persistence
- **Report Type**: codebase analysis
- **Overview Report**: [Research Overview](./OVERVIEW.md)

## Related Reports

This is part 3 of 4 in a hierarchical research analysis:
- **[Overview](./OVERVIEW.md)** - Synthesized findings across all subtopics
- **[Avante MCP Consolidation and Abstraction](./001_avante_mcp_consolidation_and_abstraction.md)** - MCP integration architecture
- **[Terminal Management and State Coordination](./002_terminal_management_and_state_coordination.md)** - Bash subprocess isolation patterns
- **[Internal API Surface and Module Organization](./004_internal_api_surface_and_module_organization.md)** - Library organization

## Executive Summary

The codebase implements two distinct system prompt configuration approaches: YAML frontmatter for .claude agents (declarative metadata) and JSON files for Neovim Avante prompts (runtime persistence). Agent frontmatter uses fields like `allowed-tools`, `model`, and `description` parsed at discovery time, while Avante uses `system-prompts.json` for user-editable prompt templates with load/save functions. Both follow file-based persistence with separation of concerns between configuration metadata and behavioral content.

## Findings

### 1. Agent YAML Frontmatter Configuration

**Location**: `/home/benjamin/.config/.claude/agents/*.md`

The .claude agent system uses YAML frontmatter blocks at the start of markdown files to configure agent behavior:

**Structure** (lines 1-7 of `/home/benjamin/.config/.claude/agents/research-specialist.md`):
```yaml
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
description: Specialized in codebase research, best practice investigation, and report file creation
model: sonnet-4.5
model-justification: Codebase research, best practices synthesis, comprehensive report generation with 28 completion criteria
fallback-model: sonnet-4.5
---
```

**Key Configuration Fields**:
- `allowed-tools`: Comma-separated list of permitted Claude Code tools (Read, Write, Edit, Bash, etc.)
- `description`: Brief summary used for agent discovery and selection
- `model`: Primary model for agent execution (haiku-4.5, sonnet-4.5, opus-4.1)
- `model-justification`: Explanation of why specific model tier selected
- `fallback-model`: Model to use if primary unavailable

**Discovery and Parsing** (`/home/benjamin/.config/.claude/lib/agent-discovery.sh:42-70`):
```bash
# Extract frontmatter between --- markers
frontmatter=$(sed -n '1,/^---$/p' "$behavioral_file" | sed '1d;$d')

# Parse description field
if echo "$frontmatter" | grep -q "^description:"; then
  description=$(echo "$frontmatter" | grep "^description:" | sed 's/^description:[ ]*//')
fi

# Parse allowed-tools and convert to JSON array
if echo "$frontmatter" | grep -q "^allowed-tools:"; then
  tools_str=$(echo "$frontmatter" | grep "^allowed-tools:" | sed 's/^allowed-tools:[ ]*//')
  tools_json=$(echo "$tools_str" | tr ',' '\n' | ... | jq -R . | jq -s .)
fi
```

**Persistence Mechanism**:
- Frontmatter is read-only at runtime (parsed during agent discovery)
- No save functionality - frontmatter modified manually in markdown files
- Agent registry at `.claude/agents/agent-registry.json` caches parsed metadata
- Registry updated via `discover_and_register_all()` function

**Behavioral Injection Pattern** (`/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:1-40`):
- Frontmatter provides configuration metadata
- Markdown body contains behavioral guidelines (STEP 1, STEP 2, etc.)
- Commands inject context into agents via file references, not inline duplication
- Separation: Commands orchestrate, agents execute based on injected context

### 2. Neovim Avante System Prompts Persistence

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/system-prompts.lua`

**JSON Storage Format** (line 10):
```lua
local prompts_file = vim.fn.stdpath("config") .. "/lua/neotex/plugins/ai/util/system-prompts.json"
```

**Data Structure** (lines 13-41):
```lua
local default_prompts = {
  default = "expert",  -- Active prompt ID
  prompts = {
    expert = {
      name = "Expert",
      description = "Expert mathematician and programmer with MCP tools",
      prompt = "You are an expert mathematician, logician and computer scientist..."
    },
    tutor = { name = "Tutor", description = "...", prompt = "..." },
    coder = { name = "Coder", description = "...", prompt = "..." },
    researcher = { name = "Researcher", description = "...", prompt = "..." }
  }
}
```

**Load/Save Functions**:

**Load** (lines 102-126):
```lua
function M.load_prompts()
  if not ensure_prompts_file() then
    return vim.deepcopy(default_prompts)  -- Fallback to defaults
  end

  local content = vim.fn.readfile(prompts_file)
  local ok, prompts = pcall(vim.fn.json_decode, table.concat(content, '\n'))

  if not ok or not prompts then
    save_default_prompts()  -- Auto-repair corrupted file
    return vim.deepcopy(default_prompts)
  end

  return prompts
end
```

**Save** (lines 129-162):
```lua
function M.save_prompts(prompts)
  local ok, json = pcall(vim.fn.json_encode, prompts)
  if not ok or not json then
    vim.notify("Failed to encode prompts to JSON", vim.log.levels.ERROR)
    return false
  end

  local formatted_json = json:gsub(...)  -- Format for readability

  local file = io.open(prompts_file, "w")
  file:write(formatted_json)
  file:close()
  return true
end
```

**Runtime Application** (lines 208-243):
```lua
function M.apply_prompt(id)
  local prompt_data = M.get_prompt(id)

  -- Store in global state for session tracking
  _G.current_avante_prompt = { id = id, name = prompt_data.name }

  -- Update Avante configuration
  local config = require("avante.config")
  config.override({
    system_prompt = prompt_data.prompt,
    prompt_name = prompt_data.name
  })

  vim.notify("Applied system prompt: " .. prompt_data.name, vim.log.levels.INFO)
end
```

**CRUD Operations**:
- `M.create_prompt(data)` - Add new prompt to JSON (lines 246-276)
- `M.edit_prompt(id, data)` - Update existing prompt (lines 279-309)
- `M.delete_prompt(id)` - Remove prompt (lines 312-341)
- `M.set_default(id)` - Change active prompt (lines 186-205)

**User Interface** (lines 344-668):
- Interactive selection menu via `vim.ui.select()`
- Floating window editor for prompt text
- Keyboard shortcuts: Enter to save, Esc to cancel
- Markdown syntax highlighting in editor

### 3. Configuration Architecture Patterns

**Agent Discovery System** (`/home/benjamin/.config/.claude/lib/agent-discovery.sh`):
- Scans `.claude/agents/` directory for `*.md` files
- Extracts frontmatter metadata from each file
- Categorizes agents by type (specialized, hierarchical) and category (research, planning, implementation, debugging, documentation, analysis, coordination)
- Registers metadata in agent registry JSON

**Metadata Extraction** (`/home/benjamin/.config/.claude/lib/metadata-extraction.sh:13-87`):
- Extracts title, summary, file paths, recommendations from research reports
- Extracts date, phases, complexity, time estimates from implementation plans
- Returns structured JSON for artifact metadata
- Used by commands for context reduction and artifact discovery

**Best Practices from Web Research**:

1. **Separation of Concerns** (ClaudeLog, 2025):
   - Frontmatter = configuration/permissions/metadata
   - Markdown body = behavioral instructions
   - Better maintainability, inspectability, shareability

2. **Lightweight Metadata Loading** (Anthropic Skills docs, 2025):
   - Load metadata at startup, include in system prompt
   - Only brief description and tool list loaded
   - Full behavioral content loaded on-demand when skill invoked
   - No context penalty for installed-but-unused skills

3. **Version Control Integration** (EmpathyFirstMedia YAML guide, 2025):
   - Track all configuration changes with Git
   - Tag stable configurations with semantic versions
   - Test changes in feature branches before merge
   - Meaningful commit messages for configuration updates

4. **Progressive Tool Expansion** (DEV Community, 2025):
   - Start with scoped tool set
   - Validate behavior before expanding
   - Add tools incrementally as capabilities validated

5. **Scoped Instructions** (GitHub Gist on AI rules, 2025):
   - Multiple instruction files possible
   - YAML frontmatter specifies file/directory scope
   - Different instructions for different codebase parts

### 4. Configuration Persistence Comparison

| Aspect | .claude Agents (YAML) | Neovim Avante (JSON) |
|--------|----------------------|----------------------|
| **Storage** | Markdown frontmatter | Separate JSON file |
| **Editability** | Manual file editing | Interactive UI + manual |
| **Persistence** | Git-tracked, read-only | JSON read/write, auto-repair |
| **Scope** | Per-agent configuration | Per-session prompt selection |
| **Discovery** | Directory scan + parsing | File load on Neovim startup |
| **Validation** | Schema validator script | pcall error handling |
| **Defaults** | No defaults (must exist) | Hard-coded defaults in code |
| **User Modification** | Rarely (stable configs) | Frequently (session-specific) |

### 5. Session and State Management

**Neovim Claude Session Persistence** (`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:19-45`):
```lua
M.sessions = {}  -- Populated from claude_worktree
M.current_session = nil

M.save_session_state = function()
  return claude_session.save_session_state()
end

M.load_session_state = function()
  return claude_session.load_session_state()
end

M.resume_session = function(id)
  local session_manager = require("neotex.plugins.ai.claude.core.session-manager")
  return session_manager.resume_session(id)
end
```

**Session Manager Features**:
- Detect Claude terminal buffers for session tracking
- Resume previous sessions by ID
- Error capture and validation
- Buffer management with pattern matching

**State Persistence** (referenced but not implemented in detail):
- Session state saved to disk (exact format not shown in searched files)
- Session browser UI for selecting/resuming sessions
- Cleanup functions for removing stale sessions

## Recommendations

### 1. Unified Configuration Schema

**Current State**: Agent frontmatter and Avante prompts use different field names and structures.

**Recommendation**: Define shared configuration schema:
- `name` - Display name (both systems)
- `description` - Brief summary (both systems)
- `tools` - Allowed tools (agent frontmatter) / capabilities (Avante)
- `model` - Model preference (agent frontmatter) / provider config (Avante)
- `scope` - File/directory applicability (missing in both)

**Benefits**:
- Easier cross-system integration
- Reduced learning curve
- Potential for shared tooling (validators, editors)

### 2. Agent Configuration UI

**Current State**: Agents require manual frontmatter editing, no interactive UI.

**Recommendation**: Create agent configuration manager similar to Avante's system prompts UI:
- List all agents with descriptions
- Edit frontmatter fields via forms
- Validate configuration before saving
- Preview behavioral file content
- Test agent with sample inputs

**Implementation**:
- Extend `system-prompts.lua` pattern to `.claude/agents/`
- Add `:ClaudeAgents` command for agent browser
- Use `vim.ui.select()` for agent selection
- Floating window editor for behavioral markdown

### 3. Configuration Validation and Defaults

**Current State**: Agent frontmatter has no defaults, no runtime validation.

**Recommendation**: Implement validation pipeline:
- Schema validator runs on agent discovery
- Warn on missing required fields (description, allowed-tools)
- Suggest defaults based on agent category
- Block registration of invalid agents
- Detailed error messages with fix suggestions

**Files to Create**:
- `.claude/lib/agent-config-validator.sh` - Shell validation
- `.claude/schemas/agent-frontmatter.json` - JSON schema
- `.claude/tests/test_agent_config_validation.sh` - Test suite

### 4. Version-Controlled Prompt Templates

**Current State**: Avante prompts in JSON not version-controlled, hard to share.

**Recommendation**: Move Avante prompts to Git-tracked markdown:
- Create `nvim/prompts/` directory
- Store each prompt as `{id}.md` with frontmatter
- Migrate JSON to markdown on Neovim startup
- Use Git for version control and sharing
- Support both formats (read JSON, prefer markdown)

**Migration Path**:
1. Export existing prompts to markdown
2. Add `nvim/prompts/` to Git
3. Update `system-prompts.lua` to prefer markdown
4. Keep JSON as fallback for backward compatibility

### 5. Session-Scoped Agent Configuration

**Current State**: Agents use same configuration across all sessions.

**Recommendation**: Allow session-specific agent overrides:
- Store session config in `.claude/sessions/{id}/config.json`
- Override allowed-tools, model, timeout per session
- Preserve base configuration in agent files
- Merge session config with base config at runtime

**Use Cases**:
- Debugging session: Enable verbose logging, extended timeout
- Production session: Restrict tools to Read-only
- Testing session: Use cheaper model (haiku) for cost reduction

## References

### Codebase Files Analyzed

1. `/home/benjamin/.config/.claude/agents/research-specialist.md:1-7` - YAML frontmatter structure
2. `/home/benjamin/.config/.claude/agents/plan-architect.md:1-50` - Agent configuration example
3. `/home/benjamin/.config/.claude/agents/code-writer.md:1-50` - Tools configuration
4. `/home/benjamin/.config/.claude/lib/agent-discovery.sh:42-150` - Frontmatter parsing logic
5. `/home/benjamin/.config/.claude/lib/metadata-extraction.sh:13-150` - Metadata extraction patterns
6. `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:1-258` - Configuration vs behavioral separation
7. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/system-prompts.lua:1-671` - Avante prompt persistence
8. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:19-45` - Session management

### External References

1. **Claude Agent Skills Deep Dive** - https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/
   - Frontmatter structure and metadata loading
2. **ClaudeLog Custom Agents** - https://claudelog.com/mechanics/custom-agents/
   - Separation of concerns in agent configuration
3. **Agent Skills Documentation** - https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview
   - Lightweight metadata loading pattern
4. **YAML Files for AI Agents** - https://empathyfirstmedia.com/yaml-files-ai-agents/
   - Version control best practices
5. **Claude Code Custom Agent Framework** - https://dev.to/therealmrmumba/claude-codes-custom-agent-framework-changes-everything-4o4m
   - Progressive tool expansion strategy
6. **AI Agent Rule Files** - https://gist.github.com/0xdevalias/f40bc5a6f84c4c5ad862e314894b2fa6
   - Scoped instructions with frontmatter
