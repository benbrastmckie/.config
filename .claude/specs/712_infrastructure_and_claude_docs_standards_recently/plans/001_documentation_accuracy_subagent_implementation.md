# Documentation Accuracy Subagent Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: Parallel Documentation Accuracy Evaluator Subagent
- **Scope**: Add Opus-tier documentation accuracy subagent to /optimize-claude workflow reading bloat recommendations and creating integrated documentation optimization plan
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 112.5
- **Research Reports**:
  - [Documentation Evaluation Framework](../reports/001_topic1.md)
  - [Bloat Analyzer Architecture](../reports/002_topic2.md)
  - [Opus Subagent Design Pattern](../reports/003_topic3.md)
  - [Integration Standards and Infrastructure](../reports/004_topic4.md)

## Revision History

### 2025-11-14 - Revision 2
**Changes**: Restored parallel execution of bloat and accuracy analyzers with independent analysis
**Reason**:
- Both bloat and accuracy analyzers should run in parallel for efficiency
- Both agents receive the same research report inputs (CLAUDE.md analysis + docs structure analysis)
- Each agent performs independent analysis without dependencies on the other
- All four reports (CLAUDE.md, docs structure, bloat analysis, accuracy analysis) passed to cleanup-plan-architect
- Planning agent creates systematic unified plan incorporating all findings for user review/implementation

**Modified Sections**:
- Architecture Overview (parallel execution of Phase 2 agents)
- Workflow Integration (parallel invocation pattern restored)
- Phase 3 tasks (parallel agent invocation)
- Planning integration (all four reports to planning agent)

### 2025-11-14 - Revision 1
**Changes**: Simplified bloat prevention strategy and workflow integration based on user feedback
**Reason**:
- Removed `/setup --validate` slash command execution (agents should not execute slash commands)
- Removed complex conditional merge logic and rollback triggers from bloat prevention strategy
- Updated accuracy analyzer to include Section 8 (Documentation Optimization Recommendations)
- Updated planning subagent to receive bloat recommendations + accuracy evaluation for unified implementation plan

**Modified Sections**:
- Report Structure (Section 8 changed from bash validation scripts to optimization recommendations)
- Bloat prevention strategy (simplified to focus on agent recommendations instead of automated rollback procedures)

## Overview

Add a fourth agent to the /optimize-claude workflow creating a documentation accuracy evaluator that runs in parallel with the bloat analyzer. This Opus-tier agent analyzes research reports to evaluate documentation accuracy, completeness, and consistency against .claude/docs/ standards, generating implementation-ready recommendations for the cleanup-plan-architect.

The new agent integrates with existing 3-agent architecture (claude-md-analyzer → docs-structure-analyzer → cleanup-plan-architect) by adding a parallel analysis stage: both bloat analyzer and accuracy analyzer receive the same research report inputs and perform independent analysis simultaneously. All four reports (CLAUDE.md analysis, docs structure analysis, bloat analysis, accuracy analysis) are then passed to the cleanup-plan-architect to create a systematic unified implementation plan for user review or implementation.

## Research Summary

Research findings informing this implementation:

**Documentation Quality Framework** (Report 001):
- Six core quality dimensions: accuracy, completeness, consistency, timeliness, usability, clarity
- Current quantitative metrics: section line count, bloat ratio, link validity, test coverage
- Missing qualitative metrics: readability scores (Flesch 70-80), error rate, completeness rate
- Verification infrastructure: verify_file_created() achieving 100% file creation, link validation scripts
- Writing standards: timeless documentation, banned temporal patterns, imperative language enforcement

**Bloat Analyzer Architecture** (Report 002):
- 4-agent pipeline: claude-md-analyzer + docs-structure-analyzer → bloat-analyzer → cleanup-plan-architect
- Opus 4.5 model for semantic understanding (overlap detection, consolidation opportunities)
- 6-step execution process: verify inputs → ensure directory → create file FIRST → read reports → analyze → verify
- Report structure: 9 sections including executive summary, bloat state, extraction risks, validation tasks
- Integration via report paths passed to planning agent with metadata extraction (95% context reduction)

**Opus Subagent Design Pattern** (Report 003):
- Behavioral injection: commands pre-calculate paths, agents create artifacts via Write tool
- Opus reserved for architectural decisions: plan-architect (42 criteria), debug-specialist (38 criteria)
- Completion criteria framework: 28-42 explicit requirements for 100% file creation rate
- Model selection: Opus for semantic analysis (nuanced overlap, quality assessment, context-aware recommendations)
- Shared protocols: progress streaming (PROGRESS: message), error handling (transient/permanent/fatal)

