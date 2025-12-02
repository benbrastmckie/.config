# TODO Command Invocation Fix Analysis

## Executive Summary

The `trigger_todo_update()` function in `.claude/lib/todo/todo-functions.sh` attempts to invoke the `/todo` command using `bash -c '/todo'`, which fails because `/todo` is a Claude Code slash command (markdown file) that must be invoked via the SlashCommand tool, not as a bash executable. This causes silent failures across 9 commands that rely on automatic TODO.md updates.

**Impact**: All commands using `trigger_todo_update()` fail to update TODO.md after creating/modifying artifacts, requiring manual `/todo` runs.

**Root Cause**: Architectural mismatch - trying to invoke a slash command (markdown file processed by Claude AI) as if it were a bash script.

## Problem Statement

### Current Broken Implementation

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`
**Function**: `trigger_todo_update()` (lines 1112-1132)

```bash
trigger_todo_update() {
  local reason="${1:-TODO.md update}"

  # Delegate to /todo command silently (suppress output)
  if bash -c "cd \"${CLAUDE_PROJECT_DIR}\" && /todo" >/dev/null 2>&1; then
    echo "✓ TODO.md updated: $reason"
    return 0
  else
    # Non-blocking: log warning but don't fail command
    echo "WARNING: Failed to update TODO.md ($reason)" >&2
    return 0  # Return success to avoid blocking parent command
  fi
}
```

**Why This Fails**:
1. `/todo` is NOT a bash command or executable in PATH
2. `/todo` is a slash command (`.claude/commands/todo.md` markdown file)
3. Slash commands are processed by Claude Code's SlashCommand tool
4. Attempting `bash -c '/todo'` results in "command not found"
5. Error is suppressed by `2>/dev/null`, causing silent failure
6. Success message prints regardless due to `return 0` in else block

### Affected Commands (9 Total)

All commands that create or modify plans/reports use `trigger_todo_update()`:

| Command | Usage Point | Expected Behavior | Current Behavior |
|---------|-------------|-------------------|------------------|
| `/build` | START (mark IN PROGRESS) | TODO.md: Not Started → In Progress | Silent failure, no update |
| `/build` | COMPLETION (mark COMPLETE) | TODO.md: In Progress → Completed | Silent failure, no update |
| `/plan` | After plan creation | Add to TODO.md Not Started | Silent failure, no update |
| `/research` | After report creation | Add to TODO.md Research | Silent failure, no update |
| `/debug` | After debug report | Add to TODO.md (plan or standalone) | Silent failure, no update |
| `/repair` | After repair plan | Add to TODO.md Not Started | Silent failure, no update |
| `/errors` | After error analysis | Add to TODO.md Research | Silent failure, no update |
| `/revise` | After plan modification | Refresh TODO.md entry | Silent failure, no update |
| `/test` | After test completion | Refresh TODO.md entry | Silent failure, no update |
| `/implement` | After implementation | Refresh TODO.md entry | Silent failure, no update |

**User Impact**: Users must manually run `/todo` after every command to see updated project status.

## Architectural Context

### Slash Command System

Claude Code uses a slash command system where:
- Commands are markdown files in `.claude/commands/`
- Files contain frontmatter (YAML) and markdown content with bash blocks
- Commands are invoked by users typing `/command-name`
- Claude processes markdown → extracts bash blocks → executes sequentially
- **Key Point**: Slash commands are NOT executable files

**Example**: `/todo` command
- **File**: `.claude/commands/todo.md`
- **Type**: Markdown with bash code blocks
- **Invocation**: Via SlashCommand tool (Claude internal mechanism)
- **NOT**: Bash script, executable, or PATH command

### Previous Failed Attempts

This is the third documented attempt to fix TODO.md integration:

#### Spec 991: Commands TODO.md Tracking Refactor (Early 2025)
- **Scope**: Added `trigger_todo_update()` to 3 commands (/repair, /errors, /debug)
- **Pattern**: Introduced helper function with `bash -c '/todo'` invocation
- **Outcome**: Silent failures, but non-blocking design prevented command breakage

#### Spec 997: TODO.md Update Pattern Fix (Mid 2025)
- **Scope**: Fixed 5 commands (/plan, /build, /implement, /revise, /research)
- **Issue**: Commands were executing `.claude/commands/todo.md` as bash script
- **Fix**: Replaced with `trigger_todo_update()` helper (which also doesn't work!)
- **Outcome**: Different silent failure - still broken, just better documented

#### Spec 015: Commands TODO.md Update Integration (December 2025)
- **Scope**: Added /test command, enhanced visibility
- **Changes**: Enhanced checkpoint format, updated documentation
- **Issue**: Still uses broken `trigger_todo_update()` implementation
- **Outcome**: All 9 commands now consistently broken

**Pattern**: Each attempt introduced better documentation and error handling, but never fixed the core invocation issue.

## Root Cause Analysis

### Why `bash -c '/todo'` Fails

```bash
$ bash -c '/todo'
bash: /todo: No such file or directory
```

**Technical Explanation**:
1. Bash interprets `/todo` as an absolute path to an executable
2. No file exists at `/todo` (it's a symbolic reference to `.claude/commands/todo.md`)
3. `.claude/commands/todo.md` is NOT executable (it's markdown)
4. Even if made executable, it wouldn't run (not a script, lacks shebang)

### Why Suppression Hides the Issue

```bash
if bash -c "cd \"${CLAUDE_PROJECT_DIR}\" && /todo" >/dev/null 2>&1; then
  # Never executes - bash -c always fails
  echo "✓ TODO.md updated: $reason"
  return 0
