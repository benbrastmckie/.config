# Behavioral Injection Standards Compliance Fix for /coordinate Command

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Fixing /coordinate command while maintaining .claude/ standards compliance
- **Report Type**: standards analysis, pattern recognition, implementation guidance
- **Parent Report**: [Comprehensive Overview](OVERVIEW.md)

## Executive Summary

The /coordinate command exhibits multiple standards violations that require systematic fixes while maintaining compliance with .claude/ architecture standards. Key findings: (1) Missing workflow-llm-classifier.sh from REQUIRED_LIBS arrays despite sm_init dependency; (2) Agent invocations follow Standard 11 correctly with imperative language and behavioral injection; (3) Verification checkpoints align with Standard 0 requirements; (4) Library sourcing order complies with Standard 15; (5) Command demonstrates proper executable/documentation separation per Standard 14. The primary fix needed is adding "workflow-llm-classifier.sh" to all four REQUIRED_LIBS arrays (lines 233, 236, 239, 242) to satisfy library sourcing requirements.

## Current State Analysis

### /coordinate Command Architecture

The /coordinate command (85,584 bytes, 1,084 lines per Standard 14 migration) implements state machine orchestration with:

1. **Two-Part Initialization** (lines 18-311):
   - Part 1: Workflow description capture via temporary file
   - Part 2: State machine initialization with library sourcing

2. **Library Sourcing Sequence** (lines 100-253):
   - workflow-state-machine.sh (line 104)
   - state-persistence.sh (line 116)
   - error-handling.sh (line 124)
   - verification-helpers.sh (line 132)
   - source_required_libraries() call (line 247)

3. **REQUIRED_LIBS Arrays** (lines 233-243):
   - research-only: 6 libraries
   - research-and-plan/revise: 8 libraries
   - full-implementation: 10 libraries
   - debug-only: 8 libraries
   - **MISSING**: workflow-llm-classifier.sh in all arrays

4. **Agent Invocations** (lines 492-649):
   - Hierarchical supervision option (≥4 topics)
   - Flat coordination option (<4 topics)
   - All use Standard 11 imperative pattern: "**EXECUTE NOW**: USE the Task tool"

### Standards Violations Detected

**Violation 1: Missing Library Dependency**

- **Location**: Lines 233, 236, 239, 242
- **Issue**: workflow-llm-classifier.sh missing from REQUIRED_LIBS arrays
- **Impact**: sm_init() calls classify_workflow_comprehensive() which requires workflow-llm-classifier.sh
- **Dependency Chain**:
  1. sm_init (workflow-state-machine.sh) calls classify_workflow_comprehensive
  2. classify_workflow_comprehensive (workflow-scope-detection.sh:48) is primary classifier
  3. workflow-scope-detection.sh sources workflow-llm-classifier.sh (line 27)
  4. workflow-detection.sh sources workflow-scope-detection.sh (line 21)
  5. **Problem**: workflow-llm-classifier.sh not explicitly in REQUIRED_LIBS
  6. **Result**: Transitive dependency, but Standard 15 requires explicit sourcing

**Evidence from Library Files**:

```bash
# workflow-scope-detection.sh:26-27
# shellcheck source=.claude/lib/workflow-llm-classifier.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-llm-classifier.sh"

# workflow-detection.sh:20-21
# shellcheck source=.claude/lib/workflow-scope-detection.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"
```

**No Other Major Violations Detected**:
- Agent invocations comply with Standard 11 (imperative language, behavioral injection)
- Verification checkpoints present per Standard 0
- Library sourcing order follows Standard 15
- File size and structure comply with Standard 14

## Standard 11: Imperative Agent Invocation Pattern

### Requirements (from command_architecture_standards.md:1173-1353)

All Task invocations MUST include:

1. **Imperative Instruction**: Explicit execution markers (`**EXECUTE NOW**: USE the Task tool...`)
2. **Agent Behavioral File Reference**: Direct reference (`Read and follow: .claude/agents/[name].md`)
3. **No Code Block Wrappers**: Task invocations NOT fenced in ` ```yaml` blocks
4. **No "Example" Prefixes**: Remove documentation context
5. **Completion Signal Requirement**: Agent returns explicit confirmation (`REPORT_CREATED: ${PATH}`)

### Current Implementation Status: **COMPLIANT**

**Evidence from /coordinate command**:

**Line 490-511: Hierarchical Research Supervision**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-sub-supervisor:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md
    ...
    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}
```