**Integration Standards** (Report 004):
- Behavioral injection pattern: Task tool + "Read and follow: .claude/agents/[name].md"
- Library utilities: metadata extraction (95-99% context reduction), verification helpers, artifact creation
- Architectural compliance: Standard 0 (execution enforcement), Standard 11 (imperative invocation), Standard 15 (sourcing order)
- Documentation patterns: executable/documentation separation (<400 lines behavioral, unlimited guide)
- Verification requirements: file existence, size validation, completion signal (REPORT_CREATED: path)

Recommended approach: Create docs-accuracy-analyzer.md agent following bloat analyzer pattern with semantic evaluation of documentation quality dimensions, integrate as parallel fourth agent in modified /optimize-claude workflow.

## Success Criteria

- [ ] docs-accuracy-analyzer.md agent created with Opus 4.5 model and semantic accuracy evaluation
- [ ] Agent follows 6-step execution process (verify → ensure dir → create FIRST → read → analyze → verify)
- [ ] Report structure includes 9 sections with implementation-ready recommendations
- [ ] /optimize-claude workflow modified to invoke accuracy analyzer parallel with bloat analyzer
- [ ] Both reports (bloat + accuracy) passed to cleanup-plan-architect for integrated planning
- [ ] Verification checkpoints enforce 100% file creation for accuracy report
- [ ] Metadata extraction achieves 95%+ context reduction for accuracy report
- [ ] All architectural standards compliance validated (Standards 0, 11, 15, 16)
- [ ] Documentation guide created following executable/documentation separation pattern
- [ ] Comprehensive test suite validates agent delegation and report creation

## Technical Design

### Architecture Overview

```
/optimize-claude Workflow (3 Agents → 5 Agents):

Phase 1: Parallel Research (2 agents)
  ├─ Agent 1: claude-md-analyzer
  │   Output: CLAUDE.md analysis report
  └─ Agent 2: docs-structure-analyzer
      Output: .claude/docs/ structure report

Phase 2: Parallel Analysis (2 agents) [NEW]
  ├─ Agent 3: docs-bloat-analyzer
  │   Input: Both research reports (CLAUDE.md analysis + docs structure)
  │   Output: Bloat analysis report with recommendations
  └─ Agent 4: docs-accuracy-analyzer [NEW AGENT]
      Input: Both research reports (CLAUDE.md analysis + docs structure)
      Output: Accuracy analysis report with quality recommendations

Phase 3: Planning (1 agent)
  └─ Agent 5: cleanup-plan-architect
      Input: All four reports (CLAUDE.md, docs structure, bloat, accuracy)
      Output: Systematic implementation plan incorporating all findings
```

### Component Specifications

**Agent Behavioral File**: .claude/agents/docs-accuracy-analyzer.md
- **Model**: opus-4.5 (semantic accuracy evaluation, nuanced quality assessment)
- **Fallback**: sonnet-4.5
- **Model Justification**: High-quality semantic understanding required for accuracy detection, completeness evaluation, consistency analysis, and context-aware recommendations (parallel to bloat analyzer rationale)
- **Allowed Tools**: Read, Write, Edit, Grep, Bash
- **Size Target**: <400 lines (executable/documentation separation compliance)

**Agent Usage Guide**: .claude/docs/guides/docs-accuracy-analyzer-agent-guide.md
- **Pattern**: Comprehensive guide following _template-command-guide.md
- **Sections**: Architecture, quality dimensions, evaluation algorithm, report structure, integration patterns, troubleshooting
- **Cross-Reference**: Bidirectional links with behavioral file

**Report Structure** (9 sections):
1. Metadata (date, agent, input reports, bloat analysis reference)
2. Executive Summary (2-3 sentences, key findings)
3. Current Accuracy State (error inventory, outdated content, inconsistencies)
4. Completeness Analysis (gap detection, required vs actual coverage, missing documentation)
5. Consistency Evaluation (terminology variance, formatting violations, structural inconsistencies)
6. Timeliness Assessment (outdated information, broken references, deprecated patterns)
7. Quality Improvement Recommendations (specific actionable recommendations with file paths and line numbers)
8. Documentation Optimization Recommendations (specific recommendations for revising/removing/combining documentation based on bloat analysis findings)
9. Completion Signal (REPORT_CREATED: absolute path)

