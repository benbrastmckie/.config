# Bloat Analyzer Architecture Research Report

## Metadata
- **Date**: 2025-11-14
- **Research Topic**: Bloat Analyzer Architecture
- **Researcher**: research-specialist
- **Complexity**: 4
- **Focus**: Integration patterns, report structure, parallel execution coordination

## Executive Summary

The bloat analyzer is a specialized Opus 4.5 agent that performs semantic documentation bloat analysis as part of the /optimize-claude workflow. It operates as the third agent in a 4-agent pipeline (claude-md-analyzer → docs-structure-analyzer → docs-bloat-analyzer → cleanup-plan-architect), receiving two research reports as input and producing a comprehensive bloat analysis report with size validation tasks. The analyzer uses semantic understanding (not just line counting) to detect content overlap, consolidation opportunities, and extraction risks, enforcing a 400-line bloat threshold with critical threshold at 800 lines. Its report structure includes 9 major sections providing bloated file inventories, extraction risk assessments, consolidation opportunities, split recommendations, and mandatory size validation tasks for implementation plan integration.

## Bloat Analyzer Role in /optimize-claude Workflow

### 4-Agent Pipeline Architecture

The /optimize-claude command implements a sequential 4-agent workflow:

```
Phase 1: Parallel Research (2 agents)
  ├─ Agent 1: claude-md-analyzer
  │   Input: CLAUDE.md file path, threshold
  │   Output: Section analysis report with bloat flags
  │
  └─ Agent 2: docs-structure-analyzer
      Input: .claude/docs/ directory
      Output: Directory tree, integration points, gaps

Phase 2: Bloat Analysis (1 agent)
  └─ Agent 3: docs-bloat-analyzer (Opus 4.5)
      Input: Both research reports from Phase 1
      Output: Bloat analysis report with validation tasks

Phase 3: Planning (1 agent)
  └─ Agent 4: cleanup-plan-architect
      Input: All three reports (CLAUDE.md, docs, bloat)
      Output: /implement-compatible plan with phases
```

### Integration Points

**Input Dependencies**:
- Receives CLAUDE_MD_REPORT_PATH (from claude-md-analyzer)
- Receives DOCS_REPORT_PATH (from docs-structure-analyzer)
- Receives BLOAT_REPORT_PATH (target path for output)

**Output Dependencies**:
- Provides bloat analysis to cleanup-plan-architect
- cleanup-plan-architect uses bloat report to:
  - Flag high-risk extractions requiring size validation
  - Generate size validation tasks per extraction phase
  - Create bloat rollback procedures
  - Enforce bloat thresholds in implementation plan

**Verification Checkpoint**:
- /optimize-claude Phase 5 verifies bloat report created
- Fail-fast if file not created (critical failure)
- Pattern: Mandatory verification checkpoints after each agent

### Workflow State Machine Integration

The bloat analyzer operates within the state-based orchestration framework:

**State Context**:
- Current State: `research` (Phase 1 research completion)
- Next State: `plan` (Phase 3 planning)
- Terminal State: `plan` (research-and-plan workflow scope)

**State Persistence**:
- Bloat report path saved to workflow state
- Enables checkpoint recovery if workflow interrupted
- State machine coordinates agent sequencing

## Bloat Analyzer Behavioral Specification

### Model Selection (Opus 4.5)

**Justification** (from agent frontmatter):
> "High-quality semantic understanding required for nuanced bloat detection, consolidation opportunities, and context-aware size recommendations"

**Why Opus**:
- Semantic duplication detection (same concepts, different wording)
- Topic relationship understanding for consolidation
- Context-aware split/merge decisions
- Better judgment than line-counting heuristics

**Fallback Model**: Sonnet 4.5 (if Opus unavailable)

### Execution Process (6-Step Sequential)

**STEP 1: Receive and Verify Input Paths**
- Validate 3 absolute paths received (CLAUDE_MD_REPORT_PATH, DOCS_REPORT_PATH, BLOAT_REPORT_PATH)
- Verify reports exist (fail-fast if missing)
- Echo verification status
- **Checkpoint**: Paths validated before proceeding

