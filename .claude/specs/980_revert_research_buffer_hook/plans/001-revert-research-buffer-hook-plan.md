# Buffer Hook Integration Reversion Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Systematic removal of buffer-hook integration
- **Scope**: Remove post-buffer-opener.sh hook, hook registration, documentation, and cleanup artifacts
- **Estimated Phases**: 5
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 25.0
- **Research Reports**:
  - [Buffer Hook Integration Reversion Analysis](../reports/001-buffer-hook-integration-reversion-analysis.md)

## Overview

Revert the automatic buffer-opening feature that was implemented across Plans 851, 975, and 978. The buffer hook integration automatically opened workflow artifacts in Neovim after command completion by consuming completion signals emitted by workflow commands. This feature is being removed to restore the /research command and other workflows to their pre-buffer-hook behavior where completion signals are emitted but no automatic buffer opening occurs.

**Key Insight**: The buffer hook was purely additive - it consumed existing signals but never modified command logic. Reverting requires only removing the hook infrastructure, not restoring any command files (which were never modified for the buffer hook).

## Research Summary

Analysis of Plans 851, 975, and 978 reveals:

1. **Implementation Scope**: The buffer hook feature created one new file (post-buffer-opener.sh), modified two existing files (hooks/README.md and settings.local.json), and potentially created ephemeral debug files. No workflow commands were modified - they already emitted completion signals before the buffer hook existed.

2. **Files Modified**:
   - NEW: `.claude/hooks/post-buffer-opener.sh` (323 lines) - Must delete entirely
   - MODIFIED: `.claude/hooks/README.md` (~35 lines added for post-buffer-opener.sh section) - Must remove section
   - MODIFIED: `.claude/settings.local.json` (hook registration added) - Must remove entry
   - EPHEMERAL: `.claude/tmp/buffer-opener-debug.log` (if exists) - Cleanup

3. **Files NOT Modified**:
   - `.claude/commands/research.md` - Already emitted REPORT_CREATED signal before buffer hook (line 691 comment references hook but signal logic unchanged)
   - `.claude/agents/research-specialist.md` - Already returned completion signals before buffer hook
   - All other workflow commands - Already emitted completion signals before buffer hook

4. **Reversion Strategy**: Five-phase approach starting with safe testing, proceeding through hook disabling, file removal, documentation cleanup, and final verification. Each phase includes specific testing steps to ensure clean state restoration.

## Success Criteria

- [ ] post-buffer-opener.sh file deleted and removal committed to git
- [ ] Hook registration removed from settings.local.json (JSON remains valid)
- [ ] post-buffer-opener.sh documentation removed from hooks/README.md
- [ ] Debug log file deleted (if present)
- [ ] Research command comment updated to remove buffer-hook reference
- [ ] /research command still works correctly (emits REPORT_CREATED signal)
- [ ] No automatic buffer opening occurs after workflow commands
- [ ] Other hooks (post-command-metrics.sh, tts-dispatcher.sh) still function correctly
- [ ] No hook-related errors in workflow command output
- [ ] Git status shows only intentional deletions and updates

## Technical Design

### Reversion Architecture

The buffer hook integration has three integration points that must be cleanly removed:

1. **Hook File**: `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`
   - Deletion: Use `git rm` to remove file and stage deletion
   - No dependencies: Hook is self-contained, no other files import it

2. **Hook Registration**: `/home/benjamin/.config/.claude/settings.local.json`
   - Edit strategy: Remove post-buffer-opener.sh entry from hooks.Stop array
   - Preserve: post-command-metrics.sh and tts-dispatcher.sh entries
   - Validation: JSON syntax must remain valid after removal

3. **Hook Documentation**: `/home/benjamin/.config/.claude/hooks/README.md`
   - Lines to remove: Approximately lines 221-359 (post-buffer-opener.sh section and subsections)
   - Preserve: All other hook documentation (post-command-metrics.sh, tts-dispatcher.sh, pre-commit-library-sourcing.sh)
   - Validation: README structure remains intact

4. **Comment Update**: `/home/benjamin/.config/.claude/commands/research.md`
   - Line 691: Change comment from "Signal enables buffer-opener hook and orchestrator detection"
   - To: "Signal enables orchestrator detection and workflow coordination"
   - Preserve: All signal emission logic (unchanged)

### Reversion Safety

**Testing Strategy**: Verify at each phase that:
- Removed components don't break remaining functionality
- Hook execution continues for non-removed hooks
- Workflow commands work normally
- No errors introduced

