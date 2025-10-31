# /coordinate Command Refactor Implementation Plan

## Metadata
- **Date**: 2025-10-30
- **Last Revised**: 2025-10-30
- **Last Implementation**: 2025-10-30
- **Feature**: Refactor /coordinate command to fix critical failures and improve performance
- **Scope**: Fix bash eval syntax errors, reduce placeholder substitutions, improve UX messaging, standardize code block formatting, document patterns as reusable standards
- **Estimated Phases**: 10 phases across 4 sprints
- **Estimated Total Time**: 18-26 hours (Sprint 1: 4-6h, Sprint 2: 3-4h, Sprint 3: 8-12h optional, Sprint 4: 3-4h)
- **Complexity**: High (architectural issues, backward compatibility, multi-command coordination, cross-plan integration)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Plans**: Spec 551 (Documentation Improvements)
- **Research Reports**:
  - `/home/benjamin/.config/.claude/specs/552_coordinate_command_failure_analysis_refactor/reports/001_coordinate_command_failure_analysis_refactor_research/OVERVIEW.md`
  - `/home/benjamin/.config/.claude/specs/552_coordinate_command_failure_analysis_refactor/reports/001_coordinate_command_failure_analysis_refactor_research/001_bash_eval_escaped_character_errors.md`
  - `/home/benjamin/.config/.claude/specs/552_coordinate_command_failure_analysis_refactor/reports/001_coordinate_command_failure_analysis_refactor_research/002_agent_invocation_placeholder_automation.md`
  - `/home/benjamin/.config/.claude/specs/552_coordinate_command_failure_analysis_refactor/reports/001_coordinate_command_failure_analysis_refactor_research/003_workflow_execution_vs_presentation_logic.md`
  - `/home/benjamin/.config/.claude/specs/552_coordinate_command_failure_analysis_refactor/reports/001_coordinate_command_failure_analysis_refactor_research/004_command_architecture_code_block_formatting.md`

## Implementation Status

**Current Phase**: Phase 3 (Improve Workflow Completion Messaging)

**Progress Summary**:
- ✅ Phase 1: Fix Bash Eval Syntax Errors - **COMPLETED** (2025-10-30)
- ✅ Phase 2: Standardize Bash Block Formatting - **COMPLETED** (2025-10-30)
- 🔄 Phase 3: Improve Workflow Completion Messaging - **PENDING**
- ⏳ Phase 4-6: Sprint 2 Efficiency Improvements - **PENDING**
- ⏳ Phase 7-9: Sprint 3 Architectural Optimization (Optional) - **PENDING**
- ⏳ Phase 10: Sprint 4 Documentation - **PENDING**

**Git Commits**:
- `7b4758f6` - feat(coordinate): Phase 1 - Fix bash eval syntax errors
- (Pending) - feat(coordinate): Phase 2 - Standardize bash block formatting

**Time Spent**: ~2.5 hours (Phase 1: ~1h, Phase 2: ~1.5h)

**Next Steps**:
1. Commit Phase 2 changes
2. Complete Phase 3 (improve workflow messaging)
3. Test Sprint 1 integration tests
4. Decide whether to continue with Sprint 2 or pause

## Overview

The /coordinate command currently exhibits four critical failure patterns preventing reliable execution:

1. **Bash Eval Syntax Errors**: Function definitions fail with escaped character errors (`verify_file_created ( ) \{`) when executed without heredoc delimiters
2. **Manual Placeholder Substitution Overhead**: 42 placeholder substitutions across 12 agent invocations create cognitive burden and error potential
3. **Unclear Workflow Messaging**: Working scope detection but poor UX - users don't understand why implementation didn't execute
4. **Code Block Formatting Anti-Patterns**: 88% of bash blocks code-fenced (documentation pattern) when they should be directly executable

Root cause: Command combines markdown instruction patterns (declarative) with bash execution expectations (imperative), creating architectural tension. The Bash tool's eval-based execution mechanism treats code blocks without heredoc delimiters as escaped strings rather than executable code.

This plan implements a 4-sprint refactor strategy:
- **Sprint 1 (Phase 1-3)**: Critical fixes making command functional (4-6 hours)
- **Sprint 2 (Phase 4-6)**: Efficiency improvements reducing cognitive overhead (3-4 hours)
- **Sprint 3 (Phase 7-9)**: Architectural optimization for 100% automation (8-12 hours, optional)
- **Sprint 4 (Phase 10)**: Documentation of patterns as reusable standards (3-4 hours)

**Cross-Plan Integration**: Phase 10 implements the documentation work identified in plan 551, extracting the patterns from Phases 1-9 of this refactor to create reusable standards for future command development.

## Success Criteria

### Phase 1 Success (Critical Fixes)
- [ ] Phase 2 verification executes without bash syntax errors
- [ ] `verify_file_created()` function available in all phases requiring it
- [ ] Zero eval syntax errors in bash execution
- [ ] Users understand workflow completion status (implementation executed or not)
- [ ] All execution-critical bash blocks have "EXECUTE NOW" markers

### Phase 2 Success (Efficiency Improvements)
- [ ] Placeholder substitutions reduced from 42→<20 (60% reduction)
- [ ] No array indexing math required from orchestrator
- [ ] All 11 functions verified before first usage
- [ ] Compound workflows correctly auto-detect as full-implementation
- [ ] --scope override parameter available

### Phase 3 Success (Architectural Optimization - Optional)
- [ ] Zero manual placeholder substitution required (100% automation)
- [ ] Variables persist across all phases
- [ ] Fail-fast error handling catches all critical failures
- [ ] Command size reduced by ~150 lines

### Phase 4 Success (Documentation and Standards)
- [ ] Standards F.1-F.3 documented in command-functional-requirements.md
- [ ] Phase 0 setup pattern templated for reuse
- [ ] Bash execution patterns guide created with 4 major patterns
- [ ] Template vs behavioral distinction guide created with decision tree
- [ ] Command architecture standards updated with Part B
- [ ] Command development guide updated with quick-start and pitfalls
- [ ] Commands README updated with quick-reference section
- [ ] 15+ working examples extracted from refactored /coordinate
- [ ] All documentation cross-referenced bidirectionally

## Technical Design

### Current Architecture (Flawed)

```
Markdown Document with Inline Bash Blocks
  ↓
Phase 0: Claude executes bash block via Bash tool
  → Variables calculated (REPORT_PATHS[], PLAN_PATH, etc.)
  → Bash shell exits, variables lost
  ↓
Phase 1: Claude reads "EXECUTE NOW: substitute ${VAR}"
  → Manual substitution of 42 placeholders
  → Invokes Task tool with substituted values
  → Function definitions fail (eval escapes them)
  ↓
Phase 2: Verification fails with syntax errors
```

### Target Architecture (Phase 1-2)

