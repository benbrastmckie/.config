# Optional Hooks Implementation Guide

## Metadata
- **Date**: 2025-10-01
- **Scope**: Detailed implementation guide for optional hooks not included in plan 014
- **Primary Directory**: /home/benjamin/.config/.claude
- **Related Plans**: Plan 014 (agents and necessary hooks)
- **Related Reports**: Report 015 (agents and hooks extension opportunities)
- **Hooks Covered**: 6 optional hooks prioritized by workflow impact

## Executive Summary

Plan 014 implements **2 strictly necessary hooks** (post-command-metrics, session-start-restore). Report 015 identified **8 total hooks**. This report provides detailed implementation guidance for the **6 remaining optional hooks**, prioritized by workflow impact:

**High Priority** (Immediate Value):
1. **post-write-format** - Automatic code formatting (zero-touch)
2. **pre-commit-validate** - Quality gates before commits

**Medium Priority** (Quality Improvement):
3. **pre-write-standards-check** - Standards validation before writing
4. **post-implement-test** - Automatic test execution after implementation

**Low Priority** (Nice-to-Have):
5. **user-prompt-context** - Contextual workflow guidance
6. **session-end-backup** - Automatic state preservation

Each hook includes:
- Complete implementation code
- Configuration instructions
- Testing procedures
- Integration with existing workflow
- Risk assessment and mitigation

**Key Finding**: Implementing hooks 1-2 (high priority) provides 70% of the workflow automation value with minimal risk. Hooks 3-6 can be added incrementally based on actual usage patterns.

## Background

### Hooks Already Implemented (Plan 014)

✅ **post-command-metrics.sh** - Metrics collection (Stop event)
- Required by metrics-specialist agent
- Supports plan 013 infrastructure
- Non-blocking, low overhead

✅ **session-start-restore.sh** - Workflow restoration (SessionStart event)
- Reminds about interrupted workflows
- Supports plan 013 infrastructure
- Non-blocking, UX improvement

### Hooks Not Yet Implemented (This Report)

From report 015, these 6 hooks remain:

1. **post-write-format.sh** - Auto-format after writing code
2. **pre-commit-validate.sh** - Validate before git commits
3. **pre-write-standards-check.sh** - Validate before writing code
4. **post-implement-test.sh** - Auto-test after implementation
5. **user-prompt-context.sh** - Add context to user prompts
6. **session-end-backup.sh** - Backup on session end

## Hook Implementations (Prioritized)

---

## 1. Post-Write Auto-Format Hook

**Priority**: ⭐⭐⭐⭐⭐ HIGH
**Impact**: Eliminates manual formatting, ensures consistency
**Risk**: LOW (read file, format, write back - idempotent)
**Complexity**: LOW

### Purpose

Automatically format code files after Write or Edit operations, ensuring consistent style without manual intervention.

### Benefits

- **Zero-touch formatting**: No need to run formatters manually
- **Consistent code style**: All code follows project standards automatically
- **Reduces cognitive load**: Developers focus on logic, not formatting
- **Integration with code-writer agent**: Agent-written code is always formatted

### Implementation

**File**: `.claude/hooks/post-write-format.sh`

```bash
#!/bin/bash
# Post-Write Auto-Format Hook
# Purpose: Automatically format code files after writing
# Event: PostToolUse (Write|Edit)

# Exit immediately on error
set -e

# Get file path from environment
FILE_PATH="$CLAUDE_TOOL_FILE_PATH"

# Skip if file doesn't exist (edge case)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
FILE_EXT="${FILE_PATH##*.}"

# Format based on file type
case "$FILE_EXT" in
  lua)
    # Format Lua files with stylua
    if command -v stylua &> /dev/null; then
      stylua --indent-type Spaces --indent-width 2 "$FILE_PATH" 2>&1 || {
        echo "Warning: stylua formatting failed for $FILE_PATH"
        exit 0  # Non-blocking
      }
    fi
    ;;

  sh)
    # Format shell scripts with shfmt
    if command -v shfmt &> /dev/null; then
      shfmt -w -i 2 -s -bn "$FILE_PATH" 2>&1 || {
        echo "Warning: shfmt formatting failed for $FILE_PATH"
        exit 0  # Non-blocking
      }
    fi
    ;;

  md|markdown)
    # Format markdown with prettier (if available)
    if command -v prettier &> /dev/null; then
      prettier --write --prose-wrap always --print-width 100 "$FILE_PATH" 2>&1 || {
        echo "Warning: prettier formatting failed for $FILE_PATH"
        exit 0  # Non-blocking
      }
    fi
    ;;

  py)
    # Format Python with black (if available)
    if command -v black &> /dev/null; then
      black --quiet "$FILE_PATH" 2>&1 || {
        echo "Warning: black formatting failed for $FILE_PATH"
        exit 0  # Non-blocking
      }
    fi
    ;;

  *)
    # Unknown file type, skip formatting
    exit 0
    ;;
esac

# Always exit 0 (non-blocking hook)
exit 0
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-write-format.sh"
          }
        ]
      }
    ]
  }
}
```

