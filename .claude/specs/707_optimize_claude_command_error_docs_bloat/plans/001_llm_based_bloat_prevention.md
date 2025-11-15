# Implementation Plan: LLM-Based Bloat Prevention for /optimize-claude

## Metadata
- **Date**: 2025-11-14
- **Feature**: LLM-based bloat prevention using Opus model agent for semantic analysis
- **Scope**: Fix library API contract violation, add bloat analyzer agent, update workflow integration
- **Research Report**: [Optimize-Claude Command Error and Documentation Bloat Prevention - Research Overview](/home/benjamin/.config/.claude/specs/707_optimize_claude_command_error_docs_bloat/reports/001_optimize_claude_command_error_docs_bloat/OVERVIEW.md)
- **Complexity**: Medium-High (5 phases, library fix + new agent + workflow refactoring)
- **Estimated Duration**: 8-12 hours
- **Testing Strategy**: Unit tests for library, integration tests for agent workflow, validation of bloat detection accuracy

## Objective

Fix the library API contract violation in unified-location-detection.sh and implement LLM-based bloat prevention using an Opus model agent for semantic documentation analysis. The new workflow adds a bloat analysis phase after initial research that studies findings from claude-md-analyzer and docs-structure-analyzer to create an explicit bloat analysis report passed to cleanup-plan-architect.

**Key Changes**:
1. Fix unified-location-detection.sh JSON output (add `project_root` and `specs_dir` fields)
2. Create docs-bloat-analyzer.md agent using Opus model for high-quality semantic analysis
3. Update optimize-claude.md workflow from 3-agent to 4-agent architecture
4. Modify cleanup-plan-architect to receive and integrate bloat analysis report
5. Update optimize-claude-command-guide.md documentation
6. **Explicitly exclude** .claude/docs/ directory cleanup (user task, separate from this implementation)

## Success Criteria

- [ ] unified-location-detection.sh exposes `project_root` and `specs_dir` in JSON output
- [ ] /optimize-claude command initializes without manual CLAUDE_PROJECT_DIR workaround
- [ ] docs-bloat-analyzer.md agent created with Opus model specification
- [ ] Bloat analyzer produces semantic analysis report identifying files >400 lines
- [ ] cleanup-plan-architect receives 3 reports (CLAUDE.md analysis, docs structure, bloat analysis)
- [ ] Workflow executes 4 agents successfully with mandatory verification checkpoints
- [ ] Test suite passes with bloat prevention validation
- [ ] Documentation updated with new workflow architecture
- [ ] No tasks related to cleaning up .claude/docs/ directory included in plan

---

## Phase 1: Library API Contract Fix (P0) [COMPLETED]

**Objective**: Fix unified-location-detection.sh to expose `project_root` and `specs_dir` in JSON output, resolving initialization failures for multiple commands.

**Complexity**: Low (2 field additions to existing JSON output)

**Tasks**:
- [x] Read unified-location-detection.sh lines 453-467 (current JSON output structure)
- [x] Add `"project_root": "$project_root"` field to JSON output after line 457
- [x] Add `"specs_dir": "$specs_root"` field to JSON output after project_root
- [x] Verify JSON structure maintains valid syntax (commas, quotes)
- [x] Test JSON parsing with jq to verify fields extractable

**Testing Strategy**:
```bash
# Test JSON output structure
TEST_JSON=$(perform_location_detection "test topic")
echo "$TEST_JSON" | jq -r '.project_root' # Should return absolute path
echo "$TEST_JSON" | jq -r '.specs_dir'    # Should return absolute path
echo "$TEST_JSON" | jq -r '.topic_path'   # Should still work (existing field)

# Test /optimize-claude initialization
cd /home/benjamin/.config/.claude/commands
bash -c "source ../lib/unified-location-detection.sh && perform_location_detection 'optimize CLAUDE.md structure'"
```

**Expected JSON Output**:
```json
{
  "topic_number": "707",
  "topic_name": "optimize_claude_md_structure",
  "topic_path": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure",
  "project_root": "/home/benjamin/.config",
  "specs_dir": "/home/benjamin/.config/.claude/specs",
  "artifact_paths": {
    "reports": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/reports",
    "plans": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/plans",
    "summaries": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/summaries",
    "debug": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/debug",
    "scripts": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/scripts",
    "outputs": "/home/benjamin/.config/.claude/specs/707_optimize_claude_md_structure/outputs"
  }
}
```

**Verification**:
- [ ] Verify all commands using `jq -r '.project_root'` still work
- [ ] Verify all commands using `jq -r '.specs_dir'` receive non-null values
- [ ] Test /optimize-claude command initialization from any subdirectory
- [ ] Confirm no regression in existing functionality

**Rollback Procedure**:
```bash
# If JSON parsing breaks
git checkout HEAD -- .claude/lib/unified-location-detection.sh
# Test existing commands still work
bash -c "cd .claude/commands && source ../lib/unified-location-detection.sh"
```

---

## Phase 2: Docs Bloat Analyzer Agent Creation (P0)

**Objective**: Create docs-bloat-analyzer.md agent behavioral file using Opus model for high-quality semantic documentation analysis.

**Complexity**: Medium (new agent, Opus model specification, semantic analysis logic)

