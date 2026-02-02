# Implementation Plan: Task #23

- **Task**: 23 - leader_ac_picker_claude_directory_management
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [specs/23_leader_ac_picker_claude_directory_management/reports/research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Add agents/ directory support to the `<leader>ac` picker for complete .claude/ directory management. The research identified that agents/ is the primary gap - containing 9 active agent definitions that are not accessible through the picker. This implementation adds a new [Agents] section to the picker UI and integrates agents into the sync operations, following existing patterns for commands, skills, and hooks.

### Research Integration

From research-001.md:
- agents/ directory contains 9 active agents (*.md files) plus archive/ subdirectory
- Picker currently supports 9 artifact types for display, 11 for sync
- Implementation approach: Add `scan_agents_directory()` to parser, `create_agents_entries()` to entries, and agent sync to sync.lua
- User guidance: Include agents/, skip output/ and systemd/

## Goals and Non-Goals

**Goals**:
- Add [Agents] section to picker UI displaying all agent definitions
- Support local/global agent merging with local priority (like other artifact types)
- Integrate agents into "Load All Artifacts" sync operation
- Add Ctrl-u (update from global) support for agent entries

**Non-Goals**:
- Adding context/ or rules/ to picker UI (already in sync, out of scope)
- Adding output/ directory support (per user guidance)
- Adding systemd/ directory support (per user guidance, system-managed)
- Adding agent execution capability (agents are reference documents)

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking existing picker functionality | Medium | Low | Test all existing artifact types after changes |
| Inconsistent display format with other sections | Low | Low | Follow existing patterns exactly |
| Performance with recursive agent scans | Low | Low | Only scan top-level agents/, exclude archive/ |

## Implementation Phases

### Phase 1: Parser Changes [NOT STARTED]

**Goal**: Add agent scanning and parsing capabilities to the parser module

**Tasks**:
- [ ] Add `scan_agents_directory()` function to parser.lua following `scan_skills_directory()` pattern
- [ ] Add `parse_agents_with_fallback()` local function for local/global merging
- [ ] Add agent metadata extraction (name, description from first heading or frontmatter)
- [ ] Integrate agents into `get_extended_structure()` return value
- [ ] Exclude archive/ subdirectory from agent scanning

**Timing**: 45 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Add agent scanning functions

**Verification**:
- Load Neovim and run `:lua print(vim.inspect(require('neotex.plugins.ai.claude.commands.parser').get_extended_structure().agents))`
- Should return array of 9 agents with name, description, filepath, is_local fields

---

### Phase 2: Entry Display Changes [NOT STARTED]

**Goal**: Add [Agents] section to the picker display

**Tasks**:
- [ ] Add `format_agent()` local function following `format_skill()` pattern
- [ ] Add `create_agents_entries()` function following `create_skills_entries()` pattern
- [ ] Add [Agents] heading with description "AI agent definitions"
- [ ] Integrate agents entries into `create_picker_entries()` after skills section
- [ ] Set entry_type as "agent" for action handling

**Timing**: 30 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Add agent entries

**Verification**:
- Open picker with `<leader>ac`
- Should see [Agents] section with agent entries listed
- Agents should show * prefix if local

---

### Phase 3: Sync Operations [NOT STARTED]

**Goal**: Integrate agents into sync operations

**Tasks**:
- [ ] Add agent scanning to `scan_all_artifacts()` in sync.lua
- [ ] Add `agents` to `execute_sync()` function
- [ ] Add agent config to `subdir_map` in `update_artifact_from_global()`
- [ ] Update "Load All Artifacts" display message to include agents count

**Timing**: 30 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Add agent sync support

**Verification**:
- In a non-.config project, run Load All Artifacts
- Should include agents in sync count
- Test Ctrl-u on an agent entry to update from global

---

### Phase 4: Action Handler Integration [NOT STARTED]

**Goal**: Enable picker actions on agent entries

**Tasks**:
- [ ] Add "agent" to action handling in picker/init.lua for Enter (open file)
- [ ] Add "agent" to Ctrl-e (edit) action handling
- [ ] Add "agent" to Ctrl-u (update from global) action handling
- [ ] Ensure agent entries can be filtered/searched

**Timing**: 20 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Add agent action handlers

**Verification**:
- Select an agent in picker, press Enter - should open agent file
- Press Ctrl-e on agent - should open for editing
- Press Ctrl-u on agent - should update from global (if in project dir)

---

### Phase 5: Testing and Verification [NOT STARTED]

**Goal**: Verify complete agent integration works correctly

**Tasks**:
- [ ] Test picker opens with [Agents] section visible
- [ ] Verify all 9 agents from .claude/agents/ are listed
- [ ] Test Enter opens agent file in buffer
- [ ] Test Ctrl-e opens agent for editing
- [ ] Test Load All Artifacts includes agents
- [ ] Verify existing artifact types still work (commands, skills, hooks, etc.)
- [ ] Test from both .config/ (global) and another project directory (local/global merge)

**Timing**: 25 minutes

**Files to modify**: None (testing only)

**Verification**:
- All test scenarios pass
- No regressions in existing functionality

## Testing and Validation

- [ ] Picker loads without errors
- [ ] [Agents] section displays with correct heading
- [ ] Agent entries show correct format (prefix, name, description)
- [ ] Local agents marked with * prefix
- [ ] Enter action opens agent file
- [ ] Ctrl-e action opens agent for editing
- [ ] Ctrl-u action updates agent from global
- [ ] Load All Artifacts includes agents in count
- [ ] No regression in existing artifact types

## Artifacts and Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (after completion)
- Modified files:
  - nvim/lua/neotex/plugins/ai/claude/commands/parser.lua
  - nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua
  - nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua
  - nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua

## Rollback/Contingency

If implementation causes issues:
1. Revert changes to the four modified files using git
2. Verify picker returns to previous working state
3. Debug issue before re-attempting

All changes are additive - existing functionality should not be affected. If agents section causes display issues, can be disabled by removing the agents entries integration from `create_picker_entries()`.