**Workflow Integration Points**:
- Pre-calculated report paths: `BLOAT_REPORT_PATH="${WORKFLOW_TOPIC_DIR}/reports/003_bloat_analysis.md"`, `ACCURACY_REPORT_PATH="${WORKFLOW_TOPIC_DIR}/reports/004_accuracy_analysis.md"`
- Parallel invocation: Both bloat and accuracy agents invoked in same bash block (single message, 2 Task calls)
- Both agents receive identical research report inputs: CLAUDE_MD_REPORT_PATH and DOCS_REPORT_PATH
- Verification checkpoint: Verify both reports created before planning phase
- Metadata extraction: extract_bloat_metadata() and extract_accuracy_metadata() functions (title + 50-word summary + key findings)
- Planning integration: cleanup-plan-architect receives ALL FOUR reports (CLAUDE.md, docs structure, bloat, accuracy) for systematic unified implementation plan

### Quality Dimensions Evaluated

**Six Core Dimensions** (from Report 001):

1. **Accuracy**: Error-free technical content, verified implementation state
   - Detection: Grep for factual errors, outdated API references, incorrect file paths
   - Validation: Cross-reference code with documentation claims
   - Output: Error inventory with file:line locations and corrections

2. **Completeness**: Comprehensive coverage without gaps
   - Detection: Required documentation matrix (commands → guides, agents → reference entries, patterns → docs)
   - Calculation: Completeness percentage (actual/required docs)
   - Output: Gap analysis with high-priority missing documentation list

3. **Consistency**: Uniform terminology, formatting, structure
   - Detection: Terminology variance scanning, style guide violations
   - Analysis: Semantic similarity for concept naming inconsistencies
   - Output: Inconsistency report with standardization recommendations

4. **Timeliness**: Current information, no outdated content
   - Detection: Temporal pattern scanning (banned phrases: "recently", "previously", "now supports")
   - Validation: Check for deprecated patterns, old version references
   - Output: Timeless writing violations with rewriting suggestions

5. **Usability**: Navigable, readable, accessible
   - Detection: Broken internal links, missing cross-references, orphaned files
   - Analysis: Navigation structure validation (guides/README.md completeness)
   - Output: Navigation improvements and link fixes

6. **Clarity**: Concise writing, readable prose
   - Detection: Readability scoring (Flesch Reading Ease target 70-80)
   - Analysis: Section complexity, sentence length, jargon density
   - Output: Clarity improvement recommendations (sections <60 or >80 readability)

### Semantic Analysis Algorithm

**Accuracy Detection** (Opus semantic understanding):
```
For each documentation file:
  1. Extract technical claims and API references
  2. Cross-reference with actual code (Grep, Read tools)
  3. Detect semantic mismatches (claims not matching implementation)
  4. Flag outdated terminology (old function names, deprecated patterns)
  5. Verify file paths and line number references
  6. Generate correction recommendations with specific replacements
```

**Completeness Assessment** (systematic gap analysis):
```
Required documentation matrix:
  commands/*.md → guides/*-command-guide.md (18/20 = 90% from Report 001)
  agents/*.md → reference/agent-reference.md entries (12/15 = 80%)
  concepts/patterns/*.md → README.md descriptions (8/10 = 80%)

For each category:
  1. Count required vs actual documentation
  2. Calculate completeness percentage
  3. Identify missing high-priority items
  4. Prioritize by architectural impact (critical > important > nice-to-have)
```

**Consistency Evaluation** (semantic similarity + rule-based):
```
Terminology analysis:
  1. Extract domain concepts from all docs (state machine, checkpoint, metadata, etc.)
  2. Identify semantic clusters (variations: "state machine", "state-based orchestration", "SM lib")
  3. Flag inconsistencies (>3 variants for same concept)
  4. Recommend canonical terms per style guide

Formatting validation:
  1. Check markdown structure (heading hierarchy, list formatting)
  2. Validate code fence language tags (bash, markdown, json)
  3. Verify cross-reference format (relative paths, anchor syntax)
  4. Detect style violations (emoji usage, line length >100)
```

