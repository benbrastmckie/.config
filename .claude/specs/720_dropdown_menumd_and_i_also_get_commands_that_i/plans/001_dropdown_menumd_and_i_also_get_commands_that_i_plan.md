# Dropdown Menu Deduplication Implementation Plan

## Metadata
- **Date**: 2025-11-15
- **Feature**: Complete ~/.claude/ Cleanup - Commands, Agents, and Hooks Removal
- **Scope**: Remove ALL commands, agents, and hooks from ~/.claude/ to prioritize .config/.claude/ for portability via <leader>ac
- **Estimated Phases**: 4
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis - User/Project Duplication](../reports/001_topic1.md)
  - [Resume-Implement Command Lifecycle Analysis](../reports/002_topic2.md)
  - [Command Enumeration Architecture and Deduplication Strategy](../reports/003_topic3.md)
- **Structure Level**: 0
- **Complexity Score**: 24.0
- **Revision**: 3 (2025-11-15)

## Overview

This plan addresses duplicate entries in Claude Code by completely cleaning ~/.claude/ of commands, agents, and hooks to prioritize .config/.claude/ for project portability.

**Key Issues**:
1. **Commands**: `/implement` appears 4 times (2 user + 2 project entries), `/resume-implement` shows despite deletion, 9 total duplicated commands
2. **Agents**: 9 agents duplicated (code-reviewer, plan-architect, research-specialist, etc.) - outdated Oct 2 vs current Nov 14
3. **Hooks**: 2-3 hooks duplicated (post-command-metrics.sh, tts-dispatcher.sh) - potential conflicts or double-execution
4. User-level artifacts are outdated (Oct 2) vs project artifacts (Nov 12-14)
5. Claude Code shows all variants without deduplication

**Solution Approach**:
Remove ALL commands, agents, and hooks from ~/.claude/ directories, keeping ONLY .config/.claude/ versions. This aligns with the workflow of using <leader>ac in nvim to copy .config/.claude/ artifacts into any project for portability, eliminating reliance on global ~/.claude/ directory. Add detection scripts to prevent future duplication.

**Workflow Context**:
The user employs <leader>ac (nvim mapping) to copy all .config/.claude/ artifacts into whatever project they're working on, providing full portability without depending on global ~/.claude/ configuration. This revision ensures ~/.claude/commands/, ~/.claude/agents/, and ~/.claude/hooks/ are completely empty to avoid conflicts.

## Research Summary

Brief synthesis of key findings from research reports:

**Report 1 (Root Cause Analysis)**:
- 9 commands exist in BOTH user-level (~/.claude/commands/) and project-level (.config/.claude/commands/)
- User-level commands dated Oct 2, 2025; project commands dated Nov 12, 2025 (41 days newer)
- `/implement` project version has new features: --report-scope-drift, --create-pr, --dashboard, --dry-run
- Claude Code correctly displays all commands from all sources (working as designed, not a bug)

**Report 2 (Resume-Implement Lifecycle)**:
- `/resume-implement` was custom project command, NOT built-in to Claude Code
- Intentionally deleted Oct 7, 2025 (commit 5f754bd1) as duplicate functionality
- Functionality merged into `/implement` auto-resume feature
- Persists in user-level commands despite project deletion
- 45+ stale references in archived spec files

**Report 3 (Enumeration Architecture)**:
- Claude Code enumerates from 5 sources: built-in registry, project commands, user commands, plugin commands, MCP servers
- No deduplication logic - shows ALL variants with scope markers
- "Conflicts between user and project level commands are not supported" (official policy)
- Scope markers should indicate SOURCE, not create VARIANTS

**Recommended Approach**: Remove ALL user-level commands immediately (complete ~/.claude/ cleanup), implement detection/prevention to ensure ~/.claude/ stays empty, and maintain .config/.claude/ as single source of truth for portability via <leader>ac workflow.

## Success Criteria

