# Command Development Guide - Troubleshooting

**Part 5 of 5** | [Index](command-development-index.md)

This document covers common mistakes, debugging techniques, and troubleshooting workflows.

---

   - Report file exists at $REPORT_PATH
   - Report contains all required sections
   ```
   - **Why inline**: Orchestrator (command) is responsible for verification
   - **Context**: Command/orchestrator responsibility

4. **JSON Schemas**
   ```json
   {
     "report_metadata": {
       "title": "string",
       "summary": "string (max 50 words)"
     }
   }
   ```
   - **Why inline**: Commands must parse and validate data structures
   - **Context**: Command/orchestrator responsibility

5. **Critical Warnings**
   ```markdown
   **CRITICAL**: Never create empty directories.
   **IMPORTANT**: File creation operations MUST be verified.
   ```
   - **Why inline**: Execution-critical constraints that commands enforce
   - **Context**: Command/orchestrator responsibility

**NOT Inline** - Behavioral Content (Reference Agent Files):

- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

These belong in `.claude/agents/*.md` files and are referenced via behavioral injection pattern.

See [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md) for complete decision criteria.

### 8.3 Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|---------------|------------------|
| **Using /expand for content changes** | /expand changes structure (creates files), not content | Use /revise to add/modify tasks or objectives |
| **Using /revise for structural reorganization** | Creating separate files is structural | Use /expand to extract phases to files |
| **Including all possible tools** | Increases security risk, violates least privilege | Include only tools actually needed |
| **Duplicating pattern documentation** | Creates maintenance burden, outdated copies | Reference docs with links |
| **Skipping standards discovery** | Inconsistent behavior across projects | Always discover and apply CLAUDE.md standards |
| **Hardcoding test commands** | Breaks in different projects | Discover test commands from CLAUDE.md |
| **Continuing after test failures** | Compounds issues in later phases | Stop, enter debugging loop, fix root cause |
| **Inline agent definitions** | Duplication across commands | Reference agent files via behavioral injection |
| **Large agent context passing** | Token waste | Use metadata-only passing (path + summary) |
| **Missing error handling** | Poor user experience on failures | Include retry logic and user escalation |

### 8.4 Dry-Run Mode Examples

Dry-run mode allows users to preview command execution without making changes or invoking agents. Commands supporting dry-run include `/orchestrate`, `/implement`, `/revise`, and `/plan`.

**Dry-Run Flag Usage**:
```bash
# Basic dry-run
/orchestrate "Add user authentication" --dry-run

# Dry-run with other flags
/implement plan_file.md --dry-run --starting-phase 3
```

**Example: /orchestrate Dry-Run Output**:
```
┌─────────────────────────────────────────────────────────────┐
│ Workflow: Add user authentication with JWT tokens (Dry-Run)│
├─────────────────────────────────────────────────────────────┤
│ Workflow Type: feature  |  Estimated Duration: ~28 minutes  │
│ Complexity: Medium-High  |  Agents Required: 6              │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research (Parallel - 3 agents)           ~8min    │
│   ├─ research-specialist: "JWT authentication patterns"    │
│   ├─ research-specialist: "Security best practices"        │
│   └─ research-specialist: "Token refresh strategies"       │
│                                                              │
│ Phase 2: Planning (Sequential)                    ~5min    │
│   └─ plan-architect: Synthesize research into plan         │
│                                                              │
│ Phase 3: Implementation (Adaptive)                ~12min   │
│   └─ code-writer: Execute plan phase-by-phase              │
│                                                              │
│ Phase 4: Debugging (Conditional)                  ~0min    │
│   └─ debug-specialist: Skipped (no test failures)          │
│                                                              │
│ Phase 5: Documentation (Sequential)               ~3min    │
│   └─ doc-writer: Update docs and generate summary          │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Phases: 5  |  Conditional Phases: 1  |  Parallel: Yes│
│   Estimated Time: 28 minutes (20min with parallelism)      │
└─────────────────────────────────────────────────────────────┘
```

**Workflow Type Detection**:
```
feature      → Full workflow (research, planning, implementation, documentation)
refactor     → Skip research if standards exist
debug        → Start with debug phase
investigation → Research-only (skip implementation)
```

### 8.5 Dashboard Progress Examples

Dashboard-style progress tracking provides real-time visibility into long-running operations. Commands using dashboards include `/implement`, `/orchestrate`, and `/test-all`.

**Example: /implement Dashboard Output**:
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
║   ✓ Tests passing (test_auth_service.lua)                  ║
║   ✓ Commit: b7d4e1f "feat: implement JWT auth service"     ║
║                                                            ║
║ ⚙ Phase 3: API Endpoints (IN PROGRESS)         1h 23m     ║
║   ✓ Task 1-7 complete                                      ║
║   ⚙ Task 8: Implement /auth/refresh endpoint              ║
║   ○ Task 9-10 pending                                      ║
║                                                            ║
║ ○ Phase 4: Token Refresh (PENDING)             Est. 1.5h  ║
║ ○ Phase 5: Integration Testing (PENDING)       Est. 1.75h ║
╠════════════════════════════════════════════════════════════╣
║ Status Legend: ✓ Complete | ⚙ In Progress | ○ Pending    ║
╚════════════════════════════════════════════════════════════╝
```

**Status Indicators**:
```
✓ Complete
⚙ In Progress
○ Pending
✗ Failed
⚠ Warning
```

### 8.6 Checkpoint Save/Restore Examples

Checkpoints enable resumability for long-running operations that may be interrupted. Commands using checkpoints include `/implement`, `/orchestrate`, and `/revise --auto-mode`.

**Checkpoint Save Pattern**:
```bash
# Source checkpoint utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/checkpoint-utils.sh"

# Create checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "command": "implement",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "completed_phases": $COMPLETED_PHASES,
  "tests_passing": $TESTS_PASSING,
  "timestamp": "$(date -Iseconds)"
}
EOF
)

# Save checkpoint
if save_checkpoint "implement_${PROJECT_NAME}" "$CHECKPOINT_DATA"; then
  echo "✓ Checkpoint saved"
fi
```

**Checkpoint Restore Pattern**:
```bash
# Check for existing checkpoint
CHECKPOINT_FILE=".claude/checkpoints/implement_${PROJECT_NAME}_latest.json"

if [ -f "$CHECKPOINT_FILE" ]; then
  # Display checkpoint info
  CHECKPOINT_TIME=$(jq -r '.timestamp' "$CHECKPOINT_FILE")
  CHECKPOINT_PHASE=$(jq -r '.current_phase' "$CHECKPOINT_FILE")

  echo "Found checkpoint from $CHECKPOINT_TIME"
  read -p "Resume from phase $CHECKPOINT_PHASE? (y/n): " RESUME

  if [ "$RESUME" = "y" ]; then
    # Load checkpoint
    PLAN_PATH=$(jq -r '.plan_path' "$CHECKPOINT_FILE")
    START_PHASE=$((CHECKPOINT_PHASE + 1))
    echo "✓ Resuming from phase $START_PHASE"
  fi
fi
```

**Checkpoint Structure**:
```json
{
  "command": "implement",
  "plan_path": "/absolute/path/to/plan.md",
  "current_phase": 2,
  "completed_phases": [1, 2],
  "tests_passing": true,
  "files_modified": ["migrations/001_create_users.lua"],
  "git_commits": ["a3f8c2e", "b7d4e1f"],
  "timestamp": "2025-10-12T16:45:30-04:00"
}
```

### 8.7 Test Execution Patterns

Consistent test execution patterns across commands for validation. Commands using test execution include `/implement`, `/test`, and `/test-all`.

**Phase-Level Test Execution**:
```bash
# After completing phase tasks, run phase tests
echo "Running tests for Phase $CURRENT_PHASE..."

# Extract test commands from phase tasks
TEST_COMMANDS=$(grep -E "^\s*-\s*\[.\]\s*(Run|Test):" "$PLAN_FILE" | \
                grep -A1 "Phase $CURRENT_PHASE" | \
                sed 's/^.*: //')

if [ -n "$TEST_COMMANDS" ]; then
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
  # No explicit test commands - use default pattern
  if [ -f "tests/run_tests.lua" ]; then
    lua tests/run_tests.lua
  elif [ -f "pytest.ini" ]; then
    pytest tests/
  elif [ -f "package.json" ]; then
    npm test
  fi
fi
```

**Test Framework Detection**:
```bash
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

  echo "unknown"
  return 1
}
```

### 8.8 Git Commit Patterns

Consistent git commit patterns for automated commits during implementation phases. Commands creating commits include `/implement`, `/document`, and `/orchestrate`.

**Phase Completion Commit**:
```bash
# After phase completes successfully
echo "Creating git commit for Phase $CURRENT_PHASE..."

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

# Stage and commit
git add .
if git commit -m "$COMMIT_MSG"; then
  COMMIT_HASH=$(git rev-parse --short HEAD)
  echo "✓ Commit created: $COMMIT_HASH"
fi
```

**Commit Message Structure**:
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

**Pre-Commit Validation**:
```bash
pre_commit_validation() {
  echo "Validating changes before commit..."

  # Check for syntax errors
  if ! find . -name "*.lua" -exec luacheck {} \;; then
    echo "✗ Syntax errors detected"
    return 1
  fi

  # Check tests pass
  if ! run_tests; then
    echo "✗ Tests failing"
    return 1
  fi

  echo "✓ Pre-commit validation passed"
  return 0
}
```

### 8.9 Context Preservation Examples

**Metadata-Only Passing Example** (Standard 6):

Traditional approach passes full content (15,000 tokens):
```bash
REPORT_1=$(cat specs/reports/001_jwt_patterns.md)    # 5000 tokens
REPORT_2=$(cat specs/reports/002_security.md)        # 5000 tokens
REPORT_3=$(cat specs/reports/003_integration.md)     # 5000 tokens

# Pass to planning agent (15,000 tokens!)
Task {
  prompt: "Research Reports: $REPORT_1 $REPORT_2 $REPORT_3"
}
```

Metadata-only approach (250 tokens):
```bash
# Extract metadata (not full content)
for report in "${REPORTS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_REFS+=("$METADATA")
done

# Pass metadata only (250 tokens - 99% reduction)
Task {
  prompt: "Research Reports (reference): ${REPORT_REFS[@]}
           Use Read tool to access full content selectively if needed."
}
```

**Benefits**: 15,000 tokens → 250 tokens (98% reduction), full details preserved in files.

**Forward Message Pattern** (Standard 7):

Traditional re-summarization (400 tokens overhead):
```bash
# Research completes
RESEARCH_SUMMARY="Research found JWT patterns with HMAC-SHA256..."

# Planning phase
Task { prompt: "Prior Research: $RESEARCH_SUMMARY" }
```

Forward message approach (0 tokens overhead):
```bash
# Research completes
HANDOFF=$(forward_message "$RESEARCH_RESULT")  # Extract agent's summary

# Planning phase - use agent's original words
Task { prompt: "Previous Phase: $HANDOFF" }
```

**Benefits**: Eliminates 200-300 tokens per transition, preserves agent's structure.

**Context Pruning Example** (Standard 8):

Without pruning (29,000 tokens accumulated):
```bash
# Research: 15,000 tokens
# Planning: +3,000 = 18,000 tokens
# Implementation: +10,000 = 28,000 tokens
# Documentation: +1,000 = 29,000 tokens
```

With aggressive pruning (1,500 tokens):
```bash
# After research: prune to metadata (750 tokens)
prune_subagent_output "$output" "$METADATA"

# After planning: prune to metadata (1,000 tokens total)
prune_phase_metadata --keep-recent 1

# After implementation: (1,500 tokens total)
prune_phase_metadata --keep-recent 0
```

**Benefits**: 29,000 tokens → 1,500 tokens (95% reduction), enables long-running workflows.

---

## Common Mistakes and Solutions

This section documents frequent errors when developing commands and their resolutions.

### Mistake 1: Agent Invocation Wrapped in Code Blocks

**Problem**: Agent invocations placed inside markdown code fences (```yaml```) prevent execution.

❌ **Incorrect**:
```markdown
Research should be conducted as follows:

```yaml
Task {
  subagent_type: "general-purpose"
  ...
}
```
```

✅ **Correct**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-analyst.

Provide context via behavioral injection pattern:
- Read and follow: .claude/agents/research-analyst.md
- Inject operational context
- Signal completion with REPORT_CREATED:
```

**Solution**: Remove code fences, use imperative instructions, invoke Task tool directly.

**See**: [Standard 11: Imperative Agent Invocation](../reference/architecture/overview.md#standard-11)

### Mistake 2: Missing Verification Checkpoints

**Problem**: Files created without verification, leading to silent failures and 0% creation rate.

❌ **Incorrect**:
```bash
# Create report
cat > /path/to/report.md <<EOF
content
EOF

# Assume success, continue...
```

✅ **Correct**:
```bash
# Create report
cat > /path/to/report.md <<EOF
content
EOF

# MANDATORY VERIFICATION
if [ ! -f /path/to/report.md ]; then
  echo "ERROR: File creation failed"
  echo "FALLBACK: Attempting Write tool..."
  # Fallback mechanism
fi

# VERIFY CONTENT (not placeholder)
if grep -q "TODO" /path/to/report.md; then
  echo "ERROR: File contains placeholder content"
fi
```

**Solution**: Add verification after every file creation, implement fallback mechanisms.

**See**: [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md)

### Mistake 3: Using "Should/May/Can" Instead of "Must/Will/Shall"

**Problem**: Permissive language creates documentation instead of executable instructions.

❌ **Incorrect**:
```markdown
The command should create a report.
Agents may be invoked for research.
You can use the behavioral injection pattern.
```

✅ **Correct**:
```markdown
The command MUST create a report.
Agents WILL be invoked for research.
You SHALL use the behavioral injection pattern.
```

**Solution**: Replace all permissive language with imperative directives.

**See**: [Imperative Language Guide](../../patterns/execution-enforcement/execution-enforcement-overview.md)

### Mistake 4: Invoking Commands with SlashCommand Tool

**Problem**: Commands invoking other commands via SlashCommand create role ambiguity and context bloat.

❌ **Incorrect**:
```yaml
SlashCommand { command: "/research topic" }
```

✅ **Correct**:
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: "
    Read and follow: .claude/agents/research-analyst.md
    You are acting as Research Analyst.

    Research the following topic: [details]...
  "
}
```

**Solution**: Use Task tool with behavioral injection pattern instead of SlashCommand.

**See**: [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

### Mistake 5: Missing Completion Signals

**Problem**: Agents complete work but supervisors can't detect completion, leading to workflow hangs.

❌ **Incorrect**:
```markdown
Agent prompt:
"Research authentication patterns and create a report."
```

✅ **Correct**:
```markdown
Agent prompt:
"Research authentication patterns and create a report.

SIGNAL COMPLETION: When research is complete, output:
REPORT_CREATED: /full/path/to/report.md"
```

**Solution**: Always require explicit completion signals (REPORT_CREATED:, PLAN_CREATED:, etc.).

**See**: [Behavioral Injection Pattern - Completion Signals](../concepts/patterns/behavioral-injection.md#completion-signals)

### Mistake 6: Passing Full Content Instead of Metadata

**Problem**: Passing full report/plan content between agents causes context bloat.

❌ **Incorrect** (15,000 tokens):
```yaml
prompt: "
  Previous research findings:
  [Full 15,000 token report content pasted here]

  Use these findings to create plan...
"
```

✅ **Correct** (750 tokens):
```yaml
prompt: "
  Previous research: See .claude/specs/027/reports/001_auth.md

  Summary: OAuth 2.0 recommended for API authentication
  Key findings: [50-word summary]

  Use report reference to create plan...
"
```

**Solution**: Pass metadata (path + 50-word summary), not full content. 95% context reduction.

**See**: [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md)

### Mistake 7: No Fail-Fast Error Handling

**Problem**: Errors in early steps propagate silently, causing cascading failures.

❌ **Incorrect**:
```bash
mkdir -p /path/to/dir
cd /path/to/dir
cat > report.md <<EOF
content
EOF
# No error checking
```

✅ **Correct**:
```bash
set -e  # Exit on error

mkdir -p /path/to/dir || {
  echo "ERROR: Failed to create directory"
  exit 1
}

cd /path/to/dir || {
  echo "ERROR: Failed to change directory"
  exit 1
}

cat > report.md <<EOF
content
EOF

[ -f report.md ] || {
  echo "ERROR: File creation failed"
  exit 1
}
```

**Solution**: Use `set -e`, check critical operations, fail fast with clear messages.

**See**: [Error Handling Flowchart](../../../reference/decision-trees/error-handling-flowchart.md)

### Mistake 8: Relative Paths Without Verification

**Problem**: Relative paths break when working directory changes unexpectedly.

❌ **Incorrect**:
```bash
cat reports/001_findings.md  # Assumes current directory
```

✅ **Correct**:
```bash
# Option 1: Use absolute paths
cat /home/benjamin/.config/.claude/specs/027/reports/001_findings.md

# Option 2: Verify working directory
pwd  # Confirm location
ls reports/ || {
  echo "ERROR: reports/ directory not found in $(pwd)"
  exit 1
}
cat reports/001_findings.md
```

**Solution**: Prefer absolute paths, verify working directory, check paths exist.

**See**: [Error Handling Flowchart - File Errors](../../../reference/decision-trees/error-handling-flowchart.md#b-file-operation-errors)

### Mistake 9: Synchronous Agent Dependencies

**Problem**: Launching agents sequentially when they could run in parallel, missing 40-60% time savings.

❌ **Incorrect** (sequential, 120 min):
```yaml
Task { research OAuth }    # 40 min
Task { research JWT }      # 40 min
Task { research sessions } # 40 min
```

✅ **Correct** (parallel, 40 min):
```yaml
# Launch all three in single message (parallel execution)
Task { research OAuth }
Task { research JWT }
Task { research sessions }
```

**Solution**: Launch independent agents in parallel (single message, multiple Task blocks).

**See**: [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md)

### Mistake 10: Excessive Template Content Inline

**Problem**: Duplicating large templates in command files instead of referencing agent behavior files.

❌ **Incorrect** (3,000 lines duplicated):
```markdown
## Agent Prompt Template

[3,000 lines of agent behavior pasted inline]
```

✅ **Correct** (reference):
```markdown
## Agent Invocation

Agents MUST follow behavioral specifications:

- Research: `.claude/agents/research-analyst.md`
- Planning: `.claude/agents/plan-architect.md`
- Implementation: `.claude/agents/implementation-researcher.md`

Use behavioral injection pattern to reference these files.
```

**Solution**: Reference agent behavioral files, don't duplicate inline.

**See**: [Standard 7: Reference Don't Duplicate](../reference/architecture/overview.md#standard-7)

### Quick Diagnostic Checklist

When command isn't working as expected, check:

- [ ] Agent invocations use imperative pattern (not code blocks)
- [ ] File creation has verification checkpoints
- [ ] All required actions use MUST/WILL/SHALL
- [ ] Agents invoked via Task tool (not SlashCommand)
- [ ] Completion signals required (REPORT_CREATED:, etc.)
- [ ] Metadata passed instead of full content
- [ ] Fail-fast error handling (`set -e`, explicit checks)
- [ ] Absolute paths used or working directory verified
- [ ] Independent agents launched in parallel
- [ ] Templates referenced, not duplicated inline

### Troubleshooting Resources

- [Agent Delegation Troubleshooting](../troubleshooting/agent-delegation-troubleshooting.md) - Complete delegation debug guide
- [Orchestration Troubleshooting](../guides/orchestration/orchestration-troubleshooting.md) - Workflow debugging
- [Error Handling Flowchart](../../../reference/decision-trees/error-handling-flowchart.md) - Quick error diagnosis
- [Command Architecture Standards](../reference/architecture/overview.md) - All 11 standards

---

## Cross-References

### Architectural Patterns

Commands should implement these patterns from the [Patterns Catalog](../concepts/patterns/README.md):

- [Behavioral Injection](../concepts/patterns/behavioral-injection.md) - How commands invoke agents via context injection
- [Verification and Fallback](../concepts/patterns/verification-fallback.md) - Mandatory checkpoints for file creation operations
- [Metadata Extraction](../concepts/patterns/metadata-extraction.md) - Passing report/plan summaries between agents
- [Checkpoint Recovery](../concepts/patterns/checkpoint-recovery.md) - State preservation for resumable workflows
- [Parallel Execution](../concepts/patterns/parallel-execution.md) - Wave-based concurrent agent invocation

### Related Guides

- [Agent Development Guide](../agent-development/agent-development-fundamentals.md) - Creating agents that commands invoke
- [Standards Integration](standards-integration.md) - Implementing CLAUDE.md standards discovery
- [Testing Patterns](testing-patterns.md) - Test organization and validation approaches
- [Execution Enforcement Guide](../../patterns/execution-enforcement/execution-enforcement-overview.md) - Migration patterns for command refactoring

### Reference Documentation

- [Command Quick Reference](../reference/standards/command-reference.md) - Quick lookup for all commands
- [Command Architecture Standards](../reference/architecture/overview.md) - Architecture standards for commands/agents
- [Agent Reference](../reference/standards/agent-reference.md) - Quick agent reference
- [Commands README](../../commands/README.md) - Complete command list and navigation
- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md) - Multi-agent coordination

---

**Notes**:
- For specific implementation patterns, reference documentation rather than duplicating
- Follow the Development Philosophy: present-focused documentation, no historical markers
- Use Unicode box-drawing for diagrams, no emojis in content
- Maintain cross-references to related documentation
