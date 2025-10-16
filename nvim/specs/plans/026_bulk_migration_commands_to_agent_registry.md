# ❌ OBSOLETE: Bulk Migration of Commands to Agent Registry Implementation Plan

## Status: OBSOLETE - DO NOT IMPLEMENT

**Date Marked Obsolete**: 2025-10-01
**Reason**: Agent registry removed; use Workaround 1 instead
**Replacement**: See `.claude/specs/reports/019_custom_agent_invocation_workarounds.md` Section "Workaround 1"

## Why This Plan Is Obsolete

Based on `specs/reports/036_agent_registry_relevance_analysis.md`:

1. **Plan 025 (Agent Registry) marked obsolete** - This plan depends on Plan 025, which is no longer needed
2. **Workaround 1 is simpler and better** - Natural language invocation requires zero infrastructure
3. **No migration script needed** - Just edit commands to use natural language
4. **Agent registry removed** - User chose picker-centric approach (2025-10-01)

## Simple Migration Pattern (Use This Instead)

```markdown
# BEFORE (broken - what this plan tried to fix)
Task {
  subagent_type: "plan-architect"
  prompt: "Create plan..."
}

# DO NOT use Plan 026 approach (too complex)
Task {
  subagent_type: general-purpose
  prompt: "[AGENT_PROMPT:plan-architect] ..."
}

# USE Workaround 1 (simple, works immediately)
Use the plan-architect agent to create an implementation plan for $ARGUMENTS
```

## Migration Steps (Manual, 5 minutes per command)

1. Open command file (e.g., `.claude/commands/plan.md`)
2. Find `Task { subagent_type: "agent-name" ... }`
3. Replace with: `Use the [agent-name] agent to [task description]`
4. Done - no tooling, no scripts, no complexity

---

## Original Plan Below (For Historical Reference Only)

## Metadata
- **Date**: 2025-10-01
- **Feature**: Bulk migration of all commands to use agent registry (Option 2)
- **Scope**: Update 5 primary commands to invoke agents via registry instead of custom types
- **Estimated Phases**: 3
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md, /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/specs/reports/036_agent_registry_migration_requirements.md

## Overview

~~Implement Option 2 (Bulk Migration) from the migration requirements report to update all commands that reference custom agent types to use the agent registry system. This will enable commands to invoke custom agents through the `general-purpose` subagent type with agent prompts loaded from `.claude/agents/*.md` files.~~

### Current State
- 5+ commands reference custom agent types (plan-architect, debug-specialist, etc.)
- Custom types cause errors: "Agent type 'X' not found"
- Agent registry is implemented and tested (all 8 agents load successfully)
- Commands use invalid pattern: `subagent_type: "agent-name"`

### Target State
- All commands use `subagent_type: general-purpose`
- Agent prompts loaded from registry and injected into Task prompts
- Consistent invocation pattern across all commands
- All commands working without agent type errors

## Success Criteria
- [ ] All custom agent type references removed from commands
- [ ] Commands use agent registry to load agent prompts
- [ ] All updated commands tested and working
- [ ] Consistent migration pattern applied across all commands
- [ ] Documentation updated with new invocation pattern
- [ ] Migration creates no regressions in command functionality

## Technical Design

### Architecture Decisions

#### Migration Strategy: Bulk with Safety

**Approach**: Create migration script that updates all commands in one pass, but with:
- Backup of original files
- Validation after each command update
- Rollback capability if issues detected
- Comprehensive testing phase

**Rationale**: Faster than gradual migration, but adds safety mechanisms to mitigate bulk migration risks.

#### Commands to Migrate

Based on report analysis:

1. **plan.md** - Uses `plan-architect`, `research-specialist` (2 agents)
2. **debug.md** - Uses `debug-specialist` (1 agent)
3. **document.md** - Uses `doc-writer` (1 agent)
4. **orchestrate.md** - Uses multiple agents: `research-specialist`, `plan-architect`, `code-writer`, `doc-writer`, `debug-specialist` (5+ agents)
5. **report.md** - May use `research-specialist` (documentation reference)