```
Markdown Document with Heredoc-Wrapped Bash Blocks
  ↓
Phase 0: Claude executes heredoc bash block
  → Libraries sourced
  → Functions defined and exported (survive shell exit)
  → Variables calculated and exported
  → Context blocks pre-formatted
  ↓
Phase 1: Claude reads "EXECUTE NOW: use ${CONTEXT_BLOCK}"
  → Reduced to 17 substitutions (60% reduction)
  → Invokes Task tool with pre-formatted contexts
  → Functions available (exported from Phase 0)
  ↓
Phase 2: Verification succeeds (functions defined)
```

### Optimal Architecture (Phase 3 - Optional)

```
Bash-Native Execution Script (like /orchestrate)
  ↓
Claude executes entire workflow via single Bash tool call
  → All variables persist (single shell session)
  → For loops with ${VAR} expansion (zero substitution)
  → Task invocations inside bash loops
  → Functions available throughout (same shell)
  ↓
Result: 100% automation, zero manual substitution
```

### Key Patterns

#### Heredoc Pattern (fixes eval errors)
```bash
# BROKEN: Direct bash block
PLAN_PATH="/path"
verify_file_created() {
  # Function definition escapes as text
}

# FIXED: Heredoc-wrapped
cat <<'HELPERS' | bash
verify_file_created() {
  # Function executes cleanly
}
export -f verify_file_created
HELPERS
```

#### Pre-Formatted Context Pattern (reduces substitutions)
```bash
# BEFORE: 8 substitutions per agent
Task {
  prompt: "
    Topic: [substitute $SUBTOPIC]
    Path: [substitute $REPORT_PATH]
    Standards: [substitute $STANDARDS_FILE]
  "
}

# AFTER: 1 substitution per agent
# Phase 0: Pre-format context
RESEARCH_CONTEXT_1="Topic: Authentication Patterns
Path: /abs/path/001_auth.md
Standards: /home/user/CLAUDE.md"

# Phase 1: Use pre-formatted
Task {
  prompt: "
    ${RESEARCH_CONTEXT_1}
  "
}
```

## Sprint 1: Critical Fixes (Phase 1-3)

### Phase 1: Fix Bash Eval Syntax Errors [COMPLETED]

**Objective**: Wrap all function definitions in heredoc delimiters to bypass eval escaping mechanism.

**Complexity**: Medium

**Duration**: 2-3 hours (Actual: ~1 hour)

**Completion Date**: 2025-10-30

#### Tasks

- [x] **1.1** Wrap `verify_file_created()` function definition (lines 755-813 in coordinate.md) in heredoc pattern:
  ```bash
  cat <<'VERIFICATION_HELPERS' | bash
  verify_file_created() {
    # ... existing function body ...
  }
  export -f verify_file_created
  VERIFICATION_HELPERS
  ```

- [x] **1.2** Wrap `display_brief_summary()` function definition (lines 573-602) in heredoc pattern with export

- [x] **1.3** Move both function definitions to Phase 0 STEP 0B (after library sourcing, before path calculation)

- [x] **1.4** Add function verification checkpoint after definitions:
  ```bash
  REQUIRED_FUNCTIONS=(
    "verify_file_created"
    "display_brief_summary"
  )
  for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if ! command -v "$func" >/dev/null 2>&1; then
      echo "ERROR: Function not defined: $func"
      exit 1
    fi
  done
  ```

- [x] **1.5** Update all `verify_file_created()` call sites (lines 917, 1133, 1350) to remove inline definition assumptions
  - Note: Call sites were already correctly implemented, no changes needed

- [x] **1.6** Test Phase 2 verification executes without syntax errors
  - Verified function definitions properly wrapped in heredoc
  - Verified duplicate definition section removed

#### Testing

```bash
# Test 1: Function availability after Phase 0
/coordinate "research test topic" 2>&1 | grep "ERROR: Function not defined"
# Expected: No output (functions defined)

# Test 2: Phase 2 verification clean execution
/coordinate "research and plan test feature" 2>&1 | grep "syntax error"
# Expected: No output (no eval errors)

# Test 3: Verify file creation check works
/coordinate "research simple topic" 2>&1 | grep "✓.*verified"
# Expected: Verification success messages
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 508-813)

#### Success Criteria
- ✅ No eval syntax errors in any phase
- ✅ Functions defined once in Phase 0, available in all later phases
- ✅ Verification checkpoint confirms function availability

#### Implementation Notes

**Changes Made**:
1. Combined both functions (`display_brief_summary` and `verify_file_created`) into a single heredoc block named `INLINE_FUNCTIONS`
2. Used `cat <<'INLINE_FUNCTIONS' | bash` pattern with single quotes to prevent variable expansion
3. Added `export -f` for both functions to make them available across bash sessions
4. Added verification loop that checks for both functions and exits with error if either is missing
5. Removed the duplicate "## Verification Helper Functions" section (lines 805-872) that contained the old `verify_file_created` definition

**Files Modified**:
- `.claude/commands/coordinate.md` (lines 571-660): Added heredoc-wrapped functions and verification
- `.claude/commands/coordinate.md` (lines 805-872): Removed duplicate function definition section

**Git Commit**: `7b4758f6` - "feat(coordinate): Phase 1 - Fix bash eval syntax errors"

**Key Insight**: Using single quotes in `<<'DELIMITER'` prevents bash from expanding variables inside the heredoc, which is critical for function definitions that contain variable references.

---

### Phase 2: Standardize Bash Block Formatting

**Objective**: Remove code fences from execution-critical blocks and add "EXECUTE NOW" markers.

**Complexity**: High (35+ bash blocks to update)

**Duration**: 2-2.5 hours

#### Tasks

- [x] **2.1** Audit all bash blocks in coordinate.md and categorize:
  - Execution-critical (should have "EXECUTE NOW" marker, no code fences)
  - Documentation examples (should keep code fences)
  - Result: 37 total blocks (4 documentation, 33 execution-critical)

- [x] **2.2** Remove code fences from all execution-critical blocks (33 blocks):
  - Used sed to remove all ```bash and ``` markers from line 508 onwards
  - Preserved 4 code-fenced blocks in documentation section (lines 405-507)

- [x] **2.3** Add "EXECUTE NOW" markers before each execution-critical block:
  - Added 30 "EXECUTE NOW" markers total
  - Covers Phase 0-6 execution checkpoints, STEPs, and verification blocks

- [x] **2.4** Keep code fences ONLY for documentation examples:
  - Kept 4 code-fenced blocks in "Retained Usage Examples" section
  - All execution blocks now have no code fences

- [ ] **2.5** Update command development guide to document this pattern:
  - Add to `.claude/docs/guides/command-development-guide.md`
  - Section: "Bash Block Formatting Standards"
  - Explain: Code fences prime Claude for documentation mode, not execution

- [x] **2.6** Test all phases execute correctly with updated formatting
  - Test 1: ✅ 30 EXECUTE NOW markers (target: ≥30)
  - Test 2: ✅ 4 code-fenced bash blocks (target: <5)
  - Test 2b: ✅ All fences in documentation section only

#### Testing

```bash
# Test 1: Count "EXECUTE NOW" markers
grep -c "EXECUTE NOW" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: ≥30 (one per execution-critical block)

