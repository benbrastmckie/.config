# Agent-Based CLAUDE.md Cleanup Enhancement

## Metadata
- **Date**: 2025-11-14
- **Feature**: Enhanced /setup --cleanup with multi-stage research and planning workflow
- **Scope**: Modify /setup command Phase 2 to delegate to research agents (CLAUDE.md + docs analysis) followed by planning agent
- **Estimated Phases**: 6
- **Complexity**: Medium-High
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Commands**: /setup, /plan, /document, /coordinate
- **Related Agents**: research-specialist (behavioral template), plan-architect (behavioral template)
- **Pattern Reference**: Similar to /coordinate but simpler (2 research agents → 1 planning agent)

## Overview

The current `/setup --cleanup` mode provides basic bloat analysis but lacks intelligent extraction and integration capabilities. This enhancement transforms it into a **multi-stage agent workflow** following the /coordinate pattern:

**Stage 1: Parallel Research** (2 agents)
1. **claude-md-analyzer**: Analyzes CLAUDE.md structure, section sizes, metadata usage
2. **docs-structure-analyzer**: Analyzes .claude/docs/ organization, existing files, integration points

**Stage 2: Sequential Planning** (1 agent)
3. **cleanup-plan-architect**: Reads both research reports and creates comprehensive cleanup plan improving both CLAUDE.md and .claude/docs/

**Stage 3: User Choice**
4. **Interactive prompt**: Review plan or implement immediately

### Success Criteria
- [ ] Three new specialized agents created following agent development guide
- [ ] /setup Phase 2 modified to invoke research agents in parallel (Stage 1)
- [ ] /setup Phase 2 includes verification checkpoints after research (Stage 1)
- [ ] /setup Phase 2 invokes planning agent with report paths (Stage 2)
- [ ] Planning agent produces structured refactoring plan in topic-based spec directory
- [ ] User can review plan before implementation (interactive prompt)
- [ ] Optional: User can proceed directly to implementation via /implement delegation
- [ ] All changes follow project standards (imperative language, verification checkpoints, behavioral injection)
- [ ] Tests validate all three agents and multi-stage workflow
- [ ] Documentation updated (setup-command-guide.md, agent-reference.md)

## Technical Design

### Architecture

```
/setup --cleanup workflow (multi-stage):

┌─────────────────────────────────────────────────┐
│ Phase 0: Argument Parsing                       │
│ • Detect MODE=cleanup                           │
│ • Set DRY_RUN, THRESHOLD flags                  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.1: Initialize Research Stage            │
│ • Calculate topic path (timestamp-based)        │
│ • Allocate 2 report paths                       │
│   - REPORT_PATH_1: CLAUDE.md analysis           │
│   - REPORT_PATH_2: .claude/docs/ analysis       │
│ • Allocate plan path                            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.2: STAGE 1 - Parallel Research          │
│                                                  │
│ ┌─────────────────────┐  ┌────────────────────┐ │
│ │ Agent 1 (parallel)  │  │ Agent 2 (parallel) │ │
│ │ claude-md-analyzer  │  │ docs-structure-    │ │
│ │                     │  │ analyzer           │ │
│ │ Analyzes:           │  │ Analyzes:          │ │
│ │ • Section structure │  │ • Directory layout │ │
│ │ • Line counts       │  │ • Existing files   │ │
│ │ • Metadata usage    │  │ • Integration pts  │ │
│ │ • Bloat detection   │  │ • Gaps/overlaps    │ │
│ │                     │  │                    │ │
│ │ Output:             │  │ Output:            │ │
│ │ REPORT_PATH_1       │  │ REPORT_PATH_2      │ │
│ └─────────────────────┘  └────────────────────┘ │
│                                                  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.3: Verification Checkpoint (MANDATORY)   │
│ • Verify REPORT_PATH_1 created                  │
│ • Verify REPORT_PATH_2 created                  │
│ • Fail-fast if either missing                   │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.4: STAGE 2 - Sequential Planning        │
│                                                  │
│ ┌──────────────────────────────────────────┐    │
│ │ Agent 3 (sequential)                     │    │
│ │ cleanup-plan-architect                   │    │
│ │                                          │    │
│ │ Inputs (report paths):                   │    │
│ │ • REPORT_PATH_1 (CLAUDE.md analysis)     │    │
│ │ • REPORT_PATH_2 (docs analysis)          │    │
│ │                                          │    │
│ │ Tasks:                                   │    │
│ │ • Read both research reports             │    │
│ │ • Identify optimization opportunities    │    │
│ │ • Map extraction → integration points    │    │
│ │ • Generate phased cleanup plan           │    │
│ │ • Include docs improvements              │    │
│ │                                          │    │
│ │ Output:                                  │    │
│ │ PLAN_PATH (implementation plan)          │    │
│ └──────────────────────────────────────────┘    │
│                                                  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.5: Verification Checkpoint (MANDATORY)   │
│ • Verify PLAN_PATH created                      │
│ • Fail-fast if plan missing                     │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2.6: User Choice (Interactive)             │
│                                                  │
│ Present options:                                │
│  1. Review plan (show paths, exit)              │
│  2. Implement now (invoke /implement)           │
│  3. Cancel                                      │
│                                                  │
│ If option 2:                                    │
│   /implement [PLAN_PATH]                        │
└─────────────────────────────────────────────────┘

Pattern Comparison:
  /coordinate: N research agents → 1 plan → M implementers
  /setup --cleanup: 2 research agents → 1 plan → user choice
```

### New Agents (3 total)

#### Agent 1: claude-md-analyzer.md

**Location**: `.claude/agents/claude-md-analyzer.md`

**Purpose**: Research agent that analyzes CLAUDE.md structure and identifies optimization opportunities

**Capabilities**:
- Parse CLAUDE.md section boundaries and hierarchy
- Count lines per section (bloat detection)
- Analyze metadata usage ([Used by: ...] tags)
- Identify sections without metadata
- Detect duplicate or overlapping content
- Calculate section complexity scores

**Model Selection**: Haiku 4.5 (deterministic parsing, simple analysis, <50 lines of output)

**Tools**: Read, Write, Grep, Bash

**Input Requirements** (provided by /setup):
- `CLAUDE_MD_PATH`: Absolute path to CLAUDE.md
- `REPORT_PATH`: Absolute path for analysis report (REPORT_PATH_1)
- `THRESHOLD`: Bloat threshold (balanced=80, aggressive=50, conservative=120)

**Output Requirements**:
- Research report file created at `REPORT_PATH`
- Completion signal: `REPORT_CREATED: [path]`
- Report format: Structured markdown with sections, line counts, bloat flags, recommendations

---

#### Agent 2: docs-structure-analyzer.md

**Location**: `.claude/agents/docs-structure-analyzer.md`

**Purpose**: Research agent that analyzes .claude/docs/ organization and identifies integration opportunities

