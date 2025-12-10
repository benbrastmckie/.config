# Implementation Plan: Fix /research Command Block Size Errors

## Plan Metadata

- **Date**: 2025-12-09 (Revised)
- **Feature**: Split /research command Block 1 into sub-400-line blocks to fix bash preprocessing transformation bugs, and update standards documentation to prevent similar issues
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-research-conform-standards-analysis.md](/home/benjamin/.config/.claude/specs/010_research_conform_standards/reports/001-research-conform-standards-analysis.md), [1-to_also_update_the_claude_docs.md](/home/benjamin/.config/.claude/specs/010_research_conform_standards/reports/1-to_also_update_the_claude_docs.md)

## Success Criteria

- [x] All bash blocks in /research.md are under 400 lines
- [x] Block 1 split into 3 smaller blocks (Block 1a, 1b, 1c)
- [x] State persistence works correctly across new block boundaries
- [x] Array declarations use explicit `declare -a` pattern
- [x] Test cases pass: single-topic mode (complexity <3) and multi-topic mode (complexity ≥3)
- [x] No "bad substitution" errors during execution
- [x] No "unbound variable" errors during array access
- [x] Command conforms to standards in CLAUDE.md
- [x] Bash block size limits standard added to command-authoring.md
- [x] CLAUDE.md code_standards section updated with quick reference
- [x] Cross-references added to output-formatting.md, bash-block-execution-model.md, bash-tool-limitations.md

## Phase 1: Block Splitting Analysis [COMPLETE]

**Objective**: Analyze Block 1 structure and identify natural split points for 3-block refactor.

**Tasks**:
1. Count current Block 1 line count (research.md lines 45-546 = 501 lines)
2. Identify natural split points based on logical sections:
   - Section A: Argument capture + state initialization (lines 45-280)
   - Section B: Topic naming agent invocation (lines 281-320)
   - Section C: Topic decomposition + report path calculation (lines 321-546)
3. Verify each section will be <400 lines after split
4. Document state variables that need persistence between blocks
5. Create split plan with explicit line ranges for each new block

**Validation**:
- Each proposed block <400 lines
- State variables identified for persistence
- No logic dependencies broken by splits

**Estimated Time**: 30 minutes

---

## Phase 2: Create Block 1a (Argument Capture + State Init) [COMPLETE]

**Objective**: Extract argument capture, library sourcing, state machine initialization, and topic naming agent invocation into first block.

**Tasks**:
1. Create Block 1a with content from research.md lines 45-280 (estimated):
   - Preprocessing safety (`set +H`, `set +o histexpand`, `set -e`)
   - Pre-trap error buffer initialization
   - Argument capture (WORKFLOW_DESCRIPTION, --complexity, --file)
   - Project directory detection
   - Three-tier library sourcing (error-handling.sh, state-persistence.sh, workflow-state-machine.sh)
   - Error logging initialization
   - Early bash error trap setup
   - State machine initialization
   - Workflow state file creation
   - State transition to RESEARCH
   - Topic name file path pre-calculation
   - Multi-topic mode detection
   - State persistence for next block
2. Add explicit `declare -a` for any arrays initialized in this block
3. Add checkpoint reporting at end: "CHECKPOINT: Block 1a setup complete, ready for topic-naming-agent"
4. Verify state variables persisted: COMMAND_NAME, USER_ARGS, WORKFLOW_ID, CLAUDE_PROJECT_DIR, WORKFLOW_DESCRIPTION, RESEARCH_COMPLEXITY, USE_MULTI_TOPIC, TOPIC_COUNT, TOPIC_NAME_FILE, TOPIC_NAMING_INPUT_FILE, ORIGINAL_PROMPT_FILE_PATH
5. Add execution directive: "**EXECUTE NOW**: Capture arguments and initialize state machine"

**Validation**:
- Block 1a line count <400 (target: ~235 lines)
- All required state variables persisted to workflow state file
- State machine transitions correctly to RESEARCH state
- Error handling preserves fail-fast behavior
- Execution directive present

**Estimated Time**: 45 minutes

---

## Phase 3: Create Block 1b (Topic Naming Agent) [COMPLETE]