**Rollback Strategy**: Each phase is independently reversible:
- Phase 1: Environment variable can be unset
- Phase 2: Hook registration can be re-added to settings.local.json
- Phase 3: Files can be restored from git history
- Phase 4: Documentation can be restored from git history
- Phase 5: Verification has no destructive actions

## Implementation Phases

### Phase 1: Test Hook Disable (Safe Verification) [NOT STARTED]
dependencies: []

**Objective**: Verify that disabling the buffer hook has no negative functional impact on workflow commands

**Complexity**: Low

Tasks:
- [ ] Set environment variable `BUFFER_OPENER_ENABLED=false` in current shell
- [ ] Run `/research "test reversion"` command
- [ ] Verify research command completes successfully
- [ ] Verify REPORT_CREATED signal appears in output
- [ ] Verify no automatic buffer opening occurs (expected after disable)
- [ ] Verify no hook-related errors in output
- [ ] Run another workflow command (e.g., `/plan "test"`) to verify broader impact
- [ ] Document that hook disable has no functional issues

Testing:
```bash
# In Claude Code terminal
export BUFFER_OPENER_ENABLED=false
/research "test reversion disable"
# Expected: Command succeeds, signal visible, no auto-open, no errors

# Test another workflow
/plan "test plan disable"
# Expected: Command succeeds normally
```

Success Criteria:
- Research command completes without errors
- REPORT_CREATED signal visible in output
- No automatic buffer opening (expected)
- Other workflow commands unaffected

**Expected Duration**: 0.25 hours

---

### Phase 2: Remove Hook Registration [NOT STARTED]
dependencies: [1]

**Objective**: Disable hook execution by removing registration from settings.local.json

**Complexity**: Low

Tasks:
- [ ] Read current `.claude/settings.local.json` to identify hook entry location
- [ ] Create backup: `cp .claude/settings.local.json .claude/settings.local.json.backup.$(date +%Y%m%d_%H%M%S)`
- [ ] Edit `.claude/settings.local.json` to remove post-buffer-opener.sh entry from hooks.Stop array
- [ ] Preserve post-command-metrics.sh entry (line 43)
- [ ] Preserve tts-dispatcher.sh entry (line 47)
- [ ] Validate JSON syntax: `jq empty .claude/settings.local.json` (exits 0 if valid)
- [ ] Test workflow command to verify no hook execution errors
- [ ] Verify other hooks still execute (check metrics log update)

Testing:
```bash
# Validate JSON after edit
jq empty .claude/settings.local.json && echo "JSON valid" || echo "JSON INVALID"

# Test hook no longer executes
/research "test no hook execution"
# Expected: No hook execution, command succeeds

# Verify other hooks still work
ls -lt .claude/data/metrics/*.jsonl | head -1
# Expected: Recent metrics entry from command above
```

Success Criteria:
- Hook entry removed from settings.local.json
- JSON syntax valid (jq validation passes)
- Workflow commands execute without hook-related errors
- Other hooks (metrics, TTS) still function

**Expected Duration**: 0.25 hours

**Note**: After this phase, post-buffer-opener.sh will never execute again (even if file still exists), making subsequent deletion safe.

---

### Phase 3: Remove Hook File and Debug Artifacts [NOT STARTED]
dependencies: [2]

**Objective**: Delete post-buffer-opener.sh hook file and cleanup ephemeral debug files

**Complexity**: Low

Tasks:
- [ ] Verify hook file exists: `ls -l .claude/hooks/post-buffer-opener.sh`
- [ ] Delete hook file using git: `git rm .claude/hooks/post-buffer-opener.sh`
- [ ] Check for debug log: `ls -l .claude/tmp/buffer-opener-debug.log` (may not exist)
- [ ] Delete debug log if present: `rm -f .claude/tmp/buffer-opener-debug.log`
- [ ] Verify deletion: `ls .claude/hooks/post-buffer-opener.sh` should return "No such file"
- [ ] Git status should show deletion staged: `git status`
- [ ] Test workflow command to verify no errors from missing file
- [ ] Do NOT commit yet (will commit in Phase 5)

Testing:
```bash
# Verify deletion
ls .claude/hooks/post-buffer-opener.sh
# Expected: ls: cannot access ... No such file or directory

# Verify debug log cleaned up
ls .claude/tmp/buffer-opener-debug.log
# Expected: No such file (or file not found)

# Test command still works
/research "test after file removal"
# Expected: Command succeeds, no hook-related errors

# Check git staging
git status
# Expected: Shows "deleted: .claude/hooks/post-buffer-opener.sh"
```

