# Clean Up .claude Configuration

## Metadata
- **Date**: 2025-10-02
- **Feature**: Refactor .claude configuration for accuracy and minimal overhead
- **Scope**: Documentation updates, permission cleanup, unused infrastructure removal
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - specs/reports/021_claude_config_refactoring_analysis.md

## Overview

This plan addresses outdated documentation and removes unused infrastructure from the `.claude/` configuration directory, based on findings from the refactoring analysis report. The goal is a tight, clean configuration that accurately reflects the simplified TTS system (plan 016) without sacrificing well-implemented functionality.

**Key Changes**:
1. Update README.md to reflect simplified 2-category TTS system
2. Clean up bloated permission rules in settings.local.json
3. Remove unused session-start-restore.sh hook
4. Update documentation to remove state directory references

## Success Criteria
- [ ] README.md accurately describes simplified TTS system
- [ ] Permission rules use wildcards instead of hardcoded commit messages
- [ ] No references to unused session-start-restore.sh hook
- [ ] Documentation clarifies that state directory is optional/unused
- [ ] All existing functionality continues to work (metrics, TTS, hooks)
- [ ] Configuration is 400+ characters smaller (permissions cleanup)
- [ ] Code is 55 lines smaller (hook removal)

## Technical Design

### Current Issues
1. **Outdated TTS Documentation**: README describes 9-category system, but TTS was simplified to 2 categories with uniform "directory, branch" messages
2. **Bloated Permissions**: settings.local.json contains 400+ characters of hardcoded git commit messages
3. **Unused Hook**: session-start-restore.sh checks for `.claude/state/` directory that doesn't exist and provides no value

### Design Decisions
- **Phase 1 (Critical)**: Update docs and permissions first - high impact, low risk
- **Phase 2 (Cleanup)**: Remove unused infrastructure - medium impact, low risk
- **Phase 3 (Polish)**: Refine documentation - low impact, safe
- **Non-Breaking**: All changes are either documentation or removal of unused code
- **Testing**: Each phase includes validation that existing functionality still works

## Implementation Phases

### Phase 1: Critical Documentation and Permission Fixes
**Objective**: Update README.md to reflect simplified TTS system and clean up bloated permissions
**Complexity**: Low
**Duration**: ~20 minutes

Tasks:
- [x] Update TTS System section in `.claude/README.md:61-68`
  - Change "Categorized notifications with customizable voice characteristics" to "Uses uniform 'directory, branch' messages with single voice configuration"
  - Describe 2-category system (completion and permission)
- [x] Update Extension Points section in `.claude/README.md:154-158`
  - Remove "Adding TTS Categories" multi-step process
  - Replace with "Customizing TTS Messages" describing how to edit `get_context_prefix()` or adjust `TTS_VOICE_PARAMS`
- [x] Clean up permissions in `.claude/settings.local.json:6-7`
  - Replace two hardcoded git commit messages (400+ characters) with `Bash(git commit:*)`
  - Verify all other permission rules are still valid
- [x] Test that changes don't break functionality

Testing:
```bash
# Verify git commits still work
echo "test" > /tmp/test.txt && cd /tmp
git init test-repo && cd test-repo
git add /tmp/test.txt
git commit -m "test: verify commit permissions"
cd ~ && rm -rf /tmp/test-repo /tmp/test.txt

# Verify TTS still works
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | \
  .claude/hooks/tts-dispatcher.sh

# Verify metrics still collected
cat .claude/data/metrics/$(date +%Y-%m).jsonl | tail -1 | jq
```

Expected:
- Git commit succeeds without permission prompt
- TTS speaks "config, master" (or current directory, branch)
- Metrics file shows recent Stop event

### Phase 2: Remove Unused Infrastructure
**Objective**: Remove session-start-restore.sh hook and its registration
**Complexity**: Low
**Duration**: ~30 minutes

Tasks:
- [x] Remove `.claude/hooks/session-start-restore.sh` file
- [x] Remove SessionStart hook registration from `.claude/settings.local.json`
  - Delete entire SessionStart section (lines 36-46)
- [x] Update `.claude/README.md` to remove state directory references
  - Remove state directory from directory structure diagram (line 32)
  - Remove state directory from workflow lifecycle diagram if present
- [x] Update `.claude/hooks/README.md` to remove state file examples
  - Remove references to `STATE_FILE` and `.claude/state/` in examples
- [x] Test session start works without hook

Testing:
```bash
# Verify hook file removed
ls .claude/hooks/session-start-restore.sh 2>&1 | grep "No such file"

# Verify settings.local.json has no SessionStart
cat .claude/settings.local.json | jq '.hooks.SessionStart' | grep null

# Test session start (requires restarting Claude Code)
# Expected: Session starts normally without state restoration message
```

Expected:
- Hook file doesn't exist
- No SessionStart hook registered
- Session starts without errors
- No overhead from checking for non-existent state directory

### Phase 3: Documentation Refinement
**Objective**: Polish documentation for consistency and clarity
**Complexity**: Low
**Duration**: ~30 minutes

Tasks:
- [x] Update hook events documentation in `.claude/README.md:108-114`
  - Note which hooks have TTS (Stop, Notification)
  - Note which don't have TTS (SessionEnd, SubagentStop)
  - Clarify that SessionStart no longer has any hooks
- [x] Update workflow lifecycle diagram in `.claude/README.md:119-138`
  - Simplify to show only active hooks (Stop with metrics + TTS)
  - Remove any state directory references
- [x] Review `.claude/docs/` for any outdated state directory references
  - Check hook integration guide
  - Check TTS integration guide (already updated in plan 016)
- [x] Verify all navigation links still work