else
  # Always executes - error suppressed
  echo "WARNING: Failed to update TODO.md ($reason)" >&2
  return 0  # Still returns success!
fi
```

**Problem**: The function ALWAYS returns 0 (success), making failures invisible to callers.

**Why Users Don't See Warnings**:
- Commands suppress stderr with `2>/dev/null` when calling `trigger_todo_update()`
- Warning message goes to stderr, gets suppressed
- Checkpoint message `✓ TODO.md updated` never prints (in if block)
- Commands continue silently without TODO.md update

## Solution Architecture

### Core Challenge: Commands Cannot Invoke Other Commands

**Fundamental Constraint**: Bash blocks in slash commands cannot invoke other slash commands directly.

**Why This Matters**:
- Slash commands are Claude AI constructs, not OS processes
- They exist in the Claude Code runtime, not the filesystem
- No direct invocation mechanism available to bash

### Solution Options Analysis

#### Option 1: SlashCommand Tool Invocation (Not Viable)
**Idea**: Use SlashCommand tool from bash blocks

```bash
# Hypothetical (doesn't work)
trigger_todo_update() {
  # SlashCommand tool only available to Claude, not bash
  SlashCommand("/todo")
}
```

**Why It Fails**:
- SlashCommand tool is a Claude API, not a bash command
- Bash blocks cannot invoke Claude tools
- Would require escaping bash context (architectural impossibility)

#### Option 2: Direct TODO.md Generation (Violates Architecture)
**Idea**: Duplicate TODO.md generation logic in bash

```bash
trigger_todo_update() {
  # Reimplement /todo logic in bash
  scan_specs_generate_todo_directly
}
```

**Why This Is Wrong**:
- Violates single source of truth principle
- Duplicates complex logic across codebase
- Creates maintenance nightmare (two implementations)
- Contradicts existing architectural patterns

#### Option 3: Eliminate trigger_todo_update() (Recommended)
**Idea**: Remove automatic TODO.md updates, document manual workflow

**Implementation**:
1. Remove all `trigger_todo_update()` calls from commands
2. Document: "Run `/todo` to update TODO.md after creating/modifying plans"
3. Add reminder in completion summaries: "Next Steps: Run /todo to refresh TODO.md"
4. Optionally: Add convenience function to print reminder

**Advantages**:
- Aligns with architectural constraints
- Simple, maintainable, honest
- No silent failures
- Users understand when TODO.md is stale

**Disadvantages**:
- Extra manual step for users
- TODO.md not automatically synchronized
- Slight UX degradation

#### Option 4: Callback Pattern (Architectural Refactor)
**Idea**: Commands emit signals, Claude orchestrates TODO.md update

**Implementation**:
```bash
# Commands emit signals
echo "PLAN_CREATED: $PLAN_PATH"
echo "TODO_UPDATE_REQUESTED: plan created"