**Agent Specifications**:
- **Model**: opus-4.5 (high-quality semantic understanding for bloat detection)
- **Fallback Model**: sonnet-4.5
- **Allowed Tools**: Read, Write, Grep, Glob, Bash
- **Input**: Two research reports (CLAUDE.md analysis, docs structure analysis)
- **Output**: Bloat analysis report with semantic size recommendations

**Tasks**:
- [ ] Create .claude/agents/docs-bloat-analyzer.md with YAML frontmatter
- [ ] Specify model: opus-4.5 with justification (semantic analysis, nuanced bloat detection)
- [ ] Define agent behavioral guidelines following create-file-first pattern
- [ ] Implement STEP 1: Input path verification (3 paths: CLAUDE_MD_REPORT, DOCS_REPORT, BLOAT_REPORT_PATH)
- [ ] Implement STEP 1.5: Lazy directory creation using ensure_artifact_directory()
- [ ] Implement STEP 2: Create bloat report file FIRST (before analysis)
- [ ] Implement STEP 3: Read both research reports and extract findings
- [ ] Implement STEP 4: Semantic bloat analysis logic
- [ ] Implement STEP 5: Verification checkpoint (file exists, >1000 bytes, no placeholders)
- [ ] Document bloat detection criteria (400 line threshold, semantic consolidation opportunities)

**STEP 4 Bloat Analysis Logic**:
```markdown
### Analysis Criteria

**File Size Thresholds** (from research findings):
- **Optimal**: <300 lines
- **Moderate**: 300-400 lines
- **Bloated**: >400 lines
- **Critical**: >800 lines (requires split)

**Semantic Analysis**:
1. Read CLAUDE.md analysis report to identify extracted sections
2. Read docs structure report to identify target integration files
3. For each extraction target:
   - Calculate current file size
   - Estimate extracted content size (from line ranges in CLAUDE.md report)
   - Project post-merge size
   - Flag if projected size >400 lines (bloated threshold)
4. Identify consolidation opportunities:
   - Files with >40% content overlap
   - Redundant navigation patterns
   - Duplicate architectural explanations
5. Recommend split operations for files >800 lines
6. Recommend merge operations only if combined size ≤400 lines

**Output Structure**:
- Bloated files (current state)
- Extraction risk analysis (projected bloat from CLAUDE.md extractions)
- Consolidation opportunities (overlap analysis)
- Split recommendations (oversized files)
- Size validation tasks for implementation plan
```

**Report Template**:
```markdown
# Documentation Bloat Analysis Report

## Metadata
- Date: [timestamp]
- Analyzer: docs-bloat-analyzer (Opus 4.5)
- Input Reports: [CLAUDE_MD_REPORT, DOCS_REPORT]

## Executive Summary
[2-3 sentence overview of bloat state]

## Current Bloat State

### Bloated Files (>400 lines)
| File Path | Current Size | Severity | Recommendation |
|-----------|--------------|----------|----------------|
| ... | ... | ... | ... |

### Critical Files (>800 lines)
[Files requiring immediate split]

## Extraction Risk Analysis

### High-Risk Extractions (projected bloat)
| Extraction | Source Section | Target File | Current Size | Projected Size | Risk Level |
|------------|----------------|-------------|--------------|----------------|------------|
| ... | ... | ... | ... | ... | HIGH/MEDIUM/LOW |

### Safe Extractions
[Extractions that won't cause bloat]

## Consolidation Opportunities

### High-Value Consolidations
[Files with >40% overlap, consolidation would reduce total size]

### Merge Analysis
[Specific merge recommendations with size projections]

## Split Recommendations

### Critical Splits (>800 lines)
[Detailed split plans for oversized files]

### Suggested Splits (600-800 lines)
[Optional splits for better organization]

## Size Validation Tasks

### Implementation Plan Requirements
- [ ] Add size validation tasks for each extraction
- [ ] Add bloat checks to verification phase
- [ ] Add rollback procedures if targets exceed 400 lines
- [ ] Include post-merge size verification

## Bloat Prevention Guidance

### For cleanup-plan-architect
[Specific instructions for plan generation to prevent bloat]

---

REPORT_CREATED: [absolute path to bloat report]
```

**Testing Strategy**:
```bash
# Create test scenario with mock reports
MOCK_CLAUDE_REPORT="/tmp/test_claude_analysis.md"
MOCK_DOCS_REPORT="/tmp/test_docs_structure.md"
BLOAT_REPORT="/tmp/test_bloat_analysis.md"

# Test agent invocation
# (Test in Phase 4 integration testing)
```

**Verification**:
- [ ] Agent file created at .claude/agents/docs-bloat-analyzer.md
- [ ] YAML frontmatter specifies opus-4.5 model
- [ ] Agent follows create-file-first pattern
- [ ] All 5 steps implemented with verification checkpoints
- [ ] Report template includes all required sections
- [ ] Size thresholds match research findings (400 line bloated threshold)

**Rollback Procedure**:
```bash
# If agent behavioral file has errors
rm .claude/agents/docs-bloat-analyzer.md
# Workflow remains 3-agent until fixed
```

---

## Phase 3: Workflow Integration (P1)