- [ ] ALL commands removed from ~/.claude/commands/ (25 files → 0)
- [ ] ALL agents removed from ~/.claude/agents/ (9 files → 0)
- [ ] ALL hooks removed from ~/.claude/hooks/ (3 files → 0)
- [ ] ~/.claude/commands/, ~/.claude/agents/, ~/.claude/hooks/ directories are empty or removed
- [ ] Dropdown shows /implement exactly 1 time (.config/.claude/ version only)
- [ ] Dropdown does NOT show /resume-implement
- [ ] All /implement features work (--report-scope-drift, --create-pr, --dashboard, --dry-run)
- [ ] All .config/.claude/ artifacts remain intact (20 commands, 34 agents, 4 hooks)
- [ ] Agent invocations use only .config/.claude/ agents (no duplicates)
- [ ] Hooks execute once per event (no double-execution)
- [ ] Backup created before deletion (rollback capability if needed)
- [ ] Documentation updated with complete removal rationale (<leader>ac portability workflow)

## Technical Design

### Architecture Overview

The solution operates at the **user filesystem level**, not within Claude Code itself. We completely clean three ~/.claude/ subdirectories to establish .config/.claude/ as the single source of truth for portability:

```
┌───────────────────────────────────────────────────────────────┐
│         Claude Code Discovery (Commands, Agents, Hooks)       │
│         (Unmodified - shows all from all sources)             │
└───────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────────────────────┐
    │ Built-in │   │ User     │   │ Project                  │
    │ Registry │   │ Level    │   │ Level                    │
    │ (~50)    │   │ (EMPTY)  │   │ (Authoritative)          │
    └──────────┘   └──────────┘   └──────────────────────────┘
                         │               │
                    [PHASE 1-3]     [Unchanged]
                    Remove ALL      Single source
                    artifacts:      of truth:
                    - 25 commands   - 20 commands
                    - 9 agents      - 34 agents
                    - 3 hooks       - 4 hooks
                         │               │
                         └───────┬───────┘
                                 ▼
                      ┌──────────────────────────┐
                      │ Unique Artifacts         │
                      │ (From .config only)      │
                      │ - No command duplicates  │
                      │ - No agent duplicates    │
                      │ - No hook conflicts      │
                      └──────────────────────────┘
                                 │
                          <leader>ac copies
                          all artifacts
                                 │
                                 ▼
                      ┌──────────────────────────┐
                      │ Any Project              │
                      │ (Fully portable setup)   │
                      └──────────────────────────┘
```

### Component Interactions

**Phase 1: Audit and Backup**
- Document ALL artifacts in ~/.claude/: 25 commands, 9 agents, 3 hooks
- Verify .config/.claude/ is complete: 20 commands, 34 agents, 4 hooks
- Create timestamped backup of entire ~/.claude/ directory

**Phase 2: Complete Removal**
- Remove ALL commands from ~/.claude/commands/ (25 files → 0)
- Remove ALL agents from ~/.claude/agents/ (9 files → 0)
- Remove ALL hooks from ~/.claude/hooks/ (3 files → 0)
- Optionally remove directories entirely
- Verify .config/.claude/ artifacts remain intact

**Phase 3: Verification**
- Restart Claude Code to refresh cache
- Test dropdown shows single entry per command (all from .config/.claude/)
- Test agent invocations use only .config/.claude/ agents
- Test hooks execute once per event (no double-execution)
- Verify all features work correctly

**Phase 4: Documentation**
- Document complete removal rationale (<leader>ac portability workflow)
- Update CLAUDE.md with .config/.claude/ priority approach
- Document agent and hook cleanup benefits
- Document <leader>ac workflow for project portability

### Risk Mitigation

**Risk 1: Loss of unique user-level customizations**
- Mitigation: Complete backup of ~/.claude/ before removal, audit phase documents all files
- Rollback: Full restore from timestamped backup if needed
- Note: User confirms .config/.claude/ contains all needed commands

**Risk 2: Claude Code caching prevents immediate cleanup visibility**
- Mitigation: Document manual cache clear procedure
- Testing: Restart Claude Code after cleanup to refresh command list

**Risk 3: Breaking <leader>ac workflow if .config/.claude/ incomplete**
- Mitigation: Verify .config/.claude/ completeness in Phase 1 before any deletion
- Prevention: Test <leader>ac copy operation works correctly

## Implementation Phases

### Phase 1: Audit and Backup [COMPLETED]
dependencies: []

**Objective**: Document all user-level artifacts (commands, agents, hooks) and create complete backup before removal
**Complexity**: Low
**Expected Duration**: 25 minutes

