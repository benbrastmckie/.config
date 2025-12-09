# Research Report: Standards Compliance and Hard Barrier Enforcement for /revise Command

## Executive Summary

The /revise command currently suffers from workflow enforcement bypass vulnerabilities. Agent delegation occurs via instructional text patterns without hard barriers, allowing Claude to bypass the intended workflow and directly modify plan files. This report identifies enforcement mechanisms from the .claude/ infrastructure and provides actionable recommendations to fix /revise using patterns proven in /create-plan.

**Key Finding**: The root cause is the absence of the **Hard Barrier Pattern** (3-block Na/Nb/Nc sequence) that /create-plan successfully implements. The /revise command uses pseudo-code Task invocation patterns that Claude interprets as documentation rather than executable directives.

## 1. What Enforcement Mechanisms Exist?

### 1.1 Hard Barrier Subagent Delegation Pattern

**Location**: `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`

**Pattern Structure** (3-block sequence):
- **Block Na (Setup)**: Pre-calculate paths, transition state, persist variables
- **Block Nb (Execute)**: Invoke agent with imperative directive
- **Block Nc (Verify)**: Validate artifacts with fail-fast policy

**Key Requirements**:
1. **CRITICAL BARRIER labels**: Execute blocks must have explicit barrier warnings
2. **Path pre-calculation**: Output paths calculated BEFORE agent invocation
3. **Imperative Task directives**: "**EXECUTE NOW**: USE the Task tool to invoke..."
4. **Fail-fast verification**: Verify blocks exit 1 on missing artifacts
5. **Error logging**: All failures logged via `log_command_error()`

**Example from /create-plan** (Block 1e-exec, line 1432):
```markdown
**CRITICAL BARRIER**: The topic decomposition block MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate parallel research for ${FEATURE_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md
    ...
  "
}
```

### 1.2 Task Tool Invocation Patterns (Command Authoring Standards)

**Location**: `.claude/docs/reference/standards/command-authoring.md` (lines 99-295)

**PROHIBITED Patterns** (causes bypass):
```markdown
# ❌ Pattern 1: Naked Task block without imperative
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}

# ❌ Pattern 2: Instructional text without Task invocation
Use the Task tool to invoke the research-specialist agent.

# ❌ Pattern 3: Incomplete EXECUTE NOW directive
**EXECUTE NOW**: Invoke the research-specialist agent.
Task { ... }
```

