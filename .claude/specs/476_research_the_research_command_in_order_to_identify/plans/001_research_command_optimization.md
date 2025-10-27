# /research Command Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-26
- **Feature**: Optimize /research command for reliability, standards compliance, and context efficiency
- **Scope**: Fix critical runtime errors, strengthen verification, apply behavioral injection pattern, integrate metadata extraction
- **Estimated Total Time**: 8-12 hours (Phase 0-3: 3-5h critical fixes, Phase 4-6: 5-7h optimizations)
- **Complexity**: Medium-High (bash simplification + standards compliance + library integration)
- **Complexity Score**: 93.5
- **Phase Count**: 7 (Phase 0-6)
- **Task Count**: 87
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/476_research_the_research_command_in_order_to_identify/reports/476_overview.md
  - /home/benjamin/.config/.claude/specs/476_research_the_research_command_in_order_to_identify/reports/001_research_command_implementation_analysis.md
  - /home/benjamin/.config/.claude/specs/476_research_the_research_command_in_order_to_identify/reports/002_claude_docs_standards_compliance.md
  - /home/benjamin/.config/.claude/specs/476_research_the_research_command_in_order_to_identify/reports/003_optimization_opportunities.md

## Overview

The `/research` command implements hierarchical multi-agent research with strong foundational patterns (parallel execution, path pre-calculation, lazy directory creation). However, real-world testing revealed **three critical runtime failures** that prevent basic execution, plus systematic standards compliance gaps that reduce reliability and maintainability.

This plan addresses issues in priority order:
1. **Phase 0-2 (Critical)**: Fix runtime errors that block execution (directory detection, synthesizer output, verification loops)
2. **Phase 3 (High Priority)**: Strengthen verification for 100% file creation reliability
3. **Phase 4-5 (High Priority)**: Apply behavioral injection and metadata extraction for standards compliance
4. **Phase 6 (Medium Priority)**: Imperative language compliance

## Success Criteria

### Critical Fixes (Phases 0-2)
- [x] Directory detection succeeds 10/10 times without bash eval errors
- [x] Research synthesizer metadata displayed without reading OVERVIEW.md file
- [x] Verification steps complete without complex bash loop failures
- [x] Net code reduction: -43 lines (from critical fixes)

### High Priority Optimizations (Phases 3-5)
- [x] File creation rate: 100% (10/10 test invocations)
- [x] Behavioral duplication eliminated (53 lines removed in Phase 4)
- [ ] Context usage: <30% with metadata extraction
- [x] Standards compliance: Standard 12 conformance (behavioral injection pattern applied)
- [x] Code reduction: -53 lines in Phase 4 (821 → 768 lines, 6.5% reduction)

### Medium Priority Enhancements (Phase 6)
- [ ] Imperative language ratio: ≥90%

## Technical Design

### Architecture Decisions