Tasks:
- [x] List ALL commands in ~/.claude/commands/ and save to audit log (file: /tmp/user-commands-audit.txt) - expect ~25 files
- [x] List ALL agents in ~/.claude/agents/ and save to audit log (file: /tmp/user-agents-audit.txt) - expect 9 files
- [x] List ALL hooks in ~/.claude/hooks/ and save to audit log (file: /tmp/user-hooks-audit.txt) - expect 3 files
- [x] List all commands in .config/.claude/commands/ and save to audit log (file: /tmp/project-commands-audit.txt) - expect 20 files
- [x] List all agents in .config/.claude/agents/ and save to audit log (file: /tmp/project-agents-audit.txt) - expect 34 files
- [x] List all hooks in .config/.claude/hooks/ and save to audit log (file: /tmp/project-hooks-audit.txt) - expect 4 files
- [x] Verify .config/.claude/ contains all essential artifacts needed for workflow
- [x] Create timestamped backup of ENTIRE ~/.claude/ directory: ~/.claude.backup-$(date +%Y%m%d-%H%M%S)
- [x] Verify backup integrity (file count matches, sizes match)
- [x] Document backup location and artifact counts in cleanup log (file: /tmp/cleanup-log.txt)
- [x] Confirm user approval to proceed with complete ~/.claude/ cleanup (37 files total)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify backup created successfully
ls -la ~/.claude.backup-*
# Verify file count matches original
ORIGINAL_COUNT=$(find ~/.claude -type f | wc -l)
BACKUP_COUNT=$(find ~/.claude.backup-* -type f | wc -l)
test "$ORIGINAL_COUNT" -eq "$BACKUP_COUNT" && echo "✓ Backup complete"
```

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(720): complete Phase 1 - Audit and Backup`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Complete Removal of ~/.claude/ Artifacts [COMPLETED]
dependencies: [1]

**Objective**: Remove ALL commands, agents, and hooks from ~/.claude/ to establish .config/.claude/ as single source
**Complexity**: Low
**Expected Duration**: 20 minutes