**Capabilities**:
- Discover .claude/docs/ directory structure (Glob)
- Identify existing documentation categories (concepts/, guides/, reference/)
- Detect gaps in documentation coverage
- Find natural integration points for CLAUDE.md extractions
- Analyze cross-references and link structure
- Identify overlapping or duplicate documentation

**Model Selection**: Haiku 4.5 (directory traversal, pattern matching, simple recommendations)

**Tools**: Read, Write, Grep, Glob, Bash

**Input Requirements** (provided by /setup):
- `DOCS_DIR`: Absolute path to .claude/docs/
- `REPORT_PATH`: Absolute path for analysis report (REPORT_PATH_2)
- `PROJECT_DIR`: Project root for context

**Output Requirements**:
- Research report file created at `REPORT_PATH`
- Completion signal: `REPORT_CREATED: [path]`
- Report format: Structured markdown with directory tree, integration points, gap analysis, recommendations

---

#### Agent 3: cleanup-plan-architect.md

**Location**: `.claude/agents/cleanup-plan-architect.md`

**Purpose**: Planning agent that synthesizes research reports and generates implementation plan

**Capabilities**:
- Read and analyze both research reports
- Synthesize findings from CLAUDE.md and docs analyses
- Map extraction targets to integration points
- Generate phased implementation plan
- Include both CLAUDE.md optimization and docs improvements
- Create rollback procedures
- Follow /implement compatibility standards

**Model Selection**: Sonnet 4.5 (complex synthesis, plan generation, multi-phase coordination)

**Tools**: Read, Write, Grep, Bash

**Input Requirements** (provided by /setup):
- `CLAUDE_MD_REPORT_PATH`: Absolute path to CLAUDE.md analysis report (REPORT_PATH_1)
- `DOCS_REPORT_PATH`: Absolute path to docs analysis report (REPORT_PATH_2)
- `PLAN_PATH`: Absolute path for implementation plan
- `THRESHOLD`: Bloat threshold (for context)
- `PROJECT_DIR`: Project root for context

**Output Requirements**:
- Implementation plan file created at `PLAN_PATH`
- Completion signal: `PLAN_CREATED: [path]`
- Plan format: /implement-compatible with phases, tasks, checkboxes, testing

### Modified /setup Command

**Changes to Phase 2** (.claude/commands/setup.md:~118-144):

The Phase 2 bash blocks are replaced with a **multi-stage workflow**:

**Stage 1**: Path Allocation (Phase 2.1)
1. Calculate topic-based path (timestamp)
2. Allocate REPORT_PATH_1 (CLAUDE.md analysis)
3. Allocate REPORT_PATH_2 (docs analysis)
4. Allocate PLAN_PATH (cleanup plan)

**Stage 2**: Parallel Research Invocation (Phase 2.2)
1. Invoke claude-md-analyzer (Agent 1) with REPORT_PATH_1
2. Invoke docs-structure-analyzer (Agent 2) with REPORT_PATH_2
3. Both agents run in parallel (single message, two Task blocks)

**Stage 3**: Research Verification (Phase 2.3)
1. Verify REPORT_PATH_1 created (fail-fast if missing)
2. Verify REPORT_PATH_2 created (fail-fast if missing)

**Stage 4**: Sequential Planning Invocation (Phase 2.4)
1. Invoke cleanup-plan-architect (Agent 3) with both report paths
2. Agent reads research reports and generates plan

**Stage 5**: Plan Verification (Phase 2.5)
1. Verify PLAN_PATH created (fail-fast if missing)

**Stage 6**: User Choice (Phase 2.6)
1. Display plan summary
2. Prompt: review/implement/cancel
3. Handle user selection

**Backward Compatibility**: Existing optimize-claude-md.sh library preserved but not used in enhanced workflow

### Agent Invocation Pattern (Following /coordinate)

**Phase 2.2**: Parallel Research Invocation (in single message)

```markdown
**EXECUTE NOW**: USE the Task tool to invoke research agents in parallel:

Task {
  subagent_type: "general-purpose"
  description: "Analyze CLAUDE.md structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/claude-md-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: ${THRESHOLD_VALUE}

    **CRITICAL**: Create report file at EXACT path provided above.

    Return: REPORT_CREATED: [exact absolute path]
  "
}

Task {
  subagent_type: "general-purpose"
  description: "Analyze .claude/docs/ structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-structure-analyzer.md

    **Input Paths** (ABSOLUTE):
    - DOCS_DIR: ${DOCS_DIR}
    - REPORT_PATH: ${REPORT_PATH_2}
    - PROJECT_DIR: ${PROJECT_DIR}

    **CRITICAL**: Create report file at EXACT path provided above.

    Return: REPORT_CREATED: [exact absolute path]
  "
}
```

**Phase 2.4**: Sequential Planning Invocation (after verification)

```markdown
**EXECUTE NOW**: USE the Task tool to invoke planning agent:

Task {
  subagent_type: "general-purpose"
  description: "Generate cleanup implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/cleanup-plan-architect.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - PLAN_PATH: ${PLAN_PATH}
    - THRESHOLD: ${THRESHOLD_VALUE}
    - PROJECT_DIR: ${PROJECT_DIR}

    **CRITICAL**: Create plan file at EXACT path provided above.

    Return: PLAN_CREATED: [exact absolute path]
  "
}
```

### Plan Format

The cleanup-plan-architect agent generates implementation plans following this structure:

```markdown
# CLAUDE.md Cleanup Refactoring Plan

## Metadata
- Feature: CLAUDE.md context optimization
- Sections Analyzed: [count]
- Extraction Targets: [count]
- Projected Reduction: [percentage]

## Phase 1: Backup and Preparation
- [ ] Create backup of CLAUDE.md
- [ ] Verify .claude/docs/ structure exists
- [ ] Create new documentation files (stubs)

## Phase 2: Extract Section X
- [ ] Extract lines N-M from CLAUDE.md
- [ ] Create .claude/docs/concepts/section-x.md
- [ ] Replace with summary + reference link
- [ ] Validate internal links still work

[Repeat Phase 2 for each extraction target]

## Phase N: Verification and Rollback
- [ ] Run /setup --validate
- [ ] Check all CLAUDE.md references resolve
- [ ] Test command discovery still works
- [ ] If issues: rollback using backup
```

## Implementation Phases

### Phase 1: Create Research and Planning Agents

**Objective**: Build three specialized agents following agent development guide and /coordinate pattern

**Complexity**: Medium

**Files**:
- `.claude/agents/claude-md-analyzer.md` (new - research agent)
- `.claude/agents/docs-structure-analyzer.md` (new - research agent)
- `.claude/agents/cleanup-plan-architect.md` (new - planning agent)

#### Subtask 1.1: Create claude-md-analyzer.md