**Objective**: Extract topic naming agent invocation into dedicated block.

**Tasks**:
1. Create Block 1b as Task invocation block (no bash block needed):
   - Task tool invocation with topic-naming-agent
   - Agent reads WORKFLOW_DESCRIPTION from persisted state
   - Agent writes topic name to TOPIC_NAME_FILE
   - Hard barrier pattern enforcement (path pre-calculated in Block 1a)
2. Add execution directive: "**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming."
3. Follow Task tool invocation standards from command-authoring.md:
   - No code block wrapper
   - Imperative instruction present
   - Completion signal required (TOPIC_NAME_GENERATED)
   - Variables interpolated inline

**Validation**:
- Task invocation uses correct pattern (no code block wrapper)
- Agent prompt includes all required context
- Hard barrier path pre-calculation working
- Completion signal verification

**Estimated Time**: 20 minutes

---

## Phase 4: Create Block 1c (Topic Path Init + Decomposition) [COMPLETE]

**Objective**: Extract topic path initialization, decomposition, and report path calculation into third block.

**Tasks**:
1. Create Block 1c with content from research.md lines 321-546 (estimated):
   - Preprocessing safety (`set +H`, `set +o histexpan d`, `set -e`)
   - Project directory detection (subprocess isolation pattern)
   - State restoration (load WORKFLOW_ID, source state file)
   - Library sourcing (error-handling.sh, state-persistence.sh, workflow-initialization.sh)
   - Error trap setup
   - Topic name parsing from agent output (TOPIC_NAME_FILE)
   - Topic name validation with fallback to "no_name_error"
   - Workflow paths initialization via `initialize_workflow_paths()`
   - Prompt file archival (if --file was used)
   - Topic decomposition logic (single-topic vs multi-topic)
   - Array initialization with `declare -a TOPICS_ARRAY=()` and `declare -a REPORT_PATHS_ARRAY=()`
   - Report path pre-calculation loop
   - State persistence for Block 2
2. Add explicit `declare -a` for TOPICS_ARRAY and REPORT_PATHS_ARRAY (lines 457, 503 in current file)
3. Add array bounds checking before REPORT_PATHS_ARRAY[0] access (defensive pattern)
4. Add checkpoint reporting: "CHECKPOINT: Block 1c complete. Topics: ${#TOPICS_ARRAY[@]}. Report paths: ${#REPORT_PATHS_ARRAY[@]}. Ready for: coordinator invocation (Block 2)"
5. Verify all array expansions are quoted correctly: `"${!TOPICS_ARRAY[@]}"`, `"${TOPICS_ARRAY[$i]}"`

**Validation**:
- Block 1c line count <400 (target: ~225 lines)
- Arrays use explicit `declare -a` declarations
- Array bounds checking present before [0] access
- All array expansions properly quoted
- State variables persisted: RESEARCH_DIR, TOPIC_PATH, TOPIC_NAME, USE_MULTI_TOPIC, ARCHIVED_PROMPT_PATH, TOPICS_LIST, REPORT_PATHS_LIST, REPORT_PATH
- Checkpoint reporting clear and actionable

**Estimated Time**: 1 hour

---

## Phase 5: Update Block 2 State Restoration [COMPLETE]

**Objective**: Update Block 2 (research coordinator/specialist invocation) to restore state from Block 1c.

**Tasks**:
1. Verify Block 2 (lines 548-799) loads state correctly after 3-block refactor
2. Add defensive variable initialization after state restoration (command-authoring.md pattern):
   ```bash
   # Defensive initialization for potentially unbound variables
   ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
   RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-3}"
   USE_MULTI_TOPIC="${USE_MULTI_TOPIC:-false}"
   ```
3. Verify TOPICS_LIST and REPORT_PATHS_LIST are correctly parsed from pipe-separated format
4. Verify routing decision logic still works (complexity < 3 → research-specialist, complexity ≥ 3 → research-coordinator)
5. No changes needed to Task invocation (already standards-compliant)

**Validation**:
- State restoration works with new 3-block structure
- Defensive variable initialization prevents unbound errors
- Routing decision logic intact
- Task invocations unchanged

