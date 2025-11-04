# Implementation Plan: Investigate and Fix /coordinate Bash Code Transformation

## Metadata
- **Date**: 2025-11-04
- **Revised**: 2025-11-04 (Aligned with .claude/docs/ standards, removed unnecessary complexity)
- **Feature**: Fix bash code transformation errors in /coordinate command
- **Type**: Bug Investigation and Fix
- **Complexity**: 3/10 (Investigation-first approach)
- **Estimated Time**: 1-2 hours
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `../reports/001_coordinate_bash_history_expansion_fixes/REVISED_FINDINGS.md`
  - `../QUICK_SUMMARY.md`

## Overview

The /coordinate command fails with bash code transformation errors (`${\!varname}`: bad substitution). The hypothesis is that Claude AI transforms bash code when extracting large (403-line) bash blocks from markdown files.

**CRITICAL INSIGHT**: Before implementing any solution, we must **confirm the root cause** through targeted testing. The "external script solution" may be unnecessary if the actual issue is different.

### Current Hypothesis
When Claude AI processes Phase 0's 403-line bash block in coordinate.md:
1. Extracts bash code from markdown
2. Transforms/escapes special characters including `!`
3. Passes transformed code to Bash tool
4. Bash receives `${\\!varname}` and fails

### Alternative Hypotheses
1. **Size threshold**: Claude AI may only transform bash blocks over a certain size
2. **Specific patterns**: Only certain bash patterns trigger transformation
3. **Markdown structure**: The issue may be specific to how the bash block is formatted in markdown
4. **Tool processing**: The Bash tool itself may be transforming the code

## Success Criteria
- [ ] Root cause definitively identified through testing
- [ ] Minimal fix applied (following .claude/ standards)
- [ ] /coordinate executes without transformation errors
- [ ] All workflow scopes work (research-only, research-and-plan, etc.)
- [ ] No performance regression
- [ ] No new complexity added to codebase

## Implementation Phases

### Phase 1: Root Cause Investigation
**Objective**: Identify the exact cause and minimal fix
**Complexity**: Low
**Estimated Time**: 30-45 minutes

**Investigation Strategy**:

1. **Test Hypothesis: Size Threshold**
   - Extract first 100 lines of Phase 0 bash block
   - Test in isolation to see if transformation occurs
   - If no error: Size is the issue
   - If error: Size is not the issue

2. **Test Hypothesis: Markdown Structure**
   - Check if bash block uses quoted delimiters
   - Test alternative markdown patterns
   - Try heredoc pattern within bash block

3. **Test Hypothesis: Specific Bash Patterns**
   - Create minimal reproduction with just indirect references
   - Test which specific patterns trigger transformation

Tasks:
- [ ] Create test file `/tmp/test_coordinate_transformation.md`: `test_file:1-50`
  ```markdown
  ---
  allowed-tools: Bash
  ---

  # Test Bash Code Transformation

  ## Test 1: Small Bash Block (50 lines)

  \```bash
  # Extract first 50 lines from coordinate.md Phase 0
  TEST_VAR="hello"
  var_name="TEST_VAR"
  result="${!var_name}"
  echo "Test result: $result"

  declare -A TEST_CACHE
  TEST_CACHE["key1"]="value1"
  for key in "${!TEST_CACHE[@]}"; do
    echo "Key: $key"
  done
  \```
  ```

- [ ] Test via SlashCommand tool to trigger markdown processing: `test:slash_command`
  ```bash
  # This requires manual testing - invoke the test command via Claude Code
  # Expected: If transformation happens, we'll see the error
  # If no error: Small blocks work, size is the issue
  ```

- [ ] If small block works, find size threshold: `test:size_threshold`
  ```bash
  # Gradually increase bash block size: 100, 200, 300, 400 lines
  # Find the exact size where transformation begins
  ```