**STEP 1.5: Ensure Parent Directory Exists**
- Source unified-location-detection.sh library
- Call `ensure_artifact_directory()` for lazy directory creation
- **Critical**: Directory must exist before file creation
- **Checkpoint**: Parent directory ready

**STEP 2: Create Bloat Report File FIRST**
- Create file with initial template structure
- Use Write tool at exact BLOAT_REPORT_PATH
- **WHY THIS MATTERS**: Guarantees artifact creation even if analysis fails
- Template includes all 9 section placeholders
- **Checkpoint**: File exists before analysis starts

**STEP 3: Read Both Research Reports**
- Read CLAUDE_MD_REPORT_PATH (section analysis, bloat flags)
- Read DOCS_REPORT_PATH (directory tree, target files)
- Extract key findings for synthesis
- **Checkpoint**: Reports read before analysis

**STEP 4: Perform Semantic Bloat Analysis**
- Scan docs for files >400 lines (bloated) and >800 lines (critical)
- Assess extraction risks (projected post-merge sizes)
- Identify consolidation opportunities (>40% overlap)
- Recommend splits for critical files
- Generate size validation tasks
- Update report sections via Edit tool
- **Checkpoint**: All placeholders replaced with analysis

**STEP 5: Verification Checkpoint**
- Verify report file exists
- Verify file >1000 bytes (not just template)
- Verify no "TO BE ANALYZED IN STEP 4" placeholders remain
- **Checkpoint**: Analysis complete and verified

**STEP 6: Completion Signal**
- Echo "REPORT_CREATED: $BLOAT_REPORT_PATH"
- **Critical**: Completion signal must be final output
- No text after signal (orchestrator parses this)

### Fail-Fast Error Handling

**Execution Enforcement Pattern**:
- Each step has explicit checkpoint
- DO NOT proceed to next step if current step fails
- Echo clear error message with step number
- Exit with non-zero status
- **Graceful Degradation**: Report file exists even if incomplete

**Error Scenarios**:
- Missing input reports → Fail at Step 1
- Directory creation failure → Fail at Step 1.5
- File creation failure → Fail at Step 2
- Report read failure → Fail at Step 3
- Placeholder text remains → Fail at Step 5

## Report Structure (9 Major Sections)

### 1. Metadata Section

**Purpose**: Attribution and input tracking

**Contents**:
- Date
- Analyzer (docs-bloat-analyzer, Opus 4.5)
- Input Reports (absolute paths to CLAUDE.md and docs reports)

### 2. Executive Summary

**Purpose**: 2-3 sentence overview of key findings

**Contents**:
- Number of extraction candidates
- Bloat risk assessment
- Critical bloat cases requiring immediate action
- High-level recommendations

### 3. Current Bloat State

**Purpose**: Inventory of existing bloated files

**Subsection 3.1: Bloated Files (>400 lines)**
- Table format: File Path, Current Size, Severity, Bloat Factor, Recommendation
- Severity levels: BLOATED (400-800 lines), CRITICAL (>800 lines)
- Bloat factor calculation: `(lines - 400) * 100 / 400` (percentage over threshold)

**Subsection 3.2: Critical Files (>800 lines)**
- Detailed analysis per critical file
- Current location, issue description
- Recommended N-way split strategy
- Projected post-split sizes
- Cross-reference update requirements

**Example Output** (from spec 711 bloat analysis):
```markdown
| File Path | Current Size | Severity | Bloat Factor | Recommendation |
|-----------|--------------|----------|--------------|----------------|
| .claude/docs/guides/command-development-guide.md | 3,980 lines | **CRITICAL** | 995% over threshold | Split into 4 specialized guides |
| .claude/docs/guides/coordinate-command-guide.md | 567 lines | BLOATED | 42% over threshold | Split into 2 files (architecture + usage) |
```

### 4. Extraction Risk Analysis

**Purpose**: Assess bloat risk for proposed CLAUDE.md extractions