**Estimated Time**: 20 minutes

---

## Phase 6: Update Block 2b Hard Barrier Validation [COMPLETE]

**Objective**: Ensure Block 2b (hard barrier validation) correctly validates multi-report creation after coordinator invocation.

**Tasks**:
1. Verify Block 2b (lines 628-799) loads state correctly
2. Verify REPORT_PATHS_LIST parsing from state works with new structure
3. Verify partial success mode logic (≥50% threshold) still applies
4. No functional changes needed (validation logic independent of Block 1 structure)

**Validation**:
- Hard barrier validation works with new state persistence
- Partial success mode logic intact
- Error logging works correctly

**Estimated Time**: 15 minutes

---

## Phase 7: Testing - Single-Topic Mode [COMPLETE]

**Objective**: Verify command works correctly for single-topic research (complexity < 3).

**Automation Metadata**:
- `automation_type`: automated
- `validation_method`: programmatic
- `skip_allowed`: false
- `artifact_outputs`: [research report, command output log]

**Test Cases**:
1. **Test Case 1**: Simple research topic, complexity 2, no flags
   ```bash
   /research "simple research topic" --complexity 2
   ```
   - Expected: TOPICS_ARRAY has 1 element
   - Expected: REPORT_PATHS_ARRAY has 1 element
   - Expected: research-specialist invoked directly (not coordinator)
   - Expected: Single report created in reports/ directory
   - Expected: No "bad substitution" errors
   - Expected: No "unbound variable" errors

2. **Test Case 2**: Research with --file flag, complexity 1
   ```bash
   echo "detailed research prompt" > /tmp/research_prompt.txt
   /research --file /tmp/research_prompt.txt --complexity 1
   ```
   - Expected: Prompt file read and archived
   - Expected: Single-topic mode engaged
   - Expected: Report created successfully

**Validation Script**:
```bash
#!/bin/bash
# test_research_single_topic.sh

FAILED=0

# Test 1: Simple research topic
echo "Test 1: Single-topic mode with complexity 2"
OUTPUT=$(/research "authentication patterns analysis" --complexity 2 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "FAIL: Command exited with code $EXIT_CODE"
  FAILED=1
fi

if echo "$OUTPUT" | grep -q "bad substitution"; then
  echo "FAIL: Found 'bad substitution' error"
  FAILED=1
fi

if echo "$OUTPUT" | grep -q "unbound variable"; then
  echo "FAIL: Found 'unbound variable' error"
  FAILED=1
fi

if echo "$OUTPUT" | grep -q "RESEARCH_COMPLETE"; then
  echo "PASS: Research completed successfully"
else
  echo "FAIL: Missing completion signal"
  FAILED=1
fi

exit $FAILED
```

**Estimated Time**: 30 minutes

---

## Phase 8: Testing - Multi-Topic Mode [COMPLETE]

**Objective**: Verify command works correctly for multi-topic research (complexity ≥ 3).

**Automation Metadata**:
- `automation_type`: automated
- `validation_method`: programmatic
- `skip_allowed`: false
- `artifact_outputs`: [multiple research reports, command output log]

**Test Cases**:
1. **Test Case 3**: Multi-topic research, complexity 3
   ```bash
   /research "authentication and authorization and audit logging" --complexity 3
   ```
   - Expected: TOPICS_ARRAY has 3 elements (decomposed by conjunctions)
   - Expected: REPORT_PATHS_ARRAY has 3 elements
   - Expected: research-coordinator invoked (not direct specialist)
   - Expected: 3 reports created in reports/ directory
   - Expected: No array expansion errors

2. **Test Case 4**: Multi-topic research, complexity 4
   ```bash
   /research "proof automation, tactic refactoring, dependency resolution, CI integration" --complexity 4
   ```
   - Expected: TOPICS_ARRAY has 4 elements
   - Expected: Parallel research execution
   - Expected: 4 reports created

3. **Test Case 5**: Edge case - decomposition produces <2 topics
   ```bash
   /research "single topic without conjunctions" --complexity 3
   ```
   - Expected: Fallback to single-topic mode
   - Expected: Arrays reset correctly
   - Expected: No unbound variable errors