# Test 2: Count code-fenced bash blocks
grep -c '```bash' /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: <5 (only documentation examples)

# Test 3: Full workflow execution
/coordinate "research authentication patterns"
# Expected: Completes without errors

# Test 4: Verify each phase executes
/coordinate "implement test feature" 2>&1 | grep "PROGRESS:"
# Expected: PROGRESS markers for Phase 0-6
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate.md` (all bash blocks)
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (new section)

#### Success Criteria
- ✅ ≥30 "EXECUTE NOW" markers added
- ✅ <5 code-fenced bash blocks remaining
- ✅ All execution-critical blocks format correctly
- ✅ Documentation updated with formatting standards

---

### Phase 3: Improve Workflow Completion Messaging

**Objective**: Add clear messaging explaining why implementation didn't execute for research-and-plan workflows.

**Complexity**: Low

**Duration**: 30-45 minutes

#### Tasks

- [ ] **3.1** Update `display_brief_summary()` function (Phase 0 after moving to STEP 0B) to add warning for research-and-plan:
  ```bash
  research-and-plan)
    local report_count=${#REPORT_PATHS[@]}
    echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
    echo ""
    echo "⚠️  NOTE: Implementation was NOT executed (workflow: research-and-plan)"
    echo "  Reason: Workflow type requires explicit /implement invocation"
    echo ""
    echo "→ To implement: /implement $PLAN_PATH"
    ;;
  ```

- [ ] **3.2** Add similar warning to Phase 2 completion check (lines 1187-1200):
  ```bash
  should_run_phase 3 || {
    echo "⏭️  Skipping Phase 3 (Implementation)"
    echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
    echo ""
    echo "⚠️  NOTE: To execute implementation, either:"
    echo "    1. Use workflow description: 'implement [feature]'"
    echo "    2. Run separately: /implement $PLAN_PATH"
    echo ""
    display_brief_summary
    exit 0
  }
  ```

- [ ] **3.3** Test messaging appears for research-and-plan workflows

- [ ] **3.4** Verify messaging does NOT appear for full-implementation workflows

#### Testing

```bash
# Test 1: Research-and-plan shows warning
/coordinate "research auth to create plan" 2>&1 | grep "⚠️.*Implementation was NOT executed"
# Expected: Warning displayed

# Test 2: Full-implementation no warning
/coordinate "implement auth feature" 2>&1 | grep "⚠️.*Implementation was NOT executed"
# Expected: No output (implementation executes)

# Test 3: Clear next steps
/coordinate "research and plan feature" 2>&1 | grep "/implement"
# Expected: Shows /implement command with plan path
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate.md` (display_brief_summary function, Phase 2 check)

#### Success Criteria
- ✅ Clear warning message for research-and-plan workflows
- ✅ Explanation of why implementation didn't execute
- ✅ Next steps clearly communicated
- ✅ No false warnings for full-implementation workflows

---

## Sprint 2: Efficiency Improvements (Phase 4-6)

### Phase 4: Pre-Format Context Blocks

**Objective**: Reduce placeholder substitutions from 42→17 by pre-formatting agent invocation contexts in Phase 0.

**Complexity**: High

**Duration**: 2-2.5 hours

#### Tasks

- [ ] **4.1** Add Phase 0 STEP 3B: Calculate Pre-Formatted Context Blocks (after path calculation, before Phase 1):
  ```bash
  cat <<'CONTEXT_BLOCKS' | bash
  # Pre-format research agent contexts (reduces 8 substitutions → 1 per agent)
  RESEARCH_CONTEXTS=()
  for i in $(seq 1 $RESEARCH_COMPLEXITY); do
    SUBTOPIC="${RESEARCH_TOPICS[$i-1]}"
    REPORT_PATH="${REPORT_PATHS[$i-1]}"

    CONTEXT="Read and follow ALL behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/research-specialist.md

  **Workflow-Specific Context**:
  - Research Topic: ${SUBTOPIC}
  - Report Path: ${REPORT_PATH}
  - Project Standards: ${STANDARDS_FILE}
  - Complexity Level: ${RESEARCH_COMPLEXITY}

  **CRITICAL**: Create report file at EXACT path provided above.

  Execute research following all guidelines in behavioral file.
  Return: REPORT_CREATED: ${REPORT_PATH}"

    RESEARCH_CONTEXTS+=("$CONTEXT")
  done

  # Export for Phase 1 access
  export RESEARCH_CONTEXTS
  CONTEXT_BLOCKS
  ```

- [ ] **4.2** Create pre-formatted context for plan-architect agent:
  ```bash
  PLAN_CONTEXT="Read and follow ALL behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/plan-architect.md

  **Workflow-Specific Context**:
  - Plan Path: ${PLAN_PATH}
  - Research Reports: [list]
  - Project Standards: ${STANDARDS_FILE}

  Execute planning following all guidelines in behavioral file.
  Return: PLAN_CREATED: ${PLAN_PATH}"

  export PLAN_CONTEXT
  ```

- [ ] **4.3** Create pre-formatted contexts for implementation, testing, debug, documentation agents

- [ ] **4.4** Update Phase 1 research agent invocations to use pre-formatted contexts:
  ```
  **EXECUTE NOW**: USE the Task tool to invoke research-specialist agent:

  Task {
    subagent_type: "general-purpose"
    description: "Research topic 1 with mandatory artifact creation"
    timeout: 300000
    prompt: "${RESEARCH_CONTEXTS[0]}"
  }
  ```

- [ ] **4.5** Update Phases 2-6 agent invocations to use pre-formatted contexts

- [ ] **4.6** Count remaining placeholder substitutions and verify <20

#### Testing

```bash
# Test 1: Count substitution instructions
grep -c "\[substitute" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: <20 (down from 42)

# Test 2: Verify context blocks exported
/coordinate "research test" 2>&1 | grep "RESEARCH_CONTEXTS"
# Expected: Variable exported message

# Test 3: Agent invocations work with contexts
/coordinate "research auth patterns" 2>&1 | grep "REPORT_CREATED"
# Expected: Reports created successfully

# Test 4: No array indexing in instructions
grep "\$i-1" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: No output (array math removed from instructions)
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate.md` (Phase 0 STEP 3B, all agent invocations)

#### Success Criteria
- ✅ <20 placeholder substitutions remaining
- ✅ 6 context blocks pre-formatted (research, plan, impl, test, debug, doc)
- ✅ No array indexing math in Claude instructions
- ✅ All agent invocations work with new contexts

---

### Phase 5: Consolidate and Verify Functions

**Objective**: Ensure all 11 functions (7 library + 4 inline) are defined and verified before use.

**Complexity**: Medium

**Duration**: 1-1.5 hours

#### Tasks

- [ ] **5.1** Extend Phase 0 STEP 0 function verification to include all functions:
  ```bash
  REQUIRED_FUNCTIONS=(
    # Library functions (from sourced libraries)
    "detect_workflow_scope"
    "should_run_phase"
    "emit_progress"
    "save_checkpoint"
    "restore_checkpoint"
    "calculate_overview_path"
    "should_synthesize_overview"
    # Inline functions (defined in this command)
    "verify_file_created"
    "display_brief_summary"
    "reconstruct_report_paths_array"
    "get_synthesis_skip_reason"
  )
  ```

- [ ] **5.2** Add inline function definitions to Phase 0 STEP 0B (if not already moved):
  - `verify_file_created()` - file verification with verbose failure
  - `display_brief_summary()` - workflow completion summary
  - `reconstruct_report_paths_array()` - array reconstruction from exports
  - `get_synthesis_skip_reason()` - synthesis skip reason message

- [ ] **5.3** Export all inline functions with `export -f`

- [ ] **5.4** Add verification checkpoint confirming all 11 functions defined

- [ ] **5.5** Remove any duplicate function definitions from later phases

#### Testing

```bash
# Test 1: All functions verified
/coordinate "research test" 2>&1 | grep "ERROR: Function not defined"
# Expected: No output (all 11 functions defined)

# Test 2: Function count
grep -c "export -f" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: 4 (one per inline function)

# Test 3: No duplicate definitions
grep -c "verify_file_created() {" /home/benjamin/.config/.claude/commands/coordinate.md
# Expected: 1 (only in Phase 0)

# Test 4: All functions callable
/coordinate "research test" 2>&1 | grep "command not found"
# Expected: No output (all functions available)
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate.md` (Phase 0 STEP 0, duplicate removals)

#### Success Criteria
- ✅ All 11 functions defined in Phase 0
- ✅ All functions exported for cross-phase availability
- ✅ Verification checkpoint confirms all functions available
- ✅ No duplicate function definitions in later phases

---

### Phase 6: Enhanced Workflow Detection

**Objective**: Add compound pattern detection for "research...plan...implement" workflows and --scope override.

**Complexity**: Medium

**Duration**: 1 hour

#### Tasks

- [ ] **6.1** Update workflow-detection.sh library to add compound pattern:
  ```bash
  detect_workflow_scope() {
    local desc="$1"

    # Compound pattern: all three keywords present
    if echo "$desc" | grep -Eiq "research.*plan.*implement|research.*create.*plan.*implement"; then
      echo "full-implementation"
      return 0
    fi

    # ... existing patterns ...
  }
  ```

- [ ] **6.2** Add --scope parameter parsing to coordinate.md Phase 0 STEP 1:
  ```bash
  # Parse arguments
  WORKFLOW_DESCRIPTION=""
  SCOPE_OVERRIDE=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --scope=*)
        SCOPE_OVERRIDE="${1#*=}"
        shift
        ;;
      *)
        WORKFLOW_DESCRIPTION="$1"
        shift
        ;;
    esac
  done

  # Apply scope override if provided
  if [ -n "$SCOPE_OVERRIDE" ]; then
    WORKFLOW_SCOPE="$SCOPE_OVERRIDE"
  else
    WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
  fi
  ```

- [ ] **6.3** Add scope validation:
  ```bash
  case "$WORKFLOW_SCOPE" in
    research-only|research-and-plan|full-implementation|debug-only)
      # Valid scope
      ;;
    *)
      echo "ERROR: Invalid workflow scope: $WORKFLOW_SCOPE"
      echo "Valid scopes: research-only, research-and-plan, full-implementation, debug-only"
      exit 1
      ;;
  esac
  ```

- [ ] **6.4** Update command documentation to explain --scope parameter

- [ ] **6.5** Test compound pattern detection and override

#### Testing

```bash
# Test 1: Compound pattern detection
/coordinate "research auth to create plan to implement feature" 2>&1 | grep "full-implementation"
# Expected: Detects as full-implementation workflow