**Lines 564-585: Research Agent 1 Invocation**
```markdown
**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1
    ...
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Compliance Checklist**:
- ✓ Imperative instruction present (`**EXECUTE NOW**: USE the Task tool`)
- ✓ Behavioral file referenced explicitly
- ✓ No YAML code block wrappers (direct Task invocation)
- ✓ No "Example" prefixes
- ✓ Completion signals required in all prompts
- ✓ No undermining disclaimers after imperative directives

**Conclusion**: /coordinate fully complies with Standard 11. All 6+ agent invocations follow the imperative pattern established in Spec 438, 495, 497.

## Standard 0: Verification and Fallback Pattern

### Requirements (from command_architecture_standards.md:51-463)

**Verification Pattern Components**:
1. **Direct Execution Blocks**: `**EXECUTE NOW - [Description]**` with immediate bash code
2. **Mandatory Verification Checkpoints**: `**MANDATORY VERIFICATION - [What]**` after critical operations
3. **Completion Signals**: Explicit confirmation of major steps
4. **Fail-Fast Philosophy**: Verification DETECTS errors (not masks them)

**Critical Distinction** (Spec 057):
- Bootstrap fallbacks PROHIBITED (hide configuration errors)
- Verification checkpoints REQUIRED (detect tool failures)
- **Orchestrator placeholder creation PROHIBITED** (hides agent failures)
- Verification fallbacks expose errors immediately for fixing

### Current Implementation Status: **COMPLIANT**

**Evidence from /coordinate command**:

**Lines 151-154: State ID File Verification**
```bash
# VERIFICATION CHECKPOINT: Verify state ID file created successfully (Standard 0: Execution Enforcement)
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created at $COORDINATE_STATE_ID_FILE" 1
}
```

**Lines 174-186: State Machine Variable Verification**
```bash
# VERIFICATION CHECKPOINT: Verify critical variables exported by sm_init
# Standard 0 (Execution Enforcement): Critical state initialization must be verified
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code" 1
fi

if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not exported by sm_init despite successful return code" 1
fi

if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON not exported by sm_init despite successful return code" 1
fi
```

**Lines 213-216: Workflow Scope Persistence Verification**
```bash
# VERIFICATION CHECKPOINT: Verify WORKFLOW_SCOPE persisted correctly
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Compliance Checklist**:
- ✓ Verification checkpoints after critical operations (file creation, variable exports)
- ✓ Fail-fast error handling (immediate termination, clear diagnostics)
- ✓ No bootstrap fallbacks masking errors
- ✓ No orchestrator placeholder file creation (agents responsible for artifacts)
- ✓ Completion signals enable downstream verification
- ✓ Aligns with fail-fast philosophy (detect errors, not hide them)

**Conclusion**: /coordinate implements verification pattern correctly. Verification detects errors immediately, does not mask agent failures with placeholder creation.

## Standard 14: Executable/Documentation Separation

### Requirements (from command_architecture_standards.md:1535-1689)

**Two-File Architecture**:
1. Executable command file (<250 lines simple, <1,200 lines orchestrators)
2. Command guide file (unlimited length, comprehensive documentation)
3. Bidirectional cross-references
4. Size enforcement via validation script

**Rationale**: Prevents meta-confusion loops (Claude interpreting docs as conversational instructions), enables fail-fast execution, allows unlimited documentation growth.

### Current Implementation Status: **COMPLIANT**

**Evidence**:

1. **File Size**: 85,584 bytes / 1,084 lines (within 1,200-line orchestrator limit)
2. **Cross-Reference Present** (line 14):
   ```markdown
   **Documentation**: See `.claude/docs/guides/coordinate-command-guide.md`
   ```
3. **Guide File Exists**: `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md` (1,250 lines)
4. **Separation Benefits Achieved**:
   - No meta-confusion incidents (0% vs 75% pre-migration)
   - Immediate execution without recursive invocations
   - Clear role statement (line 12): "YOU ARE EXECUTING AS the /coordinate command"

**Validation Script Results**: Validated via `.claude/tests/validate_executable_doc_separation.sh`

**Compliance Checklist**:
- ✓ File size within limits (1,084 lines < 1,200 max)
- ✓ Cross-reference to guide file present
- ✓ Guide file exists with comprehensive documentation
- ✓ No conversational documentation causing meta-confusion
- ✓ Lean executable with bash blocks and phase markers

**Conclusion**: /coordinate complies with Standard 14. Successfully migrated in Spec 616 (Nov 2025) with 54% size reduction.

## Standard 15: Library Sourcing Order