**Timeliness Validation** (pattern scanning + content analysis):
```
Temporal pattern detection:
  1. Grep for banned patterns: (New), (Old), "previously", "recently", "now supports"
  2. Detect version references: "v1.0", "since version", "introduced in"
  3. Flag migration language: "migration from", "backward compatibility"
  4. Suggest timeless rewrites (Report 001 patterns)

Deprecation scanning:
  1. Search for deprecated function references
  2. Identify obsolete architectural patterns
  3. Cross-reference with current implementation
  4. Recommend updates to current state
```

### Integration with /optimize-claude

**Modified Workflow Phases**:

**Phase 1: Parallel Research** (unchanged)
- Agent 1: claude-md-analyzer
- Agent 2: docs-structure-analyzer

**Phase 2: Parallel Analysis** (NEW - both agents invoked simultaneously)
```bash
# Calculate report paths BEFORE agent invocation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
BLOAT_REPORT_PATH="${WORKFLOW_TOPIC_DIR}/reports/003_bloat_analysis.md"
ACCURACY_REPORT_PATH="${WORKFLOW_TOPIC_DIR}/reports/004_accuracy_analysis.md"

**EXECUTE NOW**: Invoke BOTH analysis agents in parallel.

Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation bloat and create recommendations"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md

    INPUTS:
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${BLOAT_REPORT_PATH}

    Analyze CLAUDE.md and .claude/docs/ structure to identify bloat and create specific recommendations for revising/removing/combining documentation.

    Return: REPORT_CREATED: ${BLOAT_REPORT_PATH}
  "
}

Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation accuracy and completeness"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md

    INPUTS:
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}

    Evaluate documentation quality across six dimensions (accuracy, completeness, consistency, timeliness, usability, clarity) and create implementation-ready recommendations.

    Return: REPORT_CREATED: ${ACCURACY_REPORT_PATH}
  "
}
```

**Phase 3: Verification Checkpoint**
```bash
# Verify both reports created (fail-fast)
if [ ! -f "$BLOAT_REPORT_PATH" ]; then
  echo "ERROR: Bloat analyzer failed to create report: $BLOAT_REPORT_PATH"
  exit 1
fi

if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  echo "ERROR: Accuracy analyzer failed to create report: $ACCURACY_REPORT_PATH"
  exit 1
fi

echo "✓ Bloat analysis: $BLOAT_REPORT_PATH"
echo "✓ Accuracy analysis: $ACCURACY_REPORT_PATH"
```

**Phase 3: Verification Checkpoint**
```bash
# Verify both reports created (fail-fast)
if [ ! -f "$BLOAT_REPORT_PATH" ]; then
  echo "ERROR: Bloat analyzer failed to create report: $BLOAT_REPORT_PATH"
  exit 1
fi

if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  echo "ERROR: Accuracy analyzer failed to create report: $ACCURACY_REPORT_PATH"
  exit 1
fi

echo "✓ Bloat analysis: $BLOAT_REPORT_PATH"
echo "✓ Accuracy analysis: $ACCURACY_REPORT_PATH"
```

**Phase 4: Metadata Extraction**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Extract bloat metadata
BLOAT_METADATA=$(extract_bloat_metadata "$BLOAT_REPORT_PATH")

# Extract accuracy metadata (NEW function)
ACCURACY_METADATA=$(extract_accuracy_metadata "$ACCURACY_REPORT_PATH")
```

**Phase 5: Planning with All Four Reports**
```bash
Task {
  subagent_type: "general-purpose"
  description: "Generate systematic implementation plan from all analysis reports"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/cleanup-plan-architect.md

    INPUTS:
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${BLOAT_REPORT_PATH}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}
    - PLAN_PATH: ${PLAN_PATH}

    Integration Requirements:
    - Read ALL FOUR reports to understand complete system state
    - Incorporate bloat analysis findings (extractions, splits, merges, consolidations)
    - Incorporate accuracy analysis findings (error fixes, gap filling, consistency improvements, quality enhancements)
    - Generate systematic unified implementation plan combining CLAUDE.md changes with .claude/docs/ improvements
    - Create plan for user to review or implement
    - Prioritize: Critical accuracy errors FIRST, then bloat reduction, then enhancements

    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

## Implementation Phases

### Phase 1: Agent Behavioral File Creation
dependencies: []

**Objective**: Create docs-accuracy-analyzer.md agent following bloat analyzer pattern with 6-step execution process

**Complexity**: Medium