**Objective**: Update optimize-claude.md workflow from 3-agent to 4-agent architecture, adding bloat analyzer invocation between research and planning phases.

**Complexity**: Medium (workflow refactoring, path management, verification checkpoints)

**Current Workflow** (3 agents):
1. Parallel Research (2 agents): claude-md-analyzer, docs-structure-analyzer
2. Verification Checkpoint
3. Sequential Planning (1 agent): cleanup-plan-architect
4. Verification Checkpoint
5. Display Results

**New Workflow** (4 agents):
1. Parallel Research (2 agents): claude-md-analyzer, docs-structure-analyzer
2. Verification Checkpoint (2 reports)
3. **Sequential Bloat Analysis (1 agent): docs-bloat-analyzer**
4. **Verification Checkpoint (bloat report)**
5. Sequential Planning (1 agent): cleanup-plan-architect
6. Verification Checkpoint (plan)
7. Display Results

**Tasks**:

### Phase 3.1: Add Bloat Report Path Allocation
- [ ] Read optimize-claude.md lines 44-48 (current path definitions)
- [ ] Add `REPORT_PATH_3` definition after line 47
- [ ] Set `REPORT_PATH_3="${REPORTS_DIR}/003_bloat_analysis.md"`
- [ ] Verify path numbering consistent (001, 002, 003)

### Phase 3.2: Insert Bloat Analysis Phase
- [ ] Read optimize-claude.md Phase 3 (lines 114-138, current verification checkpoint)
- [ ] Rename current "Phase 3" to "Phase 3: Research Verification Checkpoint"
- [ ] Insert new "Phase 4: Bloat Analysis Invocation" after research verification
- [ ] Insert new "Phase 5: Bloat Analysis Verification Checkpoint" after bloat invocation
- [ ] Update subsequent phase numbers (old Phase 4 becomes Phase 6, etc.)

### Phase 3.3: Implement Bloat Analysis Invocation
- [ ] Create Phase 4 bash block with Task tool invocation
- [ ] Pass 3 absolute paths: CLAUDE_MD_REPORT ($REPORT_PATH_1), DOCS_REPORT ($REPORT_PATH_2), BLOAT_REPORT_PATH ($REPORT_PATH_3)
- [ ] Use behavioral injection pattern (read .claude/agents/docs-bloat-analyzer.md)
- [ ] Include completion signal expectation: REPORT_CREATED: [path]

**Phase 4 Template**:
```markdown
## Phase 4: Bloat Analysis Invocation

**EXECUTE NOW**: USE the Task tool to invoke bloat analyzer agent:

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation bloat"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-bloat-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${REPORT_PATH_3}

    **CRITICAL**: Create bloat analysis report at EXACT path provided above.

    **Task**:
    1. Read both research reports
    2. Perform semantic bloat analysis (400 line threshold)
    3. Identify extraction risks and consolidation opportunities
    4. Generate bloat prevention guidance for planning agent

    Expected Output:
    - Bloat analysis report created at BLOAT_REPORT_PATH
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}
```
```

### Phase 3.4: Implement Bloat Analysis Verification Checkpoint
- [ ] Create Phase 5 bash block with verification logic
- [ ] Check `REPORT_PATH_3` file exists
- [ ] Display error and exit 1 if bloat report missing
- [ ] Display success message with report path

**Phase 5 Template**:
```markdown
## Phase 5: Bloat Analysis Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying bloat analysis report..."

if [ ! -f "$REPORT_PATH_3" ]; then
  echo "ERROR: Agent 3 (docs-bloat-analyzer) failed to create report: $REPORT_PATH_3"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Bloat analysis: $REPORT_PATH_3"
echo ""
echo "Planning Stage: Generating optimization plan with bloat prevention..."
echo ""
```
```

### Phase 3.5: Update Planning Agent Invocation
- [ ] Read optimize-claude.md Phase 4 (lines 142-175, cleanup-plan-architect invocation)
- [ ] Update phase number to Phase 6
- [ ] Add BLOAT_REPORT_PATH to input paths
- [ ] Update task description to mention 3 reports (not 2)

**Updated Planning Invocation**:
```markdown
## Phase 6: Sequential Planning Invocation

**EXECUTE NOW**: USE the Task tool to invoke planning agent:

```
Task {
  subagent_type: "general-purpose"
  description: "Generate optimization plan"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/cleanup-plan-architect.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${REPORT_PATH_3}
    - PLAN_PATH: ${PLAN_PATH}
    - PROJECT_DIR: ${PROJECT_ROOT}

    **CRITICAL**: Create plan file at EXACT path provided above.

    **Task**:
    1. Read all three research reports (CLAUDE.md analysis, docs structure, bloat analysis)
    2. Synthesize findings with emphasis on bloat prevention
    3. Generate /implement-compatible plan with:
       - CLAUDE.md optimization phases
       - Documentation improvement phases (excluding .claude/docs/ cleanup)
       - Bloat prevention tasks (size validation, post-merge checks)
       - Verification and rollback procedures

    Expected Output:
    - Implementation plan file created at PLAN_PATH
    - Completion signal: PLAN_CREATED: [exact absolute path]
  "
}
```
```

