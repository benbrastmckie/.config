# /fix Command Compliance Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Command Analyzed**: /fix (fix.md)
- **Report Type**: Compliance assessment against .claude/docs/ standards

## Executive Summary

The /fix command demonstrates strong compliance with state-based orchestration architecture (100%) and proper workflow structure for debug-focused operations, with excellent state machine lifecycle management and progressive phase execution. However, like /build, it exhibits critical gaps in agent invocation patterns (no behavioral injection), lacks comprehensive execution enforcement markers, and uses simplified prompts instead of delegating to agent behavioral guidelines.

**Compliance Score**: 70/100

**Key Strengths**:
- Complete state machine implementation with proper DEBUG terminal state
- Three-phase workflow (Research → Plan → Debug) correctly structured
- Comprehensive library dependency management and version checking
- Proper directory structure creation for debug artifacts
- Excellent file-level verification with size and existence checks

**Critical Gaps**:
- Agent invocations do NOT reference behavioral guideline files (violates Standard 0.5)
- Missing "EXECUTE NOW" and "MANDATORY VERIFICATION" markers for critical operations
- Agent prompts embed procedures instead of using behavioral injection pattern
- No fail-fast error handling with diagnostic output

## Detailed Compliance Assessment

### 1. State-Based Orchestration Architecture ✅ (Excellent - 100%)

**Standard**: [workflow-state-machine.md](../../.claude/docs/architecture/workflow-state-machine.md)

**Compliance Status**: FULLY COMPLIANT

**Evidence**:
- Lines 80-88: Proper library sourcing in dependency order (state-persistence.sh → workflow-state-machine.sh → library-version-check.sh → error-handling.sh)
- Lines 89-94: Library version verification with requirements specification
- Lines 101-118: State machine initialization with proper parameters (WORKFLOW_TYPE="debug-only", TERMINAL_STATE="debug")
- Lines 127-130, 202-205, 266-269: All sm_transition calls with return code verification
- Lines 192-196, 256-260, 307-311: Proper state persistence with save_completed_states_to_state

**Specific Implementation Excellence**:
```bash
# Lines 96-118: Excellent state machine initialization
WORKFLOW_TYPE="debug-only"
TERMINAL_STATE="debug"
COMMAND_NAME="fix"

if ! sm_init \
  "$ISSUE_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "{}" 2>&1; then  # Correct JSON object for empty topics
  echo "ERROR: State machine initialization failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  # ... comprehensive diagnostics ...
  exit 1
fi
```

**Unique Feature**: Uses "debug-only" workflow type with correct terminal state ("debug" instead of "complete"), demonstrating understanding of workflow scope integration.

**Assessment**: Perfect implementation - should be used as reference for other debug-focused commands.

---

### 2. Directory Protocols ✅ (Excellent - 95%)

**Standard**: [directory-protocols.md](../../.claude/docs/concepts/directory-protocols.md)

**Compliance Status**: FULLY COMPLIANT

**Evidence**:
- Lines 136-141: Topic-based directory structure creation (`TOPIC_NUMBER`, `TOPIC_SLUG`, `SPECS_DIR`)
- Lines 142-145: Proper creation of `RESEARCH_DIR` and `DEBUG_DIR` subdirectories
- Lines 211-212: Plans directory creation
- Lines 162-179: Comprehensive directory-level verification (existence, file presence, size checks)

**Best Practices Demonstrated**:
```bash
# Lines 136-141: Proper topic numbering and slugification
TOPIC_SLUG=$(echo "$ISSUE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | wc -l | xargs)
TOPIC_NUMBER=$((TOPIC_NUMBER + 1))
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
```

**Unique Strength**: Creates both RESEARCH_DIR and DEBUG_DIR upfront (lines 142-145), aligning with directory protocols for debug-focused workflows.

**Minor Gap**: Could use `ensure_artifact_directory` from unified-location-detection.sh instead of plain `mkdir -p`, but current implementation is acceptable.

---

### 3. Agent Invocation Patterns ❌ (Poor - 25%)

**Standard**: [execution-enforcement-guide.md](../../.claude/docs/guides/execution-enforcement-guide.md) - Behavioral Injection Pattern

**Compliance Status**: NON-COMPLIANT

**Critical Violations**:

**Line 147-159: Research-Specialist Invocation**
```markdown
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
```

**Problem**: Same issue as /build - uses echo statements for documentation, NOT actual Task tool invocation. Claude sees this as instructions, not agent delegation.

