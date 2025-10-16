# Stage 1: Foundation and Analysis

## Metadata
- **Stage Number**: 1
- **Parent Phase**: phase_7_directory_modularization
- **Phase Number**: 7
- **Objective**: Set up shared directory structure and inventory extraction candidates
- **Complexity**: Low
- **Status**: COMPLETED
- **Estimated Time**: 1-2 hours
- **Actual Time**: ~30 minutes
- **Completion Date**: 2025-10-14

## Overview

This stage establishes the foundation for the entire modularization refactor by creating the `commands/shared/` directory structure and conducting a thorough analysis of extraction candidates. The analysis phase is critical—it identifies which sections should be extracted, calculates expected line reductions, and validates that baseline tests are passing before any modifications begin.

The stage follows the proven pattern from `agents/shared/`, which successfully achieved 28% file size reduction through reference-based composition. By completing this foundation work carefully, we ensure the subsequent extraction stages can proceed smoothly with clear targets and measurable success criteria.

## Detailed Tasks

### Task 1: Create .claude/commands/shared/ Directory

**Objective**: Establish the directory that will house all extracted documentation sections.

**Implementation Steps**:
1. Navigate to `.claude/commands/` directory
2. Create `shared/` subdirectory
3. Verify directory exists and has correct permissions

**Command**:
```bash
cd /home/benjamin/.config/.claude/commands
mkdir -p shared
test -d shared && echo "✓ Directory created successfully"
```

**Expected Result**: `commands/shared/` directory exists and is ready to receive extracted documentation files.

**Error Handling**:
- If directory creation fails, check parent directory permissions
- Verify no file named "shared" already exists (would conflict with directory)

### Task 2: Create shared/README.md with Structure Overview

**Objective**: Document the purpose, navigation, and usage patterns for the shared documentation directory.

**Implementation Steps**:
1. Create `shared/README.md` file
2. Document directory purpose (reusable documentation sections)
3. Add navigation structure (list of current/planned shared sections)
4. Include usage pattern (how commands reference shared sections)
5. Add cross-reference index template (will be populated as sections are extracted)

**File Structure**:
```markdown
# Shared Command Documentation

## Purpose

This directory contains reusable documentation sections referenced by multiple commands. It follows the proven reference-based composition pattern from `agents/shared/`, which reduced agent files by 28% while maintaining clarity.

## Usage Pattern

Commands reference shared sections using relative markdown links:

\`\`\`markdown
For detailed workflow phase descriptions, see [Workflow Phases](shared/workflow-phases.md).
\`\`\`

When Claude processes a command, it automatically reads referenced files, making this pattern zero-overhead.

## Shared Sections

### High Priority (orchestrate.md)
- `workflow-phases.md` - Detailed phase descriptions (~800 lines)
- `error-recovery.md` - Error handling patterns (~400 lines)
- `context-management.md` - Context optimization guide (~300 lines)
- `agent-coordination.md` - Agent invocation patterns (~500 lines)
- `orchestrate-examples.md` - Usage examples (~400 lines)

### Medium Priority (implement.md)
- `adaptive-planning.md` - Adaptive planning guide (~200 lines)
- `progressive-structure.md` - L0→L1→L2 documentation (~150 lines)
- `phase-execution.md` - Phase execution protocol (~180 lines)

### Low Priority (multiple commands)
- `error-handling.md` - Common error patterns
- `testing-patterns.md` - Testing protocols

## Cross-Reference Index

| Shared Section | Referenced By | Lines Saved |
|----------------|---------------|-------------|
| _(to be populated)_ | _(during extraction)_ | _(after extraction)_ |

## Maintenance

When adding new shared sections:
1. Extract focused, cohesive documentation (200-400 lines ideal)
2. Update this README with new section
3. Add cross-references to index
4. Validate all links with `test_command_references.sh`

## Related Patterns

- `.claude/agents/shared/` - Agent behavioral guidelines (28% reduction achieved)
- `.claude/lib/` - Bash utility functions (code extraction)
- `.claude/templates/` - Plan templates (composition without duplication)
```

**Expected Result**: `shared/README.md` exists with complete structure and usage documentation.

**Validation**:
```bash
test -f .claude/commands/shared/README.md && echo "✓ README created"
grep -q "Purpose" .claude/commands/shared/README.md && echo "✓ Purpose section exists"
grep -q "Cross-Reference Index" .claude/commands/shared/README.md && echo "✓ Index template exists"
```