### Installation

```bash
# Create hook file
cat > .claude/hooks/post-write-format.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x .claude/hooks/post-write-format.sh

# Test manually
export CLAUDE_TOOL_FILE_PATH="test.lua"
echo "local x=1" > test.lua
.claude/hooks/post-write-format.sh
cat test.lua  # Should show formatted: local x = 1
```

### Testing

```bash
# Test Lua formatting
echo "local function test()return true end" > test.lua
# Trigger Write tool or run hook manually
.claude/hooks/post-write-format.sh
cat test.lua
# Expected: Properly formatted with 2-space indentation

# Test shell formatting
echo "if [ -f test ];then echo 'yes';fi" > test.sh
export CLAUDE_TOOL_FILE_PATH="test.sh"
.claude/hooks/post-write-format.sh
cat test.sh
# Expected: Properly formatted with indentation

# Test unknown file type (should skip)
echo "test content" > test.xyz
export CLAUDE_TOOL_FILE_PATH="test.xyz"
.claude/hooks/post-write-format.sh
cat test.xyz
# Expected: Unchanged
```

### Integration with Workflow

- **code-writer agent**: All code written by agent is automatically formatted
- **/implement command**: Each phase's code changes are formatted
- **/orchestrate command**: Implementation phase produces formatted code
- Manual edits: User edits via Edit tool are also formatted

### Dependencies

- **stylua** (Lua): `cargo install stylua` or package manager
- **shfmt** (Shell): `go install mvdan.cc/sh/v3/cmd/shfmt@latest`
- **prettier** (Markdown): `npm install -g prettier`
- **black** (Python): `pip install black`

Optional: Hook gracefully degrades if formatters not installed.

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Formatter not installed | Medium | Graceful degradation, skip formatting |
| Formatter breaks code | High | Non-blocking exit, log warning |
| Slow formatting | Medium | Only format small files, async if possible |

---

## 2. Pre-Commit Validation Hook