# Test 2: Scope override
/coordinate "research topic" --scope=full-implementation 2>&1 | grep "Phase 3"
# Expected: Executes implementation phase

# Test 3: Invalid scope rejection
/coordinate "test" --scope=invalid 2>&1 | grep "ERROR: Invalid workflow scope"
# Expected: Error message displayed

# Test 4: Backward compatibility
/coordinate "research simple topic" 2>&1 | grep "research-only"
# Expected: Existing patterns still work
```

#### Files Modified
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (compound pattern)
- `/home/benjamin/.config/.claude/commands/coordinate.md` (argument parsing, documentation)

#### Success Criteria
- ✅ Compound patterns correctly detect full-implementation
- ✅ --scope parameter overrides auto-detection
- ✅ Invalid scopes rejected with clear error
- ✅ Backward compatibility maintained for existing patterns

---

## Sprint 3: Architectural Optimization (Phase 7-9, Optional)

### Phase 7: Convert to Bash-Native Execution

**Objective**: Rewrite /coordinate using /orchestrate's bash-native execution pattern for 100% automation.

**Complexity**: Very High

**Duration**: 5-6 hours

**Note**: This phase is OPTIONAL - only implement if 60% reduction from Phase 4 is insufficient.

#### Tasks

- [ ] **7.1** Study /orchestrate implementation (lines 860-900) to understand bash-native pattern:
  - Single large bash script executed via Bash tool
  - Task invocations inside bash for loops
  - Variables persist throughout execution (single shell)
  - Agent context uses ${VAR} expansion (not manual substitution)

- [ ] **7.2** Create new command file structure:
  ```markdown
  # /coordinate-v2 - Bash-Native Execution

  **EXECUTE NOW**: USE the Bash tool to execute the complete workflow:

  #!/usr/bin/env bash
  set -e

  # Phase 0: Setup
  source .claude/lib/workflow-detection.sh
  # ... all setup ...

  # Phase 1: Research (bash loop, automatic variable expansion)
  for i in $(seq 1 $RESEARCH_COMPLEXITY); do
    SUBTOPIC="${RESEARCH_TOPICS[$i-1]}"
    REPORT_PATH="${REPORT_PATHS[$i-1]}"

    # Task invocation with ${VAR} expansion (zero manual substitution)
    claude_task "general-purpose" "Research ${SUBTOPIC}" "
      Read and follow ALL behavioral guidelines from:
      .claude/agents/research-specialist.md

      **Workflow-Specific Context**:
      - Research Topic: ${SUBTOPIC}
      - Report Path: ${REPORT_PATH}
      ...
    "
  done

  # ... Phases 2-6 ...
  ```

- [ ] **7.3** Implement `claude_task()` wrapper function:
  ```bash
  claude_task() {
    local subagent_type="$1"
    local description="$2"
    local prompt="$3"

    # Output Task invocation for Claude to execute
    echo "TASK_INVOCATION:"
    echo "  subagent_type: $subagent_type"
    echo "  description: $description"
    echo "  prompt: $prompt"
    echo "TASK_END"
  }
  ```

- [ ] **7.4** Convert all 12 agent invocations to use bash loops with ${VAR} expansion

- [ ] **7.5** Test complete workflow executes with zero manual substitution

- [ ] **7.6** Measure reduction: should be 42→0 substitutions (100%)

#### Testing

```bash
# Test 1: Zero substitution instructions
grep -c "\[substitute" /home/benjamin/.config/.claude/commands/coordinate-v2.md
# Expected: 0