**Tasks**:
- [x] Create .claude/agents/docs-accuracy-analyzer.md with Opus 4.5 frontmatter (file: .claude/agents/docs-accuracy-analyzer.md)
- [x] Add model justification: "Semantic accuracy evaluation, nuanced quality assessment, completeness analysis, consistency detection require Opus-tier understanding"
- [x] Implement STEP 1: Receive and verify input paths (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH, ACCURACY_REPORT_PATH)
- [x] Implement STEP 1.5: Ensure parent directory exists using ensure_artifact_directory()
- [x] Implement STEP 2: Create report file FIRST with template structure (9 section placeholders)
- [x] Implement STEP 3: Read both research reports and extract key findings
- [x] Implement STEP 4: Perform semantic accuracy analysis across six quality dimensions
- [x] Implement STEP 5: Verification checkpoint (file exists, >1000 bytes, no placeholders)
- [x] Implement STEP 6: Completion signal (REPORT_CREATED: absolute path)
- [x] Add fail-fast error handling at each step with diagnostic messages
- [x] Add progress streaming markers (PROGRESS: Starting accuracy analysis...)
- [x] Document report structure with 9 section templates

**Testing**:
```bash
# Verify agent file structure
test -f .claude/agents/docs-accuracy-analyzer.md
grep -q "model: opus-4.5" .claude/agents/docs-accuracy-analyzer.md

# Verify execution steps present
grep -c "^## STEP [1-6]" .claude/agents/docs-accuracy-analyzer.md
# Expected: 6 steps
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(712): complete Phase 1 - Agent Behavioral File Creation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 2: Report Structure and Quality Dimension Analysis
dependencies: [1]

**Objective**: Implement semantic analysis algorithms for six quality dimensions with implementation-ready output format

**Complexity**: High

**Tasks**:
- [x] Implement accuracy detection algorithm (grep technical claims, cross-reference code, detect mismatches) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Implement completeness assessment (required documentation matrix, gap calculation, prioritization) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Implement consistency evaluation (terminology scanning, semantic similarity, formatting validation) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Implement timeliness validation (temporal pattern detection, deprecation scanning, timeless rewriting) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Implement usability analysis (broken link detection, navigation validation, orphaned files) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Implement clarity assessment (readability scoring placeholder, section complexity analysis) (file: .claude/agents/docs-accuracy-analyzer.md, STEP 4)
- [x] Create report Section 3: Current Accuracy State (error inventory table with file:line:correction)
- [x] Create report Section 4: Completeness Analysis (gap matrix, required vs actual percentages)
- [x] Create report Section 5: Consistency Evaluation (terminology variance table, standardization recommendations)
- [x] Create report Section 6: Timeliness Assessment (temporal violations, deprecation flags, rewriting patterns)
- [x] Create report Section 7: Quality Improvement Recommendations (specific fixes with file paths)
- [x] Create report Section 8: Documentation Optimization Recommendations (specific recommendations for revising/removing/combining documentation files based on bloat analysis findings)

**Testing**:
```bash
# Verify quality dimension analysis implemented
grep -q "accuracy detection" .claude/agents/docs-accuracy-analyzer.md
grep -q "completeness assessment" .claude/agents/docs-accuracy-analyzer.md
grep -q "consistency evaluation" .claude/agents/docs-accuracy-analyzer.md

# Verify report section templates present
grep -c "^## Section [3-8]" .claude/agents/docs-accuracy-analyzer.md
# Expected: 6 sections
```

**Expected Duration**: 3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(712): complete Phase 2 - Report Structure and Quality Dimension Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Workflow Integration and Parallel Invocation
dependencies: [2]

**Objective**: Modify /optimize-claude to invoke accuracy analyzer parallel with bloat analyzer and integrate both reports into planning phase

**Complexity**: Medium

**Tasks**:
- [ ] Modify .claude/commands/optimize-claude.md to pre-calculate BLOAT_REPORT_PATH and ACCURACY_REPORT_PATH (file: .claude/commands/optimize-claude.md, Phase 0)
- [ ] Update Phase 2 to invoke BOTH bloat and accuracy agents in parallel (single bash block, 2 Task invocations)
- [ ] Configure bloat analyzer to receive research reports (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH) and create bloat analysis report
- [ ] Configure accuracy analyzer to receive same research reports (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH) and create accuracy analysis report
- [ ] Both agents perform independent analysis without dependencies on each other
- [ ] Add verification checkpoint after Phase 2 verifying both reports created (fail-fast if missing)
- [ ] Update Phase 3 to extract metadata from both reports using library functions
- [ ] Update Phase 4 (planning phase) to pass ALL FOUR reports to cleanup-plan-architect agent
- [ ] Modify cleanup-plan-architect.md behavioral file to handle four input reports (file: .claude/agents/cleanup-plan-architect.md)
- [ ] Add planning agent instructions: Read all four reports, incorporate all findings, generate systematic unified plan
- [ ] Update phase prioritization logic: Critical accuracy errors FIRST, bloat reduction SECOND, enhancements THIRD

**Testing**:
```bash
# Verify workflow modifications
grep -q "BLOAT_REPORT_PATH" .claude/commands/optimize-claude.md
grep -q "ACCURACY_REPORT_PATH" .claude/commands/optimize-claude.md