**Subsection 4.1: High-Risk Extractions (projected bloat)**
- Table: Extraction, Source Section, Target File, Current Size, Projected Size, Risk Level
- Risk levels: LOW (<350 projected), MEDIUM (350-400), HIGH (>400)
- **NONE IDENTIFIED** if all extractions safe

**Subsection 4.2: Safe Extractions**
- Per-extraction risk analysis
- Extraction size calculation
- Target file current size
- Projected post-merge size
- Strategy recommendation (CREATE new vs MERGE vs LINK-ONLY)

**Example Risk Calculations**:
```
Code Standards → reference/code-standards.md (LOW RISK)
  Extraction Size: 84 lines
  Target Status: New file (does not exist)
  Projected Size: 84 lines
  Bloat Risk: None (well below 400-line threshold)
  Strategy: Direct extraction with summary in CLAUDE.md

State-Based Orchestration → state-based-orchestration-overview.md (ZERO RISK)
  Extraction Size: 108 lines (but NOT extracting)
  Target Status: File exists (2,000+ lines)
  Projected Size: N/A (no merge planned)
  Bloat Risk: Zero (using link-only strategy)
  Strategy: Replace CLAUDE.md section with 5-10 line summary + link
```

### 5. Consolidation Opportunities

**Purpose**: Identify merge candidates based on semantic overlap

**Subsection 5.1: High-Value Consolidations**
- Files with >40% content overlap
- Navigation redundancy detection
- Duplicate architectural explanations
- **ONLY recommend if combined size ≤400 lines**

**Subsection 5.2: Merge Analysis**
- Merge risk matrix table
- Pre-merge size checks required
- Overlap percentage estimation
- Projected merge size calculation

**Merge Guidelines** (from bloat analyzer):
1. Pre-merge size check (mandatory if target >350 lines)
2. Overlap detection (read both files, identify duplicates)
3. Post-merge validation (verify <400 lines)
4. Bloat prevention (DO NOT MERGE if projected >400 lines)

**Example Output**:
```markdown
development-workflow.md Duplication (MEDIUM PRIORITY)
  Issue: Two files exist with same name in different directories
  Recommended Strategy:
    1. Read both files to assess overlap
    2. If >60% overlap: Merge into workflows/development-workflow.md
    3. If <60% overlap: Rename for clarity
```

### 6. Split Recommendations

**Purpose**: Provide split strategies for bloated files

**Subsection 6.1: Critical Splits (>800 lines)**
- Immediate action required
- N-way split plans with logical boundaries
- Projected post-split sizes (all <400 lines)
- Cross-reference update requirements
- Post-split verification procedures

**Subsection 6.2: Suggested Splits (400-600 lines)**
- Non-critical but beneficial
- 2-way split patterns (architecture + usage)
- Accept-as-is criteria for near-threshold files (within 10%)

**Example Split Plan**:
```markdown
command-development-guide.md (3,980 lines) - 4-WAY SPLIT
  1. command-development-basics.md (600-800 lines)
  2. command-architecture-patterns.md (800-1,000 lines)
  3. command-template-guide.md (500-700 lines)
  4. command-troubleshooting-reference.md (1,800-2,000 lines)

Split Strategy:
  - Create 4 new files with content distribution
  - Add navigation links between sections
  - Update main guides/README.md
  - Create index landing page
  - Archive original file
  - Update all references
```

### 7. Size Validation Tasks

**Purpose**: Generate implementation plan integration tasks

**4 Phase Structure**:

**Phase 1: Pre-Extraction Validation**
- Baseline size inventory (record current sizes)
- Verify target files don't exist (for new creations)
- Bash validation scripts provided

**Phase 2: Per-Extraction Size Validation**
- One task per extraction candidate
- Pre-merge size checks (before merging)
- Post-creation size checks (after creating)
- Projected size calculations
- Bloat rollback triggers (if threshold exceeded)

**Phase 3: Post-Extraction Validation**
- CLAUDE.md reduction verification (target ± tolerance)
- No new bloated files created audit
- Automated rollback procedure script