**Total agent type references**: ~16 instances across 5 commands

#### Migration Pattern

**Original Pattern** (broken):
```yaml
Task {
  subagent_type: "plan-architect"
  description: "Create implementation plan"
  prompt: "
    Create a plan for feature X

    Context: ...
  "
}
```

**Migrated Pattern** (working):
```markdown
## Load Agent Prompt

Reading plan-architect agent system prompt from agent registry.

[This section will dynamically load the agent prompt from .claude/agents/plan-architect.md]

## Invoke Agent

Task {
  subagent_type: general-purpose
  description: "Create implementation plan"
  prompt: "[AGENT_PROMPT:plan-architect]

Task: Create implementation plan for feature X

Context:
[Task-specific context here]

Requirements:
[Task-specific requirements]

Output:
[Expected output format]
  "
}
```

**Token Pattern**: Use `[AGENT_PROMPT:agent-name]` token that will be replaced with actual agent system prompt during command processing.

### Data Structures

#### Command File Metadata

```lua
{
  filepath = "/home/benjamin/.config/.claude/commands/plan.md",
  original_content = "[full original content]",
  backup_path = "/home/benjamin/.config/.claude/commands/.backups/plan.md.backup",
  agent_references = {
    {
      agent_name = "plan-architect",
      line_number = 200,
      original_text = 'subagent_type: "plan-architect"',
      context_lines = "[surrounding lines for context]"
    },
    -- ... more references
  },
  migrated = false,
  tested = false,
  errors = {}
}
```

#### Migration Script Configuration

```lua
{
  commands_dir = "/home/benjamin/.config/.claude/commands",
  agents_dir = "/home/benjamin/.config/.claude/agents",
  backup_dir = "/home/benjamin/.config/.claude/commands/.backups",
  dry_run = false,
  validate_after_migration = true,
  rollback_on_error = true,
  commands_to_migrate = {
    "plan.md",
    "debug.md",
    "document.md",
    "orchestrate.md",
    "report.md"
  }
}
```

## Implementation Phases

### Phase 1: Migration Script and Backup
**Objective**: Create migration tooling and backup original files
**Complexity**: Low

Tasks:
- [ ] Create `.claude/commands/.backups/` directory
- [ ] Create migration script: `.claude/lib/migrate-commands-to-registry.lua`
- [ ] Implement backup function
  - Copy each command file to `.backups/[filename].backup`
  - Preserve timestamps
  - Verify backup integrity
- [ ] Implement agent prompt loader
  - Use agent registry to load agent system prompts
  - Cache loaded prompts for performance
  - Handle missing agents gracefully
- [ ] Implement command file parser
  - Scan command for `subagent_type:` patterns
  - Extract agent names from references
  - Identify line numbers and context
  - Build reference map for each command
- [ ] Implement validation function
  - Check markdown syntax after migration
  - Verify no syntax errors introduced
  - Validate YAML frontmatter intact
- [ ] Add dry-run mode
  - Show what would change without modifying files
  - Print migration preview for each command
  - Display agent prompts to be injected

Testing:
```lua
-- Test in Neovim
:lua local migrator = require('claude.lib.migrate-commands-to-registry')

-- Dry run to preview changes
:lua migrator.run({dry_run = true})

-- Verify backup function
:lua migrator.backup_command('plan.md')
:lua vim.fn.filereadable('.claude/commands/.backups/plan.md.backup')
-- Expected: 1 (true)

-- Test agent prompt loading
:lua local prompt = migrator.load_agent_prompt('plan-architect')
:lua print(#prompt)
-- Expected: >5000 (prompt length in chars)
```

Expected outcomes:
- All 5 command files backed up safely
- Migration script can load all 8 agent prompts
- Dry-run shows accurate preview of changes
- Validation function catches syntax errors

### Phase 2: Command Migration
**Objective**: Update all commands to use agent registry pattern
**Complexity**: Medium

