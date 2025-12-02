# Plan Metadata Field Deficiency Fix Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Fix plan metadata field deficiencies in /repair and /revise commands
- **Scope**: Add standards extraction and passing to plan-architect agent in /repair and /revise commands to ensure plans have required metadata fields (Status, Standards File, etc.)
- **Estimated Phases**: 5
- **Estimated Hours**: 6.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Research Reports**:
  - [Plan Metadata Deficiency Research](/home/benjamin/.config/.claude/specs/997_plan_metadata_field_deficiency/reports/001-plan-metadata-deficiency-research.md)
  - [Uniform Plan Creation Research](/home/benjamin/.config/.claude/specs/997_plan_metadata_field_deficiency/reports/002-uniform-plan-creation-research.md)

## Overview

The `/repair` and `/revise` commands currently generate plans with inconsistent metadata structures because they do not extract and pass project standards to the plan-architect agent. This causes plans to lack required fields like **Status** and **Standards File**, making them incompatible with downstream automation tools like `/implement` and `/build`.

This plan implements standards integration in both commands by:
1. Adding standards extraction blocks before plan-architect invocation
2. Injecting formatted standards into Task prompts
3. Ensuring consistent plan metadata structure across all planning commands

## Research Summary

Brief synthesis of key findings from research reports:

**Report 1 - Plan Metadata Deficiency Research**:
- `/plan` command correctly uses `standards-extraction.sh` library and passes formatted standards to plan-architect (lines 1146-1201)
- `/repair` and `/revise` commands completely omit standards extraction, causing plan-architect to generate non-standard metadata
- Plan-architect agent EXPECTS "**Project Standards**:" section in prompt and validates Status field presence
- Plans from `/repair` and `/revise` use incompatible metadata field names (Plan ID, Created, Revised vs Date, Feature, Status)
- The `standards-extraction.sh` library exists and is production-ready but unused by 2 of 3 planning commands

**Report 2 - Uniform Plan Creation Research**:
- Canonical pattern established by `/plan` command at lines 1146-1210
- Infrastructure components: `standards-extraction.sh` library, `plan-architect.md` agent, validation utilities
- Standard metadata template includes: Date, Feature, Scope, Estimated Phases, Estimated Hours, Standards File, Status, Research Reports
- This plan already follows the uniform standard pattern (validated against canonical implementation)
- Standards-Integrated Plan Creation pattern: Standards extraction → State persistence → Task prompt injection → Plan verification

Recommended approach based on research: Copy the proven standards extraction pattern from `/plan` command into both `/repair` and `/revise` commands. This ensures architectural consistency and plan metadata compatibility.

## Success Criteria
- [ ] `/repair` command sources standards-extraction.sh library
- [ ] `/repair` command passes FORMATTED_STANDARDS to plan-architect Task prompt
- [ ] `/revise` command sources standards-extraction.sh library
- [ ] `/revise` command passes FORMATTED_STANDARDS to plan-architect Task prompt
- [ ] Plans created by `/repair` include Status field in metadata
- [ ] Plans created by `/repair` include Standards File field in metadata
- [ ] Plans created by `/revise` include Status field in metadata (when creating from scratch or converting format)
- [ ] All new plans use standard field names (Date, Feature, Status) instead of legacy format (Plan ID, Created, Revised)
- [ ] Integration tests verify plan metadata compatibility across all planning commands

## Technical Design

### Architecture

The standards integration pattern follows this flow:

```
Command Orchestrator
  └─> Source standards-extraction.sh library
  └─> Extract CLAUDE.md sections (format_standards_for_prompt)
  └─> Persist FORMATTED_STANDARDS to workflow state
  └─> Pass standards to plan-architect via Task prompt
      └─> Plan-architect validates alignment and generates standard metadata
```

### Standards Extraction Library Usage