**Tasks**:
- [ ] Create agent file with frontmatter (allowed-tools: Read, Write, Grep, Bash; model: haiku-4.5)
- [ ] Follow research-specialist.md pattern for behavioral structure
- [ ] Implement STEP 1: Verify input paths (CLAUDE_MD_PATH, REPORT_PATH)
- [ ] Implement STEP 1.5: Ensure parent directory exists (lazy creation)
- [ ] Implement STEP 2: Create report file FIRST (fail-fast guarantee)
- [ ] Implement STEP 3: Analyze CLAUDE.md structure
  - Parse section boundaries (## headers)
  - Count lines per section
  - Extract metadata tags ([Used by: ...])
  - Identify sections without metadata
  - Flag sections exceeding threshold
- [ ] Implement STEP 4: Generate recommendations
  - List bloated sections with line counts
  - Suggest extraction candidates
  - Identify metadata gaps
- [ ] Implement STEP 5: Write analysis to REPORT_PATH
- [ ] Implement STEP 6: Emit completion signal (REPORT_CREATED: [path])
- [ ] Add verification checkpoints between steps
- [ ] Follow imperative language standard (MUST/WILL/SHALL)

**Report Format**:
```markdown
# CLAUDE.md Structure Analysis

## Summary
- Total Lines: 964
- Total Sections: 19
- Bloated Sections (>80 lines): 4
- Sections Missing Metadata: 2

## Section Analysis
| Section | Lines | Has Metadata | Status | Recommendation |
|---------|-------|--------------|--------|----------------|
| Code Standards | 84 | Yes | Bloated | Extract to docs/reference/ |
| ... | ... | ... | ... | ... |

## Extraction Candidates
1. Code Standards (84 lines) → docs/reference/code-standards.md
2. Directory Organization Standards (231 lines) → docs/concepts/directory-organization.md
...

## Metadata Gaps
- Section X missing [Used by: ...] tag
...
```

#### Subtask 1.2: Create docs-structure-analyzer.md

**Tasks**:
- [ ] Create agent file with frontmatter (allowed-tools: Read, Write, Grep, Glob, Bash; model: haiku-4.5)
- [ ] Follow research-specialist.md pattern for behavioral structure
- [ ] Implement STEP 1: Verify input paths (DOCS_DIR, REPORT_PATH)
- [ ] Implement STEP 1.5: Ensure parent directory exists
- [ ] Implement STEP 2: Create report file FIRST
- [ ] Implement STEP 3: Discover .claude/docs/ structure
  - Glob for all .md files
  - Build directory tree
  - Categorize by type (concepts/, guides/, reference/)
  - Identify README.md coverage
- [ ] Implement STEP 4: Analyze integration opportunities
  - Find gaps in documentation
  - Identify natural homes for CLAUDE.md extractions
  - Detect overlapping or duplicate content
- [ ] Implement STEP 5: Write analysis to REPORT_PATH
- [ ] Implement STEP 6: Emit completion signal (REPORT_CREATED: [path])
- [ ] Add verification checkpoints
- [ ] Follow imperative language standard

**Report Format**:
```markdown
# .claude/docs/ Structure Analysis

## Directory Tree
.claude/docs/
├── concepts/ (12 files)
├── guides/ (18 files)
├── reference/ (6 files)
├── workflows/ (4 files)
└── troubleshooting/ (3 files)

## Integration Points
### concepts/
- Natural home for architecture sections from CLAUDE.md
- Gaps: No directory-organization.md file
- Opportunity: Extract Directory Organization Standards here

### reference/
- Natural home for standards and API docs
- Gaps: No code-standards.md file
- Opportunity: Extract Code Standards here

...

## Overlap Detection
- hierarchical_agents.md already covers content in CLAUDE.md lines 612-706
- state-based-orchestration-overview.md duplicates CLAUDE.md lines 706-814

## Recommendations
1. Create docs/reference/code-standards.md (new file needed)
2. Merge CLAUDE.md hierarchical content into existing hierarchical_agents.md
...
```

#### Subtask 1.3: Create cleanup-plan-architect.md

**Tasks**:
- [ ] Create agent file with frontmatter (allowed-tools: Read, Write, Grep, Bash; model: sonnet-4.5)
- [ ] Follow plan-architect.md pattern for behavioral structure
- [ ] Implement STEP 1: Verify input paths (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH, PLAN_PATH)
- [ ] Implement STEP 1.5: Ensure parent directory exists
- [ ] Implement STEP 2: Create plan file FIRST
- [ ] Implement STEP 3: Read both research reports
  - Parse CLAUDE.md analysis report
  - Parse docs structure analysis report
  - Extract key findings
- [ ] Implement STEP 4: Synthesize recommendations
  - Match extraction candidates to integration points
  - Identify docs improvements needed
  - Plan for both CLAUDE.md cleanup AND docs enhancement
- [ ] Implement STEP 5: Generate phased implementation plan
  - Phase 1: Backup and preparation
  - Phase 2-N: Section extractions (one per bloated section)
  - Phase N+1: Docs improvements (README updates, cross-references)
  - Phase N+2: Verification and rollback
- [ ] Implement STEP 6: Write plan to PLAN_PATH (following /implement format)
- [ ] Implement STEP 7: Emit completion signal (PLAN_CREATED: [path])
- [ ] Add verification checkpoints
- [ ] Follow imperative language standard

**Plan Format**: Standard /implement-compatible plan with phases, tasks, checkboxes

#### Phase 1 Testing

**Testing**:
```bash
# Test Agent 1: claude-md-analyzer
export TEST_REPORT_1="/tmp/test_claude_md_analysis.md"
# (Invoke via Task tool following behavioral injection)
test -f "$TEST_REPORT_1" && echo "✓ Report 1 created" || echo "✗ Report 1 missing"
grep -q "Section Analysis" "$TEST_REPORT_1" && echo "✓ Structure found" || echo "✗ Missing structure"

# Test Agent 2: docs-structure-analyzer
export TEST_REPORT_2="/tmp/test_docs_analysis.md"
# (Invoke via Task tool)
test -f "$TEST_REPORT_2" && echo "✓ Report 2 created" || echo "✗ Report 2 missing"
grep -q "Directory Tree" "$TEST_REPORT_2" && echo "✓ Structure found" || echo "✗ Missing structure"

# Test Agent 3: cleanup-plan-architect
export TEST_PLAN="/tmp/test_cleanup_plan.md"
# (Invoke via Task tool with both report paths)
test -f "$TEST_PLAN" && echo "✓ Plan created" || echo "✗ Plan missing"
grep -q "^## Phase" "$TEST_PLAN" && echo "✓ Phases found" || echo "✗ No phases"
```

**Acceptance Criteria**:
- All three agent files <400 lines each (executable/documentation separation)
- All agents follow research-specialist.md or plan-architect.md patterns
- Verification checkpoints in all agents
- Imperative language throughout (MUST/WILL/SHALL)
- Self-test sections in each agent file
- Report and plan formats clearly specified

---

### Phase 2: Modify /setup Command Phase 2

**Objective**: Replace static analyze_bloat call with multi-stage agent workflow (research → planning)

**Complexity**: Medium-High

**Files**:
- `.claude/commands/setup.md` (modify Phase 2, lines ~118-144)

**Tasks**:
- [ ] Preserve existing Phase 2 header and MODE check
- [ ] Add bash block (Phase 2.1): Calculate topic-based paths
  - Topic directory (timestamp-based)
  - REPORT_PATH_1 (CLAUDE.md analysis)
  - REPORT_PATH_2 (docs structure analysis)
  - PLAN_PATH (implementation plan)
- [ ] Add markdown section (Phase 2.2): Invoke research agents in parallel
  - Use two Task blocks in single message
  - Pass REPORT_PATH_1 to claude-md-analyzer
  - Pass REPORT_PATH_2 to docs-structure-analyzer
- [ ] Add bash block (Phase 2.3): Verify research reports created
  - Check REPORT_PATH_1 exists (fail-fast if missing)
  - Check REPORT_PATH_2 exists (fail-fast if missing)
- [ ] Add markdown section (Phase 2.4): Invoke planning agent
  - Use single Task block
  - Pass both report paths to cleanup-plan-architect
  - Pass PLAN_PATH for output
- [ ] Add bash block (Phase 2.5): Verify plan created
  - Check PLAN_PATH exists (fail-fast if missing)
- [ ] Add bash block (Phase 2.6): Display results and user choice
  - Show plan summary
  - Prompt: review/implement/cancel
  - Handle user selection
- [ ] Update command frontmatter dependencies (add Task tool, three agent dependencies)
- [ ] Preserve backward compatibility (keep optimize-claude-md.sh as library fallback)

**Complete Multi-Stage Workflow** (replaces existing Phase 2 in setup.md):

```markdown
## Phase 2: Cleanup Mode - Multi-Stage Agent Workflow

[EXECUTION-CRITICAL: Execute when MODE=cleanup]

### Phase 2.1: Path Allocation

```bash
set +H
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

[ "$MODE" != "cleanup" ] && echo "Skipping Phase 2" && exit 0

echo "=== Phase 2: Cleanup Mode (Multi-Stage Research → Planning) ==="
CLAUDE_MD_PATH="${PROJECT_DIR}/CLAUDE.md"
DOCS_DIR="${CLAUDE_PROJECT_DIR}/.claude/docs"

[ ! -f "$CLAUDE_MD_PATH" ] && echo "ERROR: CLAUDE.md not found. Run /setup first." && exit 1
[ ! -d "$DOCS_DIR" ] && echo "ERROR: .claude/docs/ not found." && exit 1

# Calculate topic-based paths (timestamp for uniqueness)
TIMESTAMP=$(date +%s)
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/setup_cleanup_${TIMESTAMP}"
REPORT_PATH_1="${TOPIC_DIR}/reports/001_claude_md_analysis.md"
REPORT_PATH_2="${TOPIC_DIR}/reports/002_docs_structure_analysis.md"
PLAN_PATH="${TOPIC_DIR}/plans/001_cleanup_implementation.md"

# Create directories
mkdir -p "${TOPIC_DIR}/reports"
mkdir -p "${TOPIC_DIR}/plans"

# Build threshold value
THRESHOLD_VALUE="balanced"
[ "$THRESHOLD" = "aggressive" ] && THRESHOLD_VALUE="aggressive"
[ "$THRESHOLD" = "conservative" ] && THRESHOLD_VALUE="conservative"

echo ""
echo "Stage 1: Research (parallel agents)"
echo "  → Agent 1: Analyzing CLAUDE.md structure"
echo "  → Agent 2: Analyzing .claude/docs/ organization"
echo ""
```

### Phase 2.2: STAGE 1 - Parallel Research Invocation

**EXECUTE NOW**: USE the Task tool to invoke research agents **in parallel** (single message, two Task blocks):

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze CLAUDE.md structure and identify bloat"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/claude-md-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: ${THRESHOLD_VALUE}

    **CRITICAL**: Create report file at EXACT path provided above.

    Expected Output:
    - Research report with section analysis, line counts, bloat flags
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}

Task {
  subagent_type: "general-purpose"
  description: "Analyze .claude/docs/ structure and integration points"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-structure-analyzer.md

    **Input Paths** (ABSOLUTE):
    - DOCS_DIR: ${DOCS_DIR}
    - REPORT_PATH: ${REPORT_PATH_2}
    - PROJECT_DIR: ${PROJECT_DIR}

    **CRITICAL**: Create report file at EXACT path provided above.

    Expected Output:
    - Research report with directory tree, integration points, gap analysis
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}
```

### Phase 2.3: Research Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying research reports..."

if [ ! -f "$REPORT_PATH_1" ]; then
  echo "ERROR: Agent 1 (claude-md-analyzer) failed to create report: $REPORT_PATH_1"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

if [ ! -f "$REPORT_PATH_2" ]; then
  echo "ERROR: Agent 2 (docs-structure-analyzer) failed to create report: $REPORT_PATH_2"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ CLAUDE.md analysis: $REPORT_PATH_1"
echo "✓ Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Stage 2: Planning (sequential synthesis)"
echo "  → Agent 3: Generating cleanup implementation plan"
echo ""
```

### Phase 2.4: STAGE 2 - Sequential Planning Invocation

**EXECUTE NOW**: USE the Task tool to invoke planning agent:

```
Task {
  subagent_type: "general-purpose"
  description: "Generate cleanup plan from research reports"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/cleanup-plan-architect.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - PLAN_PATH: ${PLAN_PATH}
    - THRESHOLD: ${THRESHOLD_VALUE}
    - PROJECT_DIR: ${PROJECT_DIR}

    **CRITICAL**: Create plan file at EXACT path provided above.

    **Task**:
    1. Read both research reports
    2. Synthesize findings
    3. Generate /implement-compatible plan with:
       - CLAUDE.md optimization phases
       - Documentation improvement phases
       - Verification and rollback procedures

    Expected Output:
    - Implementation plan file created at PLAN_PATH
    - Completion signal: PLAN_CREATED: [exact absolute path]
  "
}
```

### Phase 2.5: Plan Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying implementation plan..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Agent 3 (cleanup-plan-architect) failed to create plan: $PLAN_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Implementation plan: $PLAN_PATH"
```

### Phase 2.6: User Choice

```bash
# Display plan summary
echo ""
echo "=== Cleanup Plan Generated ==="

# Extract summary from plan (basic grep)
PLAN_PHASES=$(grep -c "^## Phase" "$PLAN_PATH" || echo "Unknown")
EXTRACTION_COUNT=$(grep -c "Extract.*Section" "$PLAN_PATH" || echo "Unknown")

echo "Plan phases: $PLAN_PHASES"
echo "Section extractions: $EXTRACTION_COUNT"
echo ""
echo "Research Reports:"
echo "  1. CLAUDE.md analysis: $REPORT_PATH_1"
echo "  2. Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Implementation Plan:"
echo "  → $PLAN_PATH"
echo ""
echo "Options:"
echo "  1. Review plan (display paths, no changes)"
echo "  2. Implement now (run /implement with this plan)"
echo "  3. Cancel (exit)"
echo ""

read -p "Choose [1/2/3]: " CHOICE

case "$CHOICE" in
  1|review)
    echo ""
    echo "=== Review Mode ==="
    echo "Plan saved to: $PLAN_PATH"
    echo "Reports saved to:"
    echo "  - $REPORT_PATH_1"
    echo "  - $REPORT_PATH_2"
    echo ""
    echo "To implement later, run:"
    echo "  /implement $PLAN_PATH"
    exit 0
    ;;
  2|implement)
    echo ""
    echo "=== Implement Mode ==="
    echo "Proceeding with implementation..."
    echo ""
    echo "Run: /implement $PLAN_PATH"
    # Note: Full /implement invocation requires SlashCommand tool
    # For now, display command for manual execution
    exit 0
    ;;
  3|cancel)
    echo ""
    echo "=== Cancelled ==="
    echo "Cleanup cancelled. Artifacts saved for later:"
    echo "  - $PLAN_PATH"
    echo "  - $REPORT_PATH_1"
    echo "  - $REPORT_PATH_2"
    exit 0
    ;;
  *)
    echo ""
    echo "Invalid choice. Artifacts saved to:"
    echo "  - $PLAN_PATH"
    echo "  - $REPORT_PATH_1"
    echo "  - $REPORT_PATH_2"
    exit 1
    ;;
esac
```
```

**Testing**:
```bash
# Test agent invocation from /setup
cd /home/benjamin/.config
/setup --cleanup

# Verify no errors in agent execution
# Verify plan file created in specs/setup_cleanup_*/reports/
# Verify plan has proper structure

# Test with different thresholds
/setup --cleanup --threshold aggressive
/setup --cleanup --threshold conservative

# Test dry-run mode
/setup --cleanup --dry-run
```

**Acceptance Criteria**:
- Phase 2 invokes agent using Task tool with behavioral injection
- All required paths passed as absolute paths
- Verification checkpoint catches missing plan files
- Error messages are clear and actionable
- Backward compatibility maintained (optimize-claude-md.sh still exists)

---

### Phase 3: Add User Choice Workflow

**Objective**: Let user review plan before implementation or proceed automatically

**Complexity**: Low

**Files**:
- `.claude/commands/setup.md` (extend Phase 2, after verification checkpoint)

**Tasks**:
- [ ] Add bash block: Display plan summary (sections to extract, estimated reduction)
- [ ] Add prompt: "Review plan or implement now? [review/implement/cancel]"
- [ ] Add conditional: If "review" → display plan path and exit
- [ ] Add conditional: If "implement" → invoke /implement with plan path
- [ ] Add conditional: If "cancel" → exit gracefully
- [ ] Handle invalid input (re-prompt or default to review)
- [ ] Add documentation comment explaining choice workflow

**Implementation Pattern**:
```bash
# After verification checkpoint in Phase 2

# Display plan summary
echo ""
echo "=== Cleanup Plan Summary ==="
SECTIONS_TO_EXTRACT=$(grep -c "^## Phase 2:" "$REPORT_PATH" || echo "0")
PROJECTED_REDUCTION=$(grep "Projected Reduction:" "$REPORT_PATH" | cut -d: -f2 || echo "Unknown")

echo "Sections to extract: $SECTIONS_TO_EXTRACT"
echo "Projected reduction: $PROJECTED_REDUCTION"
echo "Plan location: $REPORT_PATH"
echo ""
echo "Options:"
echo "  1. Review plan (opens plan file, no changes)"
echo "  2. Implement now (runs /implement with this plan)"
echo "  3. Cancel (exit)"
echo ""
read -p "Choose [1/2/3]: " CHOICE

case "$CHOICE" in
  1|review)
    echo "Plan saved to: $REPORT_PATH"
    echo "Review the plan and run: /implement $REPORT_PATH"
    exit 0
    ;;
  2|implement)
    echo "Proceeding with implementation..."
    # Note: This requires SlashCommand invocation
    # For now, just display the command
    echo "Run: /implement $REPORT_PATH"
    exit 0
    ;;
  3|cancel)
    echo "Cleanup cancelled. Plan saved for later: $REPORT_PATH"
    exit 0
    ;;
  *)
    echo "Invalid choice. Plan saved to: $REPORT_PATH"
    exit 1
    ;;