Tasks:
- [ ] Implement migration transformer
  - Replace `subagent_type: "agent-name"` with `subagent_type: general-purpose`
  - Inject agent system prompt at start of Task prompt
  - Preserve task-specific context after agent prompt
  - Maintain proper indentation and formatting
- [ ] Migrate `/plan` command
  - Find all agent type references (2: plan-architect, research-specialist)
  - Update each reference to use general-purpose + agent prompt
  - Validate markdown syntax
  - Run test invocation if possible
- [ ] Migrate `/debug` command
  - Find agent type reference (1: debug-specialist)
  - Update to use general-purpose + agent prompt
  - Validate syntax
- [ ] Migrate `/document` command
  - Find agent type reference (1: doc-writer)
  - Update to use general-purpose + agent prompt
  - Validate syntax
- [ ] Migrate `/orchestrate` command
  - Find all agent type references (5+: multiple agents)
  - Update each reference systematically
  - Handle sequential agent invocations
  - Validate complex workflow structure
- [ ] Migrate `/report` command
  - Check for research-specialist references
  - Update if found
  - Validate syntax
- [ ] Generate migration report
  - List all changes made
  - Count agent references updated
  - Note any issues or warnings
  - Document rollback procedure

Testing:
```lua
-- Run migration (with validation)
:lua local migrator = require('claude.lib.migrate-commands-to-registry')
:lua local results = migrator.run({
  dry_run = false,
  validate_after_migration = true,
  rollback_on_error = true
})

-- Check results
:lua print(vim.inspect(results))
-- Expected: {
--   migrated = {"plan.md", "debug.md", "document.md", "orchestrate.md"},
--   errors = {},
--   total_references_updated = 16,
--   backup_created = true
-- }

-- Verify command file syntax
:lua vim.cmd('edit .claude/commands/plan.md')
-- Visual inspection: check for proper formatting

-- Check for custom agent type references (should be 0)
```
```bash
grep 'subagent_type: "' /home/benjamin/.config/.claude/commands/*.md | grep -v general-purpose | wc -l
# Expected: 0
```

Expected outcomes:
- All 5 commands migrated successfully
- ~16 agent type references updated
- No syntax errors introduced
- Backups preserved for rollback
- Migration report generated

### Phase 3: Testing and Validation
**Objective**: Test all migrated commands and validate functionality
**Complexity**: Medium

Tasks:
- [ ] Create test suite for migrated commands
  - Define test cases for each command
  - Include success and error scenarios
  - Document expected outputs
- [ ] Test `/plan` command
  - Simple plan creation test
  - Verify plan-architect agent invoked correctly
  - Check plan file generated properly
  - Confirm no agent type errors
- [ ] Test `/debug` command
  - Simple debug investigation test
  - Verify debug-specialist agent invoked
  - Check debug report generated
  - Confirm proper agent prompt inclusion
- [ ] Test `/document` command
  - Documentation update test
  - Verify doc-writer agent invoked
  - Check docs updated correctly
- [ ] Test `/orchestrate` command (most complex)
  - Multi-agent workflow test
  - Verify all 5+ agents invoked in sequence
  - Check each phase completes successfully
  - Confirm no agent type errors across workflow
- [ ] Test `/report` command
  - Research report generation test
  - Verify research-specialist used if applicable
  - Check report file created
- [ ] Validate agent prompts injected correctly
  - Read generated Task prompts
  - Verify agent system prompts present
  - Confirm task context appended properly
  - Check no truncation or corruption
- [ ] Performance testing
  - Measure command execution time before/after
  - Verify no significant performance degradation
  - Check agent registry caching working
- [ ] Create rollback procedure document
  - Steps to restore from backups
  - How to identify migration issues
  - Validation checklist after rollback
- [ ] Update migration requirements report
  - Mark migration complete
  - Document lessons learned
  - Note any edge cases discovered

