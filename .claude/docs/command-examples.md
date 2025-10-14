# Command Examples Reference

This file contains reusable command patterns and examples shared across multiple Claude Code commands.

## Table of Contents

1. [Dry-Run Mode Examples](#dry-run-mode-examples)
2. [Dashboard Progress Examples](#dashboard-progress-examples)
3. [Checkpoint Save/Restore Examples](#checkpoint-saverestore-examples)
4. [Test Execution Patterns](#test-execution-patterns)
5. [Git Commit Patterns](#git-commit-patterns)

---

## Dry-Run Mode Examples

### Overview

Dry-run mode allows users to preview command execution without making changes or invoking agents.

**Commands Supporting Dry-Run**:
- `/orchestrate` - Preview full workflow without invoking agents
- `/implement` - Preview implementation plan without executing
- `/revise` - Preview plan revisions without modifying plan file
- `/plan` - Preview plan structure without creating file

### Dry-Run Flag Usage

```bash
# Basic dry-run
/orchestrate "Add user authentication" --dry-run

# Dry-run with other flags
/orchestrate "Add feature X" --dry-run --parallel
/implement plan_file.md --dry-run --starting-phase 3
/revise "Add Phase 4" --dry-run --auto-mode
```

### Dry-Run Workflow Analysis Output

**Example: /orchestrate Dry-Run**

```
┌─────────────────────────────────────────────────────────────┐
│ Workflow: Add user authentication with JWT tokens (Dry-Run)│
├─────────────────────────────────────────────────────────────┤
│ Workflow Type: feature  |  Estimated Duration: ~28 minutes  │
│ Complexity: Medium-High  |  Agents Required: 6              │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research (Parallel - 3 agents)           ~8min    │
│   ├─ research-specialist: "JWT authentication patterns"    │
│   │    Report: specs/reports/jwt_patterns/001_*.md         │
│   ├─ research-specialist: "Security best practices"        │
│   │    Report: specs/reports/security/001_*.md             │
│   └─ research-specialist: "Token refresh strategies"       │
│        Report: specs/reports/token_refresh/001_*.md        │
│                                                              │
│ Phase 2: Planning (Sequential)                    ~5min    │
│   └─ plan-architect: Synthesize research into plan         │
│        Plan: specs/plans/NNN_user_authentication.md        │
│        Uses: 3 research reports                             │
│                                                              │
│ Phase 3: Implementation (Adaptive)                ~12min   │
│   └─ code-writer: Execute plan phase-by-phase              │
│        Files: auth/, middleware/, utils/                    │
│        Tests: test_auth.lua, test_jwt.lua                   │
│        Phases: 4 (1 sequential, 1 parallel wave)           │
│                                                              │
│ Phase 4: Debugging (Conditional)                  ~0min    │
│   └─ debug-specialist: Skipped (no test failures)          │
│        Triggers: Only if implementation tests fail          │
│        Max iterations: 3                                    │
│                                                              │
│ Phase 5: Documentation (Sequential)               ~3min    │
│   └─ doc-writer: Update docs and generate summary          │
│        Files: README.md, CHANGELOG.md, API.md               │
│        Summary: specs/summaries/NNN_*.md                    │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Phases: 5  |  Conditional Phases: 1  |  Parallel: Yes│
│   Agents Invoked: 6  |  Reports: 3  |  Plans: 1            │
│   Files Created: ~12  |  Tests: ~5                          │
│   Estimated Time: 28 minutes (20min with parallelism)      │
└─────────────────────────────────────────────────────────────┘

Proceed with workflow execution? (y/n):
```

### Dry-Run Implementation Preview

**Example: /implement Dry-Run**

```
┌────────────────────────────────────────────────────────┐
│ Implementation Plan Preview (Dry-Run)                  │
├────────────────────────────────────────────────────────┤
│ Plan: specs/plans/042_user_authentication.md          │
│ Phases: 5  |  Estimated Time: 8-12 hours               │
│ Starting Phase: 1                                       │
├────────────────────────────────────────────────────────┤
│ Phase 1: Database Schema (2-3 hours)                  │
│   Tasks: 8                                             │
│   Files: migrations/, models/user.lua                  │
│   Tests: test_user_model.lua                           │
│   Risk: Low                                            │
│                                                        │
│ Phase 2: Authentication Service (3-4 hours)           │
│   Tasks: 12                                            │
│   Files: services/auth.lua, middleware/jwt.lua         │
│   Tests: test_auth_service.lua, test_jwt_middleware.lua│
│   Risk: Medium                                         │
│                                                        │
│ Phase 3: API Endpoints (2-3 hours)                    │
│   Tasks: 10                                            │
│   Files: routes/auth.lua, controllers/auth.lua         │
│   Tests: test_auth_routes.lua                          │
│   Risk: Low                                            │
│                                                        │
│ Phase 4: Token Refresh (1-2 hours)                    │
│   Tasks: 6                                             │
│   Files: services/token_refresh.lua                    │
│   Tests: test_token_refresh.lua                        │
│   Risk: Medium                                         │
│                                                        │
│ Phase 5: Integration Testing (1-2 hours)              │
│   Tasks: 5                                             │
│   Files: tests/integration/auth_flow.lua               │
│   Tests: Full auth flow end-to-end                     │
│   Risk: Low                                            │
├────────────────────────────────────────────────────────┤
│ Execution Plan:                                         │
│   - Parse plan and validate structure                   │
│   - Execute each phase sequentially                     │
│   - Run tests after each phase                          │
│   - Create git commit for successful phases             │
│   - Save checkpoints for resumability                   │
│   - Adaptive replanning if complexity exceeds estimates │
└────────────────────────────────────────────────────────┘

Proceed with implementation? (y/n):
```

### Dry-Run Analysis Components

**Workflow Type Detection**:
```
feature      → Full workflow (research, planning, implementation, documentation)
refactor     → Skip research if standards exist
debug        → Start with debug phase
investigation → Research-only (skip implementation)
```

**Duration Estimation Algorithm**:
```python
duration = 0
duration += research_topics_count × 3  # 3 minutes per topic
duration += 5  # Planning phase (constant)
duration += plan_phases_count × (phase_complexity × 2)  # Implementation
duration += 3  # Documentation phase (constant)

# Adjust for parallelization
if parallel_mode:
    duration -= research_parallelization_savings
```

**Complexity Scoring**:
```python
score = 0
score += count_keywords(["implement", "architecture", "redesign"]) × 3
score += count_keywords(["add", "improve", "refactor"]) × 2
score += count_keywords(["security", "breaking", "core"]) × 4
score += estimated_file_count / 5
score += (research_topics_needed - 1) × 2

complexity = "Simple" if score < 4 else \
             "Medium" if score < 7 else \
             "High" if score < 10 else "Critical"
```

---

## Dashboard Progress Examples

### Overview

Dashboard-style progress tracking provides real-time visibility into long-running operations.

**Commands Using Dashboards**:
- `/implement` - Phase-by-phase implementation progress
- `/orchestrate` - Multi-phase workflow progress
- `/test-all` - Test suite execution progress

### Implementation Dashboard

**Example: /implement Dashboard Output**

```
╔════════════════════════════════════════════════════════════╗
║ Implementation Progress: User Authentication System        ║
╠════════════════════════════════════════════════════════════╣
║ Plan: specs/plans/042_user_authentication.md              ║
║ Progress: Phase 3/5 (60%)                                  ║
║ Duration: 5h 23m elapsed  |  Est. Remaining: 3h 15m        ║
╠════════════════════════════════════════════════════════════╣
║ ✓ Phase 1: Database Schema (COMPLETE)          2h 45m     ║
║   ✓ All 8 tasks complete                                   ║
║   ✓ Tests passing (test_user_model.lua)                    ║
║   ✓ Commit: a3f8c2e "feat: implement user database schema" ║
║                                                            ║
║ ✓ Phase 2: Authentication Service (COMPLETE)   3h 12m     ║
║   ✓ All 12 tasks complete                                  ║
║   ✓ Tests passing (test_auth_service.lua, test_jwt_middleware.lua)║
║   ✓ Commit: b7d4e1f "feat: implement JWT auth service"     ║
║                                                            ║
║ ⚙ Phase 3: API Endpoints (IN PROGRESS)         1h 23m     ║
║   ✓ Task 1-7 complete                                      ║
║   ⚙ Task 8: Implement /auth/refresh endpoint              ║
║   ○ Task 9-10 pending                                      ║
║   Tests: Not yet run                                       ║
║                                                            ║
║ ○ Phase 4: Token Refresh (PENDING)             Est. 1.5h  ║
║   ○ 6 tasks pending                                        ║
║                                                            ║
║ ○ Phase 5: Integration Testing (PENDING)       Est. 1.75h ║
║   ○ 5 tasks pending                                        ║
╠════════════════════════════════════════════════════════════╣
║ Status Legend: ✓ Complete | ⚙ In Progress | ○ Pending    ║
║                                                            ║
║ Checkpoints: Saved after each phase                        ║
║ Last checkpoint: .claude/checkpoints/implement_auth_phase2.json║
╚════════════════════════════════════════════════════════════╝
```

### Orchestration Workflow Dashboard

**Example: /orchestrate Dashboard Output**

```
╔════════════════════════════════════════════════════════════╗
║ Workflow Progress: User Authentication Implementation     ║
╠════════════════════════════════════════════════════════════╣
║ Type: feature  |  Mode: parallel  |  Duration: 23m elapsed║
╠════════════════════════════════════════════════════════════╣
║ ✓ Analysis Phase (COMPLETE)                      1m       ║
║   ✓ Workflow analyzed                                      ║
║   ✓ Research topics identified: 3                          ║
║   ✓ Complexity score: 8 (High)                             ║
║   ✓ Thinking mode: "think hard"                            ║
║                                                            ║
║ ✓ Research Phase (COMPLETE)                      8m       ║
║   ✓ Agent 1/3: existing_patterns (3m 12s)                 ║
║      Report: specs/reports/jwt_patterns/001_existing_patterns.md║
║   ✓ Agent 2/3: security_practices (3m 45s)                ║
║      Report: specs/reports/security/001_best_practices.md  ║
║   ✓ Agent 3/3: token_refresh (2m 58s)                     ║
║      Report: specs/reports/token_refresh/001_alternatives.md║
║   Parallelization savings: 4m 23s                          ║
║                                                            ║
║ ✓ Planning Phase (COMPLETE)                      5m       ║
║   ✓ Plan created: specs/plans/042_user_authentication.md  ║
║   ✓ Phases defined: 5                                      ║
║   ✓ Research reports integrated: 3                         ║
║                                                            ║
║ ⚙ Implementation Phase (IN PROGRESS)             9m       ║
║   ⚙ Executing phase 2/5 of implementation plan            ║
║   ✓ Phase 1 complete (tests passing)                       ║
║   ⚙ Phase 2 in progress (7/12 tasks complete)             ║
║                                                            ║
║ ○ Debugging Phase (PENDING)                      Est. 0m  ║
║   Conditional: Only if tests fail                          ║
║                                                            ║
║ ○ Documentation Phase (PENDING)                  Est. 3m  ║
║   Will generate workflow summary                           ║
╠════════════════════════════════════════════════════════════╣
║ Agents Invoked: 4  |  Files Created: 8  |  Tests: Passing║
╚════════════════════════════════════════════════════════════╝
```

### Dashboard Refresh Rate

```
Real-time commands:  Update every 1-2 seconds
Long operations:     Update every 5-10 seconds
Phase transitions:   Immediate update
```

### Dashboard Components

**Progress Bar**:
```
Progress: ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░ 60% (3/5 phases)
```

**Status Indicators**:
```
✓ Complete
⚙ In Progress
○ Pending
✗ Failed
⚠ Warning
```

**Time Tracking**:
```
Duration: 5h 23m elapsed  |  Est. Remaining: 3h 15m
```

---

## Checkpoint Save/Restore Examples

### Overview

Checkpoints enable resumability for long-running operations that may be interrupted.

**Commands Using Checkpoints**:
- `/implement` - Resume implementation from last completed phase
- `/orchestrate` - Resume workflow from last completed phase
- `/revise --auto-mode` - Resume plan revision after interruption

### Checkpoint Save Example

**After Completing a Phase**:
```bash
# Source checkpoint utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Create checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "completed_phases": $COMPLETED_PHASES,
  "tests_passing": $TESTS_PASSING,
  "files_modified": $FILES_MODIFIED,
  "timestamp": "$(date -Iseconds)"
}
EOF
)

# Save checkpoint
if save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"; then
  echo "✓ Checkpoint saved: .claude/checkpoints/implement_${PROJECT_NAME}_latest.json"
else
  echo "⚠ Warning: Checkpoint save failed - resume may not be possible"
fi
```

### Checkpoint Restore Example

**At Command Start**:
```bash
# Source checkpoint utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

# Check for existing checkpoint
CHECKPOINT_FILE=".claude/checkpoints/implement_${PROJECT_NAME}_latest.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  echo "Found existing checkpoint from interrupted implementation"
  echo ""

  # Display checkpoint info
  CHECKPOINT_TIME=$(jq -r '.timestamp' "$CHECKPOINT_FILE")
  CHECKPOINT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")
  COMPLETED_COUNT=$(jq -r '.completed_phases | length' "$CHECKPOINT_FILE")

  echo "Checkpoint Details:"
  echo "  Saved: $CHECKPOINT_TIME"
  echo "  Last completed phase: $CHECKPOINT_PHASE"
  echo "  Phases complete: $COMPLETED_COUNT"
  echo ""

  # Prompt user
  read -p "Resume from checkpoint? (y/n): " RESUME_CHOICE

  if [ "$RESUME_CHOICE" = "y" ]; then
    # Load checkpoint
    PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
    CURRENT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")
    COMPLETED_PHASES=$(jq -r '.completed_phases' "$CHECKPOINT_FILE")

    echo "✓ Resuming from phase $CURRENT_PHASE"

    # Continue implementation from current phase
    START_PHASE=$((CURRENT_PHASE + 1))
  else
    echo "Starting fresh implementation"
    START_PHASE=1
  fi
else
  # No checkpoint found - start fresh
  echo "No existing checkpoint found - starting fresh"
  START_PHASE=1
fi
```

### Checkpoint Auto-Resume Example

**Example: /implement Auto-Resume**:
```bash
# Run implement without arguments - auto-detects and resumes
/implement

# Output:
# Searching for resumable implementation...
# Found checkpoint: .claude/checkpoints/implement_user_auth_latest.json
#
# Plan: specs/plans/042_user_authentication.md
# Last completed phase: Phase 2 (Authentication Service)
# Next phase: Phase 3 (API Endpoints)
#
# Auto-resuming implementation from Phase 3...
#
# ✓ Checkpoint loaded
# ⚙ Starting Phase 3: API Endpoints
```

### Checkpoint Structure

**Implementation Checkpoint**:
```json
{
  "command": "implement",
  "plan_path": "/absolute/path/to/plan.md",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": [
    "migrations/001_create_users.lua",
    "models/user.lua",
    "services/auth.lua",
    "middleware/jwt.lua"
  ],
  "git_commits": [
    "a3f8c2e",
    "b7d4e1f"
  ],
  "timestamp": "2025-10-12T16:45:30-04:00",
  "performance": {
    "phase_durations": {
      "1": 9870,
      "2": 11520
    }
  }
}
```

**Orchestration Checkpoint**:
```json
{
  "command": "orchestrate",
  "workflow_description": "Add user authentication with JWT tokens",
  "workflow_type": "feature",
  "thinking_mode": "think hard",
  "current_phase": "implementation",
  "completed_phases": ["analysis", "research", "planning"],
  "project_name": "user_authentication_system",
  "research_reports": [
    "/absolute/path/to/report1.md",
    "/absolute/path/to/report2.md",
    "/absolute/path/to/report3.md"
  ],
  "plan_path": "/absolute/path/to/plan.md",
  "implementation_status": {
    "tests_passing": false,
    "current_phase": 3,
    "total_phases": 5
  },
  "debug_iteration": 0,
  "timestamp": "2025-10-12T16:45:30-04:00"
}
```

---

## Test Execution Patterns

### Overview

Consistent test execution patterns across commands for validation.

**Commands Using Test Execution**:
- `/implement` - Run tests after each phase
- `/test` - Run specific test targets
- `/test-all` - Run complete test suite

### Phase-Level Test Execution

**Example: /implement Phase Testing**:
```bash
# After completing phase tasks, run phase tests
echo "Running tests for Phase $CURRENT_PHASE..."

# Extract test commands from phase tasks
TEST_COMMANDS=$(grep -E "^\s*-\s*\[.\]\s*(Run|Test):" "$PLAN_FILE" | \
                grep -A1 "Phase $CURRENT_PHASE" | \
                sed 's/^.*: //')

if [ -n "$TEST_COMMANDS" ]; then
  # Execute each test command
  while IFS= read -r TEST_CMD; do
    echo "  Executing: $TEST_CMD"

    if eval "$TEST_CMD"; then
      echo "  ✓ Test passed"
    else
      echo "  ✗ Test failed"
      TESTS_PASSING=false
      break
    fi
  done <<< "$TEST_COMMANDS"
else
  # No explicit test commands - use default test pattern
  echo "  No explicit test command - using default pattern"

  # Detect test framework
  if [ -f "tests/run_tests.lua" ]; then
    lua tests/run_tests.lua
  elif [ -f "pytest.ini" ]; then
    pytest tests/
  elif [ -f "package.json" ]; then
    npm test
  else
    echo "  ⚠ No test framework detected"
  fi
fi

# Check test results
if [ "$TESTS_PASSING" = true ]; then
  echo "✓ All tests passing - proceeding to next phase"
else
  echo "✗ Tests failing - entering debugging loop"
  # Enter debugging loop
fi
```

### Test Suite Execution

**Example: /test-all**:
```bash
# Run complete test suite with progress tracking
echo "Running complete test suite..."
echo ""

# Discover all test files
TEST_FILES=$(find tests/ -name "test_*.lua" -o -name "*_spec.lua" | sort)
TOTAL_TESTS=$(echo "$TEST_FILES" | wc -l)
CURRENT_TEST=0
PASSED=0
FAILED=0

# Execute each test file
while IFS= read -r TEST_FILE; do
  CURRENT_TEST=$((CURRENT_TEST + 1))
  echo "[$CURRENT_TEST/$TOTAL_TESTS] Running: $TEST_FILE"

  if lua "$TEST_FILE" 2>&1 | tee /tmp/test_output.txt; then
    PASSED=$((PASSED + 1))
    echo "  ✓ Passed"
  else
    FAILED=$((FAILED + 1))
    echo "  ✗ Failed"

    # Capture failure details
    FAILURE_OUTPUT=$(cat /tmp/test_output.txt)
    echo "  Failure details:"
    echo "$FAILURE_OUTPUT" | sed 's/^/    /'
  fi

  echo ""
done <<< "$TEST_FILES"

# Display summary
echo "════════════════════════════════════════"
echo "Test Suite Results"
echo "════════════════════════════════════════"
echo "Total:  $TOTAL_TESTS tests"
echo "Passed: $PASSED tests ($(( PASSED * 100 / TOTAL_TESTS ))%)"
echo "Failed: $FAILED tests ($(( FAILED * 100 / TOTAL_TESTS ))%)"
echo "════════════════════════════════════════"

# Exit with appropriate code
if [ $FAILED -eq 0 ]; then
  echo "✓ All tests passing"
  exit 0
else
  echo "✗ $FAILED test(s) failed"
  exit 1
fi
```

### Test Framework Detection

```bash
# Detect project's test framework
detect_test_framework() {
  # Lua testing
  if [ -f "tests/run_tests.lua" ] || [ -f "spec/init.lua" ]; then
    echo "lua"
    return 0
  fi

  # Python testing
  if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    echo "pytest"
    return 0
  fi

  # JavaScript/Node testing
  if [ -f "package.json" ] && grep -q "\"test\":" package.json; then
    echo "npm"
    return 0
  fi

  # Go testing
  if [ -f "go.mod" ]; then
    echo "go"
    return 0
  fi

  # Rust testing
  if [ -f "Cargo.toml" ]; then
    echo "cargo"
    return 0
  fi

  echo "unknown"
  return 1
}

# Use detected framework
FRAMEWORK=$(detect_test_framework)
case "$FRAMEWORK" in
  lua)
    lua tests/run_tests.lua
    ;;
  pytest)
    pytest tests/
    ;;
  npm)
    npm test
    ;;
  go)
    go test ./...
    ;;
  cargo)
    cargo test
    ;;
  *)
    echo "⚠ Test framework not detected - manual testing required"
    return 1
    ;;
esac
```

---

## Git Commit Patterns

### Overview

Consistent git commit patterns for automated commits during implementation and documentation phases.

**Commands Creating Commits**:
- `/implement` - Commit after each successful phase
- `/document` - Commit documentation updates
- `/orchestrate` - Commit at workflow completion (via agents)

### Phase Completion Commit

**Example: /implement Phase Commit**:
```bash
# After phase completes successfully
echo "Creating git commit for Phase $CURRENT_PHASE..."

# Generate commit message
COMMIT_MSG=$(cat <<EOF
feat: implement Phase $CURRENT_PHASE - $PHASE_NAME

Automated implementation of phase $CURRENT_PHASE from implementation plan.

Changes:
$(git diff --cached --name-status | sed 's/^/- /')

Tests: All passing
Plan: $PLAN_PATH

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)

# Stage changes
git add .

# Create commit
if git commit -m "$COMMIT_MSG"; then
  COMMIT_HASH=$(git rev-parse --short HEAD)
  echo "✓ Commit created: $COMMIT_HASH"

  # Record in phase metadata
  echo "  Phase $CURRENT_PHASE committed as $COMMIT_HASH"
else
  echo "⚠ Warning: Git commit failed"
  echo "  Changes are still staged - manual commit required"
fi
```

### Workflow Completion Commit

**Example: /orchestrate Final Commit**:
```bash
# After workflow completes
echo "Creating final workflow commit..."

COMMIT_MSG=$(cat <<EOF
feat: complete workflow - $WORKFLOW_DESCRIPTION

Complete multi-agent workflow execution.

Research Reports:
$(echo "$RESEARCH_REPORTS" | while read path; do echo "- $path"; done)

Implementation Plan:
- $PLAN_PATH

Workflow Summary:
- $SUMMARY_PATH

Phases Completed: $COMPLETED_PHASES_COUNT
Agents Invoked: $AGENTS_INVOKED_COUNT
Duration: $TOTAL_DURATION

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)

# Stage all workflow artifacts
git add specs/reports/ specs/plans/ specs/summaries/
git add src/ tests/  # Implementation files

# Create commit
git commit -m "$COMMIT_MSG"
```

### Commit Message Structure

**Standard Format**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
```
feat:     New feature implementation
fix:      Bug fix
refactor: Code refactoring
docs:     Documentation changes
test:     Test additions or modifications
chore:    Build/tooling changes
```

**Example Commit Messages**:
```
feat: implement user authentication system

Automated implementation of 5-phase authentication plan.

Changes:
- Added user database schema and migrations
- Implemented JWT auth service and middleware
- Created auth API endpoints
- Added token refresh mechanism
- Comprehensive integration tests

Tests: All passing (42 tests, 100% coverage)
Plan: specs/plans/042_user_authentication.md

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Pre-Commit Validation

```bash
# Before committing, validate changes
pre_commit_validation() {
  echo "Validating changes before commit..."

  # Check for syntax errors
  if ! find . -name "*.lua" -exec luacheck {} \;; then
    echo "✗ Syntax errors detected - fix before committing"
    return 1
  fi

  # Check tests pass
  if ! run_tests; then
    echo "✗ Tests failing - fix before committing"
    return 1
  fi

  # Check for TODOs or FIXMEs in staged files
  if git diff --cached | grep -E "TODO|FIXME" > /dev/null; then
    echo "⚠ Warning: TODOs or FIXMEs in staged changes"
    read -p "Proceed with commit? (y/n): " PROCEED
    if [ "$PROCEED" != "y" ]; then
      return 1
    fi
  fi

  echo "✓ Pre-commit validation passed"
  return 0
}

# Use validation before committing
if pre_commit_validation; then
  git commit -m "$COMMIT_MSG"
else
  echo "Commit aborted - fix issues and retry"
fi
```

---

## Usage Notes

### Referencing This File

From commands:
```markdown
For detailed command examples, see:
`.claude/docs/command-examples.md`
```

### Example References by Section

**Dry-Run Example**:
```markdown
For dry-run output format, see:
`.claude/docs/command-examples.md#dry-run-mode-examples`
```

**Dashboard Example**:
```markdown
For dashboard progress format, see:
`.claude/docs/command-examples.md#dashboard-progress-examples`
```

**Checkpoint Example**:
```markdown
For checkpoint save/restore patterns, see:
`.claude/docs/command-examples.md#checkpoint-saverestore-examples`
```

### Updating Examples

When updating examples:
1. Update this file with new example versions
2. Update referencing commands to match new formats
3. Test examples with real command executions
4. Document changes in git commit message

---

**Last Updated**: 2025-10-13
**Used By**: /orchestrate, /implement, /revise, /test, /test-all, /document
**Related Files**:
- `.claude/commands/orchestrate.md`
- `.claude/commands/implement.md`
- `.claude/lib/checkpoint-utils.sh`
- `.claude/templates/orchestration-patterns.md`
