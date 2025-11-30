# Buffer Hook Integration Reversion Analysis

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Complete analysis of buffer-hook integration changes to create systematic removal plan
- **Report Type**: Codebase analysis and reversion planning
- **Related Specs**:
  - 978_research_buffer_hook_integration
  - 975_hook_buffer_opening_issue
  - 851_001_buffer_opening_integration_planmd_the_claude

## Executive Summary

The buffer-hook integration was implemented across three sequential plans (851, 975, 978) to automatically open workflow artifacts in Neovim after command completion. The implementation added a post-buffer-opener.sh hook, modified the hooks README, and affected no /research command logic directly. Reverting this feature requires removing the hook file, updating hook registration, removing hook README documentation, and cleaning up debug/diagnostic files. The /research command itself requires no changes as it was never modified for buffer-hook integration - it already emitted REPORT_CREATED signals before the hook existed.

## Findings

### 1. Buffer Hook Implementation Timeline

**Plan 851** (2025-11-20): Initial hook-based buffer opening implementation
- Created `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` (NEW FILE)
- Added hook registration in `.claude/settings.local.json`
- Created Neovim buffer-opener module (not in scope for this reversion)
- Status: COMPLETE

**Plan 975** (2025-11-29): Hook timing race condition fix
- Modified `post-buffer-opener.sh` to add 300ms delay (BUFFER_OPENER_DELAY)
- Added diagnostic terminal output dump
- Added Block execution markers check
- Status: COMPLETE

**Plan 978** (2025-11-29): ANSI code stripping for signal extraction
- Modified `post-buffer-opener.sh` to add `strip_ansi()` function
- Added `extract_signal_path()` helper with fallback patterns
- Updated all signal extraction to use cleaned output
- Status: COMPLETE

### 2. Files Modified by Buffer Hook Integration

#### Critical Files (Must Revert)

1. **`.claude/hooks/post-buffer-opener.sh`** (NEW FILE - REMOVE ENTIRELY)
   - Line count: 323 lines
   - Created: Plan 851
   - Modified: Plans 975, 978
   - Action: DELETE FILE
   - Git command: `git rm .claude/hooks/post-buffer-opener.sh`

2. **`.claude/hooks/README.md`** (MODIFIED - PARTIAL REVERT)
   - Lines modified: Approximately 6 lines added in Phase 3 of Plan 978
   - Section: "### post-buffer-opener.sh" entry added
   - Location: After existing hook documentation (lines ~50-56 based on current structure)
   - Action: REMOVE post-buffer-opener.sh section only
   - Preserve: All other hook documentation (post-command-metrics.sh, tts-dispatcher.sh, post-subagent-metrics.sh)

3. **`.claude/settings.local.json`** (MODIFIED - PARTIAL REVERT)
   - Section: `hooks.Stop` array
   - Entry added: Hook registration for post-buffer-opener.sh
   - Action: REMOVE hook entry from hooks.Stop array
   - Preserve: All other hook registrations

#### Temporary/Debug Files (Cleanup)

4. **`.claude/tmp/buffer-opener-debug.log`** (EPHEMERAL - DELETE IF EXISTS)
   - Created when: BUFFER_OPENER_DEBUG=true
   - Contains: Debug logging from hook execution
   - Action: DELETE if present
   - Command: `rm -f .claude/tmp/buffer-opener-debug.log`

#### Files NOT Modified (No Action Needed)

5. **`.claude/commands/research.md`** (UNCHANGED)
   - Confirmation: File already emitted `REPORT_CREATED` signal in Block 2 (lines 690-698) BEFORE buffer hook existed
   - Signal output logic: Pre-existing, not added for buffer hook
   - Action: NO CHANGES NEEDED
   - Evidence: Signal was part of original research command design, hook consumed existing signals

6. **`.claude/agents/research-specialist.md`** (UNCHANGED)
   - Confirmation: Agent already returned `REPORT_CREATED: [path]` signal BEFORE buffer hook
   - Action: NO CHANGES NEEDED
   - Evidence: Research specialist agent protocol predates buffer hook implementation

7. **`.claude/lib/` libraries** (UNCHANGED)
   - No library files modified by buffer hook implementation
   - Action: NO CHANGES NEEDED

8. **Other workflow commands** (UNCHANGED)
   - `/plan`, `/build`, `/debug`, `/repair`, `/revise`, `/optimize-claude`, `/errors`
   - All already emitted completion signals before buffer hook
   - Action: NO CHANGES NEEDED