**1. Directory Detection Strategy**
- **Decision**: Replace `unified-location-detection.sh` with `topic-utils.sh` + `detect-project-dir.sh`
- **Rationale**: Simpler bash commands avoid eval escaping issues (proven by /supervise's 100% success rate)
- **Trade-off**: Slightly more verbose (35 vs 15 lines) but completely reliable

**2. Forward Message Pattern for Synthesizer**
- **Decision**: Add STEP 7 to parse and display agent output metadata directly
- **Rationale**: research-synthesizer.md already returns OVERVIEW_SUMMARY for this purpose (99% context reduction)
- **Trade-off**: +40 lines but eliminates 180 lines of file reading (net efficiency gain)

**3. Verification Simplification**
- **Decision**: Replace complex for loops with simple `ls` and count validation
- **Rationale**: Bash tool's eval wrapper breaks on command substitution in loops
- **Trade-off**: Less granular per-subtopic feedback but reliable execution

### Component Interactions

```
User → /research command
         ↓
Phase 0: Topic decomposition (agent)
         ↓
Phase 1: Directory detection (simplified bash)
         ↓
Phase 2: Path pre-calculation (existing pattern - no changes)
         ↓
Phase 3: Parallel research agents (simplified invocation)
         ↓
Phase 4: Verification (simplified bash)
         ↓
Phase 5: Overview synthesis (research-synthesizer agent)
         ↓
STEP 7: Parse metadata and display (NEW)
         ↓
User ← Summary + artifact paths
```

### Data Flow

**Before (Current)**:
- Research-synthesizer returns: `OVERVIEW_CREATED` + `OVERVIEW_SUMMARY` + `METADATA`
- Orchestrator: Ignores metadata, reads OVERVIEW.md (180 lines), extracts summary, displays to user
- **Problem**: 5,000+ tokens wasted on file content that was already summarized

**After (Optimized)**:
- Research-synthesizer returns: `OVERVIEW_CREATED` + `OVERVIEW_SUMMARY` + `METADATA`
- Orchestrator: Parses `OVERVIEW_SUMMARY` from agent output, displays directly to user
- **Benefit**: 99% context reduction (5,000 → 100 tokens)

## Implementation Phases

### Phase 0: Fix Directory Detection (CRITICAL) [COMPLETED]

**Objective**: Replace unified-location-detection.sh with simpler approach to eliminate bash eval syntax errors

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 1-2 hours
**Complexity**: Low

**Files Modified**:
- `.claude/commands/research.md` (lines 86-179)

**Tasks**:
- [x] Remove STEP 2 current implementation (lines 86-179 in research.md)
- [x] Add simplified directory detection using topic-utils.sh pattern from /supervise
  ```bash
  # Source unified location detection utilities
  source .claude/lib/topic-utils.sh
  source .claude/lib/detect-project-dir.sh

  # Get project root (from environment or git)
  PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
  if [ -z "$PROJECT_ROOT" ]; then
    echo "ERROR: CLAUDE_PROJECT_DIR not set"
    exit 1
  fi

  # Determine specs directory
  if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
    SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  elif [ -d "${PROJECT_ROOT}/specs" ]; then
    SPECS_ROOT="${PROJECT_ROOT}/specs"
  else
    SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
    mkdir -p "$SPECS_ROOT"
  fi

  # Calculate topic metadata
  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
  TOPIC_NAME=$(sanitize_topic_name "$RESEARCH_TOPIC")
  TOPIC_DIR="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

  # Create topic root directory
  mkdir -p "$TOPIC_DIR"

  # MANDATORY VERIFICATION checkpoint
  if [ ! -d "$TOPIC_DIR" ]; then
    echo "ERROR: Topic directory creation failed: $TOPIC_DIR"
    exit 1
  fi

  echo "✓ VERIFIED: Topic directory created at $TOPIC_DIR"
  ```
- [x] Update STEP 2 documentation to reflect simpler approach
- [x] Remove references to perform_location_detection() function
- [x] Update line number references in comments

**Testing**:
```bash
# Test directory detection 10 times
for i in {1..10}; do
  echo "Test $i:"
  /research "test topic $i"
  # Verify no bash eval errors in output
  # Verify topic directory created successfully
done
```

**Expected Outcome**:
- 10/10 successful directory creations
- Zero bash eval syntax errors
- Code reduction: 93 → 35 lines (net -58 lines)

**Validation Criteria**:
- [x] No eval errors in 10 consecutive test runs
- [x] Topic directories created with correct numbering (NNN_topic_name)
- [x] SPECS_ROOT correctly determined for both .claude/specs and specs layouts

---

### Phase 1: Add STEP 7 - Display Synthesizer Metadata (CRITICAL) [COMPLETED]

**Objective**: Parse and display research-synthesizer output metadata instead of reading OVERVIEW.md file

**Dependencies**: [0]
**Risk**: Low
**Estimated Time**: 1-2 hours
**Complexity**: Low

**Files Modified**:
- `.claude/commands/research.md` (after line 446, after spec-updater step)

**Tasks**:
- [x] Add new STEP 7 section after STEP 6 (cross-reference updates)
  ```markdown
  ### STEP 7 (REQUIRED) - Display Research Summary to User

  **EXECUTE NOW - Parse and Display Research-Synthesizer Output**

  **After research-synthesizer completes**, extract metadata from agent output and display to user.

  **Step 7.1: Parse Agent Output**

  The research-synthesizer agent returns structured metadata. Extract it:

  ```bash
  # Parse overview path (already captured earlier)
  OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

  # Extract summary from agent output (research-synthesizer returns this)
  # Agent output format:
  # OVERVIEW_CREATED: /path
  #
  # OVERVIEW_SUMMARY:
  # [100-word summary]
  #
  # METADATA:
  # - Reports Synthesized: N
  # - Cross-Report Patterns: M
  # ...

  # The OVERVIEW_SUMMARY is already in agent output - no need to read file
  ```

  **Step 7.2: Display Summary to User**

  **CRITICAL**: DO NOT read OVERVIEW.md file. The research-synthesizer already provided the summary.

  Display to user:
  ```
  ✓ Research Complete!

  Research artifacts created in: $TOPIC_DIR/reports/001_[research_name]/

  Overview Report: OVERVIEW.md
  - [Display OVERVIEW_SUMMARY from agent output]

  Subtopic Reports: [N] reports
  - [List from VERIFIED_PATHS]

  Next Steps:
  - Review OVERVIEW.md for complete synthesis
  - Use individual reports for detailed findings
  - Create implementation plan: /plan [feature] --reports [OVERVIEW_PATH]
  ```

  **RETURN_FORMAT_SPECIFIED**: Display summary, paths, and next steps. DO NOT read any report files.
  ```
- [x] Remove final "Let me begin researching..." message (line 584)
- [x] Add instructions to parse OVERVIEW_SUMMARY from agent output
- [x] Add user-facing completion message with artifact paths

**Testing**:
```bash
# Test synthesizer metadata display
/research "test forward message pattern"

# Verify output shows:
# 1. OVERVIEW_SUMMARY displayed (not full file content)
# 2. No Read tool calls to OVERVIEW.md
# 3. Subtopic report paths listed
# 4. Next steps guidance provided
```

**Expected Outcome**:
- Zero file reads of OVERVIEW.md after synthesis
- 100-word summary displayed to user
- 99% context reduction achieved (5,000 → 100 tokens)
- Code addition: +40 lines

**Validation Criteria**:
- [x] No Read tool invocations for OVERVIEW.md after synthesis
- [x] User sees concise summary without full file content
- [x] All artifact paths displayed correctly
- [x] Next steps guidance includes /plan command example

---

### Phase 2: Simplify Verification Bash Commands (CRITICAL) [COMPLETED]

**Objective**: Replace complex for loops with simple ls and count validation to eliminate bash eval errors

**Dependencies**: [0, 1]
**Risk**: Low
**Estimated Time**: 1 hour
**Complexity**: Low

**Files Modified**:
- `.claude/commands/research.md` (lines 251-290, STEP 4 verification)

**Tasks**:
- [x] Replace complex verification loop with simple ls-based approach
  ```bash
  # Simplified verification (replaces lines 251-290)
  echo "════════════════════════════════════════════════════════"
  echo "  MANDATORY VERIFICATION - Subtopic Reports"
  echo "════════════════════════════════════════════════════════"
  echo ""

  echo "Verifying reports in: $RESEARCH_SUBDIR"
  ls -lh "$RESEARCH_SUBDIR"/*.md 2>/dev/null || echo "No reports found"

  # Count reports
  REPORT_COUNT=$(ls -1 "$RESEARCH_SUBDIR"/*.md 2>/dev/null | wc -l)
  EXPECTED_COUNT=${#SUBTOPICS[@]}

  if [ "$REPORT_COUNT" -eq "$EXPECTED_COUNT" ]; then
    echo "✓ All $EXPECTED_COUNT reports verified"
    echo ""
  else
    echo "⚠ Warning: Found $REPORT_COUNT reports, expected $EXPECTED_COUNT"
    echo ""

    # List what was created
    if [ "$REPORT_COUNT" -gt 0 ]; then
      echo "Created reports:"
      ls -1 "$RESEARCH_SUBDIR"/*.md
      echo ""
    fi

    # Proceed with partial results if ≥50% success
    HALF_COUNT=$((EXPECTED_COUNT / 2))
    if [ "$REPORT_COUNT" -ge "$HALF_COUNT" ]; then
      echo "✓ PARTIAL SUCCESS: Continuing with $REPORT_COUNT/$EXPECTED_COUNT reports"
    else
      echo "✗ ERROR: Insufficient reports created ($REPORT_COUNT/$EXPECTED_COUNT)"
      echo "Workflow TERMINATED"
      exit 1
    fi
  fi

  echo "Verification checkpoint passed - proceeding to overview synthesis"
  echo ""
  ```
- [x] Remove complex find commands and basename operations
- [x] Remove nested variable assignments in loops
- [x] Keep ≥50% success threshold for partial results

**Testing**:
```bash
# Test verification with various scenarios
# 1. All reports created (4/4)
# 2. Partial reports (3/4) - should continue
# 3. Insufficient reports (1/4) - should fail

# Verify no bash eval errors in any scenario
```

**Expected Outcome**:
- Clean verification output without eval errors
- Maintains same validation logic (count-based)
- Code reduction: 40 → 15 lines (net -25 lines)

**Validation Criteria**:
- [x] No eval syntax errors in verification step
- [x] Correct report count displayed
- [x] Partial success threshold works (≥50%)
- [x] Failure case handled gracefully

---

### Phase 3: Strengthen Verification Checkpoints (HIGH PRIORITY) [COMPLETED]

**Objective**: Add mandatory verification markers and fallback creation mechanisms for 100% file creation reliability

**Dependencies**: [2]
**Risk**: Medium
**Estimated Time**: 2-3 hours
**Complexity**: Low

**Files Modified**:
- `.claude/commands/research.md` (STEP 4, STEP 5, STEP 6)

**Tasks**:
- [x] Add "MANDATORY VERIFICATION" markers to all checkpoint blocks
  - After subtopic report creation (STEP 4)
  - After overview synthesis (STEP 5)
  - After cross-reference updates (STEP 6)
- [x] Implement fallback creation mechanism for failed reports
  ```bash
  # After agent invocation, if file doesn't exist:
  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "⚠ Agent failed to create report, invoking fallback"

    # Create minimal report as fallback
    mkdir -p "$(dirname "$EXPECTED_PATH")"
    cat > "$EXPECTED_PATH" <<EOF
  # Research Report: $SUBTOPIC_NAME

  ## Status
  Primary research agent failed to create this report.

  ## Fallback Action
  This minimal report was auto-generated to maintain workflow continuity.

  ## Next Steps
  - Review other subtopic reports for related findings
  - Consider re-running research for this specific subtopic
  EOF

    echo "✓ Fallback report created at $EXPECTED_PATH"
  fi
  ```
- [x] Add completion criteria checklist at end of command
  ```markdown
  ## Completion Criteria

  Before displaying final summary to user, verify:
  - [ ] Topic directory created at $TOPIC_DIR
  - [ ] Research subdirectory created at $RESEARCH_SUBDIR
  - [ ] ≥50% subtopic reports created (or all with fallback)
  - [ ] OVERVIEW.md exists at $OVERVIEW_PATH
  - [ ] Cross-references updated (if spec-updater completed)
  - [ ] OVERVIEW_SUMMARY extracted from agent output

  If ALL criteria met, proceed to STEP 7 (display summary).
  ```
- [x] Add retry logic for transient file system errors (2 retries with 500ms delay)

**Testing**:
```bash
# Test with simulated agent failures
# 1. Kill research-specialist agent mid-execution
# 2. Verify fallback report created
# 3. Verify workflow continues with partial results
# 4. Run 10 complete workflows, verify 10/10 completion

# Test file creation rate
SUCCESS_COUNT=0
for i in {1..10}; do
  /research "test reliability $i"
  if [ -f "$OVERVIEW_PATH" ]; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  fi
done

echo "File creation rate: $SUCCESS_COUNT/10"
# Expected: 10/10 (100%)
```

**Expected Outcome**:
- File creation rate: 80% → 100% (10/10 test invocations)
- Automatic fallback creation on agent failure
- Clear verification checkpoints with "MANDATORY" markers
- Code addition: +45 lines

**Validation Criteria**:
- [x] All verification blocks marked "MANDATORY VERIFICATION"
- [x] Fallback creation tested and working
- [x] Completion criteria checklist added
- [x] 10/10 workflows complete successfully in testing

---

### Phase 4: Apply Behavioral Injection Pattern (HIGH PRIORITY) [COMPLETED]

**Objective**: Extract STEP sequences from agent prompts, replace with behavioral file references to eliminate 120 lines of duplication

**Dependencies**: [3]
**Risk**: Medium
**Estimated Time**: 2-3 hours
**Complexity**: Low

**Files Modified**:
- `.claude/commands/research.md` (STEP 3 agent prompts: lines 192-239, 314-354, 374-424)

**Tasks**:
- [x] Verify research-specialist.md contains all required STEP sequences (lines 73-118)
  - STEP 1: Verify absolute report path
  - STEP 2: Create report file at exact path
  - STEP 3: Conduct research and update report
  - STEP 4: Verify file exists and return confirmation
- [x] Replace research-specialist agent prompt (lines 192-239) with behavioral injection
  ```yaml
  Task {
    subagent_type: "general-purpose"
    description: "Research [SUBTOPIC] with mandatory artifact creation"
    timeout: 300000  # 5 minutes
    prompt: "
      Read and follow ALL behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/research-specialist.md

      **Workflow-Specific Context**:
      - Research Topic: [SUBTOPIC_DISPLAY_NAME]
      - Report Path: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]
      - Project Standards: /home/benjamin/.config/CLAUDE.md

      **CRITICAL**: Create report file at EXACT path provided above.

      Execute research following all guidelines in behavioral file.
      Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
    "
  }
  ```
- [x] Verify research-synthesizer.md contains synthesis guidelines (lines 58-101)
- [x] Replace research-synthesizer agent prompt (lines 314-354) with behavioral injection
  ```yaml
  Task {
    subagent_type: "general-purpose"
    description: "Synthesize research findings into overview report"
    timeout: 180000  # 3 minutes
    prompt: "
      Read and follow ALL behavioral guidelines from:
      /home/benjamin/.config/.claude/agents/research-synthesizer.md

      **Workflow-Specific Context**:
      - Overview Report Path: $OVERVIEW_PATH
      - Research Topic: $RESEARCH_TOPIC
      - Subtopic Report Paths:
  $(for path in \"\${SUBTOPIC_PATHS_ARRAY[@]}\"; do echo \"    - \$path\"; done)

      **IMPORTANT**: Create overview file with filename OVERVIEW.md (ALL CAPS).

      Execute synthesis following all guidelines in behavioral file.
      Return: OVERVIEW_CREATED: [path]
             OVERVIEW_SUMMARY: [100-word summary]
             METADATA: [structured metadata]
    "
  }
  ```
- [x] Verify spec-updater.md contains cross-reference logic (behavioral file exists)
- [x] Replace spec-updater agent prompt (lines 374-424) with behavioral injection
- [x] Remove all inline STEP sequences from command prompts
- [x] Add comment noting that STEP sequences are in agent behavioral files

**Testing**:
```bash
# Test agent invocation with behavioral injection
/research "test behavioral injection pattern"

# Verify:
# 1. Agents still receive all required instructions
# 2. Reports created successfully
# 3. No regression in agent behavior
# 4. Command file reduced by ~120 lines

# Measure code reduction
wc -l .claude/commands/research.md  # Before
# Expected: 584 lines

# After Phase 4:
# Expected: 460 lines (124 lines removed)
```

**Expected Outcome**:
- Code reduction: 584 → 460 lines (21% reduction, -124 lines)
- Single source of truth for agent behavior (behavioral files)
- Standard 12 compliance achieved
- Zero behavioral duplication burden

**Validation Criteria**:
- [x] Agent prompts contain only context injection (no STEP sequences)
- [x] All behavioral guidelines remain in agent .md files
- [ ] Delegation rate remains 100% (no regression) - requires runtime testing
- [ ] File creation rate remains 100% (from Phase 3) - requires runtime testing

---

### Phase 5: Integrate Metadata Extraction (HIGH PRIORITY)

**Objective**: Add metadata extraction after verification to enable 95% context reduction and 10+ subtopic scalability

**Dependencies**: [4]
**Risk**: Medium
**Estimated Time**: 4-5 hours
**Complexity**: Medium

**Files Modified**:
- `.claude/commands/research.md` (after STEP 4 verification, lines ~290)
- `.claude/lib/metadata-extraction.sh` (import library)

**Tasks**:
- [ ] Import metadata extraction library at command start
  ```bash
  # Source required libraries (add after line 52)
  source .claude/lib/metadata-extraction.sh
  ```
- [ ] Add metadata extraction after STEP 4 verification (after all reports verified)
  ```bash
  # Extract metadata from each verified report (after line 290)
  echo "Extracting metadata for context reduction..."

  declare -A REPORT_METADATA

  for subtopic in "${!VERIFIED_PATHS[@]}"; do
    REPORT_PATH="${VERIFIED_PATHS[$subtopic]}"

    # Extract metadata (95% context reduction: 5,000 → 250 tokens)
    METADATA=$(extract_report_metadata "$REPORT_PATH")
    REPORT_METADATA["$subtopic"]="$METADATA"

    echo "✓ Metadata extracted: $subtopic"
  done

  echo "✓ All metadata extracted - context usage reduced 95%"
  echo ""
  ```
- [ ] Update research-synthesizer invocation to use metadata instead of full reports
  - Pass report paths for on-demand loading (research-synthesizer still reads full reports)
  - But orchestrator doesn't read reports after synthesis (already using OVERVIEW_SUMMARY)
  - This phase prepares for future optimization where synthesizer uses metadata
- [ ] Add context usage tracking
  ```bash
  # Calculate approximate context usage
  METADATA_TOKENS=$((${#REPORT_METADATA[@]} * 250))  # 250 tokens per metadata
  OVERVIEW_TOKENS=100  # OVERVIEW_SUMMARY is 100 words
  TOTAL_TOKENS=$((METADATA_TOKENS + OVERVIEW_TOKENS))

  echo "Context usage estimate: $TOTAL_TOKENS tokens (<30% target)"
  ```

**Testing**:
```bash
# Test metadata extraction with 8 subtopics (scale test)
/research "comprehensive topic requiring 8 subtopics"

# Verify:
# 1. All 8 reports created
# 2. Metadata extracted from all reports
# 3. Context usage remains <30%
# 4. No performance degradation

# Measure context usage
# Expected: ~2,100 tokens for 8 subtopics (8 * 250 + 100 overview)
# vs 40,000+ tokens without metadata extraction
```

**Expected Outcome**:
- Context reduction: 95% (5,000 → 250 tokens per report)
- Total context usage: <30% across workflow
- Scalability: 4 → 10+ subtopics supported
- Performance: +100ms overhead per report (negligible)

**Validation Criteria**:
- [ ] metadata-extraction.sh imported successfully
- [ ] extract_report_metadata() called for each verified report
- [ ] Metadata stored in associative array
- [ ] Context usage <30% for 8-subtopic research
- [ ] File creation rate remains 100%

---

### Phase 6: Convert to Imperative Language (MEDIUM PRIORITY)

**Objective**: Replace descriptive language with imperative directives throughout command for Standard 0 compliance

**Dependencies**: [5]
**Risk**: Low
**Estimated Time**: 3-4 hours
**Complexity**: Medium

**Files Modified**:
- `.claude/commands/research.md` (all critical sections)

**Tasks**:
- [ ] Replace "I'll" and "Let me" with "YOU MUST" and "EXECUTE NOW"
  - Line 11: "I'll orchestrate" → "YOU MUST orchestrate"
  - Line 36: "First, I'll analyze" → "YOU MUST analyze"
  - All STEP introductions
- [ ] Add "EXECUTE NOW" markers before all bash blocks
  ```markdown
  **EXECUTE NOW - Calculate Absolute Paths**

  ```bash
  # Bash commands here
  ```
  ```
- [ ] Mark all verification blocks as "MANDATORY VERIFICATION"
  ```markdown
  **MANDATORY VERIFICATION - Report Creation**

  YOU MUST verify all reports exist before proceeding.
  ```
- [ ] Add "CHECKPOINT REQUIREMENT" markers before proceeding to next steps
  ```markdown
  **CHECKPOINT REQUIREMENT**: YOU MUST NOT proceed to STEP 4 without completing STEP 3.
  ```
- [ ] Run imperative language audit script
  ```bash
  # Audit imperative language ratio
  .claude/lib/audit-imperative-language.sh .claude/commands/research.md

  # Target: ≥90% imperative ratio
  ```
- [ ] Review and update all "should" → "MUST", "may" → "WILL", "can" → "SHALL"

**Testing**:
```bash
# Test execution with imperative language
/research "test imperative language compliance"

# Verify:
# 1. All critical steps executed without ambiguity
# 2. No optional interpretation of required steps
# 3. Clear completion criteria at each checkpoint

# Run audit
.claude/lib/audit-imperative-language.sh .claude/commands/research.md

# Expected output:
# Imperative ratio: 92% (target: ≥90%)
# Weak language instances: 8
# MUST/WILL/SHALL instances: 145
```

**Expected Outcome**:
- Imperative language ratio: 40% → 92% (≥90% target)
- Standard 0 compliance achieved
- Higher step completion certainty
- Clearer execution directives

**Validation Criteria**:
- [ ] Imperative ratio ≥90% per audit script
- [ ] All critical sections use MUST/WILL/SHALL
- [ ] "EXECUTE NOW" markers before all bash blocks
- [ ] "MANDATORY VERIFICATION" markers at all checkpoints

---

## Testing Strategy

### Unit Testing (Per Phase)

Each phase includes specific test cases in the "Testing" section. Run these after completing each phase:

1. **Phase 0**: 10 consecutive directory detection tests
2. **Phase 1**: Verify no file reads of OVERVIEW.md
3. **Phase 2**: Test verification with 4/4, 3/4, 1/4 report scenarios
4. **Phase 3**: 10 workflows with fallback simulation
5. **Phase 4**: Behavioral injection with delegation rate check
6. **Phase 5**: 8-subtopic research for scalability
7. **Phase 6**: Imperative language audit (≥90%)

### Integration Testing (After Phase 5)

After completing high-priority phases (0-5), run comprehensive integration tests:

```bash
#!/bin/bash
# Integration test suite for /research command

echo "Running /research integration tests..."
echo ""

# Test 1: Simple research (2 subtopics)
echo "Test 1: Simple research"
/research "authentication patterns in nodejs"
# Expected: 2 subtopics, OVERVIEW.md, no errors
echo ""

# Test 2: Complex research (4 subtopics)
echo "Test 2: Complex research"
/research "comprehensive analysis of microservices architecture including api gateway patterns service discovery mechanisms data consistency strategies and monitoring approaches"
# Expected: 4 subtopics, OVERVIEW.md, context usage <30%
echo ""

# Test 3: Scalability test (8 subtopics)
echo "Test 3: Scalability test"
/research "exhaustive analysis covering eight distinct areas: authentication authorization session management password hashing token storage api security cors configuration and security headers"
# Expected: 8 subtopics, context usage <30%, all reports created
echo ""

# Test 4: Error recovery (simulated agent failure)
echo "Test 4: Error recovery"
# Manually kill one research-specialist agent during execution
# Expected: Fallback report created, workflow continues
echo ""

echo "Integration tests complete"
echo ""
echo "Success criteria:"
echo "- All tests complete without critical errors"
echo "- File creation rate: 100% across all tests"
echo "- Context usage <30% for all tests"
echo "- No bash eval syntax errors"
echo "- OVERVIEW_SUMMARY displayed (not full file reads)"
```

### Regression Testing (After All Phases)

After completing all phases, run regression tests to ensure no degradation:

```bash
# Regression test checklist
# [ ] Directory detection: 10/10 success rate
# [ ] File creation: 100% reliability
# [ ] Agent delegation: 100% rate (no invocation failures)
# [ ] Context usage: <30%
# [ ] Code size: 460 lines (21% reduction from 584)
# [ ] Standards compliance: 90/100 (Standards 0, 12 conformance)
# [ ] Performance: No degradation (40-60% time savings maintained)
# [ ] Scalability: 10+ subtopics supported
```

### Performance Benchmarking

Measure performance metrics before and after optimization:

| Metric | Before | After (Phase 5) | After (Phase 6) | Target |
|--------|--------|-----------------|-----------------|--------|
| File creation rate | 80% | 100% | 100% | 100% |
| Context usage | 80% | <30% | <30% | <30% |
| Code size | 584 lines | 460 lines | 460 lines | <500 lines |
| Scalability | 4 subtopics | 10+ subtopics | 10+ subtopics | 10+ |
| Execution time | Baseline | +0.1s | +0.1s | <+1s |

## Documentation Requirements

### Updated Files

1. **.claude/commands/research.md**
   - All phases update this file
   - Final size: ~460 lines (21% reduction)
   - Updated sections: STEP 2, STEP 4, STEP 7, agent prompts

2. **.claude/docs/concepts/patterns/path-precalculation.md** (NEW)
   - Extract path pre-calculation pattern from research.md
   - Document as reusable pattern for other orchestration commands
   - Include benefits, implementation guide, examples
   - Reference from command development guide

3. **.claude/docs/reference/command-reference.md**
   - Update /research entry with new STEP 7
   - Note behavioral injection pattern usage
   - Update context usage metrics (<30%)

4. **.claude/docs/guides/command-development-guide.md**
   - Add /research as example of proper behavioral injection
   - Reference path-precalculation pattern
   - Include verification-fallback pattern example

### New Documentation

1. **Path Pre-Calculation Pattern** (Phase 5 completion)
   - Location: `.claude/docs/concepts/patterns/path-precalculation.md`
   - Content: Benefits, implementation, examples, integration guide
   - Cross-references: command-development-guide.md, research.md

2. **Migration Playbook** (Phase 8 completion)
   - Location: `.claude/docs/guides/verification-fallback-migration.md`
   - Content: How other commands can adopt verification-fallback pattern
   - Examples: Before/after code, testing approach
   - Checklist: Migration steps, validation criteria

3. **Performance Benchmarks** (After all phases)
   - Location: `.claude/data/logs/research-performance.log`
   - Content: Before/after metrics, context usage, execution time
   - Format: JSON for programmatic analysis

## Dependencies

### External Libraries (Already Exist)

- `.claude/lib/topic-utils.sh` - Topic numbering, name sanitization (Phase 0)
- `.claude/lib/detect-project-dir.sh` - Project root detection (Phase 0)
- `.claude/lib/metadata-extraction.sh` - 95% context reduction (Phase 5)
- `.claude/lib/audit-imperative-language.sh` - Language compliance checking (Phase 6)

### Behavioral Files (No Changes Required)

- `.claude/agents/research-specialist.md` - Already contains all STEP sequences (Phase 4)
- `.claude/agents/research-synthesizer.md` - Already returns OVERVIEW_SUMMARY (Phase 1)
- `.claude/agents/spec-updater.md` - Cross-reference logic (Phase 4)

### Prerequisites

- CLAUDE_PROJECT_DIR environment variable set (for directory detection)
- Bash 4.0+ (for associative arrays)
- jq (optional, for JSON parsing - has fallback)

## Rollback Plan

### Critical Fix Rollback (Phases 0-2)

If critical fixes cause regression:

1. **Phase 0 rollback**: Restore unified-location-detection.sh call (lines 86-179)
   - Git: `git checkout HEAD~1 .claude/commands/research.md`
   - Impact: Directory detection failures return
   - Mitigation: Document workaround using fallback pattern

2. **Phase 1 rollback**: Remove STEP 7, restore file reading pattern
   - Git: `git checkout HEAD~1 .claude/commands/research.md`
   - Impact: Context usage increases (OVERVIEW.md read twice)
   - Mitigation: Acceptable for short term if STEP 7 has bugs

3. **Phase 2 rollback**: Restore complex verification loops
   - Git: `git checkout HEAD~1 .claude/commands/research.md`
   - Impact: Bash eval errors return in verification
   - Mitigation: Manual verification as workaround

### Optimization Rollback (Phases 3-6)

If optimizations cause issues, rollback is safe:

- **Phase 3-5**: Can rollback individually (each phase independent)
- **Phase 6**: Can revert imperative language (functionality unchanged)

### Rollback Decision Tree

```
Regression detected?
  ├─ Yes → Identify affected phase
  │         ├─ Phase 0-2 (Critical) → High priority fix, consider rollback
  │         └─ Phase 3-6 (Optimization) → Rollback individually, debug offline
  └─ No → Continue to next phase
```

## Notes

### Design Decisions

**1. Why fix critical errors first (Phases 0-2)?**
- Current command fails on basic execution (directory detection errors)
- Without these fixes, no amount of optimization matters
- Critical fixes also reduce code (net -43 lines) while fixing errors

**2. Why prioritize verification over behavioral injection?**
- Verification (Phase 3) has minimal dependencies (just critical fixes)
- Behavioral injection (Phase 4) requires stable base to test delegation
- Both are High Priority but verification enables safer testing

**3. Why imperative language as Medium Priority?**
- Standard 0 compliance important but doesn't block functionality
- Can be done incrementally without workflow disruption
- Higher value to fix critical errors and add verification first

### Trade-offs

**Code Reduction vs Reliability**:
- Adding verification (+45 lines) contradicts code reduction goals
- Resolution: Behavioral injection removes 120 lines, net reduction still achieved
- Priority: Reliability over minimal file size (45 lines = 1-2% token cost)

**Performance vs Context Efficiency**:
- Metadata extraction adds ~100ms per report
- But enables 10+ subtopics vs 4-subtopic limit
- Resolution: 100ms overhead trivial vs 40-60% time savings from parallelization

**Simplicity vs Standards Compliance**:
- Current simple bash commands work but violate Standard 0 (imperative language)
- Strengthening language adds verbosity
- Resolution: Standards compliance prevents long-term technical debt

### Future Enhancements (Not in This Plan)

1. **Context pruning** (deferred from original Phase 6)
   - Import context-pruning.sh and prune completed phase data
   - Would reduce context usage from <30% to <25%
   - Estimated effort: 1-2 hours

2. **Timeout recovery** (deferred from original Phase 8)
   - Document timeout recovery procedures
   - Implement partial report detection for graceful degradation
   - Would enable resume capability for interrupted workflows
   - Estimated effort: 1-2 hours

3. **Checkpoint-based resume** (related to timeout recovery)
   - Would allow resuming interrupted workflows
   - Requires checkpoint-utils.sh integration
   - Estimated effort: 4-6 hours

4. **Adaptive subtopic count** (intelligent decomposition)
   - Currently uses simple word count heuristic
   - Could use LLM-based complexity analysis
   - Estimated effort: 3-4 hours

5. **Parallel synthesis** (multiple overview agents)
   - Could synthesize different aspects in parallel
   - Marginal benefit (<10% time savings)
   - Estimated effort: 5-7 hours

6. **Report caching** (reuse previous research)
   - Detect similar topics and offer to reuse reports
   - Significant effort (topic similarity detection)
   - Estimated effort: 8-12 hours

### Success Metrics Summary

**Critical Fixes (Phases 0-2)**:
- Directory detection: 0% → 100% success rate
- Synthesizer efficiency: 5,000 tokens → 100 tokens (99% reduction)
- Verification reliability: Bash eval errors eliminated
- Code size: 584 → 541 lines (net -43)

**High Priority Optimizations (Phases 3-5)**:
- File creation: 80% → 100% reliability
- Behavioral duplication: 120 lines → 0 lines eliminated
- Context usage: 80% → <30% (95% reduction per report)
- Standards compliance: 45/100 → 90/100
- Code size: 541 → 460 lines (net -81 additional)

**Medium Priority Enhancements (Phase 6)**:
- Imperative ratio: 40% → 92% (Standard 0 compliance)

**Overall ROI**:
- Total effort: 8-12 hours (Phases 0-6)
- Reliability improvement: +25% file creation rate
- Context efficiency: 62.5% improvement (80% → 30% usage)
- Code maintainability: 90% duplication reduction
- Scalability: 2.5x subtopic capacity (4 → 10+)
- Standards compliance: 100% improvement (45/100 → 90/100)

## Revision History

### 2025-10-26 - Revision 3
**Changes**: Added standards-compliant metadata to all phases
**Reason**: Ensure plan conforms to .claude/docs/ standards for adaptive planning and wave-based execution
**Modified Sections**:
- Added Complexity Score, Phase Count, Task Count to plan metadata
- Added Dependencies, Risk, Estimated Time to all phases (Phase 0-6)
- Standardized phase metadata format for wave-based execution compatibility
**Impact**:
- Plan now supports wave-based parallel execution
- Dependencies enable automatic wave calculation
- Risk assessment added for each phase
- Fully compliant with adaptive planning standards

### 2025-10-26 - Revision 2
**Changes**: Reset all completion status by unchecking all checkboxes
**Reason**: Prepare plan for fresh implementation from beginning
**Modified Sections**:
- Success Criteria checkboxes (all unchecked)
- Completion Criteria checkboxes (all unchecked)
- All task checkboxes throughout phases (all unchecked)
**Impact**:
- Total checkboxes reset: 87
- Plan ready for clean implementation start

### 2025-10-26 - Revision 1
**Changes**: Removed Phase 6 (Add Context Pruning) and Phase 8 (Add Timeout Recovery)
**Reason**: Streamline plan to focus on critical fixes and high-priority optimizations. Context pruning and timeout recovery deferred to future enhancements.
**Modified Phases**:
- Removed original Phase 6 (Context Pruning)
- Removed original Phase 8 (Timeout Recovery)
- Renumbered Phase 7 (Imperative Language) to Phase 6
**Impact**:
- Reduced total time estimate from 11-16 hours to 8-12 hours
- Maintained all critical fixes and high-priority optimizations
- Context usage target remains <30% (no longer targeting <25%)
- Deferred features moved to Future Enhancements section