Testing:
```bash
# Check for any remaining state directory references
grep -r "\.claude/state" .claude/ --include="*.md" | \
  grep -v "specs/plans" | grep -v "specs/reports"

# Verify no broken links in READMEs
for readme in $(find .claude -name "README.md"); do
  echo "Checking $readme for broken links..."
  grep -o '\[.*\](.*\.md)' "$readme" || true
done
```

Expected:
- No state directory references in active documentation
- All README links point to valid files
- Documentation accurately reflects current implementation

## Testing Strategy

### Validation After Each Phase

**Phase 1 Validation**:
- Git operations work without permission prompts
- TTS notifications still speak "directory, branch"
- Metrics collection continues to work
- README accurately describes TTS as simplified 2-category system

**Phase 2 Validation**:
- Session start works normally without hook
- No errors in hook-debug.log about missing session-start-restore.sh
- README doesn't mention state directory in structure
- Hooks README doesn't have state file examples

**Phase 3 Validation**:
- All documentation is consistent
- Hook events section accurately describes which hooks have TTS
- No broken links in navigation
- No outdated references to removed functionality

### Regression Testing

After all phases complete, verify core functionality:
```bash
# 1. TTS notifications work
echo '{"hook_event_name":"Stop","status":"success","cwd":"'$(pwd)'"}' | \
  .claude/hooks/tts-dispatcher.sh

echo '{"hook_event_name":"Notification","message":"test"}' | \
  .claude/hooks/tts-dispatcher.sh

# 2. Metrics collection works
cat .claude/data/metrics/$(date +%Y-%m).jsonl | tail -3 | jq

# 3. Hooks execute properly
tail -10 .claude/data/logs/hook-debug.log

# 4. Permission rules allow git operations
git add .
git status
```

## Documentation Requirements

### Files Updated
- `.claude/README.md` - Main configuration documentation
  - TTS System section (lines 61-68)
  - Extension Points section (lines 154-158)
  - Hook events section (lines 108-114)
  - Workflow lifecycle diagram (lines 119-138)
  - Directory structure (line 32)

- `.claude/settings.local.json` - Configuration file (gitignored)
  - Permissions section (lines 6-7)
  - Hooks section (remove SessionStart)

- `.claude/hooks/README.md` - Hook documentation
  - Remove state file examples

### Commit Messages

**Phase 1 Commit**:
```
docs: update .claude docs for simplified TTS and clean permissions

Updated README.md to reflect 2-category TTS system (plan 016):
- TTS System section now describes uniform messages
- Extension Points simplified to message customization
- Removed outdated category addition instructions

Cleaned up permissions in settings.local.json:
- Replaced hardcoded git commit messages with Bash(git commit:*)
- Reduced permission rules by 400+ characters
- More maintainable wildcard pattern

Related: Plan 016 (TTS simplification)
Based on: Report 021 (refactoring analysis)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Phase 2 Commit**:
```
refactor: remove unused session-start-restore hook

Removed session-start-restore.sh hook that provided no value:
- .claude/state/ directory doesn't exist and was never needed
- Hook designed for checkpoints that were never implemented
- Exits immediately when directory missing
- Reduces session start overhead

Changes:
- Deleted .claude/hooks/session-start-restore.sh (55 lines)
- Removed SessionStart hook registration from settings.local.json
- Updated README.md to remove state directory references
- Updated hooks/README.md to remove state file examples

Based on: Report 021 (refactoring analysis)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Phase 3 Commit**:
```
docs: refine .claude documentation for clarity

Polished documentation to accurately reflect current implementation:
- Updated hook events section to note which hooks have TTS
- Simplified workflow lifecycle diagram
- Removed remaining state directory references
- Verified all navigation links work

Based on: Report 021 (refactoring analysis)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Dependencies

### Prerequisites
- Plan 016 (TTS simplification) must be completed
- Current `.claude/` configuration must be backed up if desired

### External Dependencies
None - all changes are self-contained within `.claude/` directory

### Tool Requirements
- `jq` for JSON manipulation (testing)
- `grep` for searching documentation
- Git for commits

## Risk Assessment

### Low Risk Changes
- **Documentation updates**: Safe, no functional impact
- **Permission cleanup**: Git commits already allowed via Safety Protocol
- **Hook removal**: Hook provides no value, already handles missing directory

### Mitigation Strategies
1. **Backup settings.local.json** before editing (gitignored file)
2. **Test after each phase** to catch issues early
3. **Validate git operations** before committing Phase 1
4. **Verify session start** after Phase 2 hook removal

### Rollback Plan
If issues occur:
- **Phase 1**: Restore original README.md and settings.local.json from git
- **Phase 2**: Restore session-start-restore.sh from git, re-add SessionStart hook
- **Phase 3**: Restore documentation from git

## Metrics

### Expected Improvements
- **Configuration size**: -400+ characters (permissions cleanup)
- **Code size**: -55 lines (hook removal)
- **Documentation accuracy**: 85% → 100%
- **Session start overhead**: Reduced (no state directory check)

### Success Metrics
- Zero broken links in documentation
- Zero errors in hook-debug.log after changes
- Git operations continue to work
- TTS notifications continue to work
- Metrics collection continues to work

## Notes

### Why This Matters
1. **Accuracy**: Documentation now reflects actual implementation
2. **Maintainability**: Wildcard permissions easier to maintain than hardcoded messages
3. **Performance**: Removing unused hook reduces session start overhead
4. **Cleanliness**: No references to infrastructure that doesn't exist

### Future Considerations
- If workflow checkpoints are needed in future, `.claude/state/` can be re-added
- Current cleanup makes configuration easier to understand and maintain
- Simplified TTS system (plan 016) is now fully documented

### Related Plans
- **Plan 016**: TTS simplification (completed)
- **Report 020**: TTS analysis (completed)
- **Report 021**: Configuration refactoring analysis (basis for this plan)