### 3. Git History Analysis

**Recent commits related to buffer hook** (from git log):
```
754f84f0 update (2025-11-29) - Most recent commit, likely contains Plan 978 changes
```

**Pre-buffer-hook state**:
- The commit immediately before Plan 851 implementation (approximately 2025-11-20) represents the clean state
- Research command functionality existed unchanged since before buffer hook
- Completion signals (REPORT_CREATED, PLAN_CREATED) were part of original agent protocols

**Key insight**: The buffer hook was **purely additive** - it consumed existing signals but never modified command logic. Reverting only requires removing the hook infrastructure, not restoring command files.

### 4. Neovim Integration Files (Out of Scope)

The following Neovim-side files were created as part of Plan 851 but are **NOT in scope** for this reversion (they're Neovim configuration, not Claude Code):

- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua`
- Neovim hook registration in user's init.lua or plugin config

**Reason**: These files live in user's personal Neovim config (`nvim/` directory) and don't affect Claude Code functionality. User can choose to keep or remove them independently.

### 5. Hook Dependencies and Integration Points

**Hook Registration** (`.claude/settings.local.json`):
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-buffer-opener.sh"
      }
    ]
  }
}
```
- This entry must be removed to fully disable the hook
- Other Stop hooks (post-command-metrics.sh, post-subagent-metrics.sh) must be preserved

**Environment Variables Used**:
- `BUFFER_OPENER_ENABLED` (default: true) - Feature toggle
- `BUFFER_OPENER_DEBUG` (default: false) - Debug logging
- `BUFFER_OPENER_DELAY` (default: 0.3) - Terminal read delay

**No lingering effects**: After hook removal, these environment variables become unused and harmless.

### 6. Testing Requirements for Reversion

After reverting buffer hook integration, verify:

1. **Hook removal verified**:
   ```bash
   # Should return empty or not include post-buffer-opener.sh
   grep -r "post-buffer-opener" .claude/settings.local.json
   ```

2. **File deletion verified**:
   ```bash
   # Should return "No such file"
   ls -l .claude/hooks/post-buffer-opener.sh
   ```

3. **Research command still works**:
   ```bash
   # In Claude Code terminal
   /research "test reversion"
   # Should complete successfully, emit REPORT_CREATED signal (visible in output)
   # Should NOT automatically open buffer (expected after reversion)
   ```

4. **No errors in hook execution**:
   ```bash
   # Run any workflow command
   /plan "test"
   # Should complete without hook-related errors
   ```

5. **Other hooks still function**:
   ```bash
   # Metrics hook should still work
   # TTS hook should still work (if enabled)
   ```

### 7. Potential Issues and Mitigations

**Issue 1**: User might have `BUFFER_OPENER_ENABLED=false` already set
- **Impact**: Hook already disabled, removal is purely cleanup
- **Mitigation**: No user action needed, reversion completes cleanup

**Issue 2**: Debug log file might be large
- **Impact**: Disk space usage (typically < 1MB)
- **Mitigation**: Include in cleanup step, safe to delete

**Issue 3**: Settings.local.json might have custom formatting
- **Impact**: JSON structure must remain valid after hook entry removal
- **Mitigation**: Use JSON-aware editor or jq for safe removal

**Issue 4**: User might have workflows in progress
- **Impact**: Hooks execute on command completion, no state to corrupt
- **Mitigation**: Safe to remove anytime, hooks are stateless

## Recommendations

### Reversion Strategy (Recommended Approach)

**Phase 1: Disable Hook** (Safe, Reversible)
1. Set `BUFFER_OPENER_ENABLED=false` in environment
2. Test workflow commands to verify hook disabled
3. Confirms hook removal will have no functional impact

**Phase 2: Remove Hook Registration** (Disables Hook Execution)
1. Edit `.claude/settings.local.json`
2. Remove post-buffer-opener.sh entry from hooks.Stop array
3. Validate JSON syntax
4. Test workflow command to verify no hook execution

**Phase 3: Remove Hook File** (Cleanup)
1. Delete `.claude/hooks/post-buffer-opener.sh`
2. Delete `.claude/tmp/buffer-opener-debug.log` if present
3. Git stage and commit deletion

**Phase 4: Remove Documentation** (Final Cleanup)
1. Edit `.claude/hooks/README.md`
2. Remove post-buffer-opener.sh section (approximately lines 50-85)
3. Preserve all other hook documentation
4. Git stage and commit

**Phase 5: Verification** (Confirm Clean State)
1. Run `/research` command - should work normally, no auto-open
2. Check git status - should show only intentional deletions
3. Run other workflow commands - should work normally
4. Verify no hook-related errors in output

### Alternative: Archive Instead of Delete (Conservative Approach)

If uncertain about complete removal:

1. **Move to archive**:
   ```bash
   mkdir -p .claude/archive/buffer-hook-integration
   mv .claude/hooks/post-buffer-opener.sh .claude/archive/buffer-hook-integration/
   ```

2. **Keep documentation commented out**:
   ```markdown
   <!-- Archived: post-buffer-opener.sh
   Was used for automatic buffer opening in Neovim
   Archived: 2025-11-29
   -->
   ```

3. **Remove from settings.local.json** (still required to disable)

4. **Can restore later** if needed by reversing archive steps

### Git Workflow for Reversion

**Branch strategy**:
```bash
# Current branch: claud_ref (based on git status)
# Work directly on claud_ref or create reversion branch

# Option 1: Direct on claud_ref
git add -u  # Stage deletions
git commit -m "Revert buffer-hook integration - Remove post-buffer-opener.sh and cleanup"

# Option 2: Feature branch
git checkout -b revert/buffer-hook-integration
# ... make changes ...
git commit -m "Revert buffer-hook integration"
git checkout claud_ref
git merge revert/buffer-hook-integration
```

**Commit message template**:
```
Revert buffer-hook integration - Remove post-buffer-opener.sh

Remove automatic buffer opening feature implemented in Plans 851, 975, 978.
Restores /research command to pre-buffer-hook behavior where completion
signals are emitted but no automatic buffer opening occurs.

Changes:
- Delete .claude/hooks/post-buffer-opener.sh (323 lines)
- Remove hook registration from .claude/settings.local.json
- Remove post-buffer-opener.sh documentation from .claude/hooks/README.md
- Cleanup .claude/tmp/buffer-opener-debug.log

Related specs:
- spec/978_research_buffer_hook_integration (ANSI stripping)
- spec/975_hook_buffer_opening_issue (timing fix)
- spec/851_001_buffer_opening_integration_planmd_the_claude (initial implementation)

Reason for reversion: [To be provided by user]
```

### Documentation of Pre-Buffer-Hook State

The **pre-buffer-hook state** of the /research command is the **current state** - no changes needed:

**Block 2 (lines 690-698 of research.md)**:
```bash
# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
# Get most recent report from research directory
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi
```

**Comment update needed** (minor):
Line 691 currently says "Signal enables buffer-opener hook and orchestrator detection"
After reversion, update to: "Signal enables orchestrator detection and workflow coordination"

This is the **only** change needed to /research command - updating a comment to remove reference to removed hook.

## References

### Plans Analyzed
- [Plan 978: Buffer Hook Signal Extraction Fix](../978_research_buffer_hook_integration/plans/001-research-buffer-hook-integration-plan.md) - ANSI code stripping, completion
- [Plan 975: Hook Buffer Opening Fix](../975_hook_buffer_opening_issue/plans/001-hook-buffer-opening-issue-plan.md) - Timing race condition fix, completion
- [Plan 851: Hook-Based Buffer Opening](../851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md) - Initial implementation, completion

### Reports Analyzed
- [978 Implementation Summary](../978_research_buffer_hook_integration/summaries/001-implementation-summary.md) - Final implementation state
- [978 Buffer Hook Timing Analysis](../978_research_buffer_hook_integration/reports/001-buffer-hook-timing-analysis.md) - Root cause of ANSI issue
- [975 Implementation Summary](../975_hook_buffer_opening_issue/summaries/001-implementation-summary.md) - Timing fix details
- [975 Root Cause Analysis](../975_hook_buffer_opening_issue/reports/001-hook-buffer-opening-root-cause-analysis.md) - Stop hook timing discovery

### Files Modified (Verified Paths)
- `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` (line 1-323, DELETE)
- `/home/benjamin/.config/.claude/hooks/README.md` (lines ~50-85, PARTIAL REVERT)
- `/home/benjamin/.config/.claude/settings.local.json` (hooks.Stop array, REMOVE ENTRY)
- `/home/benjamin/.config/.claude/commands/research.md` (line 691, UPDATE COMMENT ONLY)

### Git References
- Last commit: 754f84f0 "update" (likely contains Plan 978 changes)
- Clean state: Commit immediately before Plan 851 implementation (~2025-11-20)
- Current branch: claud_ref (per git status)