# Claude Code runtime detects signal, invokes /todo
# (requires changes to Claude Code itself)
```

**Requirements**:
- Modify Claude Code runtime to detect signals
- Implement signal → SlashCommand invocation mechanism
- Add signal parsing to command completion handler

**Advantages**:
- Proper separation of concerns
- Automatic updates without bash hacks
- Clean architectural pattern

**Disadvantages**:
- Requires Claude Code runtime changes (out of scope)
- High implementation complexity
- May not be feasible with current architecture

#### Option 5: Agent-Based Delegation (Hybrid Approach)
**Idea**: Commands invoke agent that uses SlashCommand tool

**Implementation**:
```bash
trigger_todo_update() {
  local reason="${1:-TODO.md update}"

  # Invoke todo-updater agent via Task tool
  # Agent has access to SlashCommand tool
  # Agent invokes /todo command
  # Agent returns success/failure

  # This requires executing from Claude context, not bash
  echo "NOTE: Run /todo to update TODO.md ($reason)" >&2
  return 0
}
```

**Why This Won't Work**:
- Task tool only available to Claude, not bash
- Same problem as Option 1 (tool access from bash)

#### Option 6: Helper Command Pattern (Pragmatic Solution)
**Idea**: Create bash-executable wrapper that triggers Claude to run /todo

**Implementation**:
1. Create `.claude/scripts/trigger-todo-update.sh` (bash script)
2. Script writes marker file: `.claude/tmp/todo_update_requested`
3. User's shell prompt or git hook detects marker, reminds user
4. User runs `/todo` when convenient

**Advantages**:
- Works within architectural constraints
- Provides user notification
- Non-blocking, non-intrusive

**Disadvantages**:
- Still requires manual `/todo` invocation
- Adds complexity with marker files
- Notification only works if shell/hooks configured

## Recommended Solution

### Hybrid Approach: Remove Auto-Update + Enhanced Visibility

**Phase 1: Immediate Fix (This Spec)**
1. **Remove broken `trigger_todo_update()` calls** from all 9 commands
2. **Add completion reminder** to all affected commands:
   ```bash
   echo ""
   echo "📋 Next Step: Run /todo to update TODO.md with new plan/report"
   echo ""
   ```
3. **Update documentation** to clarify manual `/todo` workflow
4. **Remove `trigger_todo_update()` function** from `todo-functions.sh`

**Phase 2: Future Enhancement (Separate Spec)**
- Investigate Claude Code runtime modifications for signal-based invocation
- Propose callback mechanism to Claude team
- Implement if feasible

### Implementation Details

#### Changes Required

**1. Remove trigger_todo_update() calls**

**Files to modify** (9 commands):
- `.claude/commands/build.md` (lines 347, 1061)
- `.claude/commands/plan.md` (line 1508)
- `.claude/commands/implement.md` (lines 346, 1058)
- `.claude/commands/revise.md` (line 1292)
- `.claude/commands/research.md` (line 1235)
- `.claude/commands/repair.md` (line 1460)
- `.claude/commands/errors.md` (lines 723-724)
- `.claude/commands/debug.md` (lines 1485, 1488)
- `.claude/commands/test.md` (invocation point TBD)

**Pattern to remove**:
```bash
# Source todo-functions.sh for trigger_todo_update()
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Trigger TODO.md update (non-blocking)
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "reason description"
fi
```

**Pattern to add**:
```bash
# Emit completion reminder
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this plan/report"
echo ""
```

**2. Update completion summaries**

Add to "Next Steps" section in all affected commands:

```bash
NEXT_STEPS="  • Review plan: cat $PLAN_PATH
  • Run /todo to update TODO.md (adds plan to tracking)
  • Start implementation: /build $PLAN_PATH"