- [ ] Test alternative patterns: `test:alternatives`
  ```bash
  # Pattern 1: Heredoc within bash block
  bash <<'EOF'
  TEST_VAR="hello"
  result="${!TEST_VAR}"
  echo "$result"
  EOF

  # Pattern 2: Source external file
  source /path/to/phase0-functions.sh
  run_phase_0 "$1"

  # Pattern 3: Split into multiple smaller bash blocks
  ```

Testing:
```bash
# Manual testing required via Claude Code interface
# Document which patterns trigger transformation
# Identify minimal change needed to prevent transformation
```

Expected Outcome: Clear understanding of what triggers transformation and which approach prevents it with minimal code changes.

---

### Phase 2: Apply Minimal Fix
**Objective**: Implement the simplest fix that prevents transformation
**Complexity**: Low-Medium
**Estimated Time**: 30-60 minutes

**Fix Selection** (based on Phase 1 results):

**Option A: Split Large Bash Block** (if size is the issue)
- Split Phase 0 into 2-3 smaller bash blocks
- Keep all code in coordinate.md (no new files)
- Maintain existing architecture

**Option B: Heredoc Pattern** (if markdown structure is the issue)
- Wrap Phase 0 logic in heredoc with quoted delimiter
- Single bash block remains in coordinate.md
- No new files or directories

**Option C: Source External Functions** (only if A and B fail)
- Create `.claude/lib/coordinate-phase0-functions.sh`
- Source in coordinate.md and call functions
- Minimal external dependency

**IMPORTANT**: Do NOT create `.claude/lib/orchestration/` directory unless absolutely necessary. This breaks the existing pattern where commands contain inline bash blocks.

Tasks (for Option A - Split Bash Block):
- [ ] Identify logical split points in Phase 0: `coordinate.md:524-927`
  ```bash
  # Split 1: Lines 524-650 (~126 lines) - Project detection and library sourcing
  # Split 2: Lines 651-800 (~149 lines) - Path calculation
  # Split 3: Lines 801-927 (~126 lines) - Verification and completion
  ```

- [ ] Create backup of coordinate.md: `coordinate.md:backup`
  ```bash
  cp .claude/commands/coordinate.md \
     .claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)
  ```

- [ ] Update Phase 0 section with multiple bash blocks: `coordinate.md:522-927`
  ```markdown
  ### Implementation

  **EXECUTE NOW - Step 1: Project Detection and Library Sourcing**

  \```bash
  # [First ~126 lines of Phase 0]
  \```

  **EXECUTE NOW - Step 2: Path Calculation**

  \```bash
  # [Next ~149 lines of Phase 0]
  \```

  **EXECUTE NOW - Step 3: Verification**

  \```bash
  # [Final ~126 lines of Phase 0]
  \```
  ```

- [ ] Test /coordinate with split bash blocks: `coordinate:test`
  ```bash
  # Manual test via Claude Code
  # /coordinate "research authentication patterns"
  # Expected: No transformation errors
  ```

Tasks (for Option B - Heredoc Pattern):
- [ ] Wrap Phase 0 in heredoc: `coordinate.md:522-927`
  ```markdown
  \```bash
  bash <<'PHASE0_END'
  # [All 403 lines of Phase 0 code]
  PHASE0_END
  \```
  ```

- [ ] Test /coordinate with heredoc: `coordinate:test`

Tasks (for Option C - External Functions, if needed):
- [ ] Extract reusable functions to library file: `.claude/lib/coordinate-phase0-functions.sh`
  ```bash
  #!/usr/bin/env bash
  # Shared Phase 0 functions for /coordinate

  initialize_coordinate_phase0() {
    local workflow_description="$1"
    # [Phase 0 logic as functions]
  }
  ```

- [ ] Update coordinate.md to source and call functions: `coordinate.md:522-927`
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/coordinate-phase0-functions.sh"
  initialize_coordinate_phase0 "$1"
  ```

Testing:
```bash
# Test 1: Research-only workflow
# /coordinate "research authentication patterns"