# Verify parallel invocation pattern
grep -A 30 "Phase 2:" .claude/commands/optimize-claude.md | grep -c "Task {"
# Expected: 2 Task invocations in Phase 2 (bloat + accuracy)

# Verify both agents receive same research report inputs
grep -A 10 "docs-bloat-analyzer" .claude/commands/optimize-claude.md | grep -q "CLAUDE_MD_REPORT_PATH"
grep -A 10 "docs-accuracy-analyzer" .claude/commands/optimize-claude.md | grep -q "CLAUDE_MD_REPORT_PATH"

# Verify verification checkpoint
grep -q "if \[ ! -f.*BLOAT_REPORT_PATH" .claude/commands/optimize-claude.md
grep -q "if \[ ! -f.*ACCURACY_REPORT_PATH" .claude/commands/optimize-claude.md

# Verify planning agent receives all four reports
grep -A 10 "cleanup-plan-architect" .claude/commands/optimize-claude.md | grep -q "ACCURACY_REPORT_PATH"
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(712): complete Phase 3 - Workflow Integration and Parallel Invocation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Metadata Extraction and Context Reduction
dependencies: [3]

**Objective**: Implement extract_accuracy_metadata() library function achieving 95%+ context reduction for accuracy reports

**Complexity**: Low

**Tasks**:
- [ ] Create extract_accuracy_metadata() function in .claude/lib/metadata-extraction.sh (file: .claude/lib/metadata-extraction.sh)
- [ ] Extract title from accuracy report (Section 1: Metadata)
- [ ] Extract executive summary (Section 2: Executive Summary, 50-word max)
- [ ] Extract key findings array (top 3-5 critical accuracy issues from Section 7)
- [ ] Extract completeness percentage (from Section 4: Completeness Analysis)
- [ ] Extract error count (from Section 3: Current Accuracy State)
- [ ] Return metadata structure: title, summary, key_findings[], completeness_pct, error_count
- [ ] Add caching support using load_metadata_on_demand() pattern
- [ ] Calculate context reduction percentage (full report tokens vs metadata tokens)
- [ ] Document function in library API reference (file: .claude/docs/reference/library-api.md)

**Testing**:
```bash
# Unit test extract_accuracy_metadata
source .claude/lib/metadata-extraction.sh

# Create test accuracy report
TEST_REPORT="/tmp/test_accuracy_report.md"
cat > "$TEST_REPORT" <<'EOF'
# Documentation Accuracy Analysis Report

## Metadata
- Date: 2025-11-14
- Agent: docs-accuracy-analyzer

## Executive Summary
Found 12 critical accuracy errors, 8 completeness gaps, 15 consistency violations. Overall documentation completeness: 85%. Immediate fixes required for outdated API references and missing command guides.

## Section 3: Current Accuracy State
[error inventory]

## Section 4: Completeness Analysis
Overall Completeness: 85% (102/120 required docs)
EOF

# Extract metadata
METADATA=$(extract_accuracy_metadata "$TEST_REPORT")

# Verify structure
echo "$METADATA" | grep -q "title:"
echo "$METADATA" | grep -q "summary:"
echo "$METADATA" | grep -q "completeness_pct: 85"

# Verify context reduction
FULL_SIZE=$(wc -c < "$TEST_REPORT")
META_SIZE=$(echo "$METADATA" | wc -c)
REDUCTION=$((100 - (META_SIZE * 100 / FULL_SIZE)))
test $REDUCTION -ge 95 || echo "WARNING: Context reduction only $REDUCTION%"
```