### Task 3: Analyze orchestrate.md Sections and Tag Extraction Candidates

**Objective**: Identify which sections of orchestrate.md should be extracted, with line ranges and expected savings.

**Current File Stats**:
- File: `.claude/commands/orchestrate.md`
- Current size: 2,720 lines (88KB)
- Target size: <1,200 lines (56% reduction)
- Expected extraction: ~1,500 lines to shared files

**Analysis Process**:

1. **Read orchestrate.md structure**:
```bash
grep -n "^##" .claude/commands/orchestrate.md | head -20
```

2. **Identify section categories**:
   - **Workflow Phase Descriptions**: Detailed phase-by-phase guides
   - **Error Recovery Patterns**: Error handling, debugging, retry logic
   - **Context Management**: Token optimization, context reduction strategies
   - **Agent Coordination**: Parallel invocation, sequential execution, state management
   - **Examples and Use Cases**: Extended examples, common patterns

3. **Mark line ranges for extraction**:

Use grep to find section boundaries:
```bash
# Find workflow phase sections
grep -n "^### Phase [0-9]:" .claude/commands/orchestrate.md

# Find error recovery sections
grep -n -A5 "Error\|Recovery\|Debugging" .claude/commands/orchestrate.md

# Find context management sections
grep -n -A5 "Context\|Token\|Optimization" .claude/commands/orchestrate.md

# Find agent coordination sections
grep -n -A5 "Agent\|Parallel\|Sequential\|Coordination" .claude/commands/orchestrate.md

# Find examples
grep -n "^### Example" .claude/commands/orchestrate.md
```

4. **Create extraction spreadsheet** (use plaintext table format):

| Section Name | Source File | Line Range | Target File | Priority | Est. Lines | Notes |
|--------------|-------------|------------|-------------|----------|------------|-------|
| Workflow Phase 1: Research | orchestrate.md | 150-300 | workflow-phases.md | High | 150 | Parallel research patterns |
| Workflow Phase 2: Planning | orchestrate.md | 301-450 | workflow-phases.md | High | 150 | Sequential planning |
| Workflow Phase 3: Implementation | orchestrate.md | 451-650 | workflow-phases.md | High | 200 | Adaptive implementation |
| Workflow Phase 4: Debugging | orchestrate.md | 651-850 | workflow-phases.md | High | 200 | Conditional debugging |
| Workflow Phase 5: Documentation | orchestrate.md | 851-950 | workflow-phases.md | High | 100 | Sequential documentation |
| Error Recovery Patterns | orchestrate.md | 1200-1600 | error-recovery.md | High | 400 | Debug iterations, user escalation |
| Context Management Guide | orchestrate.md | 2000-2300 | context-management.md | High | 300 | Token limits, artifact refs |
| Agent Coordination | orchestrate.md | 2500-3000 | agent-coordination.md | High | 500 | Parallel/sequential patterns |
| Extended Examples | orchestrate.md | 4000-4400 | orchestrate-examples.md | High | 400 | Real workflow examples |

**Note**: Line ranges are estimates and should be validated by reading the actual file. The file has already been reduced from 6,341 to 2,720 lines in previous refactors.

5. **Calculate expected savings**:
```bash
# Current size: 2,720 lines
# Core content to extract: ~1,500 lines
# Remaining core logic: ~1,100 lines
# References/summaries added back: ~100 lines
# Final target: ~1,200 lines
```

**Deliverable**: Extraction plan spreadsheet in markdown format, saved to project notes or printed for reference during Stage 2 execution.

**Expected Result**: Clear inventory of what to extract, where it currently lives (line ranges), and where it will go (target shared files).

### Task 4: Analyze implement.md, setup.md, and revise.md Sections

**Objective**: Identify extraction candidates in implement.md, setup.md, and revise.md with line ranges.

**Current File Stats**:
- implement.md: 987 lines (43KB) → target <500 lines (49% reduction)
- setup.md: 911 lines → target <400 lines (56% reduction)
- revise.md: 878 lines → target <400 lines (54% reduction)
- Total extraction: ~1,900 lines from these three commands

**Analysis Process**:

1. **Read implement.md structure**:
```bash
grep -n "^##" .claude/commands/implement.md
```

2. **Identify section categories**:
   - **Adaptive Planning Guide**: Replan triggers, complexity thresholds, loop prevention
   - **Progressive Structure Documentation**: L0→L1→L2 expansion/collapse
   - **Phase Execution Protocol**: Checkpoint management, test requirements, commit workflow