Success Criteria:
- post-buffer-opener.sh file deleted
- Debug log file removed (if existed)
- File deletion staged in git
- Workflow commands execute without errors
- No references to deleted file in error logs

**Expected Duration**: 0.25 hours

---

### Phase 4: Remove Hook Documentation and Update Comments [NOT STARTED]
dependencies: [3]

**Objective**: Remove post-buffer-opener.sh documentation from hooks/README.md and update research.md comment

**Complexity**: Low

Tasks:
- [ ] Read `.claude/hooks/README.md` to identify post-buffer-opener.sh section
- [ ] Remove post-buffer-opener.sh section (lines ~221-359, entire section with subsections)
- [ ] Remove reference from "Example Hooks" list (line 52)
- [ ] Verify other hook documentation preserved (post-command-metrics.sh, tts-dispatcher.sh, pre-commit-library-sourcing.sh)
- [ ] Verify README structure remains intact (headings, examples, navigation)
- [ ] Read `.claude/commands/research.md` line 691
- [ ] Update comment from "Signal enables buffer-opener hook and orchestrator detection"
- [ ] To: "Signal enables orchestrator detection and workflow coordination"
- [ ] Verify README renders correctly (no broken markdown)
- [ ] Git add both changed files: `git add .claude/hooks/README.md .claude/commands/research.md`

Testing:
```bash
# Verify post-buffer-opener.sh removed from README
grep -n "post-buffer-opener" .claude/hooks/README.md
# Expected: No matches found

# Verify other hooks still documented
grep -n "post-command-metrics" .claude/hooks/README.md
# Expected: Matches found in documentation section

# Verify comment updated in research.md
grep -n "Signal enables" .claude/commands/research.md
# Expected: Shows line 691 with "orchestrator detection and workflow coordination"

# Check git staging
git status
# Expected: Shows modified README.md and research.md
```

Success Criteria:
- post-buffer-opener.sh section removed from README
- Reference removed from Example Hooks list
- Other hook documentation intact
- README markdown structure valid
- research.md comment updated
- Both files staged in git

**Expected Duration**: 0.5 hours

---

### Phase 5: Final Verification and Commit [NOT STARTED]
dependencies: [4]

**Objective**: Verify complete removal, confirm clean state, and commit reversion

**Complexity**: Low

Tasks:
- [ ] Run comprehensive verification tests
- [ ] Test /research command functionality: `/research "final verification test"`
- [ ] Verify REPORT_CREATED signal emitted (visible in output)
- [ ] Verify no automatic buffer opening occurs
- [ ] Test /plan command: `/plan "final verification test"`
- [ ] Test /build command on simple plan (if available)
- [ ] Verify no hook-related errors in any command output
- [ ] Verify other hooks still function (check metrics log, TTS if enabled)
- [ ] Check git status shows only intentional changes
- [ ] Review staged changes: `git diff --cached`
- [ ] Commit reversion with descriptive message
- [ ] Verify clean git status after commit

Testing:
```bash
# Comprehensive hook removal verification
grep -r "post-buffer-opener" .claude/settings.local.json
# Expected: No matches found

grep -r "post-buffer-opener" .claude/hooks/README.md
# Expected: No matches found

ls -l .claude/hooks/post-buffer-opener.sh
# Expected: No such file or directory

# Test workflow commands
/research "comprehensive final test"
# Expected: Succeeds, emits REPORT_CREATED, no auto-open, no errors

# Verify other hooks work
tail -1 .claude/data/metrics/*.jsonl
# Expected: Recent metrics entry

# Review and commit
git diff --cached
git status
# Expected: Shows deletions and modifications, clean working tree

# Commit with descriptive message
git commit -m "Revert buffer-hook integration

Remove automatic buffer opening feature from Plans 851, 975, 978.
Restores workflow commands to pre-buffer-hook behavior where
completion signals are emitted but no automatic buffer opening occurs.

Changes:
- Delete .claude/hooks/post-buffer-opener.sh (323 lines)
- Remove hook registration from .claude/settings.local.json
- Remove post-buffer-opener.sh docs from .claude/hooks/README.md
- Update research.md comment (remove buffer-hook reference)
- Cleanup .claude/tmp/buffer-opener-debug.log

Related specs:
- spec/978_research_buffer_hook_integration
- spec/975_hook_buffer_opening_issue
- spec/851_001_buffer_opening_integration_planmd_the_claude

Reason for reversion: User-requested systematic removal of buffer-hook features"

# Verify commit
git status
# Expected: "nothing to commit, working tree clean"

git log -1 --stat
# Expected: Shows commit with file changes
```