**Expected Duration**: 1.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(712): complete Phase 4 - Metadata Extraction and Context Reduction`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Documentation and Architectural Compliance
dependencies: [4]

**Objective**: Create comprehensive usage guide and validate compliance with architectural standards

**Complexity**: Medium

**Tasks**:
- [ ] Create .claude/docs/guides/docs-accuracy-analyzer-agent-guide.md following _template-command-guide.md (file: .claude/docs/guides/docs-accuracy-analyzer-agent-guide.md)
- [ ] Add Section 1: Architecture (quality dimensions, semantic analysis approach, integration points)
- [ ] Add Section 2: Quality Dimensions (detailed explanation of six dimensions with examples)
- [ ] Add Section 3: Evaluation Algorithm (step-by-step analysis procedures per dimension)
- [ ] Add Section 4: Report Structure (nine section descriptions with field definitions)
- [ ] Add Section 5: Integration Patterns (workflow integration, metadata extraction, planning coordination)
- [ ] Add Section 6: Troubleshooting (common issues, debugging procedures, verification checkpoints)
- [ ] Add bidirectional cross-references (behavioral file ↔ guide file)
- [ ] Validate Standard 0 compliance: Imperative language (YOU MUST, EXECUTE NOW, MANDATORY) in behavioral file
- [ ] Validate Standard 11 compliance: Imperative agent invocation pattern in /optimize-claude modifications
- [ ] Validate Standard 14 compliance: Behavioral file <400 lines, guide unlimited
- [ ] Validate Standard 15 compliance: Library sourcing order (metadata-extraction.sh after artifact-creation.sh)
- [ ] Validate Standard 16 compliance: Return code verification for extract_accuracy_metadata()

**Testing**:
```bash
# Verify guide file created
test -f .claude/docs/guides/docs-accuracy-analyzer-agent-guide.md

# Verify bidirectional cross-references
grep -q "docs-accuracy-analyzer-agent-guide.md" .claude/agents/docs-accuracy-analyzer.md
grep -q "docs-accuracy-analyzer.md" .claude/docs/guides/docs-accuracy-analyzer-agent-guide.md

# Run architectural compliance validation
.claude/tests/validate_executable_doc_separation.sh .claude/agents/docs-accuracy-analyzer.md

# Verify imperative language patterns
grep -c "YOU MUST\|EXECUTE NOW\|MANDATORY" .claude/agents/docs-accuracy-analyzer.md
# Expected: >=5 instances

# Verify agent size compliance
LINES=$(wc -l < .claude/agents/docs-accuracy-analyzer.md)
test $LINES -lt 400 || echo "WARNING: Agent file exceeds 400 lines ($LINES)"
```

**Expected Duration**: 2.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(712): complete Phase 5 - Documentation and Architectural Compliance`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Testing, Validation, and Integration Verification
dependencies: [5]

**Objective**: Create comprehensive test suite validating agent delegation, report creation, and workflow integration

**Complexity**: Medium

**Tasks**:
- [ ] Create .claude/tests/test_docs_accuracy_analyzer.sh test suite (file: .claude/tests/test_docs_accuracy_analyzer.sh)
- [ ] Add test 1: Agent behavioral file exists and has correct frontmatter (model: opus-4.5)
- [ ] Add test 2: Agent file size compliance (<400 lines)
- [ ] Add test 3: Six-step execution process present (STEP 1-6 headings)
- [ ] Add test 4: Completion signal format validation (REPORT_CREATED: path)
- [ ] Add test 5: Mock invocation test (verify report creation with test inputs)
- [ ] Add test 6: Report structure validation (9 sections present, no placeholders)
- [ ] Add test 7: Metadata extraction test (extract_accuracy_metadata returns expected structure)
- [ ] Add test 8: Context reduction measurement (95%+ reduction achieved)
- [ ] Add test 9: Workflow integration test (/optimize-claude parallel invocation)
- [ ] Add test 10: Verification checkpoint test (fail-fast when report missing)
- [ ] Add test 11: Planning integration test (cleanup-plan-architect receives accuracy report)
- [ ] Add test 12: Architectural compliance validation (Standards 0, 11, 14, 15, 16)
- [ ] Run complete test suite and verify 100% pass rate
- [ ] Update .claude/tests/run_all_tests.sh to include new test suite
- [ ] Document test coverage in .claude/tests/COVERAGE_REPORT.md