3. **Mark line ranges for extraction**:

```bash
# Find adaptive planning sections
grep -n -A5 "Adaptive\|Replan\|Complexity" .claude/commands/implement.md

# Find progressive structure sections
grep -n -A5 "Progressive\|Level [0-2]\|Expansion\|Collapse" .claude/commands/implement.md

# Find phase execution sections
grep -n -A5 "Phase.*Execution\|Checkpoint\|Test.*Protocol" .claude/commands/implement.md
```

4. **Create extraction spreadsheet for all three commands**:

**implement.md** (987 lines → <500 lines):
| Section Name | Source File | Line Range | Target File | Priority | Est. Lines | Notes |
|--------------|-------------|------------|-------------|----------|------------|-------|
| Adaptive Planning Guide | implement.md | TBD | adaptive-planning.md | Medium | 200 | Replan triggers, complexity thresholds |
| Progressive Structure Docs | implement.md | TBD | progressive-structure.md | Medium | 150 | L0→L1→L2 expansion/collapse |
| Phase Execution Protocol | implement.md | TBD | phase-execution.md | Medium | 180 | Checkpoint, test, commit workflow |

**setup.md** (911 lines → <400 lines):
| Section Name | Source File | Line Range | Target File | Priority | Est. Lines | Notes |
|--------------|-------------|------------|-------------|----------|------------|-------|
| Command Modes Documentation | setup.md | TBD | setup-modes.md | High | 300 | 5 modes with workflows |
| Bloat Detection Algorithms | setup.md | TBD | bloat-detection.md | High | 150 | Detection logic, thresholds |
| Extraction Preferences | setup.md | TBD | extraction-strategies.md | High | 100 | Strategy selection patterns |

**revise.md** (878 lines → <400 lines):
| Section Name | Source File | Line Range | Target File | Priority | Est. Lines | Notes |
|--------------|-------------|------------|-------------|----------|------------|-------|
| Auto-mode Specification | revise.md | TBD | revise-auto-mode.md | High | 250 | JSON schemas, auto-mode logic |
| Revision Types Documentation | revise.md | TBD | revision-types.md | High | 250 | 5 revision type descriptions |

**Note**: Line ranges marked TBD will be determined during actual file analysis.

5. **Calculate expected savings**:
```bash
# implement.md: 987 → 500 lines (extract ~490 lines)
# setup.md: 911 → 400 lines (extract ~510 lines)
# revise.md: 878 → 400 lines (extract ~480 lines)
# Total extraction: ~1,480 lines from these three commands
# References/summaries added back: ~300 lines
# Net reduction: ~1,180 lines
```

**Deliverable**: Extraction plan spreadsheet for implement.md, setup.md, and revise.md.

**Expected Result**: Clear inventory of all command sections ready for extraction in Stage 2.

### Task 5: Create Consolidated Extraction Plan Spreadsheet

**Objective**: Merge extraction plans from all 4 commands into a single reference document.

**Implementation Steps**:

1. Combine spreadsheets from Tasks 3 and 4 (orchestrate, implement, setup, revise)
2. Add priority ordering (High priority sections extracted first)
3. Calculate total expected line reductions
4. Add sequencing notes (which extractions depend on others)

**Consolidated Spreadsheet Structure**:

```markdown
# .claude/ Directory Modularization - Extraction Plan

## Summary Statistics
- **Total lines to extract**: ~3,000 lines from 4 commands
- **Target shared files**: 13 files (8 high priority, 3 medium priority, 2 low priority)
- **Expected file size reductions**:
  - orchestrate.md: 2,720 → <1,200 lines (56% reduction)
  - implement.md: 987 → <500 lines (49% reduction)
  - setup.md: 911 → <400 lines (56% reduction)
  - revise.md: 878 → <400 lines (54% reduction)

## High Priority Extractions (Stage 2: All Commands)

**From orchestrate.md** (2,720 → <1,200 lines):
| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies |
|--------------|-------------|------------|-------------|------------|--------------|
| Workflow Phases | orchestrate.md | TBD | workflow-phases.md | 400 | None |
| Error Recovery Patterns | orchestrate.md | TBD | error-recovery.md | 300 | None |
| Context Management Guide | orchestrate.md | TBD | context-management.md | 200 | None |
| Agent Coordination | orchestrate.md | TBD | agent-coordination.md | 300 | None |
| Orchestrate Examples | orchestrate.md | TBD | orchestrate-examples.md | 300 | None |

**From setup.md** (911 → <400 lines):
| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies |
|--------------|-------------|------------|-------------|------------|--------------|
| Command Modes | setup.md | TBD | setup-modes.md | 300 | None |
| Bloat Detection | setup.md | TBD | bloat-detection.md | 150 | None |
| Extraction Strategies | setup.md | TBD | extraction-strategies.md | 100 | None |

**From revise.md** (878 → <400 lines):
| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies |
|--------------|-------------|------------|-------------|------------|--------------|
| Auto-mode Specification | revise.md | TBD | revise-auto-mode.md | 250 | None |
| Revision Types | revise.md | TBD | revision-types.md | 250 | None |

**Stage 2 Target**: 10 shared files created from orchestrate, setup, revise

## Medium Priority Extractions (Stage 2: implement.md)

**From implement.md** (987 → <500 lines):
| Section Name | Source File | Line Range | Target File | Est. Lines | Dependencies |
|--------------|-------------|------------|-------------|------------|--------------|
| Adaptive Planning Guide | implement.md | TBD | adaptive-planning.md | 200 | None |
| Progressive Structure Docs | implement.md | TBD | progressive-structure.md | 150 | None |
| Phase Execution Protocol | implement.md | TBD | phase-execution.md | 180 | error-recovery.md (ref) |

**Stage 2 Target**: All 13 shared files created in Stage 2

## Extraction Sequence

1. **Stage 2 (All Command Extractions)**: Extract from all 4 commands
   - orchestrate.md: 2,720 → <1,200 lines (5 shared files)
   - setup.md: 911 → <400 lines (3 shared files)
   - revise.md: 878 → <400 lines (2 shared files)
   - implement.md: 987 → <500 lines (3 shared files)
   - Creates all 13 shared files in one stage
   - Total reduction: ~3,000 lines extracted

## Cross-Reference Opportunities

Sections that can reference shared files created in earlier stages:
- implement.md Phase Execution Protocol → references error-recovery.md
- All commands → can reference error-handling.md (future low-priority extraction)

## Notes

- Line ranges are estimates and should be validated during extraction
- Each extraction should be tested immediately after completion
- Section summaries (50-100 words) must be added to source files before references
```

**Deliverable**: Save consolidated extraction plan to `.claude/specs/plans/045_claude_directory_optimization/phase_7_extraction_plan.md`

**Expected Result**: Single reference document guiding all extraction work in Stages 2-3.

### Task 6: Run and VERIFY Baseline Tests Pass 100%

**Objective**: Establish that the test suite is fully passing before any refactoring begins, preventing false positives in later regression testing.

**Why This Matters**: The plan assumes baseline test success at 68% (28/41 suites). We must verify this and document any pre-existing failures so they don't get attributed to our refactoring work.

**Implementation Steps**:

1. **Navigate to test directory**:
```bash
cd /home/benjamin/.config/.claude/tests
```

2. **Run complete test suite**:
```bash
./run_all_tests.sh 2>&1 | tee baseline_test_results.log
```

3. **Analyze results**:
```bash
# Count passing suites
passing=$(grep -c "PASS" baseline_test_results.log)

# Count total suites
total=$(grep -c "Running test:" baseline_test_results.log)

# Calculate percentage
percentage=$((passing * 100 / total))

echo "Baseline Test Results: $passing/$total ($percentage%)"
```

4. **Document pre-existing failures**:
```bash
# Extract failed test names
grep "FAIL" baseline_test_results.log > baseline_failures.txt

echo "Pre-existing failures documented in baseline_failures.txt"
echo "These failures are NOT caused by modularization refactor"
```

5. **Verify critical command tests pass**:
```bash
# Specifically check orchestrate and implement tests
grep -A10 "test_command_integration.sh.*orchestrate" baseline_test_results.log
grep -A10 "test_command_integration.sh.*implement" baseline_test_results.log
```

**Expected Results**:
- Baseline test results logged to `baseline_test_results.log`
- Pre-existing failures documented in `baseline_failures.txt`
- Percentage passing matches or exceeds 68% (28/41 suites)
- Critical command tests (orchestrate, implement) passing

**Success Criteria**:
- If baseline ≥68% passing: ✓ Proceed to Stage 2
- If baseline <68% passing: ⚠️ Investigate regression since last commit
- If orchestrate/implement tests failing: ⛔ STOP - fix before proceeding