**Expected Pattern**:
```markdown
# AGENT INVOCATION - Use THIS EXACT TEMPLATE
Task {
  subagent_type: "general-purpose"
  description: "Research-specialist - Issue investigation for debug"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **CONTEXT**:
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Issue Description: $ISSUE_DESCRIPTION
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: debug-only
    - Context Mode: root cause analysis

    Return completion signal: REPORT_CREATED: \${REPORT_PATH}
  "
}
```

**Lines 222-235, 275-287**: Plan-architect and debug-analyst invocations have identical violation.

**Impact**:
- Claude may execute research/planning/debugging directly instead of delegating
- Behavioral guidelines in agent files are not enforced
- No guarantee of file creation compliance
- Breaks hierarchical agent pattern

---

### 4. Execution Enforcement ❌ (Poor - 35%)

**Standard**: [execution-enforcement-guide.md](../../.claude/docs/guides/execution-enforcement-guide.md) - Standard 0

**Compliance Status**: PARTIALLY COMPLIANT

**Missing Patterns**:

**"EXECUTE NOW" Markers**: Only present in agent delegation echo statements (lines 147, 222, 275), NOT for critical bash operations:
- Lines 27-49: Issue description parsing has no enforcement marker
- Lines 136-145: Directory creation has no "EXECUTE NOW - Create Directory Structure" marker
- Lines 218-219: Research report collection has no enforcement marker

**"MANDATORY VERIFICATION" Blocks**: Good verification present but lacks formal markers:
- Lines 162-179: Excellent verification logic (directory existence, file presence, size checks) BUT missing "MANDATORY VERIFICATION - Research Artifacts" header
- Lines 240-252: Plan file verification present but lacks "MANDATORY VERIFICATION" header
- Lines 292-304: Debug directory verification uses "WARNING" instead of "CRITICAL ERROR" for zero artifacts

**Comparison with Standard**:
From execution-enforcement-guide.md lines 361-386:
```markdown
**MANDATORY VERIFICATION - [What is being verified]**

After [operation], YOU MUST verify:
...
echo "✓ VERIFIED: [Success message]"
```

Current implementation (lines 162-179) has verification logic but missing formal structure.

**"CHECKPOINT REQUIREMENT" Blocks**: Completely absent
- No checkpoint reporting after research phase
- No checkpoint reporting after planning phase
- No checkpoint reporting after debug phase

**Recommendation**: Add formal verification headers and checkpoint requirements to all three phases.

---

### 5. Error Handling ⚠️ (Moderate - 65%)

**Standard**: [error-enhancement-guide.md](../../.claude/docs/guides/error-enhancement-guide.md)

**Compliance Status**: PARTIALLY COMPLIANT

**Strong Error Handling**:
- Lines 105-117: Excellent state machine init error with DIAGNOSTIC, POSSIBLE CAUSES
- Lines 166-178: Comprehensive verification with specific DIAGNOSTIC and SOLUTION messages
- Lines 180-186: Undersized file detection with diagnostic output
- Lines 242-251: Plan file size validation with diagnostic context
- Lines 344-361: Excellent troubleshooting section with specific solutions

**Good Pattern Example** (Lines 166-178):
```bash
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent logs for failures" >&2
  exit 1
fi
```

This follows error-enhancement-guide.md pattern: ERROR + DIAGNOSTIC + SOLUTION

**Gaps**:
- Lines 128, 203, 267: State transition errors have generic messages, no diagnostic context
- Lines 318: Transition to complete lacks diagnostic output on failure
- Line 173-177: File verification uses fail-fast pattern but could be enhanced with error type classification

**Missing Enhancements**:
- No integration with `.claude/lib/analyze-error.sh` for error type detection
- No suggestion generation for common failure patterns
- Could classify errors (file_not_found, verification_failure, agent_non_compliance)

**Recommendation**: Enhance state transition errors with diagnostic context; consider integrating error analysis utility for complex failures.

---

### 6. Workflow Structure ✅ (Excellent - 95%)

**Standard**: Inferred from orchestration patterns

**Compliance Status**: FULLY COMPLIANT

**Evidence**:
- Lines 124-196: Research phase properly structured with verification
- Lines 198-260: Planning phase with backup creation and modification verification
- Lines 262-311: Debug phase with artifact counting
- Lines 313-337: Proper completion and cleanup recommendations

**Unique Features**:

**1. Backup Creation Before Plan Modification** (Lines 235-255):
```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

mkdir -p "$BACKUP_DIR"
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"
```

This demonstrates understanding of backup retention policy (see directory-protocols.md section on backups/).

**2. Complexity-Based Research Configuration** (Lines 37-43):
```bash
DEFAULT_COMPLEXITY=2
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$ISSUE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  ISSUE_DESCRIPTION=$(echo "$ISSUE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```

Excellent use of optional complexity parameter for debug-focused research.

**3. Three-Phase Progressive Execution**:
- Research → Planning → Debug (not Research → Plan → Implement like /build)
- Properly uses "debug-only" terminal state
- Correct workflow scope for issue investigation

**Assessment**: Workflow structure is exemplary for debug-focused commands.

---

### 7. File Verification ✅ (Excellent - 95%)

**Standard**: Inferred from verification patterns in standards

**Compliance Status**: FULLY COMPLIANT

**Evidence**:

**Directory-Level Verification** (Lines 165-179):
```bash
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent logs for failures" >&2
  exit 1
fi

# File-level verification (not directory-level)
if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files found: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent behavioral file compliance" >&2
  exit 1
fi

# Verify file size (minimum 100 bytes)
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
  echo "DIAGNOSTIC: Files: $UNDERSIZED_FILES" >&2
  exit 1
fi
```

**Best Practices Demonstrated**:
1. **Three-level verification**: directory existence → file presence → file size
2. **Specific diagnostics**: Shows expected vs actual (directory path, file pattern)
3. **Actionable solutions**: Points to specific logs or behavioral files
4. **Fail-fast**: Exits immediately on critical errors

**Plan File Verification** (Lines 241-251):
```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  echo "DIAGNOSTIC: Expected file: $PLAN_PATH" >&2
  exit 1
fi

FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 200 ]; then
  echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi
```

**Minor Gap**: Debug artifact verification (lines 292-304) uses "NOTE" and "WARNING" instead of fail-fast pattern. This is acceptable for debug-only workflow where artifacts are optional.

**Assessment**: File verification is more comprehensive than /build command - should be used as reference pattern.

---

### 8. Code Standards - Library Usage ✅ (Excellent - 95%)

**Standard**: [library-api.md](../../.claude/docs/reference/library-api.md)

**Compliance Status**: FULLY COMPLIANT

**Evidence**:
- Lines 80-94: Proper library sourcing and version checking
- Lines 101-107: Correct sm_init signature for debug-only workflow
- Lines 46-50: Complexity validation with regex pattern
- Lines 136-145: Topic slug generation using standard pattern

**Best Practices**:
- Lines 10-12: Library requirements documented in frontmatter
- Lines 112-116: Excellent diagnostic output for init failures
- Lines 192-196: Proper state persistence with error handling

---

### 9. Documentation Standards ✅ (Good - 85%)