### Phase 3.6: Update Display Results
- [ ] Read optimize-claude.md Phase 6 (lines 197-214, display results)
- [ ] Update phase number to Phase 8
- [ ] Add bloat analysis report to displayed research reports
- [ ] Update report count (2 → 3 reports)

**Updated Display Results**:
```markdown
## Phase 8: Display Results

```bash
# Display results
echo ""
echo "=== Optimization Plan Generated ==="
echo ""
echo "Research Reports:"
echo "  • CLAUDE.md analysis: $REPORT_PATH_1"
echo "  • Docs structure analysis: $REPORT_PATH_2"
echo "  • Bloat analysis: $REPORT_PATH_3"
echo ""
echo "Implementation Plan:"
echo "  • $PLAN_PATH"
echo ""
echo "Next Steps:"
echo "  Review the plan and run: /implement $PLAN_PATH"
echo ""
```
```

**Verification**:
- [ ] All phase numbers sequential (1, 2, 3, 4, 5, 6, 7, 8)
- [ ] 3 verification checkpoints (research, bloat, plan)
- [ ] All paths absolute and consistent
- [ ] Behavioral injection pattern used for all agents
- [ ] Completion signals expected from all agents

**Rollback Procedure**:
```bash
# If workflow breaks
git checkout HEAD -- .claude/commands/optimize-claude.md
# Revert to 3-agent workflow until fixes applied
```

---

## Phase 4: Planning Agent Update (P1)

**Objective**: Modify cleanup-plan-architect.md to receive and integrate bloat analysis report into plan generation.

**Complexity**: Low-Medium (add 3rd input path, update plan generation logic)

**Tasks**:

### Phase 4.1: Update Input Verification
- [ ] Read cleanup-plan-architect.md STEP 1 (lines 25-71)
- [ ] Add BLOAT_REPORT_PATH to input verification
- [ ] Add absolute path check for bloat report
- [ ] Add file existence check for bloat report
- [ ] Update echo statement to include bloat report path

**Updated STEP 1 Verification**:
```bash
# CRITICAL: Verify paths are absolute
if [[ ! "$CLAUDE_MD_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: CLAUDE_MD_REPORT_PATH is not absolute: $CLAUDE_MD_REPORT_PATH"
  exit 1
fi

if [[ ! "$DOCS_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: DOCS_REPORT_PATH is not absolute: $DOCS_REPORT_PATH"
  exit 1
fi

if [[ ! "$BLOAT_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: BLOAT_REPORT_PATH is not absolute: $BLOAT_REPORT_PATH"
  exit 1
fi

if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: PLAN_PATH is not absolute: $PLAN_PATH"
  exit 1
fi

if [[ ! -f "$CLAUDE_MD_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: CLAUDE.md analysis report not found: $CLAUDE_MD_REPORT_PATH"
  exit 1
fi

if [[ ! -f "$DOCS_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: Docs structure analysis report not found: $DOCS_REPORT_PATH"
  exit 1
fi

if [[ ! -f "$BLOAT_REPORT_PATH" ]]; then
  echo "CRITICAL ERROR: Bloat analysis report not found: $BLOAT_REPORT_PATH"
  exit 1
fi

echo "✓ VERIFIED: Absolute paths received"
echo "  CLAUDE_MD_REPORT: $CLAUDE_MD_REPORT_PATH"
echo "  DOCS_REPORT: $DOCS_REPORT_PATH"
echo "  BLOAT_REPORT: $BLOAT_REPORT_PATH"
echo "  PLAN_PATH: $PLAN_PATH"
echo "  PROJECT_DIR: $PROJECT_DIR"
```

### Phase 4.2: Update Report Reading Logic
- [ ] Read cleanup-plan-architect.md STEP 3 (report synthesis section)
- [ ] Add instruction to read bloat analysis report
- [ ] Update synthesis logic to integrate bloat findings
- [ ] Emphasize bloat prevention tasks in plan generation

**Updated Report Reading Instructions**:
```markdown
### STEP 3 - Read All Three Research Reports

**EXECUTE NOW - Read Reports**

Use Read tool to read all three research reports:

1. **CLAUDE.md Analysis Report** ($CLAUDE_MD_REPORT_PATH)
   - Extract bloated sections (>80 lines)
   - Identify extraction candidates
   - Note line ranges for extraction

2. **Docs Structure Analysis Report** ($DOCS_REPORT_PATH)
   - Extract directory organization
   - Identify integration points for extractions
   - Note existing file sizes

3. **Bloat Analysis Report** ($BLOAT_REPORT_PATH) - NEW
   - Extract bloated files (>400 lines)
   - Identify high-risk extractions (projected bloat)
   - Extract consolidation opportunities
   - Extract split recommendations
   - **CRITICAL**: Use size validation tasks from bloat report
```

### Phase 4.3: Update Plan Generation Guidelines
- [ ] Locate plan generation instructions in STEP 4
- [ ] Add bloat prevention emphasis
- [ ] Include size validation tasks in extraction phases
- [ ] Add bloat checks to verification phase
- [ ] Document rollback procedures for bloat-inducing merges