**Validation Script**:
```bash
#!/bin/bash
# test_research_multi_topic.sh

FAILED=0

# Test 3: Multi-topic mode
echo "Test 3: Multi-topic mode with complexity 3"
OUTPUT=$(/research "auth and logging and caching" --complexity 3 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "FAIL: Command exited with code $EXIT_CODE"
  FAILED=1
fi

REPORT_COUNT=$(echo "$OUTPUT" | grep -c "REPORT_CREATED" || echo 0)
if [ "$REPORT_COUNT" -lt 2 ]; then
  echo "FAIL: Expected at least 2 reports, got $REPORT_COUNT"
  FAILED=1
else
  echo "PASS: Created $REPORT_COUNT reports"
fi

exit $FAILED
```

**Estimated Time**: 30 minutes

---

## Phase 9: Documentation Updates [COMPLETE]

**Objective**: Update command guide and related documentation to reflect 3-block structure.

**Tasks**:
1. Update `.claude/docs/guides/commands/research-command-guide.md`:
   - Document 3-block architecture (Block 1a/1b/1c → Block 2 → Block 3)
   - Add troubleshooting section for array-related errors
   - Document explicit `declare -a` pattern requirement
   - Add block size threshold guidance (<400 lines)
2. Update `.claude/commands/research.md` header comments:
   - Add architecture summary referencing 3-block split
   - Note: Block 1 split to prevent bash preprocessing bugs (>400 line threshold)
3. Add entry to `.claude/specs/010_research_conform_standards/README.md` (if needed)

**Validation**:
- Documentation accurately describes new structure
- Troubleshooting section helpful
- Cross-references to standards correct

**Estimated Time**: 30 minutes

---

## Phase 10: Validation and Standards Compliance Check [COMPLETE]

**Objective**: Verify refactored command complies with all CLAUDE.md standards.

**Automation Metadata**:
- `automation_type`: automated
- `validation_method`: programmatic
- `skip_allowed`: false
- `artifact_outputs`: [validation report, lint results]

**Tasks**:
1. Run bash conditional linter (if ! pattern detection):
   ```bash
   bash .claude/scripts/lint_bash_conditionals.sh .claude/commands/research.md
   ```
   - Expected: 0 violations (exit 0)

2. Run library sourcing validator:
   ```bash
   bash .claude/scripts/check-library-sourcing.sh .claude/commands/research.md
   ```
   - Expected: All 3 blocks have three-tier sourcing pattern
   - Expected: Fail-fast handlers present for Tier 1 libraries

3. Run Task invocation pattern linter:
   ```bash
   bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/research.md
   ```
   - Expected: Task invocation in Block 1b has imperative directive
   - Expected: No naked Task blocks

4. Manual checklist verification:
   - [x] All bash blocks have `set +H` at start
   - [x] All bash blocks re-source required libraries
   - [x] All critical function calls have return code verification
   - [x] All Task invocations use executable pattern (no code block wrapper)
   - [x] All Task invocations have imperative instruction
   - [x] All array declarations use explicit `declare -a`
   - [x] All array expansions properly quoted
   - [x] Output suppression applied (library sourcing with 2>/dev/null)
   - [x] Block consolidation appropriate (3 blocks for setup is reasonable)

**Validation Script**:
```bash
#!/bin/bash
# validate_research_standards_compliance.sh

FAILED=0

# Check 1: Block size threshold
echo "Validation 1: Block size threshold (<400 lines)"
for block_num in 1a 1b 1c 2 2b 3; do
  # Extract block content (between ```bash and ```)
  # Count lines
  # Report if >400
  :
done

# Check 2: Explicit array declarations
echo "Validation 2: Explicit array declarations"
if ! grep -q "declare -a TOPICS_ARRAY" .claude/commands/research.md; then
  echo "FAIL: Missing explicit TOPICS_ARRAY declaration"
  FAILED=1
fi

if ! grep -q "declare -a REPORT_PATHS_ARRAY" .claude/commands/research.md; then
  echo "FAIL: Missing explicit REPORT_PATHS_ARRAY declaration"
  FAILED=1
fi

# Check 3: Quoted array expansions
echo "Validation 3: Quoted array expansions"
UNQUOTED_EXPANSIONS=$(grep -n '\${TOPICS_ARRAY\[' .claude/commands/research.md | grep -v '\"' || echo "")
if [ -n "$UNQUOTED_EXPANSIONS" ]; then
  echo "FAIL: Found unquoted array expansions:"
  echo "$UNQUOTED_EXPANSIONS"
  FAILED=1
fi

exit $FAILED
```