Testing:
```bash
# Test each command with simple invocation
# (These would be run interactively in Claude Code CLI)

# Test /plan
/plan Create a simple test feature

# Test /debug
/debug Test issue for validation

# Test /document
/document Update README files

# Test /orchestrate (most complex)
/orchestrate Implement simple auth feature

# Test /report
/report Test research topic

# Verify no agent type errors in any command output
# Expected: All commands complete without "Agent type 'X' not found" errors

# Performance check
time /plan Create test plan
# Expected: <5 seconds (similar to before migration)

# Validation: Check agent prompts in generated tasks
# (Would require inspecting Task tool invocations during command execution)
```

Expected outcomes:
- All 5 commands tested successfully
- No agent type errors
- Agent prompts correctly injected
- Performance maintained
- Rollback procedure documented

## Testing Strategy

### Unit Testing

**Migration Script Tests**:
```lua
describe('migrate-commands-to-registry', function()
  it('creates backups correctly', function()
    -- Test backup creation
  end)

  it('loads agent prompts from registry', function()
    -- Test agent prompt loading
  end)

  it('identifies agent type references', function()
    -- Test reference scanning
  end)

  it('transforms agent invocations', function()
    -- Test migration transformation
  end)

  it('validates migrated syntax', function()
    -- Test validation function
  end)

  it('rolls back on error', function()
    -- Test rollback mechanism
  end)
end)
```

### Integration Testing

**Command Execution Tests**:
- Execute each migrated command with test input
- Verify expected output generated
- Check for agent type errors
- Validate agent prompts included in Task calls

### Edge Cases

- Command with no agent references (should skip)
- Command with multiple references to same agent (should handle)
- Command with malformed agent type syntax (should warn)
- Agent not found in registry (should error gracefully)
- Corrupted command file (should skip with error)
- Permission denied for backup creation (should fail gracefully)

### Rollback Testing

- Simulate migration failure
- Verify rollback restores original files
- Confirm no data loss
- Validate backup integrity

## Documentation Requirements

### Code Documentation
- [ ] Add LuaLS annotations to migration script
- [ ] Document each function's purpose and behavior
- [ ] Add inline comments for complex logic
- [ ] Document configuration options

### User Documentation
- [ ] Update command documentation with new invocation pattern
- [ ] Document migration process and rationale
- [ ] Create troubleshooting guide for migration issues
- [ ] Add examples of before/after patterns

### Developer Documentation
- [ ] Document migration script architecture
- [ ] Explain backup and rollback procedures
- [ ] Document validation approach
- [ ] Add notes on extending migration for future commands

## Dependencies

### External Dependencies
- Agent registry module (already implemented)
- plenary.nvim (for file operations)
- Agent files in `.claude/agents/` (already present)

### Internal Dependencies
- Commands must have valid YAML frontmatter
- Agent names must match filenames in `.claude/agents/`
- Agent registry must be loaded before migration

### File Dependencies
- `.claude/commands/*.md` (5 files to migrate)
- `.claude/agents/*.md` (8 agent files for prompts)
- Agent registry module: `nvim/lua/neotex/plugins/ai/claude/agent_registry.lua`

## Risk Assessment

### High Risk
- **Bulk migration errors**: Migrating all commands at once could introduce errors across all commands
  - Mitigation: Comprehensive backup, validation after each command, rollback on error
  - Mitigation: Dry-run mode to preview changes before applying

- **Agent prompt corruption**: Injecting agent prompts incorrectly could break commands
  - Mitigation: Use agent registry API (tested), validate markdown syntax after migration
  - Mitigation: Test agent prompt injection with small examples first

### Medium Risk
- **Orchestrate command complexity**: Most complex command with 5+ agents
  - Mitigation: Migrate orchestrate last, test thoroughly with full workflow
  - Mitigation: Keep backup easily accessible for quick rollback

- **Syntax errors in migrated files**: Migration could introduce markdown syntax errors
  - Mitigation: Syntax validation after each migration
  - Mitigation: Rollback automatically if validation fails