esac
```

**Testing**:
```bash
# Test user choice workflow
/setup --cleanup
# Choose option 1 (review) - verify path displayed, no implementation
# Choose option 2 (implement) - verify /implement command displayed
# Choose option 3 (cancel) - verify graceful exit
# Provide invalid input - verify error handling
```

**Acceptance Criteria**:
- User sees clear options after plan generation
- Option 1 displays plan path and exits cleanly
- Option 2 provides /implement command (or invokes it if SlashCommand available)
- Option 3 exits gracefully
- Invalid input handled appropriately

**Note**: Full /implement invocation from /setup requires SlashCommand tool availability. Initial implementation can display the command for user to run manually.

---

### Phase 4: Testing and Validation

**Objective**: Comprehensive testing of agent, command modifications, and user workflow

**Complexity**: Medium

**Files**:
- `.claude/tests/test_cleanup_optimizer_agent.sh` (new)
- `.claude/tests/test_setup_cleanup_integration.sh` (new)

**Tasks**:
- [ ] Create unit tests for cleanup-optimizer agent
- [ ] Test agent with various CLAUDE.md sizes (small, medium, large)
- [ ] Test agent with different threshold values (aggressive, balanced, conservative)
- [ ] Test agent error handling (missing inputs, invalid paths)
- [ ] Test /setup --cleanup integration (agent invocation)
- [ ] Test verification checkpoint catches missing plan files
- [ ] Test user choice workflow (all three options)
- [ ] Test dry-run mode behavior
- [ ] Validate plan format compliance (/implement compatibility)
- [ ] Test rollback procedures (if implementation fails)
- [ ] Run all tests and verify 100% pass rate

**Test File Structure** (.claude/tests/test_cleanup_optimizer_agent.sh):
```bash
#!/usr/bin/env bash
# Test cleanup-optimizer agent behavioral compliance