```

**3. Remove trigger_todo_update() function**

**File**: `.claude/lib/todo/todo-functions.sh`

Remove function definition (lines 1112-1132):
```bash
# trigger_todo_update()
# Purpose: Delegate to /todo command for full TODO.md regeneration
# Arguments:
#   $1 - Reason for update (for console output)
# Returns: 0 on success (non-blocking - warnings only on failure)
# Usage:
#   trigger_todo_update "repair plan created"
#
trigger_todo_update() {
  local reason="${1:-TODO.md update}"

  # Delegate to /todo command silently (suppress output)
  if bash -c "cd \"${CLAUDE_PROJECT_DIR}\" && /todo" >/dev/null 2>&1; then
    echo "✓ TODO.md updated: $reason"
    return 0
  else
    # Non-blocking: log warning but don't fail command
    echo "WARNING: Failed to update TODO.md ($reason)" >&2
    return 0  # Return success to avoid blocking parent command
  fi
}
```

Remove export statement (line 1471):
```bash
export -f trigger_todo_update
```

**4. Update documentation**

**File**: `.claude/docs/guides/development/command-todo-integration-guide.md`

- Document removal of automatic updates
- Add manual workflow documentation
- Update all pattern examples to show reminder approach
- Add troubleshooting section for stale TODO.md

**5. Update library README**

**File**: `.claude/lib/todo/README.md`

- Remove trigger_todo_update() from function list
- Document manual /todo workflow
- Add migration guide for commands

### Testing Strategy

#### Unit Tests

**File**: `.claude/tests/lib/test_todo_functions.sh`

Remove tests for `trigger_todo_update()`:
- `test_trigger_todo_update_success`
- `test_trigger_todo_update_failure_graceful`

Add tests for manual workflow:
- `test_manual_todo_workflow`
- `test_completion_reminder_present`

#### Integration Tests

**Test**: Verify TODO.md NOT auto-updated after command
```bash
# Create plan
BEFORE_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
/plan "test plan creation"
AFTER_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)

# Verify TODO.md unchanged (no auto-update)
[ "$BEFORE_HASH" = "$AFTER_HASH" ] || fail "TODO.md should not auto-update"

# Verify reminder printed
/plan "test plan" 2>&1 | grep -q "Run /todo to update TODO.md" || fail "Missing reminder"

# Manual update works
/todo
grep -q "test plan" .claude/TODO.md || fail "Manual /todo failed"
```

**Test**: Verify commands succeed without todo-functions.sh
```bash
# Remove library temporarily
mv .claude/lib/todo/todo-functions.sh .claude/lib/todo/todo-functions.sh.bak

# Commands should still succeed
/plan "test plan without todo-functions" || fail "Command should not depend on todo-functions.sh"

# Restore library
mv .claude/lib/todo/todo-functions.sh.bak .claude/lib/todo/todo-functions.sh
```

#### Regression Tests

**Test**: Ensure no commands still reference trigger_todo_update()
```bash
# Search all command files
grep -r "trigger_todo_update" .claude/commands/ && fail "Found trigger_todo_update() references"

# Search all test files
grep -r "trigger_todo_update" .claude/tests/ && fail "Found trigger_todo_update() test references"
```

### Migration Path

#### For End Users

**Before** (broken):
```bash
/plan "new feature"
# (Silent failure - TODO.md not updated)
# User expects plan in TODO.md, but must manually run /todo
```

**After** (fixed):
```bash
/plan "new feature"
# Output: 📋 Next Step: Run /todo to update TODO.md with this plan