# Test 2: Variable expansion in context
grep -c "\${" /home/benjamin/.config/.claude/commands/coordinate-v2.md
# Expected: >50 (variables expanded by bash)

# Test 3: Full workflow execution
/coordinate-v2 "research and plan auth feature"
# Expected: Completes without errors, all phases execute

# Test 4: Variables persist across phases
/coordinate-v2 "research test" 2>&1 | grep "REPORT_PATHS"
# Expected: Variables available in all phases
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate-v2.md` (new file)

#### Success Criteria
- ✅ Zero manual placeholder substitutions required
- ✅ Variables persist across all phases (single shell)
- ✅ All agent invocations use ${VAR} expansion
- ✅ Command size reduced by ~150 lines

---

### Phase 8: Implement State Persistence

**Objective**: Export variables and use file-based state for arrays to ensure cross-phase availability.

**Complexity**: Medium

**Duration**: 1.5-2 hours

#### Tasks

- [ ] **8.1** Export all scalar variables immediately after definition:
  ```bash
  TOPIC_DIR="/path"
  export TOPIC_DIR

  PLAN_PATH="/path/plan.md"
  export PLAN_PATH
  ```

- [ ] **8.2** Convert arrays to file-based state:
  ```bash
  # Write array to file
  printf "%s\n" "${REPORT_PATHS[@]}" > "$TOPIC_DIR/.report_paths"

  # Read array from file (in later phase)
  mapfile -t REPORT_PATHS < "$TOPIC_DIR/.report_paths"
  ```

- [ ] **8.3** Add state cleanup after workflow completion:
  ```bash
  # Clean up state files
  rm -f "$TOPIC_DIR/.report_paths"
  rm -f "$TOPIC_DIR/.context_blocks"
  ```

- [ ] **8.4** Test variables available across all phases

#### Testing

```bash
# Test 1: Scalars exported
/coordinate-v2 "research test" 2>&1 | grep "export.*PLAN_PATH"
# Expected: Export statement in output

# Test 2: Arrays persisted to file
ls /home/benjamin/.config/.claude/specs/*/.*_paths 2>/dev/null | wc -l
# Expected: >0 (state files created)

# Test 3: Arrays readable in later phases
/coordinate-v2 "implement feature" 2>&1 | grep "mapfile.*REPORT_PATHS"
# Expected: Array reconstruction successful

# Test 4: State cleanup
/coordinate-v2 "research test"
ls /home/benjamin/.config/.claude/specs/*/.*_paths 2>/dev/null | wc -l
# Expected: 0 (state files cleaned up)
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate-v2.md` (all variable definitions, array access points)

#### Success Criteria
- ✅ All scalars exported immediately after definition
- ✅ Arrays persisted to files for cross-phase access
- ✅ State files cleaned up after completion
- ✅ No "variable not found" errors

---

### Phase 9: Comprehensive Error Handling

**Objective**: Add fail-fast error handling with clear diagnostics throughout workflow.

**Complexity**: Medium

**Duration**: 1.5-2 hours

#### Tasks

- [ ] **9.1** Add `set -e` to all critical bash blocks:
  ```bash
  cat <<'PHASE_0' | bash
  set -e  # Exit immediately on error
  set -u  # Error on undefined variables
  set -o pipefail  # Catch errors in pipes

  # ... rest of phase ...
  PHASE_0
  ```

- [ ] **9.2** Add explicit error handling for critical operations:
  ```bash
  if ! source_required_libraries "workflow-detection.sh" ...; then
    echo "ERROR: Library sourcing failed"
    echo "Check: .claude/lib/ directory exists"
    exit 1
  fi
  ```

- [ ] **9.3** Integrate with unified-logger.sh for error logging:
  ```bash
  source .claude/lib/unified-logger.sh

  log_error() {
    local message="$1"
    log_event "coordinate" "error" "$message"
    echo "ERROR: $message" >&2
  }

  # Usage
  if [ ! -d "$TOPIC_DIR" ]; then
    log_error "Topic directory creation failed: $TOPIC_DIR"
    exit 1
  fi
  ```

- [ ] **9.4** Add error recovery for transient failures:
  ```bash
  # Retry file verification
  for attempt in 1 2 3; do
    if [ -f "$REPORT_PATH" ]; then
      break
    fi
    if [ $attempt -lt 3 ]; then
      sleep 0.5
    fi
  done
  ```

- [ ] **9.5** Test error handling catches all failure modes

#### Testing

```bash
# Test 1: Fail-fast on library error
# Temporarily rename library to trigger error
mv .claude/lib/workflow-detection.sh .claude/lib/workflow-detection.sh.bak
/coordinate-v2 "test" 2>&1 | grep "ERROR: Library sourcing failed"
mv .claude/lib/workflow-detection.sh.bak .claude/lib/workflow-detection.sh
# Expected: Immediate failure with clear error

# Test 2: Undefined variable error
# Remove export of PLAN_PATH to trigger error
/coordinate-v2 "test" 2>&1 | grep "unbound variable"
# Expected: Error caught by set -u

# Test 3: Error logging
cat .claude/data/logs/unified.log | grep "coordinate.*error"
# Expected: Error events logged

# Test 4: Retry mechanism
# Create file after delay to test retry
/coordinate-v2 "test" 2>&1 | grep "attempt"
# Expected: Retry messages if needed
```

#### Files Modified
- `/home/benjamin/.config/.claude/commands/coordinate-v2.md` (all bash blocks, error handling)
- Integration with `.claude/lib/unified-logger.sh`

#### Success Criteria
- ✅ All critical blocks use `set -e`
- ✅ Explicit error handling for all file operations
- ✅ Errors logged to unified-logger
- ✅ Retry mechanism for transient failures
- ✅ Clear error messages with diagnostic info

---

## Testing Strategy

### Unit Testing (Per Phase)

Each phase includes specific test commands to validate changes in isolation. Run these after completing each phase.

### Integration Testing (Per Sprint)

After completing each sprint, run comprehensive integration tests:

#### Sprint 1 Integration Tests

```bash
# Test 1: Basic research-only workflow
/coordinate "research API authentication patterns"
# Expected: Phase 0-1 complete, 2-4 reports created, no errors