source "$(dirname "$0")/../lib/test-framework.sh"

test_agent_file_exists() {
  local agent_file=".claude/agents/cleanup-optimizer.md"
  assert_file_exists "$agent_file" "Agent file must exist"
}

test_agent_has_frontmatter() {
  local agent_file=".claude/agents/cleanup-optimizer.md"
  assert_file_contains "$agent_file" "allowed-tools:" "Must have allowed-tools"
  assert_file_contains "$agent_file" "model:" "Must have model selection"
}

test_agent_creates_plan_file() {
  # Create test environment
  local test_claude_md="/tmp/test_claude.md"
  local test_report="/tmp/test_cleanup_plan.md"

  # Create minimal CLAUDE.md
  cat > "$test_claude_md" << 'EOF'
# Project Configuration

## Code Standards
[50 lines of content...]

## Very Large Section
[150 lines of bloated content...]
EOF

  # Invoke agent (behavioral injection pattern)
  # ... (detailed invocation)

  # Verify plan created
  assert_file_exists "$test_report" "Plan file must be created"
  assert_file_contains "$test_report" "^## Phase" "Must have phases"
}

run_all_tests
```

**Testing**:
```bash
# Run agent tests
.claude/tests/test_cleanup_optimizer_agent.sh

# Run integration tests
.claude/tests/test_setup_cleanup_integration.sh