```bash
# Source library (with error handling)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "file_error" "Failed to source standards-extraction library" "..."
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards
FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
  log_command_error "execution_error" "Standards extraction failed" "{}"
  echo "WARNING: Standards extraction failed, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Persist for plan-architect block
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"
```

### Task Prompt Injection

```markdown
Task {
  prompt: "
    **Project Standards**:
    ${FORMATTED_STANDARDS}

    Execute planning according to behavioral guidelines...
  "
}
```

### Block Placement

- `/repair`: Add standards extraction as new **Block 1g** (after state initialization, before Block 2b-exec plan creation delegation)
- `/revise`: Add standards extraction as new **Block 5a** (after research verification, before Block 5b-exec plan revision delegation)

## Implementation Phases

### Phase 1: Add Standards Extraction to /repair Command [COMPLETE]
dependencies: []

**Objective**: Integrate standards extraction library into /repair command workflow
**Complexity**: Low

Tasks:
- [x] Add standards extraction block to /repair command after Block 2a (planning setup) (file: .claude/commands/repair.md)
- [x] Source standards-extraction.sh library with error handling
- [x] Call format_standards_for_prompt and capture output
- [x] Persist FORMATTED_STANDARDS to workflow state using append_workflow_state with heredoc syntax
- [x] Add graceful degradation if standards extraction fails (set FORMATTED_STANDARDS to empty string)
- [x] Update block numbering: new Block 2a-standards, shift Block 2b onwards

**Block Structure**:
```markdown
## Block 2a-standards: Extract Project Standards

**EXECUTE NOW**: Extract project standards for plan-architect agent.

```bash
set +H  # CRITICAL: Disable history expansion

# === RESTORE STATE FROM BLOCK 2A ===
[... state restoration code ...]

# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source standards-extraction library" \
    "bash_block_2a_standards" \
    "$(jq -n --arg path "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" '{library_path: $path}')"
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards for prompt injection
if [ -z "${FORMATTED_STANDARDS:-}" ]; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "execution_error" \
      "Standards extraction failed" \
      "bash_block_2a_standards" \
      "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# Persist standards for Block 2b-exec divergence detection
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"

if [ -n "$FORMATTED_STANDARDS" ]; then
  STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
  echo "Extracted $STANDARDS_COUNT standards sections for plan-architect"
else
  echo "No standards extracted (graceful degradation)"
fi

echo ""
echo "[CHECKPOINT] Standards extraction complete"
\```
```

Testing:
```bash
# Test standards extraction block in isolation
cd /home/benjamin/.config
WORKFLOW_ID="test_repair_$(date +%s)"
COMMAND_NAME="/repair"
USER_ARGS="test repair"
export WORKFLOW_ID COMMAND_NAME USER_ARGS

# Initialize minimal state file
mkdir -p .claude/tmp
STATE_FILE=".claude/tmp/workflow_${WORKFLOW_ID}.sh"
echo "WORKFLOW_ID=$WORKFLOW_ID" > "$STATE_FILE"
echo "COMMAND_NAME=$COMMAND_NAME" >> "$STATE_FILE"
export STATE_FILE

# Source required libraries
source .claude/lib/core/error-handling.sh
source .claude/lib/core/state-persistence.sh
ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Execute standards extraction
source .claude/lib/plan/standards-extraction.sh 2>/dev/null || {
  echo "WARNING: Standards extraction unavailable"
  FORMATTED_STANDARDS=""
}

FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || FORMATTED_STANDARDS=""

if [ -n "$FORMATTED_STANDARDS" ]; then
  echo "SUCCESS: Extracted $(echo "$FORMATTED_STANDARDS" | grep -c '^###') sections"
  echo "$FORMATTED_STANDARDS" | head -20
else
  echo "FAIL: No standards extracted"
fi

# Cleanup
rm -f "$STATE_FILE"
```

Success Criteria:
- [ ] Standards extraction block executes without errors
- [ ] FORMATTED_STANDARDS contains at least 4 sections (code_standards, testing_protocols, documentation_policy, error_logging)
- [ ] Standards are persisted to workflow state file
- [ ] Graceful degradation works if library missing (empty FORMATTED_STANDARDS, no exit)