### Requirements (from command_architecture_standards.md:2277-2412)

**Standard Sourcing Pattern**:
```bash
# 1. State machine foundation (FIRST)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (BEFORE any verification checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries as needed (AFTER core libraries)
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Dependency Justification**:
- State persistence → Error/Verification (error functions depend on `append_workflow_state()`)
- Error/Verification → Checkpoints (verification calls depend on `verify_state_variable()`, `handle_state_error()`)
- Bash block execution model: Functions only available AFTER sourcing (subprocess isolation)

### Current Implementation Status: **COMPLIANT**

**Evidence from /coordinate command (lines 100-253)**:

```bash
# Line 104: State machine
source "${LIB_DIR}/workflow-state-machine.sh"

# Line 116: State persistence
source "${LIB_DIR}/state-persistence.sh"

# Lines 124, 132: Error handling and verification (EARLY sourcing)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Line 247: Additional libraries via source_required_libraries
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**First Function Calls**:
- Line 162: `handle_state_error()` - AFTER sourcing (line 124)
- Line 177: `verify_state_variable()` - AFTER sourcing (line 132)
- No premature function calls detected

**Compliance Checklist**:
- ✓ State machine sourced first
- ✓ State persistence sourced second
- ✓ Error handling sourced before first verification checkpoint
- ✓ Verification helpers sourced before first verification call
- ✓ No premature function calls (all after sourcing)
- ✓ Libraries have source guards (safe for multiple sourcing)

**Conclusion**: /coordinate complies with Standard 15. Fixed in Spec 675 (Nov 2025) which moved error-handling.sh and verification-helpers.sh sourcing to lines 113-138 (immediately after state-persistence.sh).

## Working Examples from Other Commands

### /research Command Agent Invocation (lines 284-300)

**COMPLIANT Example showing Standard 11 pattern**:

```markdown
**EXECUTE NOW**: USE the Task tool for each subtopic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert actual subtopic name] with mandatory artifact creation"
- timeout: 300000
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly subtopic name]
    - Report Path: [insert absolute path from SUBTOPIC_REPORT_PATHS array for this subtopic]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
    - The ORCHESTRATOR calculated your report path (injected above)
    - DO NOT use Task tool to orchestrate other agents
```

**Key Pattern Elements**:
- Imperative directive: "**EXECUTE NOW**: USE the Task tool"
- Behavioral injection: "Read and follow ALL behavioral guidelines from:"
- Context injection only (no behavioral duplication)
- Clear role clarification
- No code block wrappers

### /supervise Command Pattern (lines 167-180)

**COMPLIANT Example showing Standard 11 simplicity**:

```markdown
**EXECUTE NOW**: USE the Task tool for research-specialist (invoke $RESEARCH_COMPLEXITY times in parallel):

Task {
  subagent_type: "general-purpose"
  description: "Research [topic]"
  timeout: 300000
  prompt: "
    Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    Topic: [specific topic name]
    Output: [pre-calculated reports directory]/[001-00N]_[topic].md
    Standards: [project CLAUDE.md path]

    Return: REPORT_CREATED: [absolute path to created report]
  "
}
```

**Key Pattern Elements**:
- Minimal context injection (topic, output path, standards)
- Behavioral file reference (agent reads its own guidelines)
- Completion signal requirement
- Clean imperative directive

## Recommendations

### 1. Add workflow-llm-classifier.sh to REQUIRED_LIBS Arrays

**Priority**: HIGH (Fixes library sourcing violation)

**Rationale**:
- sm_init() depends on classify_workflow_comprehensive()
- classify_workflow_comprehensive() requires workflow-llm-classifier.sh
- Transitive dependency via workflow-scope-detection.sh not explicit
- Standard 15 requires all dependencies sourced

**Implementation**: Add "workflow-llm-classifier.sh" to all four REQUIRED_LIBS arrays

**Lines to Modify**:
- Line 233 (research-only scope)
- Line 236 (research-and-plan/revise scope)
- Line 239 (full-implementation scope)
- Line 242 (debug-only scope)

**Testing**: Run /coordinate with all workflow scopes to verify no "command not found" errors

### 2. Maintain Current Standards Compliance

**Priority**: MEDIUM (Preservation)

**Rationale**: /coordinate already complies with Standards 0, 11, 14, 15. No changes needed.

**Actions**:
- Keep imperative agent invocations unchanged
- Preserve verification checkpoints
- Maintain library sourcing order
- Continue using executable/documentation separation

### 3. Add Source Guard to workflow-llm-classifier.sh