**Phase 4: Final Verification**
- Comprehensive bloat audit (scan all .claude/docs/)
- Bloat metrics report generation
- Before/after comparison

**Example Validation Task**:
```bash
# Task 2.1: Code Standards Extraction Size Check
lines=$(wc -l < .claude/docs/reference/code-standards.md)
echo "code-standards.md: $lines lines"

if (( lines > 400 )); then
  echo "BLOAT ALERT: code-standards.md exceeds 400 lines ($lines)"
  exit 1
elif (( lines > 100 )); then
  echo "WARNING: Larger than expected ($lines lines, expected ~84)"
fi

echo "✓ PASSED: code-standards.md within threshold"
```

### 8. Bloat Prevention Guidance

**Purpose**: Instructions for cleanup-plan-architect agent

**7 Subsections**:

1. **Mandatory Size Validation Tasks**
   - Every extraction phase requires pre/post validation
   - Template for extraction task structure
   - Rollback procedure automation

2. **Hierarchical Agents Merge Decision**
   - Conditional merge logic (if projected <400: merge, else: cross-reference only)
   - Two-branch plan requirement (Branch A: merge, Branch B: keep separate)

3. **State-Based Orchestration Link-Only Strategy**
   - Mandate: NO content extraction, ONLY link replacement
   - 5-10 line summary requirements
   - Verification: target file size unchanged

4. **Bloat Threshold Enforcement**
   - Hard limits: 400 lines (warning), 350 lines (merge target), 800 lines (critical)
   - Fail-fast enforcement script

5. **Split Task Prioritization**
   - Phase priority (critical >800 first, defer moderate 400-600)
   - Rationale: Address critical bloat first, avoid scope creep

6. **Cross-Reference Update Requirements**
   - MUST update after each extraction
   - Link validation mandatory

7. **Final Bloat Audit Phase**
   - Mandatory final phase in implementation plan
   - Success criteria: CLAUDE.md target range, zero new bloated files

### 9. Completion Signal

**Final Line**:
```
REPORT_CREATED: /absolute/path/to/bloat_analysis.md
```

**Critical Requirements**:
- Must be exact absolute path
- Must be final line in report
- No text after this signal
- Orchestrator parses this for verification

## Semantic Analysis Guidelines

### Why Semantic Analysis?

**Traditional Approach** (rejected):
- Line counting only
- Regex pattern matching
- Mechanical file size thresholds
- No understanding of content meaning

**Semantic Approach** (implemented):
- Nuanced detection of content overlap (not just identical text)
- Semantic consolidation opportunities (understands topic relationships)
- Context-aware size recommendations (considers documentation purpose)
- Better judgment for split/merge decisions

### Consolidation Detection Techniques

**Semantic Duplication**:
- Same concepts explained differently (paraphrase detection)
- Identifies navigation boilerplate (repeated link sections)
- Detects architectural redundancy (same patterns documented multiple times)
- Considers content purpose (guides vs references vs tutorials)

**Example**:
```
File A: "State machines provide explicit states and validated transitions"
File B: "Using state-based orchestration ensures transitions are validated"
→ Detected as semantic overlap despite different wording
```

### Split Decision Criteria

**Logical Topic Boundaries**:
- Don't split mid-concept
- Identify natural section breaks
- Preserve conceptual cohesion

**Independent Readability**:
- Each split file must be self-contained
- Minimal forward/backward references
- Complete context within file

**Size Balance**:
- Avoid uneven splits (e.g., 900 lines + 100 lines)
- Target similar sizes across split files
- All splits below 400-line threshold

**Cross-Reference Minimization**:
- Reduce interdependencies between split files
- Self-contained sections preferred
- Navigation links acceptable, content dependencies not

### Bloat Prevention Philosophy

**Prevention > Remediation**:
- Stop bloat before creation (not after)
- Size validation in every extraction task
- Rollback procedures for bloat-inducing merges
- Final verification phase catches accumulated bloat

**Fail-Fast Enforcement**:
- Hard threshold at 400 lines
- Immediate rollback if exceeded
- No "we'll fix it later" approach