# Test 2: Research-and-plan workflow
# /coordinate "research and plan authentication feature"

# Test 3: Verify no transformation errors
# Check console output for:
# - NO "!: command not found" errors
# - NO "bad substitution" errors
# - Phase 0 completion message present

# Test 4: Performance check
# Ensure Phase 0 still completes in <500ms
```

Expected: All tests pass, transformation errors eliminated with minimal code changes.

---

## Testing Strategy

### Regression Testing
Ensure no functionality loss:
- All 4 workflow scopes work correctly
- Library conditional loading still works
- Path pre-calculation still works
- Performance unchanged or improved

### Performance Validation
- Phase 0 execution time: Target ≤500ms (same as before)
- No additional subprocess overhead
- Library sourcing overhead unchanged

### Critical Path Testing
The primary fix validation:
1. ✓ No `!: command not found` errors
2. ✓ No `bad substitution` errors
3. ✓ All indirect variable references work: `${!varname}`, `${!array[@]}`
4. ✓ Phase 0 completion message appears

## Standards Compliance

### Command Architecture Standards
From `.claude/docs/reference/command_architecture_standards.md`:

✅ **Standard 0**: Imperative language for execution enforcement
- All "EXECUTE NOW" markers preserved
- Mandatory verification checkpoints maintained

✅ **Inline Execution**: Bash blocks remain in coordinate.md
- No external references during execution
- All code visible when command runs

✅ **Minimal Complexity**: Simplest fix that solves the problem
- No new directories unless absolutely necessary
- No redundant infrastructure

### Phase 0 Optimization Standards
From `.claude/docs/guides/phase-0-optimization.md`:

✅ **Library-based location detection**: Preserved
- No regression to agent-based detection
- Unified-location-detection.sh still used

✅ **Lazy directory creation**: Maintained
- Topic directory created, artifact dirs on-demand
- No directory pollution

✅ **Performance targets**: Met
- <1 second for location detection
- <500ms total for Phase 0

## Documentation Requirements

### Files to Update (Only if Option C is chosen)
- [ ] `.claude/lib/coordinate-phase0-functions.sh` - Create only if external functions needed
- [ ] `.claude/lib/README.md` - Document new library file only if created

### Git Commit Message
Following CLAUDE.md conventions:

**For Option A (Split Bash Blocks)**:
```
fix(coordinate): split Phase 0 into smaller bash blocks to prevent transformation

Split 403-line Phase 0 bash block into 3 smaller blocks (~126-149 lines each)
to prevent bash code transformation errors when Claude AI extracts code from
markdown. Fixes "!: command not found" and "bad substitution" errors.

All functionality preserved, no performance regression.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**For Option B (Heredoc Pattern)**:
```
fix(coordinate): wrap Phase 0 in heredoc to prevent bash code transformation

Use heredoc with quoted delimiter ('PHASE0_END') to prevent bash code
transformation when Claude AI extracts Phase 0 bash block from markdown.
Fixes "!: command not found" and "bad substitution" errors.

All functionality preserved, no performance regression.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**For Option C (External Functions)**:
```
fix(coordinate): extract Phase 0 functions to library file to prevent transformation

Move Phase 0 logic to .claude/lib/coordinate-phase0-functions.sh to prevent
bash code transformation when Claude AI processes large markdown bash blocks.
Fixes "!: command not found" and "bad substitution" errors.

All functionality preserved, follows existing library patterns.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Dependencies

### Prerequisites
- Bash 5.2+ (already satisfied)
- Existing library files in `.claude/lib/` (already present)
- Git (for CLAUDE_PROJECT_DIR detection)

### No New Dependencies
This fix uses existing infrastructure and adds minimal complexity.

## Risk Assessment

### Low Risk ✅
- **Investigation phase**: Testing is non-destructive
- **Backup created**: Original coordinate.md preserved
- **Rollback simple**: `cp coordinate.md.backup-* coordinate.md`