### Phase 2: Inject Standards into /repair Task Prompt [COMPLETE]
dependencies: [1]

**Objective**: Pass extracted standards to plan-architect agent in /repair command
**Complexity**: Low

Tasks:
- [x] Modify Block 2b-exec Task prompt to include "**Project Standards**:" section (file: .claude/commands/repair.md)
- [x] Use ${FORMATTED_STANDARDS} variable substitution for standards content
- [x] Ensure standards section appears BEFORE repair-specific requirement section
- [x] Verify standards variable is restored from workflow state in Block 2b (before Task invocation)

**Task Prompt Structure**:
```markdown
## Block 2b-exec: Plan Creation Delegation

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are creating an implementation plan for: repair workflow

    **Input Contract (Hard Barrier Pattern)**:
    - Plan Path: ${PLAN_PATH}
    - Feature Description: ${ERROR_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_JSON}
    - Workflow Type: research-and-plan
    - Operation Mode: new plan creation

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **CRITICAL**: You MUST create the plan file at the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.

    **REPAIR-SPECIFIC REQUIREMENT**:
    [... existing repair phase content ...]

    Execute planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}
```

Testing:
```bash
# Test Task prompt includes standards (dry-run simulation)
cd /home/benjamin/.config

# Create mock state file with standards
WORKFLOW_ID="test_repair_$(date +%s)"
STATE_FILE=".claude/tmp/workflow_${WORKFLOW_ID}.sh"
mkdir -p .claude/tmp

cat > "$STATE_FILE" <<'EOF'
WORKFLOW_ID=test_repair_12345
ERROR_DESCRIPTION="test error repair"
PLAN_PATH="/tmp/test_plan.md"
REPORT_PATHS_JSON='["/tmp/report1.md"]'
FORMATTED_STANDARDS="### Code Standards
Test standards content here

### Testing Protocols
Test protocols content here"
EOF

# Source state and verify variable expansion
source "$STATE_FILE"

# Simulate Task prompt construction (using cat with variable expansion)
cat <<TASK_PROMPT
Task {
  prompt: "
    **Project Standards**:
    ${FORMATTED_STANDARDS}

    Execute planning...
  "
}
TASK_PROMPT

# Verify output contains "### Code Standards" and "### Testing Protocols"
if cat <<PROMPT | grep -q "### Code Standards"; then
    **Project Standards**:
    ${FORMATTED_STANDARDS}
PROMPT
  echo "SUCCESS: Standards injected into Task prompt"
else
  echo "FAIL: Standards not found in Task prompt"
fi

# Cleanup
rm -f "$STATE_FILE"
```

Success Criteria:
- [ ] Task prompt contains "**Project Standards**:" section
- [ ] ${FORMATTED_STANDARDS} variable expands correctly in prompt
- [ ] Standards section appears before repair-specific requirements
- [ ] Graceful handling if FORMATTED_STANDARDS is empty (empty section, no Task failure)

### Phase 3: Add Standards Extraction to /revise Command [COMPLETE]
dependencies: [2]

**Objective**: Integrate standards extraction library into /revise command workflow
**Complexity**: Low

Tasks:
- [x] Add standards extraction block to /revise command after Block 4c (research verification) (file: .claude/commands/revise.md)
- [x] Source standards-extraction.sh library with error handling
- [x] Call format_standards_for_prompt and capture output
- [x] Persist FORMATTED_STANDARDS to workflow state using append_workflow_state with heredoc syntax
- [x] Add graceful degradation if standards extraction fails
- [x] Update block numbering: new Block 4d-standards, keep Block 5a as planning setup

**Block Structure**:
```markdown
## Block 4d: Extract Project Standards

**EXECUTE NOW**: Extract project standards for plan-architect agent.

```bash
set +H  # CRITICAL: Disable history expansion