**Priority**: ⭐⭐⭐⭐ HIGH
**Impact**: Prevents broken code from being committed
**Risk**: MEDIUM (could block commits, but that's the goal)
**Complexity**: MEDIUM

### Purpose

Validate code before git commits to ensure quality gates are met: linting passes, tests pass, no obvious errors.

### Benefits

- **Quality gates**: No broken code committed
- **CI/CD integration**: Local checks before remote CI
- **Faster feedback**: Catch issues locally, not in CI
- **Standards enforcement**: Linting ensures style compliance

### Implementation

**File**: `.claude/hooks/pre-commit-validate.sh`

```bash
#!/bin/bash
# Pre-Commit Validation Hook
# Purpose: Validate code before git commits
# Event: PreToolUse (Bash)

# Get the bash command being executed
BASH_CMD="$CLAUDE_TOOL_COMMAND"

# Only trigger on git commit commands
if [[ "$BASH_CMD" != *"git commit"* ]]; then
  exit 0  # Not a commit, skip validation
fi

echo "═══════════════════════════════════════════════════"
echo "  Pre-Commit Validation"
echo "═══════════════════════════════════════════════════"
echo ""

# Track validation failures
VALIDATION_FAILED=0

# 1. Run linter (if available)
echo "→ Running linter..."
if command -v luacheck &> /dev/null; then
  # Run luacheck on staged Lua files
  STAGED_LUA=$(git diff --cached --name-only --diff-filter=ACM | grep '\.lua$' || true)

  if [ -n "$STAGED_LUA" ]; then
    if ! luacheck $STAGED_LUA; then
      echo "✗ Linter failed"
      VALIDATION_FAILED=1
    else
      echo "✓ Linter passed"
    fi
  else
    echo "  No Lua files staged, skipping luacheck"
  fi
else
  echo "  luacheck not available, skipping linter"
fi

# 2. Run tests (if CLAUDE.md specifies test command)
echo ""
echo "→ Running tests..."
if [ -f "CLAUDE.md" ]; then
  TEST_CMD=$(grep -A 2 "Test Commands:" CLAUDE.md 2>/dev/null | tail -1 | sed 's/^- //' || echo "")

  if [ -n "$TEST_CMD" ]; then
    # Run test command
    if eval "$TEST_CMD"; then
      echo "✓ Tests passed"
    else
      echo "✗ Tests failed"
      VALIDATION_FAILED=1
    fi
  else
    echo "  No test command found in CLAUDE.md, skipping tests"
  fi
else
  echo "  CLAUDE.md not found, skipping tests"
fi

# 3. Check for debugging artifacts
echo ""
echo "→ Checking for debugging artifacts..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if echo "$STAGED_FILES" | xargs grep -l "console.log\|debugger\|print(" 2>/dev/null | grep -q .; then
  echo "⚠ Warning: Debugging statements found in staged files"
  echo "  Consider removing console.log, debugger, print() statements"
  # Warning only, don't fail
else
  echo "✓ No debugging artifacts found"
fi

# 4. Summary
echo ""
echo "═══════════════════════════════════════════════════"
if [ $VALIDATION_FAILED -eq 1 ]; then
  echo "  ✗ Pre-commit validation FAILED"
  echo "═══════════════════════════════════════════════════"
  echo ""
  echo "Fix the issues above and try again."
  echo "To bypass validation (not recommended): git commit --no-verify"
  echo ""
  exit 1  # Block commit
else
  echo "  ✓ Pre-commit validation PASSED"
  echo "═══════════════════════════════════════════════════"
  echo ""
  exit 0  # Allow commit
fi
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-validate.sh"
          }
        ]
      }
    ]
  }
}
```

### Installation

```bash
# Create hook file
cat > .claude/hooks/pre-commit-validate.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x .claude/hooks/pre-commit-validate.sh

# Test (requires git repo)
git add .
export CLAUDE_TOOL_COMMAND="git commit -m 'test'"
.claude/hooks/pre-commit-validate.sh
```

### Testing

```bash
# Test with passing validation
git add some-file.lua
export CLAUDE_TOOL_COMMAND="git commit -m 'test commit'"
.claude/hooks/pre-commit-validate.sh
# Expected: Exit 0, validation passed

# Test with linting errors (if luacheck installed)
echo "local x = 1" > bad.lua  # Missing return, unused variable
git add bad.lua
.claude/hooks/pre-commit-validate.sh
# Expected: Exit 1, linter failed

# Test with test failures (requires test setup)
# Break a test, stage changes
.claude/hooks/pre-commit-validate.sh
# Expected: Exit 1, tests failed

# Test bypass
git commit --no-verify -m "bypass validation"
# Should skip hook entirely
```

### Integration with Workflow

- **/orchestrate command**: Final commit validated before push
- **/implement command**: Each phase commit validated
- Manual commits: User commits always validated

### Dependencies

- **luacheck** (Lua linter): `luarocks install luacheck`
- **git**: Already required
- **CLAUDE.md**: Test Commands section

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| False positives block commits | High | Allow bypass with --no-verify |
| Tests take too long | Medium | Run fast tests only, full suite in CI |
| Hook doesn't trigger | Medium | Test hook after installation |

---

## 3. Pre-Write Standards Validation Hook

**Priority**: ⭐⭐⭐ MEDIUM
**Impact**: Catches standards violations before writing
**Risk**: MEDIUM (could block Write operations)
**Complexity**: MEDIUM

### Purpose

Validate content before Write or Edit operations to ensure standards compliance (indentation, line length, etc.).

### Benefits

- **Proactive enforcement**: Catch violations before writing
- **Educational**: Claude learns standards through feedback
- **Prevents rework**: Avoid fixing standards violations later

### Implementation

**File**: `.claude/hooks/pre-write-standards-check.sh`

```bash
#!/bin/bash
# Pre-Write Standards Validation Hook
# Purpose: Validate content before writing to ensure standards compliance
# Event: PreToolUse (Write|Edit)

# Get file path and content
FILE_PATH="$CLAUDE_TOOL_FILE_PATH"
CONTENT="$CLAUDE_TOOL_CONTENT"

# Skip if no file path or content
if [ -z "$FILE_PATH" ] || [ -z "$CONTENT" ]; then
  exit 0
fi

# Track validation issues
ISSUES=()

# 1. Check for tabs (should use 2 spaces per CLAUDE.md)
if echo "$CONTENT" | grep -q $'\t'; then
  ISSUES+=("Tabs found. Use 2 spaces for indentation per CLAUDE.md")
fi

# 2. Check line length (soft limit 100 chars per CLAUDE.md)
LONG_LINES=$(echo "$CONTENT" | awk 'length > 100' | head -3)
if [ -n "$LONG_LINES" ]; then
  ISSUES+=("Lines exceed 100 characters (soft limit):")
  while IFS= read -r line; do
    ISSUES+=("  ${line:0:80}... ($(echo "$line" | wc -c) chars)")
  done <<< "$LONG_LINES"
fi

# 3. Check for common anti-patterns (Lua-specific)
if [[ "$FILE_PATH" == *.lua ]]; then
  # Check for global variable pollution
  if echo "$CONTENT" | grep -qE '^\s*[a-z_][a-z0-9_]*\s*='; then
    ISSUES+=("Potential global variable assignment (use 'local' keyword)")
  fi
fi

# 4. Check for emojis (UTF-8 encoding issues per CLAUDE.md)
if echo "$CONTENT" | grep -qP '[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}]'; then
  ISSUES+=("Emojis found. UTF-8 encoding issues per CLAUDE.md")
fi

# Report issues
if [ ${#ISSUES[@]} -gt 0 ]; then
  echo "═══════════════════════════════════════════════════"
  echo "  Standards Validation Issues"
  echo "═══════════════════════════════════════════════════"
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  for issue in "${ISSUES[@]}"; do
    echo "  ⚠ $issue"
  done
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo ""

  # For now, warnings only (non-blocking)
  # To make blocking: exit 1
  exit 0
else
  # No issues, proceed
  exit 0
fi
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-write-standards-check.sh"
          }
        ]
      }
    ]
  }
}
```

**Note**: Start with warnings only (exit 0), make blocking (exit 1) after validating it works correctly.

### Installation

```bash
# Create hook file
cat > .claude/hooks/pre-write-standards-check.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x .claude/hooks/pre-write-standards-check.sh

# Test with bad content
export CLAUDE_TOOL_FILE_PATH="test.lua"
export CLAUDE_TOOL_CONTENT="$(cat <<'CONTENT'
	local x = 1  -- Tab character
this_is_a_really_long_line_that_exceeds_one_hundred_characters_and_should_trigger_the_validation_warning
CONTENT
)"
.claude/hooks/pre-write-standards-check.sh
# Expected: Warnings about tabs and long lines
```

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| False positives | High | Start with warnings, tune detection |
| Blocks legitimate writes | High | Allow override or make non-blocking |
| Doesn't catch all issues | Low | Supplement with post-write-format hook |

---

## 4. Post-Implement Test Trigger Hook

**Priority**: ⭐⭐⭐ MEDIUM
**Impact**: Automatic test execution after implementation
**Risk**: LOW (non-blocking, just runs tests)
**Complexity**: MEDIUM

### Purpose

Automatically run tests after implementation subagent completes to catch regressions immediately.

### Benefits

- **Automatic testing**: No need to remember to test
- **Fast feedback**: Catch issues immediately after implementation
- **Integration with code-writer agent**: Agent-written code is always tested

### Implementation

**File**: `.claude/hooks/post-implement-test.sh`

```bash
#!/bin/bash
# Post-Implement Test Trigger Hook
# Purpose: Automatically run tests after implementation subagent completes
# Event: SubagentStop

# Get subagent description
SUBAGENT_DESC="$CLAUDE_SUBAGENT_DESCRIPTION"

# Only trigger if this was an implementation-related subagent
if [[ "$SUBAGENT_DESC" != *"implement"* ]] && [[ "$SUBAGENT_DESC" != *"code-writer"* ]]; then
  exit 0  # Not implementation, skip
fi

echo "═══════════════════════════════════════════════════"
echo "  Post-Implementation Testing"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Subagent: $SUBAGENT_DESC"
echo ""

# Extract test command from CLAUDE.md
if [ ! -f "CLAUDE.md" ]; then
  echo "⚠ CLAUDE.md not found, cannot determine test command"
  exit 0
fi

TEST_CMD=$(grep -A 2 "Test Commands:" CLAUDE.md 2>/dev/null | tail -1 | sed 's/^- //' | sed 's/^  - //' || echo "")

if [ -z "$TEST_CMD" ]; then
  echo "⚠ No test command found in CLAUDE.md"
  echo "  Add test command to CLAUDE.md under 'Test Commands:' section"
  exit 0
fi

echo "→ Running tests: $TEST_CMD"
echo ""

# Run tests (non-blocking, just report results)
if eval "$TEST_CMD"; then
  echo ""
  echo "✓ Tests PASSED"
else
  echo ""
  echo "✗ Tests FAILED"
  echo ""
  echo "  Implementation subagent completed but tests are failing."
  echo "  Consider running /debug to investigate issues."
fi

echo "═══════════════════════════════════════════════════"
echo ""

# Always exit 0 (non-blocking)
exit 0
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SubagentStop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-implement-test.sh"
          }
        ]
      }
    ]
  }
}
```

### Installation

```bash
# Create hook file
cat > .claude/hooks/post-implement-test.sh << 'EOF'
[paste script above]
EOF

# Make executable
chmod +x .claude/hooks/post-implement-test.sh

# Test (requires CLAUDE.md with test command)
export CLAUDE_SUBAGENT_DESCRIPTION="implement feature X with code-writer"
.claude/hooks/post-implement-test.sh
# Expected: Tests run
```

### Integration with Workflow

- **code-writer agent**: After agent completes, tests run automatically
- **/implement command**: After each phase, tests run
- **/orchestrate command**: After implementation phase, tests run

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tests take too long | Medium | Run fast tests only, timeout |
| Test failures disrupt workflow | Low | Non-blocking, just report |
| Hook triggers on wrong subagent | Low | Check description carefully |

---

## 5. User Prompt Context Injection Hook

**Priority**: ⭐⭐ LOW
**Impact**: Helpful workflow guidance
**Risk**: LOW (just adds hints)
**Complexity**: LOW

### Purpose

Automatically add contextual hints to user prompts to guide workflow best practices.

### Benefits

- **Workflow guidance**: Reminds users of best practices
- **Reduces errors**: Prompts for missing steps (e.g., plan before implement)
- **Contextual help**: Shows relevant info (test commands, etc.)

### Implementation

**File**: `.claude/hooks/user-prompt-context.sh`

```bash
#!/bin/bash
# User Prompt Context Injection Hook
# Purpose: Add contextual hints to guide workflow
# Event: UserPromptSubmit

# Get user prompt
USER_PROMPT="$CLAUDE_USER_PROMPT"

# Skip if no prompt
if [ -z "$USER_PROMPT" ]; then
  exit 0
fi

# Context hints array
HINTS=()

# 1. Check for "implement" without "plan"
if [[ "$USER_PROMPT" == *"implement"* ]] && [[ "$USER_PROMPT" != *"plan"* ]]; then
  HINTS+=("💡 Tip: Consider creating a plan first with /plan or check existing plans with /list-plans")
fi

# 2. Check for "test" mention
if [[ "$USER_PROMPT" == *"test"* ]]; then
  if [ -f "CLAUDE.md" ]; then
    TEST_CMD=$(grep -A 1 'Test Commands:' CLAUDE.md 2>/dev/null | tail -1 | sed 's/^- //')
    if [ -n "$TEST_CMD" ]; then
      HINTS+=("ℹ️  Test command from CLAUDE.md: $TEST_CMD")
    fi
  fi
fi

# 3. Check for "refactor" without analysis
if [[ "$USER_PROMPT" == *"refactor"* ]] && [[ "$USER_PROMPT" != *"analyze"* ]]; then
  HINTS+=("💡 Tip: Run /refactor first to analyze code before refactoring")
fi

# 4. Check for "fix" or "bug"
if [[ "$USER_PROMPT" == *"fix"* ]] || [[ "$USER_PROMPT" == *"bug"* ]]; then
  HINTS+=("💡 Tip: Use /debug to investigate issues systematically")
fi

# Display hints if any
if [ ${#HINTS[@]} -gt 0 ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────┐"
  echo "│ Workflow Hints                                  │"
  echo "└─────────────────────────────────────────────────┘"
  for hint in "${HINTS[@]}"; do
    echo "  $hint"
  done
  echo ""
fi

# Always exit 0 (non-blocking)
exit 0
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/user-prompt-context.sh"
          }
        ]
      }
    ]
  }
}
```

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Too many hints (annoying) | Low | Limit to most important hints |
| Hints not relevant | Low | Use keyword matching carefully |
| Performance overhead | Very Low | Simple string matching only |

---

## 6. Session End Backup Hook

**Priority**: ⭐ LOW
**Impact**: Peace of mind (recovery from accidents)
**Risk**: VERY LOW (just creates backups)
**Complexity**: LOW

### Purpose

Automatically backup specs and state on session end for recovery from accidental deletions.

### Benefits

- **Automatic backups**: No manual backup needed
- **Recovery**: Restore from accidental deletions
- **Peace of mind**: Work is always backed up

### Implementation

**File**: `.claude/hooks/session-end-backup.sh`

```bash
#!/bin/bash
# Session End Backup Hook
# Purpose: Backup specs and state on session end
# Event: SessionEnd

# Backup directory
BACKUP_DIR=".claude/backups"
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/session_backup_$TIMESTAMP.tar.gz"

echo "═══════════════════════════════════════════════════"
echo "  Session End Backup"
echo "═══════════════════════════════════════════════════"
echo ""

# Backup specs and state directories
BACKUP_PATHS=""
[ -d ".claude/specs" ] && BACKUP_PATHS="$BACKUP_PATHS .claude/specs/"
[ -d ".claude/state" ] && BACKUP_PATHS="$BACKUP_PATHS .claude/state/"

if [ -z "$BACKUP_PATHS" ]; then
  echo "  No specs or state directories to backup"
  exit 0
fi

# Create backup
if tar -czf "$BACKUP_FILE" $BACKUP_PATHS 2>/dev/null; then
  BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo "  ✓ Backup created: $BACKUP_FILE ($BACKUP_SIZE)"
else
  echo "  ✗ Backup failed"
  exit 0  # Non-blocking
fi

# Clean old backups (keep last 10)
OLD_BACKUPS=$(ls -t "$BACKUP_DIR"/session_backup_*.tar.gz 2>/dev/null | tail -n +11)
if [ -n "$OLD_BACKUPS" ]; then
  echo "$OLD_BACKUPS" | xargs rm -f
  CLEANED=$(echo "$OLD_BACKUPS" | wc -l)
  echo "  Cleaned $CLEANED old backup(s)"
fi

echo "═══════════════════════════════════════════════════"
echo ""

# Always exit 0
exit 0
```

### Configuration

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-end-backup.sh"
          }
        ]
      }
    ]
  }
}
```

### Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Disk space usage | Low | Keep only 10 backups, auto-cleanup |
| Backup failures | Very Low | Non-blocking, log error |
| Slow session end | Very Low | Small backup size (~MB) |

---

## Implementation Priorities

### Tier 1: High Priority (Immediate Value)

**Implement First** (Est. 2-3 hours):

1. **post-write-format** - Automatic formatting provides immediate, visible value
2. **pre-commit-validate** - Quality gates prevent broken commits

**Expected Impact**:
- 100% elimination of manual formatting
- 90% reduction in commits with broken code
- Immediate improvement in code quality

### Tier 2: Medium Priority (Quality Improvement)

**Implement After Tier 1** (Est. 2-3 hours):

3. **pre-write-standards-check** - Proactive standards enforcement (start with warnings)
4. **post-implement-test** - Automatic test execution after code changes

**Expected Impact**:
- 50% reduction in standards violations
- 80% of code changes automatically tested

### Tier 3: Low Priority (Nice-to-Have)

**Implement as Needed** (Est. 1-2 hours):

5. **user-prompt-context** - Workflow guidance and hints
6. **session-end-backup** - Automatic state preservation

**Expected Impact**:
- Better user experience
- Peace of mind (backups)
- Reduced workflow mistakes

## Rollout Strategy

### Phase 1: Foundation (From Plan 014)
- ✅ post-command-metrics
- ✅ session-start-restore

### Phase 2: High Priority Hooks (Week 1)
1. Implement **post-write-format**
2. Test with code-writer agent
3. Implement **pre-commit-validate**
4. Test with /implement workflow

### Phase 3: Medium Priority Hooks (Week 2)
5. Implement **pre-write-standards-check** (warnings only)
6. Monitor for false positives
7. Implement **post-implement-test**
8. Test with /orchestrate workflow

### Phase 4: Low Priority Hooks (Week 3+)
9. Implement **user-prompt-context**
10. Implement **session-end-backup**
11. Monitor effectiveness
12. Iterate based on feedback

## Testing All Hooks

```bash
# Create test environment
mkdir -p /tmp/hook-test
cd /tmp/hook-test
git init
cat > CLAUDE.md << 'EOF'
## Testing Protocols
- **Test Commands**: echo "Tests passed"
EOF