# Run full test suite
./run_all_tests.sh | grep cleanup
```

**Acceptance Criteria**:
- All new tests pass (100% success rate)
- Agent behavioral compliance verified
- /setup integration verified
- User workflow tested end-to-end
- Error handling validated
- No regressions in existing /setup modes

---

### Phase 5: Documentation

**Objective**: Update all relevant documentation for new cleanup workflow

**Complexity**: Low

**Files**:
- `.claude/docs/guides/setup-command-guide.md` (update)
- `.claude/docs/reference/agent-reference.md` (update)
- `.claude/agents/cleanup-optimizer.md` (ensure self-documenting)
- `.claude/commands/setup.md` (inline comments)

**Tasks**:
- [ ] Update setup-command-guide.md with new cleanup workflow
- [ ] Add cleanup-optimizer to agent-reference.md catalog
- [ ] Document user choice workflow (review vs implement)
- [ ] Add examples of cleanup plans generated
- [ ] Document threshold options (aggressive/balanced/conservative)
- [ ] Add troubleshooting section for common issues
- [ ] Update CLAUDE.md quick reference if needed
- [ ] Add architecture diagram for agent-based cleanup
- [ ] Cross-link related documentation

**Documentation Additions** (setup-command-guide.md):

```markdown
### Cleanup Mode (`--cleanup`)

**Enhanced with Agent-Based Optimization**

The cleanup mode now delegates to a specialized `cleanup-optimizer` agent that:

1. **Analyzes** CLAUDE.md section structure and line counts
2. **Discovers** existing .claude/docs/ organization
3. **Identifies** bloat using configurable thresholds
4. **Proposes** systematic refactoring with extraction targets
5. **Generates** implementation-ready plan

#### Usage

```bash
# Default (balanced threshold)
/setup --cleanup

# Aggressive optimization (50+ line sections)
/setup --cleanup --threshold aggressive

# Conservative optimization (120+ line sections)
/setup --cleanup --threshold conservative

# Dry-run (analysis only, no plan generation)
/setup --cleanup --dry-run
```

#### Workflow

```
┌────────────────────────────────┐
│ /setup --cleanup               │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ cleanup-optimizer agent        │
│ • Analyzes CLAUDE.md           │
│ • Discovers .claude/docs/      │
│ • Generates refactoring plan   │
└───────────┬────────────────────┘
            │
            ▼
┌────────────────────────────────┐
│ User Choice                    │
│ 1. Review plan                 │
│ 2. Implement now               │
│ 3. Cancel                      │
└────────────────────────────────┘
```

#### Plan Format

The agent generates /implement-compatible plans with:

- **Phase 1**: Backup and preparation
- **Phase 2-N**: Section extraction (one per bloated section)
- **Phase N+1**: Verification and rollback procedures

Example extraction phase:

```markdown
## Phase 2: Extract "Hierarchical Agent Architecture" Section

**Objective**: Move 93-line section to .claude/docs/concepts/

Tasks:
- [ ] Extract lines 612-706 from CLAUDE.md
- [ ] Create .claude/docs/concepts/hierarchical-agents.md
- [ ] Replace with 10-line summary + reference link
- [ ] Validate all internal links resolve
- [ ] Update cross-references in related docs
```

#### Troubleshooting

**Issue**: Agent fails to create plan file
- **Cause**: Missing report directory
- **Solution**: Agent should create directories lazily; check error output

**Issue**: Plan has no extraction targets
- **Cause**: No sections exceed threshold
- **Solution**: Use `--threshold aggressive` or CLAUDE.md already optimal

**Issue**: User choice prompt not appearing
- **Cause**: Non-interactive shell or I/O redirection
- **Solution**: Run in interactive terminal or check plan manually
```

**Testing**:
```bash
# Verify documentation links resolve
.claude/scripts/validate-links-quick.sh

# Check for broken cross-references
grep -r "cleanup-optimizer" .claude/docs/ | grep -v ".md:"
```

**Acceptance Criteria**:
- setup-command-guide.md has complete cleanup mode section
- agent-reference.md lists cleanup-optimizer with capabilities
- All documentation links validate successfully
- Examples are clear and accurate
- Troubleshooting covers common issues

---

### Phase 6: Integration and Final Validation

**Objective**: End-to-end validation and production readiness check

**Complexity**: Low

**Files**:
- All files from previous phases
- `.claude/specs/setup_cleanup_agent_enhancement/summaries/001_implementation_summary.md` (new)

**Tasks**:
- [ ] Run complete test suite (.claude/tests/run_all_tests.sh)
- [ ] Test /setup --cleanup on real CLAUDE.md file
- [ ] Verify agent creates valid refactoring plan
- [ ] Test user choice workflow (review and implement paths)
- [ ] Validate plan is /implement-compatible
- [ ] Run /setup --validate to check no regressions
- [ ] Check all documentation links resolve
- [ ] Review code against project standards (imperative language, verification checkpoints)
- [ ] Create implementation summary document
- [ ] Prepare for git commit (run tests before commit per standards)

**End-to-End Test**:
```bash
# Complete workflow test
cd /home/benjamin/.config

# 1. Run cleanup mode
/setup --cleanup

# 2. Choose "review" option
# Verify plan path displayed

# 3. Read generated plan
PLAN_PATH=$(find .claude/specs/setup_cleanup_* -name "*refactoring_plan.md" | head -1)
cat "$PLAN_PATH"

# 4. Verify plan structure
grep -c "^## Phase" "$PLAN_PATH"  # Should be ≥3 phases
grep -q "Backup and Preparation" "$PLAN_PATH"  # Should have backup phase
grep -q "Verification and Rollback" "$PLAN_PATH"  # Should have verification

# 5. Optional: Run implementation
/implement "$PLAN_PATH" --dry-run  # Test implementation dry-run

# 6. Validate no regressions
/setup --validate
```

**Implementation Summary** (001_implementation_summary.md):
```markdown
# Setup Cleanup Agent Enhancement - Implementation Summary

## Overview
Enhanced /setup --cleanup mode with intelligent agent-based CLAUDE.md optimization.