**Updated Plan Generation Guidelines**:
```markdown
### Plan Generation Requirements

**CRITICAL BLOAT PREVENTION**:
- Add size validation task for EVERY extraction operation
- Verify target file size <400 lines BEFORE merge
- Include rollback procedure if post-merge size >400 lines
- Add bloat check to final verification phase
- Flag high-risk extractions identified in bloat report
- Recommend splits for files >800 lines
- Only recommend merges if combined size ≤400 lines

**Phase Structure**:
1. CLAUDE.md Optimization Phase
   - Extract bloated sections
   - **Size validation for each extraction**
   - Verify target files remain <400 lines

2. Documentation Improvement Phase
   - Integration point updates
   - **Pre-merge size calculation**
   - Consolidation operations (only if safe)
   - **EXCLUDE any .claude/docs/ cleanup tasks**

3. Bloat Prevention Validation Phase - NEW
   - Verify no extracted files exceed 400 lines
   - Check for new bloat introduced by merges
   - Validate consolidations stayed within thresholds
   - Run size checks on all modified documentation

4. Verification and Rollback Phase
   - Link validation
   - Cross-reference checks
   - **Bloat rollback procedures**
```

### Phase 4.4: Update Completion Signal
- [ ] Locate STEP 5 verification
- [ ] Update echo statement to confirm 3 reports processed
- [ ] Maintain PLAN_CREATED completion signal format

**Verification**:
- [ ] Agent accepts 3 input reports
- [ ] All reports verified before plan generation
- [ ] Plan includes bloat prevention tasks
- [ ] Size validation tasks added to extraction phases
- [ ] Verification phase includes bloat checks
- [ ] Rollback procedures account for bloat scenarios

**Rollback Procedure**:
```bash
# If planning agent update breaks workflow
git checkout HEAD -- .claude/agents/cleanup-plan-architect.md
# Test with previous 2-report workflow
```

---

## Phase 5: Testing and Documentation (P2)

**Objective**: Comprehensive testing of 4-agent workflow and documentation updates.

**Complexity**: Medium (integration testing, documentation updates, test creation)

**Tasks**:

### Phase 5.1: Integration Testing
- [ ] Create test script: .claude/tests/test_optimize_claude_4_agent_workflow.sh
- [ ] Test library JSON output includes project_root and specs_dir
- [ ] Test /optimize-claude initialization from multiple directories
- [ ] Test docs-bloat-analyzer agent with mock reports
- [ ] Test complete 4-agent workflow end-to-end
- [ ] Verify all 3 verification checkpoints pass
- [ ] Verify 3 reports created (CLAUDE.md analysis, docs structure, bloat analysis)
- [ ] Verify plan created with bloat prevention tasks
- [ ] Test rollback procedures for each phase

**Test Script Template**:
```bash
#!/bin/bash
# test_optimize_claude_4_agent_workflow.sh

set -euo pipefail

TEST_DIR="/tmp/test_optimize_claude_workflow"
CLAUDE_PROJECT_DIR="/home/benjamin/.config"

echo "=== Testing /optimize-claude 4-Agent Workflow ==="
echo ""

# Test 1: Library JSON Output
echo "Test 1: Verify library JSON output includes project_root and specs_dir"
source "$CLAUDE_PROJECT_DIR/.claude/lib/unified-location-detection.sh"
TEST_JSON=$(perform_location_detection "test bloat workflow")
PROJECT_ROOT=$(echo "$TEST_JSON" | jq -r '.project_root')
SPECS_DIR=$(echo "$TEST_JSON" | jq -r '.specs_dir')

if [[ "$PROJECT_ROOT" == "null" ]]; then
  echo "FAIL: project_root missing from JSON output"
  exit 1
fi

if [[ "$SPECS_DIR" == "null" ]]; then
  echo "FAIL: specs_dir missing from JSON output"
  exit 1
fi

echo "✓ PASS: Library JSON output includes required fields"
echo ""

# Test 2: Agent Behavioral File Validation
echo "Test 2: Verify docs-bloat-analyzer.md exists and is valid"
BLOAT_AGENT="$CLAUDE_PROJECT_DIR/.claude/agents/docs-bloat-analyzer.md"

if [[ ! -f "$BLOAT_AGENT" ]]; then
  echo "FAIL: docs-bloat-analyzer.md not found"
  exit 1
fi

# Check YAML frontmatter
if ! grep -q "model: opus-4.5" "$BLOAT_AGENT"; then
  echo "FAIL: Bloat analyzer missing Opus model specification"
  exit 1
fi

echo "✓ PASS: Bloat analyzer agent exists with Opus model"
echo ""

# Test 3: Workflow Phase Count
echo "Test 3: Verify /optimize-claude has 8 phases (4-agent workflow)"
OPTIMIZE_CMD="$CLAUDE_PROJECT_DIR/.claude/commands/optimize-claude.md"
PHASE_COUNT=$(grep -c "^## Phase" "$OPTIMIZE_CMD")

if [[ "$PHASE_COUNT" -ne 8 ]]; then
  echo "FAIL: Expected 8 phases, found $PHASE_COUNT"
  exit 1
fi

echo "✓ PASS: Workflow has 8 phases"
echo ""

# Test 4: Verification Checkpoints
echo "Test 4: Verify 3 verification checkpoints exist"
CHECKPOINT_COUNT=$(grep -c "VERIFICATION CHECKPOINT (MANDATORY)" "$OPTIMIZE_CMD")

if [[ "$CHECKPOINT_COUNT" -ne 3 ]]; then
  echo "FAIL: Expected 3 verification checkpoints, found $CHECKPOINT_COUNT"
  exit 1
fi

echo "✓ PASS: 3 verification checkpoints present"
echo ""

# Test 5: Bloat Report Path Allocation
echo "Test 5: Verify bloat report path defined"
if ! grep -q "REPORT_PATH_3=" "$OPTIMIZE_CMD"; then
  echo "FAIL: REPORT_PATH_3 not defined in workflow"
  exit 1
fi

echo "✓ PASS: Bloat report path allocated"
echo ""

echo "=== All Tests Passed ==="
```