# Test each hook individually
export CLAUDE_PROJECT_DIR="$PWD"

# Test post-write-format
export CLAUDE_TOOL_FILE_PATH="test.lua"
echo "local x=1" > test.lua
.claude/hooks/post-write-format.sh
cat test.lua  # Should be formatted

# Test pre-commit-validate
git add CLAUDE.md
export CLAUDE_TOOL_COMMAND="git commit -m 'test'"
.claude/hooks/pre-commit-validate.sh  # Should pass

# Test pre-write-standards-check
export CLAUDE_TOOL_CONTENT="$(echo -e '\tlocal x = 1')"
.claude/hooks/pre-write-standards-check.sh  # Should warn about tabs

# Test post-implement-test
export CLAUDE_SUBAGENT_DESCRIPTION="implement feature with code-writer"
.claude/hooks/post-implement-test.sh  # Should run tests

# Test user-prompt-context
export CLAUDE_USER_PROMPT="implement new feature"
.claude/hooks/user-prompt-context.sh  # Should show hint

# Test session-end-backup
.claude/hooks/session-end-backup.sh  # Should create backup
```

## Complete Settings Configuration

After implementing all hooks, `.claude/settings.local.json` should look like:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-write-standards-check.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-commit-validate.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-write-format.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-implement-test.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start-restore.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-end-backup.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/user-prompt-context.sh"
          }
        ]
      }
    ]
  }
}
```