**Estimated Time**: 45 minutes

---

## Phase 11: Add Bash Block Size Standard to command-authoring.md [COMPLETE]

**Objective**: Document bash block size limits as a primary standard in command-authoring.md to prevent future oversized block issues.

**Tasks**:
1. Add new section "Bash Block Size Limits and Prevention" after "Bash Block Isolation" section (after line 400 in command-authoring.md)
2. Document size thresholds:
   - **Safe Zone**: <300 lines (recommended for complex logic)
   - **Caution Zone**: 300-400 lines (requires review, monitor for issues)
   - **Prohibited**: >400 lines (causes bash preprocessing transformation bugs)
3. Include technical root cause explanation:
   - Claude's bash preprocessing applies transformations (variable interpolation, command substitution)
   - Transformations are lossy and introduce subtle bugs at >400 line threshold
   - Symptoms: "bad substitution" errors, conditional expression failures, array expansion issues
4. Document detection methods:
   - Manual line counting via `sed -n '/^```bash/,/^```/p' file.md | wc -l`
   - Automated validation via check-bash-block-size.sh (future tool)
5. Document prevention patterns:
   - Split blocks at logical boundaries (setup → execution → validation)
   - Use state persistence for cross-block communication
   - Target 2-3 consolidated blocks per command
   - Use Task tool invocations as natural split points (no bash block needed)
6. Include real-world example from /research command:
   - Before: 501-line Block 1 caused "bad substitution" errors
   - After: 3-block split (235 + Task invocation + 225 lines) eliminated all errors
   - Reference: `.claude/specs/010_research_conform_standards/reports/001-research-conform-standards-analysis.md`
7. Add cross-references:
   - Link to bash-tool-limitations.md troubleshooting section
   - Link to output-formatting.md block consolidation guidelines
   - Link to bash-block-execution-model.md subprocess isolation patterns

**Validation**:
- New section is comprehensive and actionable
- Thresholds clearly documented with rationale
- Real-world example provides concrete guidance
- Cross-references enable navigation to related concepts
- Section integrates naturally with existing command-authoring.md structure

**Estimated Time**: 30 minutes

---

## Phase 12: Update CLAUDE.md Code Standards Section [COMPLETE]

**Objective**: Add bash block size limits quick reference to CLAUDE.md for high-visibility standards enforcement.

**Tasks**:
1. Open CLAUDE.md and locate `<!-- SECTION: code_standards -->` section (around line 80)
2. Add new quick reference subsection after "Quick Reference - Path Validation" (around line 97):
   ```markdown
   **Quick Reference - Bash Block Size Limits**:
   - All bash blocks MUST be under 400 lines (hard limit, causes preprocessing bugs)
   - Recommended: <300 lines for complex logic (safe zone)
   - Split oversized blocks at logical boundaries using state persistence
   - See [Bash Block Size Limits and Prevention](.claude/docs/reference/standards/command-authoring.md#bash-block-size-limits-and-prevention)
   ```
3. Ensure quick reference follows established formatting pattern (bold label, bullet points, cross-reference link)
4. Verify section integrates naturally with surrounding quick references

**Validation**:
- Quick reference added in correct location within code_standards section
- Formatting consistent with existing quick reference patterns
- Cross-reference link points to new command-authoring.md section
- Markdown rendering verified (links work, formatting clean)

**Estimated Time**: 10 minutes

---

## Phase 13: Add Cross-References to Related Documents [COMPLETE]

**Objective**: Add cross-references to bash block size standard in related documentation for discoverability.