# User explicitly runs /todo
/todo
# Output: TODO.md updated: .claude/TODO.md
```

**User Benefit**: No more silent failures, clear expectations

#### For Command Authors

**Before**:
```bash
# Create artifact
echo "PLAN_CREATED: $PLAN_PATH"

# Attempt auto-update (fails silently)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh"
trigger_todo_update "plan created"
```

**After**:
```bash
# Create artifact
echo "PLAN_CREATED: $PLAN_PATH"

# Remind user to update TODO.md
echo ""
echo "📋 Next Step: Run /todo to update TODO.md with this plan"
echo ""
```

**Benefit**: Simpler, honest, maintainable

## Risk Assessment

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users forget to run /todo | Medium | Low | Reminders in completion output, documentation |
| TODO.md becomes stale | Medium | Low | Clearly document manual workflow, /todo is fast |
| Confusion about auto-update removal | Low | Low | Clear migration guide, update all docs |
| Commands break during refactor | Low | Medium | Comprehensive testing, staged rollout |

### Breaking Changes

**User-Facing**:
- TODO.md no longer auto-updates after commands
- Users must manually run `/todo` (one extra step)

**Developer-Facing**:
- `trigger_todo_update()` function removed from `todo-functions.sh`
- Commands no longer source `todo-functions.sh` for TODO updates
- Integration patterns updated

**Mitigation**:
- Document in CHANGELOG
- Update all command documentation
- Add migration guide
- Provide clear reminders in command output

## Success Criteria

- [ ] All 9 commands remove `trigger_todo_update()` calls
- [ ] All 9 commands add completion reminders
- [ ] `trigger_todo_update()` function removed from `todo-functions.sh`
- [ ] All tests updated (remove trigger_todo_update() tests)
- [ ] Documentation updated (integration guide, command docs)
- [ ] Zero grep hits for "trigger_todo_update" in commands/
- [ ] Manual `/todo` workflow documented and tested
- [ ] Users receive clear next-step guidance
- [ ] No silent failures in TODO.md update flow

## Alternative Considered: Hybrid Notification System

**Idea**: Keep function but change behavior to notification only

```bash
trigger_todo_update() {
  local reason="${1:-TODO.md update}"
  echo ""
  echo "📋 TODO.md Update Requested: $reason"
  echo "   Run: /todo"
  echo ""
  return 0
}
```

**Why Rejected**:
- Still requires keeping function and sourcing library
- Adds complexity for simple reminder
- Function name misleading ("trigger" implies action)
- Better to inline reminder where needed

## References

### Specifications
- Spec 991: Commands TODO.md Tracking Refactor (introduced trigger_todo_update)
- Spec 997: TODO.md Update Pattern Fix (fixed .md execution, introduced consistent failure)
- Spec 015: Commands TODO.md Update Integration (extended to /test, enhanced visibility)

### Implementation Files
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (lines 1112-1132: trigger_todo_update function)
- `/home/benjamin/.config/.claude/commands/todo.md` (slash command, not bash executable)
- `/home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md` (integration patterns)

### Standards
- [TODO Organization Standards](/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md)
- [Command Authoring Standards](/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md)
- [Output Formatting Standards](/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md)

## Conclusion

The current implementation attempts to invoke slash commands from bash, which is architecturally impossible in Claude Code. The solution is to remove automatic TODO.md updates, provide clear user guidance, and document the manual `/todo` workflow. This honest approach eliminates silent failures and aligns with architectural constraints while maintaining usability through enhanced visibility and clear next-step guidance.

**Key Insight**: Sometimes the best fix is to acknowledge architectural constraints and design around them, rather than fighting against them with increasingly complex workarounds.