## Artifacts Created
- `.claude/agents/cleanup-optimizer.md` - Specialized cleanup agent
- `.claude/tests/test_cleanup_optimizer_agent.sh` - Agent tests
- `.claude/tests/test_setup_cleanup_integration.sh` - Integration tests

## Artifacts Modified
- `.claude/commands/setup.md` - Phase 2 enhanced with agent delegation
- `.claude/docs/guides/setup-command-guide.md` - Documentation updated

## Key Changes
1. Agent-based cleanup analysis (replaces static analyze_bloat)
2. Interactive user choice workflow (review/implement/cancel)
3. Topic-based plan generation in specs/setup_cleanup_*/
4. Threshold configuration (aggressive/balanced/conservative)
5. /implement-compatible plan format

## Testing
- Agent behavioral compliance: ✓ PASS
- /setup integration: ✓ PASS
- User workflow: ✓ PASS
- Plan format validation: ✓ PASS
- Documentation links: ✓ PASS

## Performance
- Plan generation time: ~15-30 seconds (depends on CLAUDE.md size)
- Context reduction: 99% (agent passes metadata summaries only)
- User intervention: Optional (can auto-implement or review first)

## Next Steps
- Consider adding --auto-implement flag to skip user prompt
- Explore progressive cleanup (small batches over time)
- Add metrics tracking (sections extracted, context saved)
```

**Testing**:
```bash
# Final validation checklist
./run_all_tests.sh  # All tests pass
/setup --validate  # No structural issues
/setup --cleanup  # Works end-to-end
.claude/scripts/validate-links-quick.sh  # All links valid
git status  # Review changes before commit
```

**Acceptance Criteria**:
- All tests pass (100% success rate)
- /setup --cleanup works on real CLAUDE.md
- Documentation complete and accurate
- No regressions in other /setup modes
- Code follows all project standards
- Ready for git commit and production use

---

## Testing Strategy

### Unit Tests
- Agent behavioral compliance (frontmatter, steps, verification)
- Plan generation logic (threshold detection, section mapping)
- Error handling (missing inputs, invalid paths)

### Integration Tests
- /setup --cleanup invokes agent correctly
- Agent receives all required inputs
- Verification checkpoint catches failures
- User choice workflow functions

### End-to-End Tests
- Complete cleanup workflow from invocation to plan generation
- Plan compatibility with /implement command
- Rollback procedures if implementation fails

### Regression Tests
- Existing /setup modes still work (standard, validate, analyze)
- optimize-claude-md.sh library still functional
- CLAUDE.md structure remains valid after cleanup

## Dependencies

### Required Components
- `.claude/agents/` directory (exists)
- `.claude/specs/` directory (exists)
- Task tool availability (confirmed in allowed-tools)
- Behavioral injection pattern support (confirmed)

### Required Libraries
- `.claude/lib/unified-location-detection.sh` (for directory creation)
- `.claude/lib/test-framework.sh` (for testing, if exists)

### External Commands
- `awk` (for section parsing)
- `grep` (for pattern matching)
- `find` (for file discovery)

## Risks and Mitigation

### Risk: Agent fails to create plan
- **Mitigation**: Verification checkpoint catches failure immediately
- **Fallback**: Display error and suggest manual plan creation

### Risk: Plan is not /implement-compatible
- **Mitigation**: Agent follows strict plan template from /plan standards
- **Testing**: Validate plan format in integration tests

### Risk: User chooses "implement" but /implement unavailable
- **Mitigation**: Initial implementation displays command for manual execution
- **Enhancement**: Add SlashCommand invocation in future iteration

### Risk: Extracted sections break CLAUDE.md references
- **Mitigation**: Plan includes validation phase to check all links
- **Rollback**: Backup created in Phase 1 of every plan

### Risk: Agent takes too long (large CLAUDE.md files)
- **Mitigation**: Use Sonnet model (fast, capable of analysis)
- **Optimization**: Agent reads sections incrementally, not all at once

## Notes

### Design Decisions

1. **Agent-based vs Library Function**: Chose agent delegation for:
   - Separation of concerns (analysis logic outside command)
   - Reusability (agent can be invoked by other commands)
   - Testability (agent can be tested independently)
   - Context reduction (agent summaries passed, not full analysis)

2. **Topic-based Plan Storage**: Following project standards for:
   - Artifact lifecycle management (plans in specs/)
   - Gitignore compliance (reports tracked, plans optional)
   - Discoverability (timestamped topics prevent collisions)

3. **User Choice Workflow**: Interactive prompt because:
   - Plan review often reveals unexpected extractions
   - User may want to adjust threshold before implementing
   - Fail-safe default (review) prevents accidental changes

4. **Threshold Configuration**: Three levels to support:
   - Aggressive (50+ lines): New projects, aggressive optimization
   - Balanced (80+ lines): Default, handles clear bloat
   - Conservative (120+ lines): Mature projects, minimal changes

### Future Enhancements

- **Automatic /implement invocation**: Use SlashCommand tool if available
- **Progressive cleanup**: Extract one section at a time over multiple runs
- **Metrics tracking**: Log sections extracted, context reduction achieved
- **Smart integration**: Suggest merging with existing docs vs new files
- **Cross-project patterns**: Learn common extraction patterns from history

### Standards Compliance Checklist

- [x] Imperative language (MUST/WILL/SHALL) in agent instructions
- [x] Verification checkpoints at critical steps
- [x] Fail-fast error handling (exit on missing plan)
- [x] Behavioral injection pattern for agent invocation
- [x] Absolute paths throughout (no relative paths)
- [x] Executable/documentation separation (<400 lines for agent)
- [x] Topic-based artifact organization
- [x] Test-before-commit workflow
- [x] Documentation updated (guides, references)
- [x] Self-documenting code (inline comments)

---

## Appendix: Example Agent Output

### Sample Refactoring Plan

```markdown
# CLAUDE.md Cleanup Refactoring Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: CLAUDE.md context optimization
- **Sections Analyzed**: 19
- **Extraction Targets**: 4
- **Projected Reduction**: 437 lines (45.3%)
- **Threshold**: balanced (80 lines)

## Current State
- **File**: /home/benjamin/.config/CLAUDE.md
- **Size**: 964 lines
- **Bloated Sections**: 4 (>80 lines each)
- **Target Size**: 527 lines

## Extraction Targets

1. **Code Standards** (84 lines → 15 lines)
   - Target: .claude/docs/reference/code-standards.md
   - Integration: Create new file in reference/

2. **Directory Organization Standards** (231 lines → 30 lines)
   - Target: .claude/docs/concepts/directory-organization.md
   - Integration: Merge with existing directory docs

3. **Hierarchical Agent Architecture** (93 lines → 20 lines)
   - Target: .claude/docs/concepts/hierarchical-agents.md
   - Integration: File already exists, update with CLAUDE.md content