**REQUIRED Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "[Brief description] with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-file].md

    **Workflow-Specific Context**:
    - [Variable 1]: ${VAR1}
    - Output Path: ${OUTPUT_PATH}

    Execute [action] per behavioral guidelines.
    Return: [SIGNAL_NAME]: ${OUTPUT_PATH}
  "
}
```

### 1.3 Validation Scripts (Enforcement Mechanisms)

**Location**: `.claude/scripts/` and `.claude/tests/utilities/`

| Script | What It Checks | Severity |
|--------|---------------|----------|
| `lint-task-invocation-pattern.sh` | Naked Task blocks, instructional text patterns, incomplete directives | ERROR |
| `validate-hard-barrier-compliance.sh` | Na/Nb/Nc block structure, CRITICAL BARRIER labels, fail-fast verification | ERROR |
| `check-library-sourcing.sh` | Three-tier sourcing pattern, fail-fast handlers | ERROR |

**Pre-Commit Integration**: These validators run automatically on staged command files, blocking commits with violations.

### 1.4 Pre-Commit Hook

**Location**: `.claude/hooks/pre-commit`

**Enforcement Flow**:
1. Detects staged `.claude/commands/*.md` files
2. Runs `lint-task-invocation-pattern.sh` on each file
3. Runs `validate-hard-barrier-compliance.sh` on orchestrator commands
4. Blocks commit on ERROR-level violations
5. Allows bypass via `git commit --no-verify` (requires justification)

## 2. How /create-plan Uses Hard Barriers Effectively

### 2.1 Research Phase Hard Barrier (Blocks 1d-topics, 1e-exec, 1f)

**Block 1d-topics** (Setup):
- Pre-calculates topic array and report paths
- Persists `TOPICS_LIST` and `REPORT_PATHS_LIST` to state
- Prepares contract for research-coordinator

**Block 1e-exec** (Execute - line 1432):
```markdown
**CRITICAL BARRIER**: The topic decomposition block MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Coordinate parallel research for ${FEATURE_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Workflow-Specific Context**:
    - Topics: ${TOPICS_JSON}
    - Report Paths: ${REPORT_PATHS_JSON}
    - Research Complexity: ${RESEARCH_COMPLEXITY}

    Execute research coordination per behavioral guidelines.
    Return: RESEARCH_COMPLETE: [summary of completed reports]
  "
}
```

**Block 1f** (Verify - line 1482):
```bash
# MANDATORY VERIFICATION (fail-fast pattern)
echo "Verifying research artifacts..."

# Load state
load_workflow_state "$WORKFLOW_ID" false

# Parse report paths from state
REPORT_PATHS_LIST=$(grep "^REPORT_PATHS_LIST=" "$STATE_FILE" | cut -d'=' -f2-)
REPORT_PATHS_ARRAY=$(echo "$REPORT_PATHS_LIST" | tr ',' ' ')

# Validate each report exists
for REPORT_PATH in $REPORT_PATHS_ARRAY; do
  if [ ! -f "$REPORT_PATH" ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "agent_error" \
      "Research-coordinator failed to create report" \
      "bash_block_1f" \
      "$(jq -n --arg path "$REPORT_PATH" '{expected_report: $path}')"

    echo "ERROR: Research report not found: $REPORT_PATH" >&2
    echo "RECOVERY: Check research-coordinator output for errors" >&2
    exit 1
  fi
done
```

**Key Success Factors**:
1. **Path pre-calculation prevents coordinator bypass**: Paths calculated in Block 1d-topics, passed as contract
2. **Imperative directive enforces execution**: "USE the Task tool" tells Claude to invoke, not skip
3. **Fail-fast verification catches missing artifacts**: exit 1 blocks workflow continuation
4. **Error logging enables debugging**: `log_command_error()` records failures for `/errors` query

### 2.2 Planning Phase Hard Barrier (Blocks 2a, 2b, 2c)

**Block 2a** (Setup):
- Transitions to STATE_PLAN via `sm_transition`
- Pre-calculates plan path and backup directory
- Collects research report metadata for injection

**Block 2b** (Execute - similar pattern):
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent via Task tool.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Generate implementation plan for ${FEATURE_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature: ${FEATURE_DESCRIPTION}
    - Plan Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_JSON}

    Execute plan creation per behavioral guidelines.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Block 2c** (Verify):
- Validates plan file exists at pre-calculated path
- Checks file size (must be >500 bytes)
- Validates plan structure (phase headings present)
- Logs errors and exits 1 on failures

## 3. Specific Changes Needed in /revise

### 3.1 Current /revise Issues

**Issue 1: Instructional Text Pattern in Block 4b (line 640)**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS}"
  prompt: "..."
}
```
**Problem**: No imperative directive ("**EXECUTE NOW**: USE the Task tool..."). Claude interprets this as documentation.

**Issue 2: Incomplete Barrier in Block 5b (line 1070)**
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan"
  prompt: "..."
}
```
**Problem**: Missing imperative directive between barrier label and Task block.

**Issue 3: Weak Verification in Block 4c (line 728)**
```bash
# Fail-fast: Check at least some reports exist
if [ "$TOTAL_REPORT_COUNT" -eq 0 ]; then
  # ... error handling
fi
```
**Problem**: Only checks total count, doesn't validate NEW reports created by research-specialist.

### 3.2 Required Changes

**Change 1: Fix Block 4b Task Invocation (line 640)**

**BEFORE**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS}"
  prompt: "..."
}
```

**AFTER**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: revise workflow

    **Workflow-Specific Context**:
    - Research Topic: Plan revision insights for: ${REVISION_DETAILS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-revise
    - Existing Plan: ${EXISTING_PLAN_PATH}

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}
```

**Change 2: Fix Block 5b Task Invocation (line 1070)**

**BEFORE**:
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent via Task tool.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan"
  prompt: "..."
}
```

**AFTER**:
```markdown
**CRITICAL BARRIER**: This section invokes the plan-architect agent via Task tool. The Task invocation is MANDATORY and CANNOT be bypassed.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are revising an implementation plan for: revise workflow

    **Workflow-Specific Context**:
    - Existing Plan Path: ${EXISTING_PLAN_PATH}
    - Backup Path: ${BACKUP_PATH}
    - Revision Details: ${REVISION_DETAILS}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-revise
    - Operation Mode: plan revision
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
    1. Use STEP 1-REV → STEP 2-REV → STEP 3-REV → STEP 4-REV workflow (revision flow)
    2. Use Edit tool (NEVER Write) for all modifications to existing plan file
    3. Preserve all [COMPLETE] phases unchanged (do not modify completed work)
    4. Update plan metadata (Date, Estimated Hours, Phase count) to reflect revisions

    Execute plan revision according to behavioral guidelines and return completion signal:
    PLAN_REVISED: ${EXISTING_PLAN_PATH}
  "
}
```

**Change 3: Strengthen Block 4c Verification (line 667)**

**BEFORE**:
```bash
# Count new reports created (may already have existing reports)
NEW_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' -type f -newer "$EXISTING_PLAN_PATH" 2>/dev/null | wc -l)

if [ "$NEW_REPORT_COUNT" -eq 0 ]; then
  echo "WARNING: No new research reports created"
  echo "NOTE: Proceeding with plan revision using existing reports"
fi
```

**AFTER**:
```bash
# Pre-calculate expected report path for hard barrier validation
EXPECTED_REPORT_PATH="${RESEARCH_DIR}/${REVISION_NUMBER}-${REVISION_TOPIC_SLUG}.md"

# MANDATORY VERIFICATION (fail-fast pattern)
echo "Verifying research artifacts..."

# Fail-fast: Check expected report exists
if [ ! -f "$EXPECTED_REPORT_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Research-specialist failed to create report at expected path" \
    "bash_block_4c" \
    "$(jq -n --arg expected "$EXPECTED_REPORT_PATH" --arg dir "$RESEARCH_DIR" \
       '{expected_path: $expected, reports_directory: $dir}')"

  echo "ERROR: Research report not found at expected path: $EXPECTED_REPORT_PATH" >&2
  echo "DIAGNOSTIC: Research-specialist must create report at pre-calculated path" >&2
  echo "RECOVERY: Verify research-specialist was invoked correctly in Block 4b" >&2
  exit 1
fi

# Validate file size (must be >100 bytes)
FILE_SIZE=$(wc -c < "$EXPECTED_REPORT_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Research report suspiciously small" \
    "bash_block_4c" \
    "$(jq -n --arg path "$EXPECTED_REPORT_PATH" --arg size "$FILE_SIZE" \
       '{report_path: $path, file_size_bytes: $size}')"

  echo "ERROR: Research report too small ($FILE_SIZE bytes)" >&2
  echo "DIAGNOSTIC: Report may be empty or corrupted" >&2
  exit 1
fi
```

**Change 4: Add Expected Report Path to Block 4a (line 607)**

**BEFORE**:
```bash
# Generate unique research topic for revision insights
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-30)
REVISION_NUMBER=$(find "$RESEARCH_DIR" -name 'revision_*.md' 2>/dev/null | wc -l | xargs)
REVISION_NUMBER=$((REVISION_NUMBER + 1))
```

**AFTER**:
```bash
# Generate unique research topic for revision insights
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-30)
REVISION_NUMBER=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l | xargs)
REVISION_NUMBER=$((REVISION_NUMBER + 1))

# Pre-calculate expected report path (Hard Barrier Pattern)
EXPECTED_REPORT_PATH="${RESEARCH_DIR}/${REVISION_NUMBER}-${REVISION_TOPIC_SLUG}.md"
```

**Change 5: Persist Expected Report Path (line 617)**

**BEFORE**:
```bash
append_workflow_state "REVISION_TOPIC_SLUG" "$REVISION_TOPIC_SLUG"
append_workflow_state "REVISION_NUMBER" "$REVISION_NUMBER"
```

**AFTER**:
```bash
append_workflow_state "REVISION_TOPIC_SLUG" "$REVISION_TOPIC_SLUG"
append_workflow_state "REVISION_NUMBER" "$REVISION_NUMBER"
append_workflow_state "EXPECTED_REPORT_PATH" "$EXPECTED_REPORT_PATH"
```

**Change 6: Update Block 4b Prompt to Use Expected Path (line 640)**

Add to prompt injection:
```markdown
- Output Path: ${EXPECTED_REPORT_PATH}

**CRITICAL**: You MUST write the research report to the EXACT path specified above.
```

### 3.3 Validation After Changes

**Step 1: Run Task Invocation Linter**
```bash
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/revise.md
# Expected: 0 violations (all Task blocks have imperative directives)
```

**Step 2: Run Hard Barrier Compliance Validator**
```bash
bash .claude/scripts/validate-hard-barrier-compliance.sh --command revise --verbose
# Expected: 100% compliance (Na/Nb/Nc structure, CRITICAL BARRIER labels, fail-fast verification)
```

**Step 3: Integration Test**
```bash
# Create test scenario
echo "revise plan at /tmp/test_plan.md based on security requirements" > /tmp/test_revise.txt

# Run command
/revise "$(cat /tmp/test_revise.txt)"

# Verify hard barrier enforcement:
# 1. research-specialist creates report at EXPECTED_REPORT_PATH
# 2. plan-architect modifies plan file (not identical to backup)
# 3. Workflow exits with PLAN_REVISED signal
```

## 4. Migration Checklist

### Phase 1: Fix Task Invocation Patterns
- [ ] Add "**EXECUTE NOW**: USE the Task tool..." directive to Block 4b (line 640)
- [ ] Add "**EXECUTE NOW**: USE the Task tool..." directive to Block 5b (line 1070)
- [ ] Update Block 4b prompt to include behavioral guideline reference
- [ ] Update Block 5b prompt to include behavioral guideline reference
- [ ] Update CRITICAL BARRIER label in Block 5b to include "CANNOT be bypassed" warning

### Phase 2: Implement Hard Barrier Verification
- [ ] Add EXPECTED_REPORT_PATH calculation to Block 4a (line 607)
- [ ] Persist EXPECTED_REPORT_PATH to state in Block 4a (line 617)
- [ ] Update Block 4b prompt to inject EXPECTED_REPORT_PATH
- [ ] Replace weak verification in Block 4c with fail-fast pattern (line 667)
- [ ] Add file size validation in Block 4c
- [ ] Add error logging to Block 4c failures

### Phase 3: Validation and Testing
- [ ] Run `lint-task-invocation-pattern.sh` on revise.md (expect 0 violations)
- [ ] Run `validate-hard-barrier-compliance.sh --command revise` (expect 100% compliance)
- [ ] Create integration test scenario with real plan file
- [ ] Verify research-specialist creates report at expected path
- [ ] Verify plan-architect modifies plan (not bypassed)
- [ ] Verify workflow exits with PLAN_REVISED signal

### Phase 4: Documentation Updates
- [ ] Update revise-command-guide.md with hard barrier pattern notes
- [ ] Add troubleshooting section for verification failures
- [ ] Update CLAUDE.md with enforcement mechanism cross-references

## 5. Related Patterns and Standards

### 5.1 Standards Documents
- **Command Authoring Standards** (`.claude/docs/reference/standards/command-authoring.md`):
  - Task Tool Invocation Patterns (lines 99-295)
  - Prohibited Patterns (lines 1773-1924)
- **Hard Barrier Pattern** (`.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`):
  - 3-Block Na/Nb/Nc Structure
  - CRITICAL BARRIER Requirements
- **Enforcement Mechanisms** (`.claude/docs/reference/standards/enforcement-mechanisms.md`):
  - Tool Inventory (lines 14-25)
  - Pre-Commit Integration (lines 333-366)

### 5.2 Reference Implementations
- **Working Command**: `/create-plan` (`.claude/commands/create-plan.md`)
  - Research Phase Hard Barrier (Blocks 1d-topics, 1e-exec, 1f)
  - Planning Phase Hard Barrier (Blocks 2a, 2b, 2c)
- **Validation Scripts**:
  - `lint-task-invocation-pattern.sh` (`.claude/scripts/`)
  - `validate-hard-barrier-compliance.sh` (`.claude/scripts/`)
  - Pre-commit hook (`.claude/hooks/pre-commit`)

### 5.3 Agent Behavioral Guidelines
- **research-specialist.md** (`.claude/agents/`)
  - STEP 1-4 workflow pattern
  - Mandatory file creation contract
  - Completion signal format
- **plan-architect.md** (`.claude/agents/`)
  - STEP 1-REV → STEP 2-REV → STEP 3-REV → STEP 4-REV revision workflow
  - Edit tool usage requirements
  - Metadata update requirements

## 6. Expected Outcomes

### 6.1 Before Fix (Current State)
- Claude bypasses research-specialist delegation
- Claude directly modifies plan files without agent invocation
- Verification blocks pass despite missing artifacts
- No error logging when delegation skipped

### 6.2 After Fix (Target State)
- Hard barriers enforce mandatory agent delegation
- Task invocations use imperative directives (cannot be ignored)
- Verification blocks fail-fast on missing artifacts
- All failures logged via `log_command_error()` for debugging
- Pre-commit hooks block commits with Task invocation violations

### 6.3 Success Metrics
- **Linter Validation**: 0 violations in `lint-task-invocation-pattern.sh`
- **Compliance Check**: 100% compliance in `validate-hard-barrier-compliance.sh`
- **Integration Test**: research-specialist and plan-architect both invoked successfully
- **Error Logging**: Failures queryable via `/errors --command /revise`

## 7. Conclusion

The /revise command's workflow bypass issue stems from missing hard barrier enforcement. The fix requires:

1. **Imperative Task Directives**: Add "**EXECUTE NOW**: USE the Task tool..." to Blocks 4b and 5b
2. **Path Pre-Calculation**: Calculate EXPECTED_REPORT_PATH in Block 4a before agent invocation
3. **Fail-Fast Verification**: Replace weak verification with exit 1 on missing artifacts
4. **Error Logging**: Log all failures for queryable debugging

These changes align /revise with the proven hard barrier pattern from /create-plan and comply with command authoring standards enforced by pre-commit hooks.

## Metadata

- **Research Date**: 2025-12-09
- **Workflow**: /create-plan research-and-plan
- **Complexity**: 3
- **Standards References**:
  - `.claude/docs/reference/standards/command-authoring.md`
  - `.claude/docs/reference/standards/enforcement-mechanisms.md`
  - `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`
- **Reference Implementation**: `.claude/commands/create-plan.md`