Tasks:
- [x] Remove ALL .md files from ~/.claude/commands/: rm ~/.claude/commands/*.md (25 files)
- [x] Remove ALL .md files from ~/.claude/agents/: rm ~/.claude/agents/*.md (9 files)
- [x] Remove ALL .sh files from ~/.claude/hooks/: rm ~/.claude/hooks/*.sh (3 files)
- [x] Optionally remove directories entirely: rm -rf ~/.claude/commands/ ~/.claude/agents/ ~/.claude/hooks/
- [x] Verify ~/.claude/commands/ is empty or removed
- [x] Verify ~/.claude/agents/ is empty or removed
- [x] Verify ~/.claude/hooks/ is empty or removed
- [x] Verify .config/.claude/commands/ remains intact with all 20 commands
- [x] Verify .config/.claude/agents/ remains intact with all 34 agents
- [x] Verify .config/.claude/hooks/ remains intact with all 4 hooks
- [x] Document removal in cleanup log: 37 total files removed (25 commands + 9 agents + 3 hooks)
- [x] Confirm duplicates will be eliminated upon Claude Code restart

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify all three directories empty or removed
test ! -d ~/.claude/commands/ && echo "✓ Commands directory removed" || \
  (test -z "$(ls -A ~/.claude/commands/)" && echo "✓ Commands empty")
test ! -d ~/.claude/agents/ && echo "✓ Agents directory removed" || \
  (test -z "$(ls -A ~/.claude/agents/)" && echo "✓ Agents empty")
test ! -d ~/.claude/hooks/ && echo "✓ Hooks directory removed" || \
  (test -z "$(ls -A ~/.claude/hooks/)" && echo "✓ Hooks empty")

# Verify .config/.claude/ intact
test -f .config/.claude/commands/implement.md && echo "✓ Project commands intact"
test -f .config/.claude/agents/plan-architect.md && echo "✓ Project agents intact"
test -f .config/.claude/hooks/post-command-metrics.sh && echo "✓ Project hooks intact"

# Count files
echo "Commands: $(ls .config/.claude/commands/*.md 2>/dev/null | wc -l) (expect 20)"
echo "Agents: $(find .config/.claude/agents -name '*.md' 2>/dev/null | wc -l) (expect 34)"
echo "Hooks: $(ls .config/.claude/hooks/*.sh 2>/dev/null | wc -l) (expect 4)"
```

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(720): complete Phase 2 - Complete Removal of ~/.claude/ Artifacts`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: Verify Dropdown, Agent Invocations, and Hook Execution
dependencies: [2]

**Objective**: Confirm dropdown shows single entries, agents work correctly, and hooks execute once
**Complexity**: Low
**Expected Duration**: 35 minutes

Tasks:
- [ ] Restart Claude Code to refresh cache (commands, agents, hooks)
- [ ] Type /im in dropdown and verify exactly 1 /implement entry (from .config/.claude/)
- [ ] Verify /implement description matches project version (includes --report-scope-drift mention)
- [ ] Verify /resume-implement does NOT appear in dropdown
- [ ] Test /implement functionality with auto-resume (invoke without arguments)
- [ ] Test /implement with new flags: --dry-run, --dashboard, --create-pr
- [ ] Verify all other commands show once: /debug, /document, /plan, /test, /test-all, etc.
- [ ] Confirm no (user) scope markers appear for any commands
- [ ] Test agent invocation uses .config/.claude/agents/ only (invoke /plan or /research to trigger agents)
- [ ] Verify post-command-metrics hook executes exactly once per command (check logs)
- [ ] Verify tts-dispatcher hook executes exactly once per TTS event (check logs)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Manual testing in Claude Code UI:
# 1. Type /im → Should see single /implement entry with (project) marker only
# 2. Type /res → Should NOT see /resume-implement
# 3. Type /deb → Should see single /debug entry
# 4. Invoke: /implement --help (verify command works)
# 5. Check for any (user) markers → Should be none
# 6. Invoke: /plan "test feature" (verify agents from .config/.claude/ used)
# 7. Check logs for hook execution counts (should be 1× per event)
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(720): complete Phase 3 - Verify Dropdown, Agent Invocations, and Hook Execution`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Update Documentation for Complete Cleanup Workflow [COMPLETED]
dependencies: [3]

**Objective**: Document complete removal rationale (commands, agents, hooks) and <leader>ac portability workflow
**Complexity**: Medium
**Expected Duration**: 1.5 hours

Tasks:
- [x] Update .claude/docs/troubleshooting/duplicate-commands.md with complete cleanup case study (all three directories)
- [x] Document <leader>ac portability workflow in main CLAUDE.md
- [x] Add section explaining .config/.claude/ priority over ~/.claude/ for all artifact types
- [x] Document why ~/.claude/ is kept empty (portability via <leader>ac for commands, agents, hooks)
- [x] Document agent duplication issues and resolution
- [x] Document hook duplication/conflict issues and resolution
- [x] Add rollback procedure to troubleshooting guide (restore from backup if needed)
- [x] Create cleanup procedure documentation with step-by-step instructions for all three directories
- [x] Update project-specific commands section with portability notes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

Testing:
```bash
# Verify documentation updated
grep -q "leader.*ac" .claude/docs/troubleshooting/duplicate-commands.md && echo "✓ Portability workflow documented"
grep -q "config/.claude/" CLAUDE.md && echo "✓ Priority approach documented"
grep -q "agents" .claude/docs/troubleshooting/duplicate-commands.md && echo "✓ Agent cleanup documented"
grep -q "hooks" .claude/docs/troubleshooting/duplicate-commands.md && echo "✓ Hook cleanup documented"
# Verify rollback procedure exists
grep -q "rollback\|restore.*backup" .claude/docs/troubleshooting/duplicate-commands.md && echo "✓ Rollback documented"
```

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(720): complete Phase 4 - Update Documentation for Complete Cleanup Workflow`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

## Testing Strategy

### Pre-Cleanup Testing
- Verify current state: Count duplicate entries in dropdown (expect 4× /implement)
- Document current user artifact counts:
  - Commands: `ls ~/.claude/commands/*.md | wc -l` (expect ~25)
  - Agents: `ls ~/.claude/agents/*.md | wc -l` (expect 9)
  - Hooks: `ls ~/.claude/hooks/*.sh | wc -l` (expect 3)
- Document current project artifact counts:
  - Commands: `ls .config/.claude/commands/*.md | wc -l` (expect 20)
  - Agents: `find .config/.claude/agents -name '*.md' | wc -l` (expect 34)
  - Hooks: `ls .config/.claude/hooks/*.sh | wc -l` (expect 4)
- Save dropdown screenshot showing duplicates with (user) and (project) markers

### Post-Cleanup Testing
- Verify ~/.claude/commands/ is empty or removed
- Verify ~/.claude/agents/ is empty or removed
- Verify ~/.claude/hooks/ is empty or removed
- Verify dropdown shows single entry per command (visual inspection)
- Verify NO (user) scope markers appear
- Verify all command functionality works (test key commands)
- Verify agent invocations use .config/.claude/ agents only
- Verify hooks execute exactly once per event
- Run detection script to confirm all three directories stay empty

### Regression Testing
- Test all 20 .config/.claude/ commands still appear in dropdown
- Test all 34 .config/.claude/ agents available for invocation
- Test all 4 .config/.claude/ hooks execute correctly
- Verify each command/agent/hook appears exactly once
- Verify descriptions match project versions
- Test critical commands: /implement, /plan, /test-all, /coordinate
- Test critical agents: plan-architect, research-specialist, implementer-coordinator

### Automated Testing
- Manual periodic checks to verify directories stay empty (no automated detection)
- Add manual verification to monthly maintenance checklist

## Documentation Requirements

### Files to Update

1. **.claude/docs/troubleshooting/duplicate-commands.md**
   - Add complete removal case study (successor to /setup case study)
   - Document rationale: portability via <leader>ac workflow
   - Include complete removal procedure with exact bash commands
   - Add rollback instructions (restore from backup)

2. **Main CLAUDE.md**
   - Add section documenting <leader>ac portability workflow
   - Explain .config/.claude/ priority over ~/.claude/
   - Document why ~/.claude/ is kept empty
   - Add command discovery hierarchy with .config priority
   - Link to troubleshooting guide

3. **Portability Workflow Guide**
   - Document <leader>ac mapping and usage
   - Explain how .config/.claude/ gets copied to projects
   - Benefits of single-source approach
   - Maintenance strategy (keep ~/.claude/ empty)

### Documentation Standards
- Follow CommonMark specification
- Use code blocks with bash syntax highlighting
- Include before/after examples
- Document all file paths as absolute
- No historical commentary (present-focused)

## Dependencies

### External Dependencies
- Claude Code v2.0.42+ (current version supports command enumeration)
- bash 4.0+ (for comm -12 command and associative arrays)
- git (for commits and version control)

### Internal Dependencies
- .config/.claude/commands/ directory (project commands - authoritative source)
- ~/.claude/commands/ directory (user commands - to be cleaned)
- Testing framework from CLAUDE.md
- Troubleshooting guide template

### Prerequisite Knowledge
- Understanding of Claude Code's command discovery process (5 sources)
- Familiarity with user vs project command hierarchy
- bash scripting for detection script
- Git workflow for committing changes

## Rollback Procedure

If issues arise after complete ~/.claude/ removal:

1. **Full Rollback** (restore entire ~/.claude/ directory):
   ```bash
   # Restore complete backup
   cp -r ~/.claude.backup-YYYYMMDD-HHMMSS ~/.claude
   # Restart Claude Code
   # All user-level commands will reappear (duplicates return)
   ```

2. **Partial Rollback** (restore single command if truly needed):
   ```bash
   # Restore specific command only
   mkdir -p ~/.claude/commands/
   cp ~/.claude.backup-YYYYMMDD-HHMMSS/commands/implement.md ~/.claude/commands/
   # Note: This will recreate duplicates for that command
   ```

3. **Verification After Rollback**:
   - Confirm restored commands appear in dropdown
   - Test command functionality
   - Note: Duplicates will return if user-level commands restored

## Future Enhancements (Out of Scope)

The following improvements require Claude Code product team changes:

1. **Priority-Based Deduplication** (Claude Code internal)
   - Implement priority hierarchy: user > project > built-in
   - Show single command entry with highest priority source
   - Hide lower-priority duplicates

2. **Cache Invalidation** (Claude Code internal)
   - Detect file system changes in command directories
   - Auto-refresh command list on changes
   - Clear stale entries when files deleted

3. **Centralized Command Registry** (Claude Code architecture)
   - JSON registry with command metadata
   - Lifecycle states (active, deprecated, removed)
   - Replacement tracking for deprecated commands

4. **CLAUDE.md Reference Filtering** (Claude Code parser)
   - Distinguish command invocations from documentation references
   - Stop parsing archived spec files as command sources
   - Validate consistency between CLAUDE.md and actual commands

These enhancements are documented in research reports for future consideration by Claude Code team.

## Revision History

### Revision 3 (2025-11-15)
**Changes**: Removed detection script phase to keep implementation simple
**Reason**: User requested simplification - avoid adding automated detection scripts for now
**Modified Phases**:
- Removed Phase 4 (Create Multi-Directory Detection Script) entirely
- Renumbered Phase 5 → Phase 4 (Documentation)
- Updated testing strategy to use manual periodic checks instead of automated script
- Removed detection script from success criteria

**Impact**: Reduced complexity from 31.0 to 24.0, reduced time from 5.0h to 3.5h (simpler approach)
- Reduced from 5 phases to 4 phases
- Removed 10 detection script tasks
- Simpler maintenance with manual verification

### Revision 2 (2025-11-15)
**Changes**: Expanded scope from commands-only to include agents and hooks cleanup
**Reason**: User identified duplicate agents (9 files) and hooks (3 files) causing same issues as command duplicates. Complete cleanup needed for full portability.
**Modified Phases**:
- Phase 1: Added agents and hooks to audit (37 total files vs 25)
- Phase 2: Added agents and hooks removal (rm agents/*.md, hooks/*.sh)
- Phase 3: Added agent invocation and hook execution verification
- Phase 4: Updated detection script to check all three directories
- Phase 5: Added agent and hook cleanup documentation

**Impact**: Increased complexity from 28.0 to 31.0, increased time from 4.5h to 5.0h (more thorough cleanup)

**Files Affected**:
- Commands: 25 user files → 0
- Agents: 9 user files → 0
- Hooks: 3 user files → 0
- Total: 37 files removed from ~/.claude/

### Revision 1 (2025-11-15)
**Changes**: Complete scope revision from selective duplicate removal to full ~/.claude/ cleanup
**Reason**: User employs <leader>ac portability workflow, copying .config/.claude/ to projects. Requires ~/.claude/ to be completely empty to avoid conflicts.
**Modified Phases**:
- Phase 1: Changed from selective duplicate audit to complete directory backup
- Phase 2: Changed from comparison/analysis to complete removal of ALL commands
- Phase 3: Renamed from "Remove Duplicates" to "Verify Dropdown and Functionality"
- Phase 4: Changed detection script from duplicate finder to empty-directory validator
- Phase 5: Updated documentation to focus on portability workflow and complete removal rationale

**Impact**: Reduced complexity from 32.5 to 28.0, reduced time from 6h to 4.5h (simpler approach)

## Notes

**Complexity Calculation** (Revision 3):
```
Score = Base(enhance) + Tasks/2 + Files*3 + Integrations*5
Score = 7 + (31/2) + (3*3) + (0*5)
Score = 7 + 15.5 + 9 + 0 = 24.0
```
- 31 tasks across 4 phases (reduced from 41 in Rev 2)
- 3 file types modified (audit logs, cleanup log, docs - no detection script)
- 0 integrations (no test suite integration, manual checks only)

**Why Complete Removal (Commands, Agents, Hooks)**:
- **User workflow**: <leader>ac copies .config/.claude/ to projects for portability
- **Single source of truth**: .config/.claude/ is authoritative, version-controlled
- **Eliminates conflicts**: No user/project overlap possible for any artifact type
- **Simpler approach**: Remove all vs. selective comparison and merging
- **Manual verification**: Periodic checks instead of automated scripts (simpler maintenance)
- **Aligns with workflow**: User doesn't need ~/.claude/ for global access
- **Agent benefits**: Ensures consistent agent versions across all invocations
- **Hook benefits**: Prevents double-execution and conflicting behavior

**Related Work**:
- Spec 1763163004: Previous /setup command duplication fix (selective approach)
- Spec 718: Original dropdown investigation (led to this plan)
- This plan (Rev 1): Complete commands removal for portability
- This plan (Rev 2): Extended to agents and hooks for comprehensive cleanup