4. **State-Based Orchestration Architecture** (108 lines → 25 lines)
   - Target: .claude/docs/architecture/state-based-orchestration-overview.md
   - Integration: File already exists, update summary link

## Implementation Phases

### Phase 1: Backup and Preparation
**Objective**: Protect against failures with backup and directory setup
**Complexity**: Low

Tasks:
- [ ] Create backup: .claude/backups/CLAUDE.md.20251114-163000
- [ ] Verify .claude/docs/reference/ exists (create if needed)
- [ ] Verify .claude/docs/concepts/ exists
- [ ] Verify .claude/docs/architecture/ exists
- [ ] Create stub files for new documents

### Phase 2: Extract "Code Standards" Section
**Objective**: Move 84-line section to reference documentation
**Complexity**: Low

Tasks:
- [ ] Extract lines 100-184 from CLAUDE.md
- [ ] Create .claude/docs/reference/code-standards.md with full content
- [ ] Add frontmatter and navigation to new file
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## Code Standards
  [Used by: /implement, /refactor, /plan]

  See [Code Standards](.claude/docs/reference/code-standards.md) for complete guidelines.

  **Summary**: 2-space indentation, ~100 char lines, snake_case naming, UTF-8 only, executable/documentation separation pattern.
  ```
- [ ] Validate link resolves: .claude/docs/reference/code-standards.md

Testing:
```bash
# Verify file created and linked
test -f .claude/docs/reference/code-standards.md
grep -q "code-standards.md" CLAUDE.md
```

### Phase 3: Extract "Directory Organization Standards" Section
**Objective**: Move 231-line section to concepts documentation
**Complexity**: Medium (largest section, multiple subsections)

Tasks:
- [ ] Extract lines 185-416 from CLAUDE.md
- [ ] Create .claude/docs/concepts/directory-organization.md
- [ ] Preserve all subsections (scripts/, lib/, utils/, commands/, agents/)
- [ ] Preserve decision matrix and anti-patterns
- [ ] Add navigation links to parent and related docs
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## Directory Organization Standards
  [Used by: /implement, /plan, /refactor, all development commands]

  See [Directory Organization Standards](.claude/docs/concepts/directory-organization.md) for complete structure and placement rules.

  **Summary**: scripts/ (standalone tools), lib/ (sourced functions), commands/ (slash commands), agents/ (behavioral files), docs/ (guides/concepts/reference). Each directory has specific characteristics and placement criteria.
  ```
- [ ] Validate link resolves
- [ ] Check cross-references to README.md files still work

Testing:
```bash
# Verify comprehensive file created
test -f .claude/docs/concepts/directory-organization.md
grep -c "^### " .claude/docs/concepts/directory-organization.md  # Should have ~6 subsections
.claude/scripts/validate-links-quick.sh  # All links valid
```

### Phase 4: Update "Hierarchical Agent Architecture" Reference
**Objective**: Replace 93-line inline section with link to existing doc
**Complexity**: Low (file already exists)

Tasks:
- [ ] Verify .claude/docs/concepts/hierarchical_agents.md exists
- [ ] Read existing file to ensure it covers CLAUDE.md content
- [ ] Extract key points from CLAUDE.md lines 612-706 not in existing doc
- [ ] Merge unique content into hierarchical_agents.md if needed
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## Hierarchical Agent Architecture
  [Used by: /orchestrate, /implement, /plan, /debug]

  See [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical_agents.md) for complete documentation.

  **Summary**: Multi-level agent coordination with metadata-based context passing (99% reduction), recursive supervision, forward message pattern, and aggressive context pruning. Target: <30% context usage throughout workflows.
  ```
- [ ] Validate link resolves

Testing:
```bash
# Verify existing file has all necessary content
grep -q "Metadata Extraction" .claude/docs/concepts/hierarchical_agents.md
grep -q "Forward Message Pattern" .claude/docs/concepts/hierarchical_agents.md
```

### Phase 5: Update "State-Based Orchestration Architecture" Reference
**Objective**: Replace 108-line inline section with link to existing doc
**Complexity**: Low (file already exists)

Tasks:
- [ ] Verify .claude/docs/architecture/state-based-orchestration-overview.md exists
- [ ] Read existing file to ensure comprehensive coverage
- [ ] Extract key points from CLAUDE.md lines 706-814 not in existing doc
- [ ] Merge unique content if needed
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## State-Based Orchestration Architecture
  [Used by: /coordinate, /orchestrate, /supervise, custom orchestrators]

  See [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) for complete architecture.

  **Summary**: Explicit state machines with validated transitions for multi-phase workflows. 8 states, atomic transitions, checkpoint coordination, 48.9% code reduction across orchestrators, 100% file creation reliability.
  ```
- [ ] Validate link resolves

Testing:
```bash
# Verify existing file comprehensive
test -f .claude/docs/architecture/state-based-orchestration-overview.md
grep -q "State Machine Library" .claude/docs/architecture/state-based-orchestration-overview.md
```

### Phase 6: Verification and Validation
**Objective**: Ensure all changes work correctly and no breakage
**Complexity**: Low

Tasks:
- [ ] Run /setup --validate (check CLAUDE.md structure)
- [ ] Run .claude/scripts/validate-links-quick.sh (all links resolve)
- [ ] Verify all [Used by: ...] metadata intact
- [ ] Check CLAUDE.md size reduced to ~527 lines
- [ ] Test command discovery still works (/plan, /implement, etc.)
- [ ] Grep for broken section references in .claude/commands/
- [ ] If any validation fails: ROLLBACK using backup

Testing:
```bash
# Comprehensive validation
/setup --validate
.claude/scripts/validate-links-quick.sh
wc -l CLAUDE.md  # Should be ~527 lines

# Check command references still work
grep -r "Code Standards" .claude/commands/ | grep -v ".md:.*http"  # Should find [Used by: ...] metadata

# If failures detected:
# cp .claude/backups/CLAUDE.md.20251114-163000 CLAUDE.md
```

## Rollback Procedure

If any phase fails or validation errors occur:

```bash
# Restore from backup
BACKUP_FILE=".claude/backups/CLAUDE.md.20251114-163000"
cp "$BACKUP_FILE" CLAUDE.md

# Verify restoration
wc -l CLAUDE.md  # Should be 964 lines
/setup --validate  # Should pass

# Remove incomplete extracted files (optional)
rm -f .claude/docs/reference/code-standards.md  # If created but incomplete
rm -f .claude/docs/concepts/directory-organization.md  # If created but incomplete
```

## Success Metrics

- [x] CLAUDE.md reduced from 964 to ~527 lines (45.3% reduction)
- [x] All 4 bloated sections extracted to appropriate docs/
- [x] All internal links validate successfully
- [x] All command metadata references intact
- [x] /setup --validate passes
- [x] Backup created and restoration tested
```

---

This plan is ready for `/implement` execution or manual implementation following the phased approach.