**Continuous Monitoring**:
- Baseline size inventory
- Per-extraction validation
- Post-extraction audit
- Final comprehensive scan

## Parallel Execution Coordination

### Sequential Within Orchestration

**Bloat Analyzer Position**: Sequential (not parallel)
- Runs AFTER both research agents complete
- Runs BEFORE planning agent starts
- Phase 2 of 3 in /optimize-claude workflow

**Rationale**:
- Requires both research reports as input (dependency)
- Planning agent requires bloat report (downstream dependency)
- No parallelization opportunity (linear dependency chain)

### Parallel Research Pattern (Phase 1)

**Two Agents in Parallel**:
```
/optimize-claude Phase 2: Parallel Research Invocation

Task {
  description: "Analyze CLAUDE.md structure"
  agent: claude-md-analyzer
  output: REPORT_PATH_1
}

Task {
  description: "Analyze .claude/docs/ structure"
  agent: docs-structure-analyzer
  output: REPORT_PATH_2
}
```

**Coordination Mechanism**:
- Single bash block invokes both agents
- Task tool supports parallel execution
- Both must complete before Phase 3 (verification checkpoint)
- Fail-fast if either agent fails to create report

**Verification Checkpoint**:
```bash
if [ ! -f "$REPORT_PATH_1" ]; then
  echo "ERROR: Agent 1 failed to create report"
  exit 1
fi

if [ ! -f "$REPORT_PATH_2" ]; then
  echo "ERROR: Agent 2 failed to create report"
  exit 1
fi
```

### Verification and Fallback Pattern

**Mandatory Verification Checkpoints**:
- After Phase 2 (parallel research): Verify both reports created
- After Phase 4 (bloat analysis): Verify bloat report created
- After Phase 6 (planning): Verify plan created

**Fail-Fast Pattern**:
```bash
# Phase 5: Bloat Analysis Verification Checkpoint

if [ ! -f "$REPORT_PATH_3" ]; then
  echo "ERROR: Agent 3 (docs-bloat-analyzer) failed to create report: $REPORT_PATH_3"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Bloat analysis: $REPORT_PATH_3"
```

**No Silent Fallbacks**:
- Missing reports cause immediate failure
- No "continue anyway" logic
- Clear diagnostic messages
- Agent logs available for debugging

### Context Reduction via Metadata Extraction

**Bloat Analyzer Output**:
- Full report: 754 lines (from spec 711 example)
- Orchestrator extracts metadata only
- Metadata: Title, 50-word summary, key findings
- 99% context reduction (754 lines → ~8 lines metadata)

**Metadata Passed to Planning Agent**:
```
Bloat Analysis Summary:
  - 4 extraction candidates (437 total lines)
  - 1 high-risk extraction identified
  - 2 critical files require immediate split (>800 lines)
  - Size validation tasks generated for implementation plan
```

**Benefits**:
- Planning agent receives findings without full report
- Avoids context window bloat
- Planning agent reads full report only if needed
- Hierarchical information disclosure

## Integration with State Machine Library

### State Transitions

**Bloat Analyzer Context**:
- Operates during `research` state (Phase 1)
- State machine coordinates agent sequencing
- No direct state machine calls within agent

**Workflow State Machine**:
```
initialize → research → plan → complete
                 ↑ Bloat analyzer executes here
```

**State Persistence**:
- Workflow ID saved to state file
- Report paths saved to state
- Enables checkpoint recovery if interrupted

### Checkpoint Coordination

**State Machine Integration**:
- sm_transition() called by orchestrator (not agent)
- Agent completion triggers state transition
- Checkpoint saved after bloat analysis completes

**Checkpoint Schema V2.0**:
```json
{
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize", "research"]
  },
  "phase_data": {
    "report_path_3": "/path/to/bloat_analysis.md"
  }
}
```

### Error State Tracking

**Agent Failure Handling**:
- If bloat analyzer fails: ERROR state recorded
- Retry logic: Maximum 2 retries per state
- If retries exhausted: Escalate to user
- State machine tracks retry counter