# === RESTORE STATE FROM BLOCK 4C ===
[... state restoration code ...]

# === EXTRACT PROJECT STANDARDS ===
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source standards-extraction library" \
    "bash_block_4d" \
    "$(jq -n --arg path "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" '{library_path: $path}')"
  echo "WARNING: Standards extraction unavailable, proceeding without standards" >&2
  FORMATTED_STANDARDS=""
}

# Extract and format standards for prompt injection
if [ -z "${FORMATTED_STANDARDS:-}" ]; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "execution_error" \
      "Standards extraction failed" \
      "bash_block_4d" \
      "{}"
    echo "WARNING: Standards extraction failed, proceeding without standards" >&2
    FORMATTED_STANDARDS=""
  }
fi

# Persist standards for Block 5b-exec
append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF
$FORMATTED_STANDARDS
STANDARDS_EOF"

if [ -n "$FORMATTED_STANDARDS" ]; then
  STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
  echo "Extracted $STANDARDS_COUNT standards sections for plan-architect"
else
  echo "No standards extracted (graceful degradation)"
fi

echo ""
echo "[CHECKPOINT] Standards extraction complete"
\```
```

Testing:
```bash
# Test standards extraction in /revise context
cd /home/benjamin/.config
WORKFLOW_ID="test_revise_$(date +%s)"
COMMAND_NAME="/revise"
USER_ARGS="test revise"
export WORKFLOW_ID COMMAND_NAME USER_ARGS

# Initialize minimal state file
mkdir -p .claude/tmp
STATE_FILE=".claude/tmp/workflow_${WORKFLOW_ID}.sh"
echo "WORKFLOW_ID=$WORKFLOW_ID" > "$STATE_FILE"
echo "COMMAND_NAME=$COMMAND_NAME" >> "$STATE_FILE"
export STATE_FILE

# Source required libraries
source .claude/lib/core/error-handling.sh
source .claude/lib/core/state-persistence.sh
ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Execute standards extraction
source .claude/lib/plan/standards-extraction.sh 2>/dev/null || {
  echo "WARNING: Standards extraction unavailable"
  FORMATTED_STANDARDS=""
}

FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || FORMATTED_STANDARDS=""

if [ -n "$FORMATTED_STANDARDS" ]; then
  echo "SUCCESS: Extracted $(echo "$FORMATTED_STANDARDS" | grep -c '^###') sections"
else
  echo "FAIL: No standards extracted"
fi

# Cleanup
rm -f "$STATE_FILE"
```

Success Criteria:
- [ ] Standards extraction block executes without errors in /revise context
- [ ] FORMATTED_STANDARDS contains complete standards sections
- [ ] Standards are persisted to workflow state file
- [ ] Graceful degradation works if library missing

### Phase 4: Inject Standards into /revise Task Prompt [COMPLETE]
dependencies: [3]

**Objective**: Pass extracted standards to plan-architect agent in /revise command
**Complexity**: Low

Tasks:
- [x] Modify Block 5b-exec Task prompt to include "**Project Standards**:" section (file: .claude/commands/revise.md)
- [x] Use ${FORMATTED_STANDARDS} variable substitution for standards content
- [x] Add instruction to convert metadata to standard format during revision
- [x] Ensure standards section appears before revision-specific instructions
- [x] Verify standards variable is restored from workflow state in Block 5b (before Task invocation)

**Task Prompt Structure**:
```markdown
## Block 5b-exec: Plan Revision Delegation

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
    5. **METADATA NORMALIZATION**: If metadata uses non-standard fields (Plan ID, Created, Revised, Workflow Type), convert to standard format (Date, Feature, Status, Standards File)
    6. Maintain /implement compatibility (checkbox format, phase markers, dependency syntax)

    Execute plan revision according to behavioral guidelines and return completion signal:
    PLAN_REVISED: ${EXISTING_PLAN_PATH}
  "
}
```