**Testing**:
```bash
# Run accuracy analyzer test suite
.claude/tests/test_docs_accuracy_analyzer.sh

# Expected output:
# Test 1: Agent file exists and has Opus 4.5 frontmatter ... PASS
# Test 2: Agent file size <400 lines ... PASS
# Test 3: Six-step execution process ... PASS
# Test 4: Completion signal format ... PASS
# Test 5: Mock invocation ... PASS
# Test 6: Report structure ... PASS
# Test 7: Metadata extraction ... PASS
# Test 8: Context reduction 95%+ ... PASS
# Test 9: Workflow integration ... PASS
# Test 10: Verification checkpoint ... PASS
# Test 11: Planning integration ... PASS
# Test 12: Architectural compliance ... PASS
#
# 12/12 tests passed (100%)

# Run full test suite
.claude/tests/run_all_tests.sh
# Verify no regressions in existing tests

# Verify coverage update
grep -q "docs-accuracy-analyzer" .claude/tests/COVERAGE_REPORT.md
```

**Expected Duration**: 3 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(712): complete Phase 6 - Testing, Validation, and Integration Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Agent behavioral file structure validation (frontmatter, execution steps, completion signal)
- Metadata extraction function testing (extract_accuracy_metadata unit tests)
- Report structure validation (9 sections, no placeholders, >1000 bytes)
- Quality dimension algorithm testing (accuracy, completeness, consistency, timeliness, usability, clarity)

### Integration Testing
- Workflow integration testing (/optimize-claude parallel invocation)
- Verification checkpoint testing (fail-fast when reports missing)
- Planning integration testing (cleanup-plan-architect receives four reports)
- Context reduction measurement (95%+ reduction achieved)
- End-to-end workflow testing (/optimize-claude with real CLAUDE.md and .claude/docs/)

### Compliance Testing
- Architectural standards validation (Standards 0, 11, 14, 15, 16)
- Executable/documentation separation validation (agent <400 lines, guide unlimited)
- Link validation (bidirectional cross-references)
- Imperative language pattern detection (YOU MUST, EXECUTE NOW, MANDATORY)

### Performance Testing
- Context reduction measurement (full report vs metadata tokens)
- Parallel execution timing (bloat + accuracy agents vs sequential)
- Metadata extraction performance (caching effectiveness)
- Overall workflow duration (target <30% context usage)

### Regression Testing
- Existing /optimize-claude functionality preserved (bloat analysis still works)
- No degradation in context reduction percentages
- 100% file creation rate maintained
- All existing tests continue passing

## Documentation Requirements

### Agent Documentation
- [ ] docs-accuracy-analyzer.md behavioral file (<400 lines, imperative language, six-step process)
- [ ] docs-accuracy-analyzer-agent-guide.md usage guide (architecture, quality dimensions, evaluation algorithm, troubleshooting)
- [ ] Bidirectional cross-references between behavioral file and guide

### Library Documentation
- [ ] extract_accuracy_metadata() function documented in library-api.md
- [ ] Context reduction patterns documented
- [ ] Caching behavior explained

### Workflow Documentation
- [ ] /optimize-claude workflow updated in optimize-claude-command-guide.md
- [ ] Parallel analysis phase documented (bloat + accuracy)
- [ ] Integration patterns explained (four reports to planning agent)

### Reference Documentation
- [ ] Agent reference updated with docs-accuracy-analyzer entry
- [ ] Model selection guide updated with accuracy analyzer example
- [ ] Quality dimension catalog added to reference documentation

## Dependencies

### External Dependencies
- Opus 4.5 model availability (fallback to Sonnet 4.5 if unavailable)
- Existing /optimize-claude workflow functional
- Research reports available as input (CLAUDE.md analysis, docs structure analysis)

### Internal Dependencies
- .claude/lib/metadata-extraction.sh library
- .claude/lib/artifact-creation.sh library
- .claude/lib/verification-helpers.sh library
- .claude/agents/cleanup-plan-architect.md agent

### Prerequisite Work
- Bloat analyzer agent fully functional (provides parallel pattern reference)
- Workflow state machine library operational
- Behavioral injection pattern infrastructure established
- Architectural compliance standards documented (Standards 0, 11, 14, 15, 16)