**Error Recovery**:
```bash
# workflow-state-machine.sh integration
if ! verify_report_created "$REPORT_PATH_3"; then
  increment_retry_counter "research"
  if (( retry_count >= 2 )); then
    echo "ERROR: Maximum retries exceeded for bloat analyzer"
    sm_transition "error"
    exit 1
  fi
fi
```

## Performance Characteristics

### Execution Time

**Bloat Analysis Phase**: 5-10 seconds
- Opus 4.5 semantic analysis
- File size calculations
- Report generation
- Dependent on number of documentation files

**Total /optimize-claude Workflow**: 15-30 seconds
- Research stage: 10-20 seconds (parallel agents)
- Bloat analysis: 5-10 seconds (this agent)
- Planning stage: 5-10 seconds (cleanup-plan-architect)

### Context Consumption

**Agent Context Usage**:
- Input: 2 research reports (~4-10 KB combined)
- Output: Bloat analysis report (~5-15 KB)
- Metadata extracted by orchestrator: ~50-100 tokens

**Context Reduction**:
- Full report: 5,000-15,000 tokens
- Metadata summary: 50-100 tokens
- 99% reduction for downstream planning agent

### Report Size

**Typical Output**:
- Bloat analysis report: 750-1,000 lines
- 9 major sections with tables, code blocks, guidelines
- Example from spec 711: 754 lines
- Storage: ~15-30 KB per report

## Anti-Patterns and Lessons Learned

### Anti-Pattern 1: Line Counting Without Semantic Analysis

**Problem**: Early implementations used simple line counting
**Issue**: Missed semantic duplication, poor split boundaries
**Solution**: Opus 4.5 for semantic understanding

**Before** (mechanical):
```bash
if (( lines > 400 )); then
  echo "File bloated, split recommended"
fi
```

**After** (semantic):
```
Analyze content purpose, topic boundaries, overlap
Consider documentation type (guide vs reference vs tutorial)
Recommend splits based on logical boundaries
Detect semantic duplication across files
```

### Anti-Pattern 2: Creating Report After Analysis

**Problem**: Analysis errors prevented report creation
**Issue**: No artifact to debug failures
**Solution**: Create report file FIRST (Step 2), then analyze (Step 4)

**Current Pattern**:
1. Create report with template structure
2. Verify file exists
3. Perform analysis
4. Update template sections via Edit tool
5. **Result**: Report exists even if analysis fails

**Benefits**:
- Artifact always created (guaranteed)
- Partial analysis visible if error occurs
- Easier debugging (see what step failed)

### Anti-Pattern 3: No Bloat Threshold Enforcement

**Problem**: Extractions created new bloated files
**Issue**: Solved CLAUDE.md bloat but created docs/ bloat
**Solution**: Mandatory size validation tasks in every extraction phase