Testing:
```bash
# Test Task prompt includes standards and metadata normalization instructions
cd /home/benjamin/.config

# Create mock state file
WORKFLOW_ID="test_revise_$(date +%s)"
STATE_FILE=".claude/tmp/workflow_${WORKFLOW_ID}.sh"
mkdir -p .claude/tmp

cat > "$STATE_FILE" <<'EOF'
WORKFLOW_ID=test_revise_12345
EXISTING_PLAN_PATH="/tmp/test_plan.md"
BACKUP_PATH="/tmp/test_plan_backup.md"
REVISION_DETAILS="add new phase"
REPORT_PATHS_JSON='[]'
FORMATTED_STANDARDS="### Code Standards
Test standards

### Testing Protocols
Test protocols"
EOF

# Source state and verify variable expansion
source "$STATE_FILE"

# Simulate Task prompt construction
TASK_PROMPT=$(cat <<PROMPT
Task {
  prompt: "
    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **CRITICAL INSTRUCTIONS FOR PLAN REVISION**:
    5. **METADATA NORMALIZATION**: If metadata uses non-standard fields...
  "
}
PROMPT
)

# Verify standards and normalization instruction present
if echo "$TASK_PROMPT" | grep -q "### Code Standards" && \
   echo "$TASK_PROMPT" | grep -q "METADATA NORMALIZATION"; then
  echo "SUCCESS: Standards and normalization instructions injected"
else
  echo "FAIL: Missing standards or normalization instructions"
fi

# Cleanup
rm -f "$STATE_FILE"
```

Success Criteria:
- [ ] Task prompt contains "**Project Standards**:" section
- [ ] Task prompt includes metadata normalization instruction
- [ ] ${FORMATTED_STANDARDS} variable expands correctly
- [ ] Standards section appears before revision instructions
- [ ] Graceful handling if FORMATTED_STANDARDS is empty

### Phase 5: Integration Testing and Validation [COMPLETE]
dependencies: [2, 4]

**Objective**: Verify standards integration works end-to-end across all planning commands
**Complexity**: Medium

Tasks:
- [x] Create integration test for /repair command standards integration (file: .claude/tests/integration/test_repair_standards_integration.sh)
- [x] Create integration test for /revise command standards integration (file: .claude/tests/integration/test_revise_standards_integration.sh)
- [x] Test /repair creates plans with Status field
- [x] Test /repair creates plans with Standards File field
- [x] Test /repair creates plans with Date field (not Plan ID/Created)
- [x] Test /revise normalizes legacy metadata to standard format
- [x] Test /revise creates plans with Status field when revising legacy plans
- [x] Verify plan metadata compatibility across all planning commands (/plan, /repair, /revise)
- [x] Update command documentation to reflect standards integration (file: .claude/docs/guides/commands/repair-command-guide.md, .claude/docs/guides/commands/revise-command-guide.md)