Success Criteria:
- All verification tests pass
- /research command works normally
- Completion signals still emitted by workflow commands
- No automatic buffer opening occurs
- Other hooks (metrics, TTS) still function
- Git status clean after commit
- Commit message documents reversion comprehensively

**Expected Duration**: 0.75 hours

---

## Testing Strategy

### Per-Phase Testing
Each phase includes specific test commands and success criteria. Phases are designed to be independently testable and reversible.

### Integration Testing
After Phase 5, verify complete system:
1. Run multiple workflow commands (/research, /plan, /build, /debug)
2. Verify completion signals still emitted (visible in output)
3. Verify no automatic buffer opening
4. Verify no hook-related errors
5. Verify other hooks still function (metrics, TTS)

### Regression Testing
Ensure reversion doesn't break existing functionality:
- Workflow commands execute normally
- Completion signals visible in output
- Metrics hook collects data
- TTS hook sends notifications (if enabled)
- Pre-commit hook validates code (if installed)

## Documentation Requirements

### Files to Update
1. `.claude/hooks/README.md` - Remove post-buffer-opener.sh section (Phase 4)
2. `.claude/commands/research.md` - Update comment to remove buffer-hook reference (Phase 4)

### Files NOT to Update
No new documentation files required. The reversion is documented in:
- This implementation plan
- Commit message (Phase 5)
- Research report that informed this plan

## Dependencies

### External Dependencies
- Git (for file removal and commit)
- jq (for JSON validation)
- Standard bash utilities (grep, ls, rm)

### File Dependencies
- `.claude/hooks/post-buffer-opener.sh` (will be deleted)
- `.claude/settings.local.json` (will be modified)
- `.claude/hooks/README.md` (will be modified)
- `.claude/commands/research.md` (will be modified - comment only)

### Hook Dependencies
No hook dependencies. Removal of post-buffer-opener.sh doesn't affect other hooks:
- post-command-metrics.sh (independent)
- tts-dispatcher.sh (independent)
- post-subagent-metrics.sh (independent)

## Risk Analysis

### Low Risk
- Hook removal is non-destructive (commands never modified for buffer hook)
- Phased approach allows testing at each step
- Each phase independently reversible
- Git history preserves all deleted files for rollback

### Mitigation Strategies
1. **JSON Syntax Error**: Use jq validation after editing settings.local.json
2. **Accidental Deletion**: Create backup of settings.local.json before editing
3. **Documentation Structure Break**: Verify README markdown after section removal
4. **Other Hook Breakage**: Test metrics hook after Phase 2 to ensure independence
5. **Workflow Command Issues**: Test /research and /plan after each phase

### Rollback Plan
If issues discovered during any phase:
1. Restore settings.local.json from backup (Phase 2)
2. Restore deleted files from git: `git checkout HEAD -- .claude/hooks/post-buffer-opener.sh`
3. Restore documentation from git: `git checkout HEAD -- .claude/hooks/README.md`
4. Re-add hook registration to settings.local.json
5. Test workflow commands to verify restoration

## Notes

### Neovim Integration Files
The following Neovim-side files are OUT OF SCOPE for this reversion (they live in user's personal Neovim config):
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua`
- Neovim hook registration in init.lua or plugin config

User can choose to keep or remove these files independently. They don't affect Claude Code functionality.

### Environment Variables
After reversion, these environment variables become unused but harmless:
- `BUFFER_OPENER_ENABLED` (default: true)
- `BUFFER_OPENER_DEBUG` (default: false)
- `BUFFER_OPENER_DELAY` (default: 0.3)

No action needed to unset them. They have no effect without the hook file.

### Pre-Buffer-Hook State
The /research command's "pre-buffer-hook state" is its CURRENT state. The command already emitted REPORT_CREATED signals before the buffer hook existed (since original design). The hook consumed these existing signals but never modified command logic. Only change needed is updating the comment on line 691.

### Git Branch
Current branch: claud_ref (based on git status from research report)
Reversion will be committed directly to claud_ref branch.