### Phase 5.2: Bloat Detection Accuracy Testing
- [ ] Create test documentation files with known sizes (300, 400, 500, 800 lines)
- [ ] Test bloat analyzer identifies >400 line files correctly
- [ ] Test extraction risk analysis with mock CLAUDE.md report
- [ ] Verify semantic consolidation detection accuracy
- [ ] Test split recommendations for >800 line files
- [ ] Validate size projection calculations

### Phase 5.3: Documentation Updates
- [ ] Read optimize-claude-command-guide.md current architecture section
- [ ] Update workflow description from 3-agent to 4-agent
- [ ] Document bloat analyzer agent role and responsibilities
- [ ] Add Phase 4 (Bloat Analysis) and Phase 5 (Bloat Verification) documentation
- [ ] Update agent descriptions table with docs-bloat-analyzer entry
- [ ] Document Opus model usage and justification
- [ ] Add bloat prevention methodology section
- [ ] Update troubleshooting guide with bloat analyzer failure scenarios
- [ ] Add examples of bloat analysis reports

**Documentation Sections to Update**:

1. **Architecture Overview** (update agent count):
```markdown
## Architecture

/optimize-claude uses a 4-agent workflow:
1. **claude-md-analyzer** (Haiku 4.5): Analyzes CLAUDE.md structure
2. **docs-structure-analyzer** (Haiku 4.5): Analyzes .claude/docs/ organization
3. **docs-bloat-analyzer** (Opus 4.5): Performs semantic bloat analysis
4. **cleanup-plan-architect** (Sonnet 4.5): Generates optimization plan

Workflow phases:
- Phase 1: Path allocation
- Phase 2: Parallel research (agents 1 & 2)
- Phase 3: Research verification
- Phase 4: Bloat analysis (agent 3)
- Phase 5: Bloat verification
- Phase 6: Planning (agent 4)
- Phase 7: Plan verification
- Phase 8: Display results
```

2. **Agent Reference Table**:
```markdown
| Agent | Model | Purpose | Input | Output |
|-------|-------|---------|-------|--------|
| claude-md-analyzer | Haiku 4.5 | CLAUDE.md structure analysis | CLAUDE.md file | Analysis report |
| docs-structure-analyzer | Haiku 4.5 | Docs organization analysis | .claude/docs/ dir | Structure report |
| docs-bloat-analyzer | Opus 4.5 | Semantic bloat detection | 2 research reports | Bloat analysis report |
| cleanup-plan-architect | Sonnet 4.5 | Plan generation | 3 reports | Implementation plan |
```

3. **Bloat Prevention Methodology** (new section):
```markdown
## Bloat Prevention Methodology

### LLM-Based Semantic Analysis

The docs-bloat-analyzer agent uses Opus 4.5 for high-quality semantic understanding:

**Why Opus?**
- Nuanced detection of content overlap (not just regex patterns)
- Semantic consolidation opportunities (understands topic relationships)
- Context-aware size recommendations (considers documentation purpose)
- Better judgment for split/merge decisions

**Bloat Thresholds**:
- **Optimal**: <300 lines
- **Moderate**: 300-400 lines
- **Bloated**: >400 lines (triggers warning)
- **Critical**: >800 lines (requires split)

**Analysis Process**:
1. Read CLAUDE.md analysis (bloated sections, extraction line ranges)
2. Read docs structure analysis (existing file sizes, integration points)
3. Calculate extraction risks (projected post-merge sizes)
4. Identify consolidation opportunities (>40% content overlap)
5. Recommend splits for critical files (>800 lines)
6. Generate size validation tasks for implementation plan

**Size Validation Tasks**:
- Pre-extraction size check (verify target file current size)
- Extraction size calculation (from line ranges)
- Post-merge size projection
- Bloat prevention condition: Projected size MUST be ≤400 lines
- Rollback procedure if merge exceeds threshold
```

### Phase 5.4: Test Suite Integration
- [ ] Add test_optimize_claude_4_agent_workflow.sh to .claude/tests/
- [ ] Update run_all_tests.sh to include new workflow tests
- [ ] Run complete test suite and verify no regressions
- [ ] Verify test coverage ≥95% (target from research findings)
- [ ] Document test execution instructions