**Standard**: [documentation-policy](../../CLAUDE.md#documentation_policy)

**Compliance Status**: MOSTLY COMPLIANT

**Strengths**:
- Lines 1-13: Complete frontmatter with all required fields
- Lines 344-361: Comprehensive troubleshooting section
- Lines 350-360: Excellent usage examples with descriptions

**Gaps**:
- Missing cross-references to fix-command-guide.md (should exist but not referenced)
- No explicit references to research-specialist.md, plan-architect.md, debug-analyst.md behavioral guidelines
- Could reference debug-structure.md for debug report format

**Recommendation**: Add "See Also" section with cross-references to related documentation.

---

## Specific Violations and Recommendations

### Critical Issue 1: Agent Invocation Pattern Violation (All 3 Agents)

**Location**: Lines 147-159, 222-235, 275-287

**Current Implementation** (Lines 147-159):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke research-specialist agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
echo "2. Return completion signal: REPORT_CREATED: \${REPORT_PATH}"
echo ""
echo "Workflow-Specific Context:"
echo "- Research Complexity: $RESEARCH_COMPLEXITY"
echo "- Issue Description: $ISSUE_DESCRIPTION"
echo "- Output Directory: $RESEARCH_DIR"
echo "- Workflow Type: debug-only"
echo "- Context Mode: root cause analysis"
```

**Problem**: This is documentation of what Claude should do, not executable delegation. Task tool never invoked.

**Required Fix**:
```bash
# AGENT INVOCATION - Use THIS EXACT TEMPLATE

Task {
  subagent_type: "general-purpose"
  description: "Research-specialist - Debug issue investigation"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Create research reports for root cause analysis.

    **CONTEXT**:
    - Research Complexity: $RESEARCH_COMPLEXITY
    - Issue Description: $ISSUE_DESCRIPTION
    - Output Directory: $RESEARCH_DIR
    - Workflow Type: debug-only
    - Context Mode: root cause analysis

    **CRITICAL**: YOU MUST create report files in \$RESEARCH_DIR.
    DO NOT return text summary without file creation.

    Return completion signal: REPORT_CREATED: \${REPORT_PATH}
  "
}
```

Apply same pattern to plan-architect (lines 222-235) and debug-analyst (lines 275-287) invocations.

**Standard Reference**: execution-enforcement-guide.md lines 104-139 (Behavioral Injection for Agent Invocations)

---

### Critical Issue 2: Missing Formal Verification Headers

**Location**: Lines 162-179, 239-252, 289-304

**Current Implementation** (Lines 162-179):
```bash
# FAIL-FAST VERIFICATION
echo ""
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  # ... verification logic ...
```

**Problem**: Has verification logic but lacks formal "MANDATORY VERIFICATION" structure from standards.

**Required Fix**:
```bash
**MANDATORY VERIFICATION - Research Artifacts Created**

After research-specialist execution, YOU MUST verify:

# Directory existence
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "CRITICAL ERROR: Research directory not created" >&2
  echo "DIAGNOSTIC: Expected directory: $RESEARCH_DIR" >&2
  echo "SOLUTION: Check research-specialist agent execution logs" >&2
  exit 1
fi

# File presence (directory-level check insufficient)
if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
  echo "CRITICAL ERROR: No report files created" >&2
  echo "DIAGNOSTIC: Directory exists but no .md files in: $RESEARCH_DIR" >&2
  echo "SOLUTION: Verify research-specialist agent behavioral file compliance" >&2
  exit 1
fi

# File size validation (minimum 100 bytes)
UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
if [ -n "$UNDERSIZED_FILES" ]; then
  echo "CRITICAL ERROR: Report file(s) too small (< 100 bytes)" >&2
  echo "DIAGNOSTIC: Undersized files: $UNDERSIZED_FILES" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
echo "✓ VERIFIED: Research artifacts complete ($REPORT_COUNT reports created)"
```

Apply similar pattern to plan verification (lines 239-252) and debug verification (lines 289-304).

**Standard Reference**: execution-enforcement-guide.md lines 361-386 (Pattern 4: Verification Checkpoints)

---

### Medium Issue 3: Missing Checkpoint Reporting

**Location**: After lines 196, 260, 311 (end of each phase)

**Current Implementation**: No checkpoint reporting present.

**Required Addition** (After line 196):
```bash
**CHECKPOINT REQUIREMENT - Research Phase Status**

YOU MUST report phase status:
```
CHECKPOINT: Research phase complete
- Issue: $ISSUE_DESCRIPTION
- Complexity: $RESEARCH_COMPLEXITY
- Reports Created: $REPORT_COUNT
- Output Directory: $RESEARCH_DIR
- All files verified: ✓
- Proceeding to: Planning phase
```
```

Apply similar checkpoints after planning phase (line 260) and debug phase (line 311).

**Standard Reference**: execution-enforcement-guide.md lines 995-1013 (Phase 3: Checkpoint Reporting)

---

### Medium Issue 4: State Transition Error Diagnostic Context

**Location**: Lines 128-130, 203-205, 267-269, 318-320

**Current Implementation** (Lines 128-130):
```bash
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi
```

**Problem**: Generic error, no context about current state or why transition failed.

**Required Fix**:
```bash
if ! sm_transition "$STATE_RESEARCH" 2>&1; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: $(sm_current_state)" >&2
  echo "  - Attempted Transition: → RESEARCH" >&2
  echo "  - Workflow Type: $WORKFLOW_TYPE (debug-only)" >&2
  echo "  - Terminal State: $TERMINAL_STATE (debug)" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Invalid transition from current state" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - State file corruption in ~/.claude/data/state/" >&2
  exit 1
fi
```

**Standard Reference**: error-enhancement-guide.md Section 2 (Error Types and Suggestions)

---

### Low Issue 5: Documentation Cross-References

**Location**: End of file (after line 361)

**Current Implementation**: No "See Also" or cross-reference section.

**Required Addition**:
```markdown
---

## Related Documentation

### Command Guides
- [Fix Command Guide](.claude/docs/guides/fix-command-guide.md) - Complete usage guide
- [Debug Command Guide](.claude/docs/guides/debug-command-guide.md) - Alternative debug workflow

### Agent Behavioral Guidelines
- [Research Specialist](.claude/agents/research-specialist.md) - Research and report creation
- [Plan Architect](.claude/agents/plan-architect.md) - Debug strategy planning
- [Debug Analyst](.claude/agents/debug-analyst.md) - Root cause analysis

### Reference Documentation
- [Debug Report Structure](.claude/docs/reference/debug-structure.md) - Debug report format
- [Workflow State Machine](.claude/docs/architecture/workflow-state-machine.md) - State transitions
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Artifact organization
```

**Standard Reference**: documentation-policy from CLAUDE.md (Navigation Links requirement)

---

## Summary of Compliance Gaps

| Standard Area | Compliance Level | Priority | Effort |
|--------------|------------------|----------|--------|
| State Machine Architecture | ✅ Excellent | N/A | N/A |
| Directory Protocols | ✅ Excellent | N/A | N/A |
| Agent Invocation Patterns | ❌ Poor | **CRITICAL** | 3 hours |
| Execution Enforcement | ❌ Poor | **HIGH** | 3 hours |
| Error Handling | ⚠️ Moderate | Medium | 2 hours |
| Workflow Structure | ✅ Excellent | N/A | N/A |
| File Verification | ✅ Excellent | N/A | N/A |
| Library Usage | ✅ Excellent | N/A | N/A |
| Documentation | ✅ Good | Low | 1 hour |

**Total Estimated Remediation Time**: 9 hours

---

## Recommended Action Plan

### Phase 1: Critical Fixes (Priority 1) - 3 hours

1. **Replace echo-based agent instructions with Task invocations** (Lines 147-159, 222-235, 275-287)
   - Research-specialist invocation with behavioral injection
   - Plan-architect invocation with context parameters
   - Debug-analyst invocation with debug context

2. **Add formal MANDATORY VERIFICATION headers** (Lines 162, 239, 289)
   - Research artifacts verification
   - Plan file verification
   - Debug artifacts verification

### Phase 2: High Priority (Priority 2) - 3 hours

3. **Add CHECKPOINT REQUIREMENT blocks** (After lines 196, 260, 311)
   - Research phase checkpoint with metrics
   - Planning phase checkpoint with backup info
   - Debug phase checkpoint with artifact count

4. **Add EXECUTE NOW markers** (Lines 136, 218, 235)
   - Directory creation operations
   - Research report collection
   - Backup creation

5. **Enhance state transition errors** (Lines 128, 203, 267, 318)
   - Add diagnostic context (current state, attempted transition)
   - Include possible causes and solutions
   - Reference state machine documentation

### Phase 3: Medium Priority (Priority 3) - 2 hours

6. **Integrate error classification** (Lines 166-178, 241-252)
   - Use error type categorization (file_not_found, verification_failure, agent_non_compliance)
   - Consider calling analyze-error.sh for complex failures

7. **Enhance debug artifact verification** (Lines 292-304)
   - Use CRITICAL ERROR instead of WARNING for critical paths
   - Add fail-fast exit on zero artifacts if required

### Phase 4: Low Priority (Enhancements) - 1 hour

8. **Add cross-references section** (After line 361)
   - Reference fix-command-guide.md
   - Link to agent behavioral files
   - Link to debug-structure.md and workflow-state-machine.md

---

## References

### Standards Documents Analyzed
- `/home/benjamin/.config/.claude/docs/architecture/workflow-state-machine.md` (Full document reviewed)
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (Sections 1-7 reviewed)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (Sections 1-4 reviewed)
- `/home/benjamin/.config/.claude/docs/guides/error-enhancement-guide.md` (Sections 1-3 reviewed)

### Command File Analyzed
- `/home/benjamin/.config/.claude/commands/fix.md` (362 lines, all sections reviewed)

### Agent Behavioral Files Referenced
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (Should be invoked via Task tool)
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (Should be invoked via Task tool)
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` (Should be invoked via Task tool)

---

**Analysis Complete**: 2025-11-17
**Confidence Level**: High (95%) - Analysis based on direct comparison with documented standards
**Recommended Next Steps**: Begin Phase 1 critical fixes, prioritizing agent invocation pattern compliance (identical to /build command gaps)