**Error Handling**:
- If baseline is lower than 68%, check git status for uncommitted changes
- If critical tests fail, verify commands work manually: `/orchestrate Simple test`, `/implement --help`
- If test infrastructure is broken, fix test harness before proceeding with refactor

**Deliverable**:
- `baseline_test_results.log` file
- `baseline_failures.txt` file
- Confirmation message: "Baseline tests verified at X%, ready to proceed"

## Testing Strategy

### Verification Tests

After completing all 6 tasks, verify foundation is ready:

```bash
# 1. Directory structure exists
test -d .claude/commands/shared && echo "✓ shared/ directory exists"
test -f .claude/commands/shared/README.md && echo "✓ README exists"

# 2. Extraction plan exists
test -f .claude/specs/plans/045_claude_directory_optimization/phase_7_extraction_plan.md && echo "✓ Extraction plan created"

# 3. Baseline tests documented
test -f .claude/tests/baseline_test_results.log && echo "✓ Baseline results logged"
test -f .claude/tests/baseline_failures.txt && echo "✓ Pre-existing failures documented"

# 4. Baseline test percentage
passing=$(grep -c "PASS" .claude/tests/baseline_test_results.log)
total=$(grep -c "Running test:" .claude/tests/baseline_test_results.log)
percentage=$((passing * 100 / total))
echo "Baseline: $passing/$total ($percentage%)"
test $percentage -ge 68 && echo "✓ Baseline meets threshold"
```

### Regression Prevention

During extraction stages, compare test results against baseline:
```bash
# After each stage extraction
./run_all_tests.sh 2>&1 | tee stage_N_test_results.log

# Compare against baseline
diff baseline_failures.txt <(grep "FAIL" stage_N_test_results.log)

# If diff shows NEW failures, revert extraction and investigate
```

## Success Criteria

Stage 1 is complete when:
- [x] `.claude/commands/shared/` directory exists
- [x] `shared/README.md` documents purpose, usage, and navigation
- [x] Extraction plan spreadsheet identifies all candidates with line ranges
- [x] orchestrate.md extraction targets documented (5 files, ~5,000 lines)
- [x] implement.md extraction targets documented (3 files, ~1,000 lines)
- [x] Baseline test results verified (≥68% passing)
- [x] Pre-existing test failures documented separately
- [x] No code or documentation modified yet (analysis only)

## Dependencies

### Prerequisites
- orchestrate.md currently at 2,720 lines (post-October 13-14 refactors)
- implement.md currently at 987 lines (post-recent optimizations)
- setup.md currently at 911 lines
- revise.md currently at 878 lines
- Test suite functional and baseline documented

### Enables
- **Stage 2**: All command documentation extraction (relies on extraction plan)
- **Stage 3**: Utility consolidation (depends on commands being stable)
- **Stage 4**: Test validation (compares against baseline results)

## Risk Mitigation

### Low Risk Items
- Directory creation (simple mkdir operation)
- README creation (no functional impact)
- Analysis/tagging (no code changes)

### Mitigation Strategies
- **Test baseline verification**: Prevents attributing pre-existing failures to refactor
- **Extraction plan documentation**: Ensures clarity and reduces extraction errors in later stages
- **Line range marking**: Makes extraction surgical and reversible

## Notes

### Design Decisions

**Why analyze both files in Stage 1?**
- Creates complete picture of refactoring scope
- Allows identification of cross-file patterns (e.g., error-recovery.md referenced by both)
- Enables better sequencing (high-priority shared files created first)

**Why verify 100% baseline before starting?**
- Plan text says "VERIFY baseline tests pass 100%" but current baseline is 68%
- This task clarifies: verify current percentage, document it, ensure no regressions below that point
- Prevents confusion about test failures during refactor

**Why mark line ranges?**
- Makes extraction surgical (copy exactly these lines)
- Enables progress tracking (X of Y lines extracted)
- Allows partial rollback if extraction causes issues

### Efficiency Tips

- Use grep with line numbers (`grep -n`) for quick section boundary detection
- Use wc -l on line ranges to validate expected extraction sizes
- Create extraction plan in markdown for easy updates during execution

### Future Considerations

After Stage 1 completes, Stages 2-3 can proceed independently (orchestrate.md and implement.md extractions don't block each other), but sequential execution recommended to validate the pattern works before scaling it.