### Phase 5.5: Validation Checklist
- [ ] Run link validation: .claude/scripts/validate-links-quick.sh
- [ ] Verify no broken references to updated files
- [ ] Test /optimize-claude command from 3 different directories
- [ ] Verify all 3 reports created with expected content
- [ ] Verify plan includes bloat prevention tasks
- [ ] Confirm no .claude/docs/ cleanup tasks in generated plans
- [ ] Test rollback procedures for each phase
- [ ] Verify documentation cross-references bidirectional

**Verification**:
- [ ] All integration tests pass
- [ ] Bloat detection accuracy ≥90% (test with known bloated files)
- [ ] Documentation updated with new workflow architecture
- [ ] Test suite coverage ≥95%
- [ ] No broken links after documentation updates
- [ ] Rollback procedures validated

**Rollback Procedure**:
```bash
# If tests fail
git checkout HEAD -- .claude/commands/optimize-claude.md
git checkout HEAD -- .claude/agents/cleanup-plan-architect.md
git checkout HEAD -- .claude/agents/docs-bloat-analyzer.md
git checkout HEAD -- .claude/lib/unified-location-detection.sh

# Revert to working state
bash .claude/tests/test_optimize_claude_agents.sh
```

---

## Rollback Strategy

### Phase-Specific Rollback

**Phase 1 (Library Fix)**:
```bash
git checkout HEAD -- .claude/lib/unified-location-detection.sh
# Impact: Commands revert to manual CLAUDE_PROJECT_DIR initialization
```

**Phase 2 (Bloat Analyzer Agent)**:
```bash
rm .claude/agents/docs-bloat-analyzer.md
# Impact: Workflow remains 3-agent until agent recreated
```

**Phase 3 (Workflow Integration)**:
```bash
git checkout HEAD -- .claude/commands/optimize-claude.md
# Impact: Workflow reverts to 3-agent (no bloat analysis)
```

**Phase 4 (Planning Agent Update)**:
```bash
git checkout HEAD -- .claude/agents/cleanup-plan-architect.md
# Impact: Planning agent expects 2 reports (not 3)
```

**Phase 5 (Testing and Documentation)**:
```bash
git checkout HEAD -- .claude/docs/guides/optimize-claude-command-guide.md
rm .claude/tests/test_optimize_claude_4_agent_workflow.sh
# Impact: Documentation shows old architecture, tests removed
```

### Complete Rollback

```bash
# Revert all changes
git checkout HEAD -- .claude/lib/unified-location-detection.sh
git checkout HEAD -- .claude/commands/optimize-claude.md
git checkout HEAD -- .claude/agents/cleanup-plan-architect.md
git checkout HEAD -- .claude/docs/guides/optimize-claude-command-guide.md
rm .claude/agents/docs-bloat-analyzer.md
rm .claude/tests/test_optimize_claude_4_agent_workflow.sh

# Verify clean state
bash .claude/tests/test_optimize_claude_agents.sh
```

---

## Risk Assessment

### High-Risk Areas
- **Library JSON Changes**: Multiple commands depend on unified-location-detection.sh
  - Mitigation: Add fields only (backwards compatible)
  - Validation: Test all commands using library
- **Workflow Refactoring**: Breaking 3-agent workflow could affect existing usage
  - Mitigation: Maintain verification checkpoints, fail-fast on errors
  - Validation: Integration tests before deployment

### Medium-Risk Areas
- **Opus Model Cost**: Bloat analyzer uses Opus (higher cost than Haiku)
  - Mitigation: Use only for bloat analysis (targeted, not exploratory)
  - Validation: Monitor token usage, consider Sonnet fallback
- **Agent Coordination**: 4-agent workflow more complex than 3-agent
  - Mitigation: Strict path management, verification checkpoints
  - Validation: End-to-end testing with mock scenarios

### Low-Risk Areas
- **Documentation Updates**: Changes to guide files don't affect execution
  - Mitigation: Link validation before commit
  - Validation: Cross-reference checks
- **Test Creation**: New tests don't affect production behavior
  - Mitigation: Test in isolation before integration
  - Validation: Run existing test suite first

---

## Performance Expectations

### Workflow Execution Time
- **3-Agent Workflow** (baseline): 8m 32s (from research findings)
- **4-Agent Workflow** (projected): 10-12 minutes
  - Additional agent: +2-3 minutes (Opus bloat analysis)
  - Trade-off: Higher quality bloat prevention vs execution time

### Context Usage
- **claude-md-analyzer**: 58.0k tokens (Haiku)
- **docs-structure-analyzer**: 67.7k tokens (Haiku)
- **docs-bloat-analyzer**: ~80-100k tokens (Opus, estimated)
- **cleanup-plan-architect**: 58.9k tokens (Sonnet)
- **Total**: ~265-285k tokens (vs 185k for 3-agent)

### Cost Comparison
- **3-Agent**: Mostly Haiku (low cost) + Sonnet (medium cost)
- **4-Agent**: Adds Opus (high cost but targeted analysis)
- **Justification**: Opus bloat analysis prevents creating 300-500+ line bloated files, saving maintenance cost long-term

---

## Success Metrics

### Technical Metrics
- [ ] Library fix: 0 initialization failures for all commands using unified-location-detection.sh
- [ ] Bloat detection: ≥90% accuracy identifying files >400 lines
- [ ] Workflow reliability: 100% agent file creation rate (4/4 agents)
- [ ] Test coverage: ≥95% (48-56 tests including bloat prevention tests)
- [ ] Execution time: <15 minutes for complete 4-agent workflow