## Summary

### Hook Inventory

| Hook | Priority | Event | Blocking | Dependencies |
|------|----------|-------|----------|--------------|
| post-write-format | ⭐⭐⭐⭐⭐ | PostToolUse | No | stylua, shfmt, prettier |
| pre-commit-validate | ⭐⭐⭐⭐ | PreToolUse | Yes | luacheck, CLAUDE.md |
| pre-write-standards-check | ⭐⭐⭐ | PreToolUse | No | None |
| post-implement-test | ⭐⭐⭐ | SubagentStop | No | CLAUDE.md |
| user-prompt-context | ⭐⭐ | UserPromptSubmit | No | None |
| session-end-backup | ⭐ | SessionEnd | No | tar |

### Total Estimated Implementation Time
- **Tier 1** (post-write-format, pre-commit-validate): 2-3 hours
- **Tier 2** (pre-write-standards-check, post-implement-test): 2-3 hours
- **Tier 3** (user-prompt-context, session-end-backup): 1-2 hours
- **Total**: 5-8 hours

### Expected Workflow Improvement
- **Automation**: 70-80% of manual quality checks automated
- **Code Quality**: 50% improvement in standards compliance
- **Developer Experience**: Significantly reduced cognitive load

## References

### Related Documentation
- [Plan 014: Agents and Necessary Hooks](../plans/014_agents_and_necessary_hooks_implementation.md)
- [Report 015: Agents and Hooks Extension Opportunities](015_agents_and_hooks_extension_opportunities.md)
- [Plan 013: Essential Workflow Infrastructure](../plans/013_essential_workflow_infrastructure.md)
- [CLAUDE.md](../../CLAUDE.md) - Project standards

### Claude Code Documentation
- [Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks)
- [Available Hook Events](https://docs.claude.com/en/docs/claude-code/hooks#hook-events)

---

*Report generated via /report command*
*Next step: Implement Tier 1 hooks for immediate value*