**Priority**: LOW (Enhancement, already present)

**Status**: VERIFIED - workflow-llm-classifier.sh already has source guard (lines 9-12):
```bash
if [ -n "${WORKFLOW_LLM_CLASSIFIER_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_LLM_CLASSIFIER_SOURCED=1
```

**Action**: No changes needed

### 4. Consider Validation Script Addition

**Priority**: LOW (Optional quality assurance)

**Proposal**: Add `/coordinate` to existing orchestration validation suite

**Benefits**:
- Automated detection of Standard 11 violations
- Library sourcing order verification
- Regression prevention

**Implementation**: Update `.claude/tests/test_orchestration_commands.sh` to include coordinate.md

## Implementation Guidance

### Step-by-Step Fix for Missing Library Dependency

**STEP 1**: Backup current coordinate.md
```bash
cp /home/benjamin/.config/.claude/commands/coordinate.md \
   /home/benjamin/.config/.claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)
```

**STEP 2**: Edit coordinate.md at lines 233, 236, 239, 242

**Before (Line 233)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
```

**After (Line 233)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
```

**Before (Line 236)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**After (Line 236)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**Before (Line 239)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
```

**After (Line 239)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
```

**Before (Line 242)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**After (Line 242)**:
```bash
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**STEP 3**: Verify library file exists
```bash
ls -la /home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh
# Expected: -rwxr-xr-x ... 25003 bytes
```

**STEP 4**: Test with all workflow scopes
```bash
# Test research-only
/coordinate "research authentication patterns"

# Test research-and-plan
/coordinate "implement user login with OAuth"

# Test full-implementation
/coordinate "refactor authentication system with new architecture"

# Test debug-only
/coordinate "debug session management race condition"
```

**STEP 5**: Verify no errors in workflow classification
- Expected: Workflow classification succeeds
- No "command not found" errors
- All WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON variables exported

**STEP 6**: Commit changes
```bash
git add /home/benjamin/.config/.claude/commands/coordinate.md
git commit -m "fix(coordinate): add workflow-llm-classifier.sh to REQUIRED_LIBS arrays

Resolves library sourcing violation where sm_init dependency chain
(sm_init → classify_workflow_comprehensive → workflow-llm-classifier.sh)
was not explicitly sourced in all workflow scope cases.

Changes:
- Added workflow-llm-classifier.sh to all four REQUIRED_LIBS arrays
- Maintains compliance with Standard 15 (Library Sourcing Order)
- Ensures transitive dependencies are explicit

Testing: Verified with all workflow scopes (research-only, research-and-plan,
full-implementation, debug-only) - no 'command not found' errors.

Standards compliance: Maintains Standards 0, 11, 14, 15 compliance."
```

## References

### Command Files Analyzed
- `/home/benjamin/.config/.claude/commands/coordinate.md` (1,084 lines, 85,584 bytes)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 284-300 for agent invocation example)
- `/home/benjamin/.config/.claude/commands/supervise.md` (lines 167-180 for simplified pattern example)

### Library Files Analyzed
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (25,003 bytes, source guard present)
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (lines 26-27 show dependency on workflow-llm-classifier.sh)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (lines 20-21 show dependency on workflow-scope-detection.sh)

### Standards Documentation Referenced
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`:
  - Standard 0 (lines 51-463): Execution Enforcement / Verification and Fallback Pattern
  - Standard 11 (lines 1173-1353): Imperative Agent Invocation Pattern
  - Standard 14 (lines 1535-1689): Executable/Documentation Separation
  - Standard 15 (lines 2277-2412): Library Sourcing Order
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-300): Behavioral injection pattern documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md` (lines 1-200): Verification and fallback pattern documentation

### Historical Context
- Spec 438 (2025-10-24): /supervise agent delegation fix establishing Standard 11
- Spec 495 (2025-10-27): /coordinate and /research agent delegation fixes
- Spec 497 (2025-10-27): Unified orchestration improvements
- Spec 057 (2025-10-27): /supervise fail-fast error handling and bootstrap removal
- Spec 616 (2025-11-07): /coordinate executable/documentation separation migration
- Spec 675 (2025-11-11): /coordinate library sourcing order fix
- Spec 678 (2025-11-XX): Comprehensive workflow classification integration

### Testing Resources
- `.claude/tests/validate_executable_doc_separation.sh` - Standard 14 validation
- `.claude/tests/test_orchestration_commands.sh` - Standard 11 validation
- `.claude/tests/test_library_sourcing_order.sh` - Standard 15 validation