### Quality Metrics
- [ ] Bloat prevention: 0 plans recommend creating files >400 lines without split
- [ ] Size validation: 100% of extraction tasks include size checks
- [ ] Rollback coverage: All phases have documented rollback procedures
- [ ] Documentation: All workflow changes documented in guide

### User Experience Metrics
- [ ] Initialization: /optimize-claude works from any directory without manual setup
- [ ] Clarity: Bloat analysis report clearly identifies risks and recommendations
- [ ] Actionability: Generated plans include specific size validation tasks
- [ ] Transparency: Each phase displays clear progress and verification results

---

## Future Enhancements

### Out of Scope for This Implementation
- **Cleanup of .claude/docs/ directory**: User will perform separately
- **Consolidation of orchestration documentation**: Separate planning task (18,663 lines consolidation opportunity from research)
- **README consolidation**: Separate task (2,126 → 1,200 lines reduction)
- **Oversized file splits**: Separate task (command-development-guide.md 3,980 lines)

### Potential Follow-Up Work
- **Iterative optimization**: Add post-implementation bloat check suggesting re-run
- **Metrics logging**: Track optimization patterns over time
- **Archive audit**: Review orchestration-patterns.md (2,522 lines) for unique content
- **Documentation maintenance guide**: Create process for ongoing consolidation

---

## Implementation Notes

### Key Design Decisions

1. **Why Opus for Bloat Analysis?**
   - Semantic understanding required for accurate consolidation detection
   - Nuanced judgment for split/merge recommendations
   - Better context awareness for documentation purpose
   - Cost justified by long-term maintenance savings (preventing bloated files)

2. **Why 4-Agent Sequential Workflow (Not 3-Agent)?**
   - Bloat analysis requires both research reports as input
   - Can't parallelize with research (depends on research output)
   - Can't merge with planning (different expertise, Opus vs Sonnet)
   - Clear separation of concerns (analysis vs planning)

3. **Why File Size Threshold at 400 Lines?**
   - Research findings: 132 files, average 36.8 KB per file (~672 lines)
   - Executable/documentation separation: Guides unlimited, but maintainability threshold exists
   - 400 lines = ~5 printed pages, practical for single-topic documentation
   - >800 lines = critical, requires split (too large for single reading)

4. **Why Exclude .claude/docs/ Cleanup?**
   - User explicitly requested separation of concerns
   - Cleanup requires manual review (44% consolidation opportunity high-risk)
   - This plan focuses on bloat PREVENTION, not remediation
   - Separate planning task needed for 10.6-13.7% reduction (9,410-12,132 lines)

### Standards Integration

**From CLAUDE.md**:
- Executable/Documentation Separation Pattern: Guides <400 lines (new bloat threshold)
- Fail-Fast Philosophy: Verification checkpoints catch missing files immediately
- Clean-Break Philosophy: No backward compatibility shims for library changes
- Hierarchical Agent Architecture: 4-agent coordination with metadata-only passing
- Testing Protocols: ≥95% coverage target, bloat prevention test group

**Agent Development Standards**:
- Create-file-first pattern: All agents create output BEFORE analysis
- Verification checkpoints: Minimum file size, no placeholders
- Behavioral injection: Task tool with behavioral file reference
- Model selection: Opus for high-quality semantic analysis (per model selection guide)

---

## Appendix: File Locations

### Modified Files
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 453-467)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (phases 3-8)
- `/home/benjamin/.config/.claude/agents/cleanup-plan-architect.md` (STEP 1, STEP 3, STEP 4)
- `/home/benjamin/.config/.claude/docs/guides/optimize-claude-command-guide.md` (architecture, agents, methodology)

### New Files
- `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md` (agent behavioral file)
- `/home/benjamin/.config/.claude/tests/test_optimize_claude_4_agent_workflow.sh` (integration tests)

### Reference Files
- Research Overview: `/home/benjamin/.config/.claude/specs/707_optimize_claude_command_error_docs_bloat/reports/001_optimize_claude_command_error_docs_bloat/OVERVIEW.md`
- Library API Reference: `/home/benjamin/.config/.claude/docs/reference/library-api.md`
- Agent Development Guide: `/home/benjamin/.config/.claude/docs/guides/agent-development-guide.md`
- Model Selection Guide: `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md`

---

## Phase Dependencies

```
Phase 1 (Library Fix)
    ↓
Phase 2 (Bloat Analyzer Agent)
    ↓
Phase 3 (Workflow Integration) ← depends on Phase 2 agent file
    ↓
Phase 4 (Planning Agent Update) ← depends on Phase 3 workflow
    ↓
Phase 5 (Testing & Documentation) ← depends on all previous phases
```

**Critical Path**: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 (sequential)

**Parallel Opportunities**: None (each phase depends on previous completion)

---

**Plan Status**: Ready for implementation via `/implement`

**Next Steps**: Review plan and execute: `/implement /home/benjamin/.config/.claude/specs/707_optimize_claude_command_error_docs_bloat/plans/001_llm_based_bloat_prevention.md`