**Integration Test Structure** (test_repair_standards_integration.sh):
```bash
#!/usr/bin/env bash
# Integration test: /repair command standards integration
# Verifies that /repair command extracts standards and creates plans with required metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test setup
TEST_TOPIC="999_repair_standards_test"
TEST_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TEST_TOPIC}"
PLAN_PATH="${TEST_DIR}/plans/001-repair-standards-test-plan.md"

# Cleanup function
cleanup() {
  rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Execute /repair command (simulated - would need actual invocation in real test)
# For now, verify standards extraction works in isolation

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Initialize test state
WORKFLOW_ID="test_repair_$(date +%s)"
COMMAND_NAME="/repair"
USER_ARGS="test error"
export WORKFLOW_ID COMMAND_NAME USER_ARGS

STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
init_workflow_state "$WORKFLOW_ID" >/dev/null
export STATE_FILE

ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Test standards extraction
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  echo "FAIL: Cannot source standards-extraction.sh"
  exit 1
}

FORMATTED_STANDARDS=$(format_standards_for_prompt 2>/dev/null) || {
  echo "FAIL: Standards extraction failed"
  exit 1
}

# Verify standards content
if [ -z "$FORMATTED_STANDARDS" ]; then
  echo "FAIL: FORMATTED_STANDARDS is empty"
  exit 1
fi

STANDARDS_COUNT=$(echo "$FORMATTED_STANDARDS" | grep -c "^###" || echo 0)
if [ "$STANDARDS_COUNT" -lt 4 ]; then
  echo "FAIL: Expected at least 4 standards sections, got $STANDARDS_COUNT"
  exit 1
fi

# Verify specific sections present
for section in "Code Standards" "Testing Protocols" "Documentation Policy" "Error Logging"; do
  if ! echo "$FORMATTED_STANDARDS" | grep -q "### $section"; then
    echo "FAIL: Missing required section: $section"
    exit 1
  fi
done

echo "PASS: /repair standards integration validation"
echo "  - Extracted $STANDARDS_COUNT standards sections"
echo "  - All required sections present"

# Cleanup
rm -f "$STATE_FILE"
exit 0
```

Testing:
```bash
# Run integration tests
cd /home/benjamin/.config
bash .claude/tests/integration/test_repair_standards_integration.sh
bash .claude/tests/integration/test_revise_standards_integration.sh

# Verify test results
if [ $? -eq 0 ]; then
  echo "Integration tests PASSED"
else
  echo "Integration tests FAILED"
  exit 1
fi
```

Success Criteria:
- [x] Integration tests pass for both /repair and /revise
- [x] Plans created by /repair contain all required metadata fields
- [x] Plans created by /revise normalize legacy metadata to standard format
- [x] All planning commands (/plan, /repair, /revise) produce compatible plan structures
- [x] Documentation updated to reflect standards integration behavior

## Testing Strategy

### Unit Testing
- Test standards extraction library functions in isolation
- Test variable substitution in Task prompts
- Test graceful degradation when standards extraction fails

### Integration Testing
- Test complete /repair workflow with standards integration
- Test complete /revise workflow with standards integration
- Test metadata normalization during plan revision
- Verify plan compatibility across all planning commands

### Validation Testing
- Verify Status field presence in all new plans
- Verify Standards File field presence in all new plans
- Verify Date field used instead of Plan ID/Created/Revised
- Verify plan-architect receives and validates standards

## Documentation Requirements

### Command Documentation Updates
- Update /repair command guide to document standards integration
- Update /revise command guide to document standards integration and metadata normalization
- Add examples showing standard metadata structure in plans

### Architecture Documentation
- Document standards integration pattern in command authoring guide
- Document metadata normalization behavior in /revise workflow
- Add standards extraction to troubleshooting guides

## Rollout Plan

1. **Phase 1-2**: Implement /repair command standards integration (2 hours)
2. **Phase 3-4**: Implement /revise command standards integration (2 hours)
3. **Phase 5**: Integration testing and validation (2.5 hours)
4. **Post-Implementation**: Monitor error logs for standards extraction failures

## Risk Mitigation

### Risk: Standards extraction library failure
- **Mitigation**: Graceful degradation with empty FORMATTED_STANDARDS
- **Impact**: Plans created without standards reference but workflow continues

### Risk: Existing /repair and /revise plans become incompatible
- **Mitigation**: Consider creating metadata normalization script (deferred to future work)
- **Impact**: Low - new plans will use correct format, old plans remain readable

### Risk: Breaking changes to /repair or /revise workflows
- **Mitigation**: Add standards extraction as new blocks (minimal changes to existing flow)
- **Impact**: Very low - only adds new functionality, doesn't modify existing logic

## Success Metrics

- [ ] 100% of new /repair plans include Status field
- [ ] 100% of new /repair plans include Standards File field
- [ ] 100% of new /revise plans include Status field
- [ ] 0 standards extraction errors in normal operation
- [ ] All integration tests pass