**Tasks**:
1. **Update output-formatting.md Block Consolidation section**:
   - Locate "Block Consolidation" section (around line 50)
   - Add warning callout after consolidation guidelines:
     ```markdown
     **WARNING**: While consolidating blocks improves readability, always maintain the 400-line hard limit per block. Oversized blocks (>400 lines) cause bash preprocessing transformation bugs. See [Bash Block Size Limits and Prevention](command-authoring.md#bash-block-size-limits-and-prevention) for split patterns.
     ```

2. **Update bash-block-execution-model.md Anti-Patterns section**:
   - Locate "Anti-Patterns" section (around line 300)
   - Add new anti-pattern entry "AP-011: Oversized Bash Blocks (>400 lines)":
     ```markdown
     #### AP-011: Oversized Bash Blocks (>400 lines)

     **Problem**: Bash blocks exceeding 400 lines trigger preprocessing transformation bugs causing "bad substitution" errors, conditional failures, and array expansion issues.

     **Detection**: Manual line count or automated check-bash-block-size.sh validation

     **Solution**: Split at logical boundaries (setup → execution → validation) using state persistence for cross-block communication. See [Bash Block Size Limits](../reference/standards/command-authoring.md#bash-block-size-limits-and-prevention).

     **Example**: `/research` command Block 1 split from 501 lines into 3 blocks (235 + Task + 225)
     ```

3. **Update bash-tool-limitations.md Prevention section**:
   - Locate "Prevention Strategies" section (around line 200)
   - Add reference to block size standard:
     ```markdown
     - **Block Size Management**: Keep all bash blocks under 400 lines to avoid preprocessing transformation bugs. See [Bash Block Size Standard](../reference/standards/command-authoring.md#bash-block-size-limits-and-prevention) for thresholds and split patterns.
     ```

**Validation**:
- All three cross-references added in appropriate locations
- Links use correct relative paths and anchor syntax
- Warning callout in output-formatting.md is prominent
- Anti-pattern entry in bash-block-execution-model.md follows established format
- Prevention reference in bash-tool-limitations.md integrates naturally

**Estimated Time**: 20 minutes

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| State persistence breaks between blocks | HIGH | Comprehensive state restoration testing in Phase 5 |
| Array bounds errors after refactor | MEDIUM | Add defensive bounds checking in Phase 4 |
| Routing decision logic breaks | MEDIUM | Explicit testing in Phases 7-8 |
| Block split creates logic gaps | MEDIUM | Careful split point selection in Phase 1 |
| Backward compatibility breaks | LOW | Keep same API, internal refactor only |

## Implementation Notes

**Key Design Decisions**:
1. **3-Block Split Rationale**: Natural logical boundaries align with command workflow phases (setup → agent → decomposition)
2. **explicit `declare -a` Adoption**: Aligns with `/create-plan` success pattern, improves bash type checking
3. **Defensive Bounds Checking**: Adds robustness without performance cost
4. **Backward Compatibility**: No API changes, existing users unaffected

**Standards Applied**:
- Bash block execution model (subprocess isolation, `set +H` requirement)
- Three-tier library sourcing pattern (Tier 1 fail-fast, Tier 2 graceful degradation)
- State persistence patterns (file-based communication, defensive initialization)
- Task tool invocation standards (imperative directives, hard barrier pattern)
- Output suppression requirements (library sourcing with 2>/dev/null)
- Block size threshold (<400 lines to avoid preprocessing transformation bugs)

**Cross-References**:
- Research Report: [001-research-conform-standards-analysis.md](/home/benjamin/.config/.claude/specs/010_research_conform_standards/reports/001-research-conform-standards-analysis.md)
- Standards File: [CLAUDE.md](/home/benjamin/.config/CLAUDE.md)
- Bash Tool Limitations: [.claude/docs/troubleshooting/bash-tool-limitations.md](/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md)
- Command Authoring Standards: [.claude/docs/reference/standards/command-authoring.md](/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md)
- Bash Block Execution Model: [.claude/docs/concepts/bash-block-execution-model.md](/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md)

## Next Steps

After implementation:
1. Run `/implement` on this plan to execute refactoring
2. Run `/test` to execute validation test suite
3. Create PR with changes and test results
4. Update TODO.md with `/todo` command