### Low Risk
- **Performance degradation**: Agent registry lookup could slow commands
  - Mitigation: Agent registry uses caching (already tested)
  - Mitigation: Performance testing phase to detect issues

- **Backup space**: Backups could consume disk space
  - Mitigation: Backups are small markdown files (<100KB total)
  - Mitigation: Can be deleted after successful migration

## Migration Script Design

### Script Location
`/home/benjamin/.config/.claude/lib/migrate-commands-to-registry.lua`

### Core Functions

```lua
local M = {}

-- Configuration
M.config = {
  commands_dir = vim.fn.expand("~/.config/.claude/commands"),
  agents_dir = vim.fn.expand("~/.config/.claude/agents"),
  backup_dir = vim.fn.expand("~/.config/.claude/commands/.backups"),
  commands_to_migrate = {
    "plan.md",
    "debug.md",
    "document.md",
    "orchestrate.md",
    "report.md"
  }
}

-- Create backup of command file
function M.backup_command(filename) end

-- Load agent system prompt from registry
function M.load_agent_prompt(agent_name) end

-- Scan command for agent type references
function M.scan_agent_references(content) end

-- Transform agent invocation to registry pattern
function M.transform_agent_invocation(content, reference) end

-- Validate migrated command file
function M.validate_command(filepath) end

-- Rollback command to backup
function M.rollback_command(filename) end

-- Main migration function
function M.migrate_command(filename, opts) end

-- Run full migration
function M.run(opts) end

return M
```

### Usage Example

```lua
-- Load migration script
local migrator = require('claude.lib.migrate-commands-to-registry')

-- Preview changes (dry run)
migrator.run({dry_run = true})

-- Run migration with validation
local results = migrator.run({
  dry_run = false,
  validate_after_migration = true,
  rollback_on_error = true
})

-- Check results
print(vim.inspect(results))

-- Rollback if needed
migrator.rollback_command('plan.md')
```

## Rollback Procedure

If migration causes issues:

### Automatic Rollback (during migration)
Migration script automatically rolls back if:
- Syntax validation fails
- Agent prompt loading fails
- File write operation fails

### Manual Rollback (after migration)
```lua
-- Rollback single command
local migrator = require('claude.lib.migrate-commands-to-registry')
migrator.rollback_command('plan.md')

-- Rollback all commands
for _, cmd in ipairs(migrator.config.commands_to_migrate) do
  migrator.rollback_command(cmd)
end
```

### Verification After Rollback
```bash
# Check files restored
diff .claude/commands/plan.md .claude/commands/.backups/plan.md.backup
# Expected: no differences

# Test original command
/plan Create test feature
# Expected: Works as before (or has original errors)
```

## Notes

### Design Decisions

**Why Bulk Migration**:
- User specifically requested Option 2 (bulk migration)
- Faster than gradual migration (all commands ready at once)
- Consistent pattern applied across all commands
- Single migration event vs. multiple partial migrations

**Why Add Safety Mechanisms**:
- Report notes bulk migration risks (harder to test, difficult rollback)
- Backups make rollback trivial
- Validation prevents broken commands from being deployed
- Automatic rollback on error prevents partial migration state

**Why Migration Script vs. Manual**:
- Consistent transformation across all commands
- Reusable for future commands
- Automated validation reduces human error
- Easier to test transformation logic

### Implementation Timeline
Estimated 2-3 hours total:
- Phase 1: 1 hour (script creation and backup)
- Phase 2: 30-45 minutes (migration execution)
- Phase 3: 1-1.5 hours (testing and validation)

### Post-Migration Cleanup
After successful migration and testing:
- [ ] Keep backups for 1 week for safety
- [ ] Document migration in project changelog
- [ ] Update agent-development-guide.md with migration notes
- [ ] Archive migration script (may be useful for future commands)

### Future Considerations
- New commands should use agent registry from start
- Template in `example-with-agent.md` shows correct pattern
- Migration script can be reused if new commands need updating
- Consider adding command validation to `/setup` slash command