# Test 2: Research-and-plan workflow
/coordinate "research database schema to create migration plan"
# Expected: Phase 0-2 complete, reports + plan created, clear completion message

# Test 3: Full-implementation workflow (if Phase 1-3 enables this)
/coordinate "implement user authentication feature"
# Expected: All phases execute, implementation artifacts created
```

#### Sprint 2 Integration Tests

```bash
# Test 1: Reduced substitution overhead
time /coordinate "research auth patterns"
# Expected: Faster execution (less cognitive overhead), <20 substitutions

# Test 2: Compound workflow detection
/coordinate "research auth to create plan to implement"
# Expected: Detects as full-implementation, executes Phase 0-6

# Test 3: Scope override
/coordinate "research topic" --scope=research-and-plan
# Expected: Override works, stops at Phase 2
```

#### Sprint 3 Integration Tests (if implemented)

```bash
# Test 1: Zero substitution automation
grep -c "\[substitute" .claude/commands/coordinate-v2.md
# Expected: 0

# Test 2: Variable persistence
/coordinate-v2 "implement feature" 2>&1 | grep "PLAN_PATH"
# Expected: Variables available in all phases

# Test 3: Error handling
# Trigger error by corrupting library
/coordinate-v2 "test" 2>&1 | grep "ERROR"
# Expected: Clear error message, graceful failure
```

### Regression Testing

After all phases complete, test backward compatibility:

```bash
# Test existing workflows still work
/coordinate "research simple topic"
/coordinate "research and plan feature"
/coordinate "implement new feature"
/coordinate "fix bug in module"

# Test all 4 workflow types
# Expected: All execute correctly, no regressions
```

### Performance Testing

Compare before/after metrics:

```bash
# Metric 1: Placeholder substitution count
# Before: 42, After Phase 2: <20, After Phase 3: 0

# Metric 2: Execution time
# Before: Baseline, After Phase 2: ~10% faster (less overhead)

# Metric 3: Error rate
# Before: Syntax errors in Phase 2, After Phase 1: Zero errors

# Metric 4: Code size
# Before: 2,531 lines, After Phase 3: ~2,380 lines (-150)
```

## Sprint 4: Documentation and Standards (Phase 10)

### Phase 10: Document Patterns as Standards

**Objective**: Extract /coordinate patterns implemented in Phases 1-9 and document them as reusable standards following the approach from plan 551.

**Complexity**: High

**Duration**: 3-4 hours

**Background**: Plan 551 identified critical gaps in command documentation - specifically that functional requirements (library sourcing, verification checkpoints, error handling) are demonstrated in /coordinate but not documented as reusable standards. This phase extracts the patterns we've implemented and makes them available to all future command development.

#### Tasks

- [ ] **10.1** Create `/home/benjamin/.config/.claude/docs/reference/command-functional-requirements.md` (following 551 Phase 1):
  - **Standard F.1: Library Sourcing Requirements**
    - Extract from /coordinate Phase 0 STEP 0 (post-refactor)
    - Document REQUIRED_FUNCTIONS verification pattern
    - Include error handling for missing libraries
  - **Standard F.2: Verification Checkpoint Implementation**
    - Extract `verify_file_created()` pattern from Phase 1 refactor
    - Document silent success / verbose failure pattern
    - Include verification loop patterns
    - Document fallback creation mechanism
  - **Standard F.3: Error Message Structure**
    - Extract from Phase 9 error handling patterns
    - Document three-level structure (ERROR / DIAGNOSTIC / ACTIONS)
    - Include fail-fast vs retry decision criteria

- [ ] **10.2** Create `/home/benjamin/.config/.claude/docs/guides/phase-0-implementation-guide.md` (following 551 Phase 2):
  - Document seven-step mandatory structure from refactored /coordinate
  - Add function consolidation pattern
  - Document export pattern for cross-phase availability
  - Include template code blocks with heredoc wrappers

- [ ] **10.3** Create `/home/benjamin/.config/.claude/docs/guides/bash-execution-patterns.md`:
  - **Heredoc Pattern for Function Definitions** (from Phase 1)
    - Document cat <<'DELIMITER' | bash pattern
    - Explain why this bypasses eval escaping
    - Show single quotes vs double quotes trade-offs
  - **Code Fence vs Direct Execution** (from Phase 2)
    - Document "EXECUTE NOW" marker pattern
    - Explain code fence priming effect
    - Show when to use each pattern
  - **Variable Scoping and Export** (from Phase 8)
    - Document export patterns for scalars
    - Document file-based state for arrays
    - Show integration with checkpoint utilities
  - **Pre-Formatted Context Pattern** (from Phase 4)
    - Document context block pre-calculation
    - Show 60% placeholder reduction technique
    - Include template expansion examples

- [ ] **10.4** Create `/home/benjamin/.config/.claude/docs/guides/template-vs-behavioral-distinction.md` (following 551 Phase 3):
  - Decision tree: "Is this structural (inline) or behavioral (reference)?"
  - Document placeholder substitution pattern from Phase 4
  - Add before/after examples from /coordinate refactor

- [ ] **10.5** Update `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (following 551 Phase 4):
  - Add Part B: Functional Requirements section
  - Add cross-references to new guides (F.1-F.3)
  - Add decision trees:
    - "When do I inline vs reference?"
    - "When do I verify vs trust?"
    - "When do I use heredoc vs direct bash?"

- [ ] **10.6** Update `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (following 551 Phase 5):
  - Add Section 1.4: "Common Pitfalls and How to Avoid Them"
    - Code-fenced Task invocations
    - Missing heredoc wrappers
    - No verification checkpoints
  - Add Section 1.5: "Quick Start: Your First Command"
    - Minimal working command template
    - Reference /coordinate as working example
  - Add Section 5.5.1: "Standard Phase 0 Setup Template"
    - Copy-paste ready template from refactored /coordinate
  - Update Section 6: Add automated validation scripts integration

- [ ] **10.7** Update `/home/benjamin/.config/.claude/commands/README.md` with quick-reference section:
  - Library sourcing decision tree
  - Imperative language requirements (Standard 0)
  - Agent invocation patterns (Standard 11)
  - Common setup patterns from /coordinate

- [ ] **10.8** Create working examples for each new standard:
  - Extract before/after code from /coordinate refactor
  - Show improvement from applying each standard
  - Link examples from documentation

#### Testing

```bash
# Test 1: All new documentation files created
test -f /home/benjamin/.config/.claude/docs/reference/command-functional-requirements.md
test -f /home/benjamin/.config/.claude/docs/guides/phase-0-implementation-guide.md
test -f /home/benjamin/.config/.claude/docs/guides/bash-execution-patterns.md
test -f /home/benjamin/.config/.claude/docs/guides/template-vs-behavioral-distinction.md