**Enforcement Levels**:
- 350 lines: Pre-merge stop threshold (don't merge if projected >350)
- 400 lines: Bloat warning threshold (immediate review)
- 800 lines: Critical threshold (mandatory split)

### Anti-Pattern 4: Silent Merge Failures

**Problem**: Merges exceeded threshold without warning
**Issue**: Bloat accumulated silently
**Solution**: Fail-fast size validation with automated rollback

**Validation Pattern**:
```bash
# Pre-merge check
projected=$((current_size + extraction_size))
if (( projected > 400 )); then
  echo "BLOAT RISK: Merge would exceed threshold"
  echo "FALLBACK: Keep CLAUDE.md section inline"
  exit 1
fi

# Post-merge check
actual=$(wc -l < merged_file.md)
if (( actual > 400 )); then
  echo "BLOAT DETECTED: Rolling back"
  git checkout HEAD -- merged_file.md
  exit 1
fi
```

### Anti-Pattern 5: No Cross-Reference Tracking

**Problem**: Extractions broke internal links
**Issue**: Commands couldn't find referenced sections
**Solution**: Cross-reference update requirements in bloat guidance

**Requirements**:
- Track all files referencing extracted content
- Update CLAUDE.md summaries to link to new locations
- Update guides/README.md navigation
- Run link validation after all extractions

## Key Architectural Insights

### 1. Lazy Directory Creation Pattern

**Pattern**: Agents don't pre-create directories
**Implementation**: `ensure_artifact_directory()` called before file creation
**Benefits**: Avoids empty directories, directories created only when needed

**Code**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh"
ensure_artifact_directory "$BLOAT_REPORT_PATH"
```

### 2. Absolute Path Enforcement

**Pattern**: All paths must be absolute, validated at agent entry
**Enforcement**: Step 1 validates paths with regex `^/`
**Benefits**: Prevents relative path confusion, works across directory contexts

**Validation**:
```bash
if [[ ! "$BLOAT_REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: BLOAT_REPORT_PATH is not absolute: $BLOAT_REPORT_PATH"
  exit 1
fi
```

### 3. Completion Signal Protocol

**Pattern**: Agents echo "ARTIFACT_CREATED: /path" as final output
**Parsing**: Orchestrators use grep/awk to extract path
**Benefits**: Reliable artifact detection, fails if signal missing

**Protocol**:
```bash
# Agent (final line)
echo "REPORT_CREATED: $BLOAT_REPORT_PATH"

# Orchestrator (verification)
if ! grep -q "REPORT_CREATED:" agent_output; then
  echo "ERROR: Agent did not signal completion"
  exit 1
fi
```

### 4. Hierarchical Metadata Passing

**Pattern**: Agents create full reports, orchestrators extract metadata
**Benefit**: Downstream agents receive summaries, not full reports
**Implementation**: Metadata extraction library (metadata-extraction.sh)

**Flow**:
```
bloat-analyzer → Full report (750 lines)
orchestrator   → Extract metadata (50-word summary)
plan-architect ← Receive metadata only (99% reduction)
               ← Read full report only if needed
```

### 5. Bloat Prevention as First-Class Concern

**Pattern**: Size validation is not optional, it's mandatory
**Enforcement**: Every extraction phase includes size checks
**Philosophy**: Prevention > remediation

**Integration**:
- Bloat analyzer generates validation tasks
- Planning agent integrates tasks into implementation plan
- /implement executes validation as part of each phase
- Rollback automatic if threshold exceeded

## Recommendations for New Subagents

### 1. Follow 6-Step Execution Process

**Recommended Structure**:
1. Receive and verify input paths (absolute, existing)
2. Ensure parent directory exists (lazy creation)
3. Create output file FIRST with template
4. Read input artifacts
5. Perform analysis and update output file
6. Verify output and signal completion

**Why**: Guarantees artifact creation even if analysis fails

### 2. Use Semantic Analysis for Quality Tasks

**When to Use Opus**:
- Content overlap detection
- Quality assessment
- Consolidation opportunities
- Context-aware recommendations

**When to Use Sonnet**:
- Structured synthesis (plan generation)
- Template-based generation
- Straightforward analysis

### 3. Generate Implementation-Ready Tasks

**Requirement**: Provide concrete bash validation scripts
**Format**: Copy-paste ready code blocks
**Benefit**: Planning agent can integrate directly into phases

**Example Output**:
```bash
# Task 2.1: Validate Extraction Size
lines=$(wc -l < target_file.md)
if (( lines > 400 )); then
  echo "BLOAT ALERT: $lines lines exceeds threshold"
  exit 1
fi
```

### 4. Enforce Thresholds with Fail-Fast

**Pattern**: Hard limits with immediate rollback
**Implementation**: Automated rollback scripts in guidance section
**Philosophy**: Don't continue if threshold exceeded

### 5. Support Checkpoint Recovery

**Integration**: Save artifact paths to workflow state
**Benefit**: Workflow can resume after interruption
**Implementation**: Orchestrator handles state persistence, agent provides path

---

REPORT_CREATED: /home/benjamin/.config/.claude/specs/712_infrastructure_and_claude_docs_standards_recently/reports/002_topic2.md