### Medium Risk ⚠️
- **Multiple bash blocks**: State must propagate between blocks (if Option A)
  - **Mitigation**: Test exports between blocks, verify WORKFLOW_SCOPE set
- **Heredoc nesting**: Potential quoting issues (if Option B)
  - **Mitigation**: Test carefully, verify all variables expand correctly

## Rollback Plan

If fix fails:

1. **Restore from backup**:
   ```bash
   cp .claude/commands/coordinate.md.backup-YYYYMMDD-HHMMSS \
      .claude/commands/coordinate.md
   ```

2. **Remove any created files** (if Option C used):
   ```bash
   rm .claude/lib/coordinate-phase0-functions.sh
   ```

3. **Verify restore**:
   ```bash
   git diff .claude/commands/coordinate.md
   ```

## Notes

### Why This Plan is Different

**Original Plan Issues**:
- Created new `.claude/lib/orchestration/` directory (breaks existing patterns)
- Added 400+ lines of external script (unnecessary complexity)
- Multiple verification checkpoints (over-engineered)
- 2-3 hours implementation time

**This Revised Plan**:
- Investigates root cause first (30-45 min)
- Applies minimal fix only after confirming cause (30-60 min)
- No new directories unless absolutely necessary
- Follows existing .claude/ patterns
- Total time: 1-2 hours

### Alignment with .claude/docs/

✅ **Command Architecture Standards**: Keeps bash blocks inline in command file
✅ **Phase 0 Optimization**: Preserves library-based location detection
✅ **No Unnecessary Complexity**: Simplest fix that works
✅ **Performance First**: No regression in execution time

### Why Investigation First Matters

The "external script solution" assumes:
1. Size is the issue (unconfirmed)
2. External scripts prevent transformation (unconfirmed)
3. Transformation always happens with large blocks (unconfirmed)

Without testing, we might:
- Create unnecessary infrastructure
- Add complexity that doesn't solve the problem
- Introduce new bugs or performance issues

**Investigation-first approach**:
- Confirms root cause through testing
- Identifies minimal fix
- Reduces implementation risk
- Follows scientific method

## Success Metrics

Implementation successful when:
1. ✅ Root cause identified through Phase 1 testing
2. ✅ Minimal fix applied in Phase 2
3. ✅ /coordinate executes without transformation errors
4. ✅ All 4 workflow types work correctly
5. ✅ Phase 0 performance ≤500ms
6. ✅ No new complexity added (unless necessary)
7. ✅ Standards compliance verified

## Revision History

### 2025-11-04 - Revision 1
**Changes**: Complete rewrite focusing on investigation-first approach
**Reason**: Original plan violated .claude/ standards by:
  - Creating new `.claude/lib/orchestration/` directory (no precedent)
  - Adding unnecessary complexity (external scripts, verification checkpoints)
  - Not investigating root cause first
  - Over-engineering the solution

**Modified Approach**:
- Phase 1: Investigate and confirm root cause (30-45 min)
- Phase 2: Apply minimal fix only after confirmation (30-60 min)
- Total: 1-2 hours vs 2-3 hours original

**Standards Alignment**:
- ✅ Command Architecture Standards (inline bash blocks)
- ✅ Phase 0 Optimization Guide (library-based detection)
- ✅ Minimal complexity principle
- ✅ No redundant infrastructure

## References

- **Diagnostic Report**: `.claude/specs/coordinate_diagnostic_report.md`
- **Revised Findings**: `../reports/001_coordinate_bash_history_expansion_fixes/REVISED_FINDINGS.md`
- **Console Outputs**: `.claude/specs/coordinate_output.md`
- **Command Architecture Standards**: `.claude/docs/reference/command_architecture_standards.md`
- **Phase 0 Optimization Guide**: `.claude/docs/guides/phase-0-optimization.md`
- **coordinate.md**: `.claude/commands/coordinate.md` (lines 522-927 affected)