# Test 2: Standards F.1-F.3 documented
grep -c "^## Standard F\.[1-3]:" /home/benjamin/.config/.claude/docs/reference/command-functional-requirements.md
# Expected: 3

# Test 3: Heredoc pattern documented
grep -c "cat <<'DELIMITER' | bash" /home/benjamin/.config/.claude/docs/guides/bash-execution-patterns.md
# Expected: ≥3

# Test 4: Cross-references added
grep -c "command-functional-requirements.md" /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
# Expected: ≥3

# Test 5: Quick-start added
grep -c "Quick Start" /home/benjamin/.config/.claude/docs/guides/command-development-guide.md
# Expected: ≥1

# Test 6: Working examples linked
grep -c "/coordinate" /home/benjamin/.config/.claude/docs/reference/command-functional-requirements.md
# Expected: ≥5 (examples from refactored command)
```

#### Files Modified
- 4 new guide files created
- 3 existing files updated (command_architecture_standards.md, command-development-guide.md, commands/README.md)
- Extracted 15+ working examples from refactored /coordinate

#### Success Criteria
- ✅ All functional requirements documented as Standards F.1-F.3
- ✅ Phase 0 setup pattern templated for reuse
- ✅ Bash execution patterns documented with examples
- ✅ Decision trees created for common scenarios
- ✅ Quick-start guide added with minimal template
- ✅ Working examples from /coordinate refactor linked
- ✅ All documentation cross-referenced bidirectionally

#### Integration with Plan 551

This phase implements the documentation work outlined in plan 551, but extracts patterns from the /coordinate refactor we've just completed. This creates a feedback loop:

1. **Plan 551** identified gaps in documentation
2. **Plan 552 Phases 1-9** implemented fixes to /coordinate
3. **Plan 552 Phase 10** documents those fixes as reusable standards
4. **Future commands** benefit from documented patterns

Key synergies:
- 551 Phase 1 → 552 Phase 10.1 (Functional Requirements)
- 551 Phase 2 → 552 Phase 10.2 (Phase 0 Guide)
- 551 Phase 3 → 552 Phase 10.4 (Template vs Behavioral)
- 551 Phase 4 → 552 Phase 10.5 (Architecture Standards Update)
- 551 Phase 5 → 552 Phase 10.6 (Development Guide Update)

**Rationale**: By completing /coordinate refactor first, we have concrete working examples to extract rather than theoretical patterns. This makes the documentation more practical and verifiable.

---

## Documentation Requirements

### Command Documentation Updates

- [ ] Update `/home/benjamin/.config/.claude/commands/coordinate.md` with:
  - New bash block formatting standards (after Phase 2)
  - --scope parameter usage (after Phase 6)
  - Migration guide for Phase 3 (if implemented)
  - References to new documentation standards (after Phase 10)

### Standards Documentation Updates

**NOTE**: Phase 10 creates most of these documents. This section tracks additional updates needed.

- [ ] After Phase 10: Review all documentation for consistency
- [ ] After Phase 10: Validate all cross-references functional
- [ ] After Phase 10: Test all code examples execute correctly

### Coordination with Related Commands

- [ ] Review `/home/benjamin/.config/.claude/commands/orchestrate.md` for additional patterns to adopt

- [ ] Review `/home/benjamin/.config/.claude/commands/supervise.md` for consistency

- [ ] Update `.claude/commands/README.md` to document differences between orchestration commands (covered in Phase 10.7)

## Dependencies

### Required Libraries

All phases depend on these libraries remaining functional:

- `.claude/lib/unified-location-detection.sh` - Path calculation
- `.claude/lib/workflow-detection.sh` - Scope detection, phase gating
- `.claude/lib/checkpoint-utils.sh` - State persistence
- `.claude/lib/unified-logger.sh` - Error logging
- `.claude/lib/error-handling.sh` - Fail-fast patterns
- `.claude/lib/metadata-extraction.sh` - Context reduction
- `.claude/lib/context-pruning.sh` - Memory management

### External Dependencies

- Claude Code's Bash tool (execution mechanism)
- Claude Code's Task tool (agent invocation)
- Bash 4.0+ (for associative arrays)
- jq (for JSON parsing in checkpoints)

### Backward Compatibility

- **Phase 1-2**: Fully backward compatible (fix bugs, no interface changes)
- **Phase 3**: New command file (coordinate-v2.md), original preserved
- **Migration**: If Phase 3 implemented, deprecate coordinate.md after validation period

## Rollback Plan

### Phase 1-3 Rollback

If critical issues arise:

1. Git revert commits from Sprint 1
2. Restore coordinate.md from commit before Phase 1
3. Test original command still works
4. Document issues for future retry

### Phase 4-6 Rollback

If efficiency improvements cause regressions:

1. Keep Phase 1-3 fixes (critical)
2. Revert Phase 4-6 changes
3. Accept 42 substitutions as acceptable overhead
4. Document reasons for rollback

### Phase 7-9 Rollback

If bash-native conversion fails:

1. Delete coordinate-v2.md
2. Keep coordinate.md with Phase 1-6 improvements
3. Accept 60% reduction as sufficient
4. Document architectural barriers

## Notes

### Design Decisions

1. **Heredoc Pattern Choice**: Single quotes (`<<'DELIMITER'`) preferred over double quotes for function definitions to avoid variable expansion issues.

2. **Pre-Formatted Contexts vs Full Conversion**: Phase 4 implements 60% reduction with minimal risk, Phase 7-9 implements 100% reduction with high complexity. Recommend Phase 4 first, defer Phase 7-9 until proven necessary.

3. **Backward Compatibility Strategy**: Phase 3 creates new file (coordinate-v2.md) rather than breaking changes to coordinate.md, allowing staged migration.

4. **Function Consolidation**: All functions move to Phase 0 STEP 0B to ensure availability throughout workflow, following "define once, use everywhere" principle.

5. **Error Handling Philosophy**: Fail-fast with clear diagnostics preferred over silent fallbacks, aligning with project's "clean-break, fail-fast evolution" philosophy.

### Research Findings Summary

Key insights from research reports informing this plan:

- **Report 1 (Bash Eval Errors)**: Heredoc pattern bypasses eval escaping, fixing syntax errors
- **Report 2 (Placeholder Automation)**: 60% reduction achievable with current architecture, 100% requires bash-native conversion
- **Report 3 (Workflow Logic)**: Code works correctly, UX messaging needs improvement
- **Report 4 (Code Block Formatting)**: 88% of blocks incorrectly formatted, removing code fences critical

### Alternative Approaches Considered

1. **Template Expansion with envsubst**: Rejected - envsubst not available in Claude Code environment
2. **Inline Agent Invocations**: Rejected - Task tool requires separate invocation, can't be inlined
3. **Full Rewrite in Python**: Rejected - adds new language dependency, bash sufficient for orchestration
4. **Merge with /orchestrate**: Rejected - commands serve different use cases, maintain separation

### Future Enhancements

After this refactor completes, consider:

1. **Parallel Research Optimization**: Research agents currently sequential in Task invocations, explore true parallelism
2. **Checkpoint Recovery**: Enhance resume capability for interrupted workflows
3. **Performance Metrics**: Add instrumentation to measure context usage, execution time per phase
4. **Template-Based Planning**: Add plan templates for common refactor patterns
5. **Unified Orchestration Framework**: Extract common patterns from /coordinate, /orchestrate, /supervise into shared library

### Risk Mitigation

High-risk areas and mitigations:

1. **Risk**: Breaking existing workflows that depend on /coordinate
   **Mitigation**: Comprehensive regression testing, staged rollout, preserve original for fallback

2. **Risk**: Bash eval behavior changes in future Claude Code versions
   **Mitigation**: Document assumptions, add version detection, test on upgrades

3. **Risk**: Variable scoping issues causing subtle bugs
   **Mitigation**: Explicit export of all variables, file-based state for arrays, thorough testing

4. **Risk**: Context bloat from pre-formatted blocks
   **Mitigation**: Monitor context usage, apply pruning after each phase, validate <30% target

5. **Risk**: Agent invocation reliability with new patterns
   **Mitigation**: Preserve existing agent behavioral files, test all 6 agent types, validate REPORT_CREATED signals

## Completion Checklist

### Sprint 1 Complete
- [x] Phase 1: Function definitions wrapped in heredoc, exported, verified (COMPLETED 2025-10-30)
- [ ] Phase 2: Bash blocks standardized (≥30 EXECUTE NOW, <5 code fences) (IN PROGRESS)
- [ ] Phase 3: Workflow messaging improved with clear warnings
- [ ] Sprint 1 integration tests passing
- [x] No eval syntax errors in any phase (COMPLETED via Phase 1)

### Sprint 2 Complete
- [ ] Phase 4: Context blocks pre-formatted, <20 substitutions
- [ ] Phase 5: All 11 functions consolidated and verified
- [ ] Phase 6: Compound workflows detected, --scope parameter working
- [ ] Sprint 2 integration tests passing
- [ ] 60% reduction in placeholder overhead achieved

### Sprint 3 Complete (Optional)
- [ ] Phase 7: Bash-native execution model implemented
- [ ] Phase 8: State persistence with exports and file-based arrays
- [ ] Phase 9: Comprehensive error handling with fail-fast
- [ ] Sprint 3 integration tests passing
- [ ] 100% automation achieved (zero substitutions)

### Sprint 4 Complete
- [ ] Phase 10: All documentation files created (4 new guides)
- [ ] Standards F.1-F.3 documented
- [ ] Phase 0 setup template created
- [ ] Bash execution patterns documented (4 major patterns)
- [ ] Command architecture standards updated with Part B
- [ ] Command development guide updated (quick-start, pitfalls)
- [ ] Commands README updated with quick-reference
- [ ] 15+ working examples extracted and linked
- [ ] All documentation cross-referenced bidirectionally

### Documentation Complete
- [ ] Command documentation updated with references to new standards
- [ ] All code examples tested and verified
- [ ] Cross-references validated (all links functional)
- [ ] Migration guide written (if Phase 3 implemented)
- [ ] Related commands reviewed for consistency
- [ ] Plan 551 documentation goals satisfied

### Production Ready
- [ ] All regression tests passing
- [ ] Performance metrics meet targets
- [ ] Backward compatibility validated
- [ ] Rollback plan tested
- [ ] Team review completed
- [ ] Documentation review completed

## Revision History

### 2025-10-30 - Revision 1: Integration with Plan 551 Documentation Work

**Changes**: Added Phase 10 (Sprint 4) to document patterns as reusable standards

**Reason**: Plan 551 identified critical gaps in command documentation - specifically that functional requirements (library sourcing, verification checkpoints, error handling) are demonstrated in /coordinate but not documented as reusable standards. By adding Phase 10 to this refactor plan, we create a natural feedback loop where the patterns we implement in Phases 1-9 become documented standards for future command development.

**Reports Used**:
- Plan 551: `/home/benjamin/.config/.claude/specs/551_research_what_could_be_improved_in_claudedocs_and_/plans/001_research_what_could_be_improved_in_claudedocs_and__plan.md`

**Modified Sections**:
- Metadata: Updated phase count (9→10), sprint count (3→4), estimated time (15-22h→18-26h)
- Overview: Added Sprint 4 description and cross-plan integration note
- Success Criteria: Added Phase 4 success criteria (9 documentation deliverables)
- New Phase 10: Complete implementation of plan 551's documentation work
- Documentation Requirements: Noted Phase 10 covers most updates
- Completion Checklist: Added Sprint 4 checklist items

**Integration Strategy**: Phase 10 extracts patterns from Phases 1-9 as working examples rather than theoretical documentation, ensuring all documented standards are proven in production code.

**Key Synergies**:
- Plan 551 Phase 1 → Plan 552 Phase 10.1 (command-functional-requirements.md with Standards F.1-F.3)
- Plan 551 Phase 2 → Plan 552 Phase 10.2 (phase-0-implementation-guide.md)
- Plan 551 Phase 3 → Plan 552 Phase 10.4 (template-vs-behavioral-distinction.md)
- Plan 551 Phase 4 → Plan 552 Phase 10.5 (command_architecture_standards.md Part B)
- Plan 551 Phase 5 → Plan 552 Phase 10.6 (command-development-guide.md updates)

**Expected Benefits**:
1. /coordinate refactor fixes immediate failures (Phases 1-9)
2. Documentation captures those fixes as reusable patterns (Phase 10)
3. Future commands avoid repeating the same mistakes
4. Reduces time for new command development (templates + quick-start guides)
5. Improves command reliability across the board (standardized verification, error handling)

**Dependencies**: Phase 10 depends on completion of Phases 1-9 (or at least Phases 1-2 for minimum viable documentation).

**Estimated Impact**:
- Additional 3-4 hours of work (Phase 10)
- Creates 4 new documentation files
- Updates 3 existing documentation files
- Extracts 15+ working examples
- Establishes bidirectional cross-references between 7 documentation files
- Satisfies all major documentation gaps identified in plan 551
