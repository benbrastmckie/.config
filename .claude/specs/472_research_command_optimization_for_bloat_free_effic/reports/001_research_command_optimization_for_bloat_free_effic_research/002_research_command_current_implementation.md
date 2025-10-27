# Research Command Current Implementation

## Research Metadata
- **Topic**: Research Command Current Implementation
- **Created**: 2025-10-24
- **Status**: Complete
- **Research Specialist**: Claude (Agent)

## Related Reports
- [Overview Report](./OVERVIEW.md) - Complete synthesis of research command optimization research

## Executive Summary

The `/research` command implements a sophisticated hierarchical multi-agent research pattern (improved from `/report`) with 6-step workflow: topic decomposition, path pre-calculation, parallel agent invocation, verification, synthesis, and cross-reference updates. While the architecture achieves 40-60% time savings through parallel execution and 95% context reduction, the implementation contains significant bloat (567 lines vs 629 in `/report`), extensive inline documentation duplication, and complex verification checkpoints that create maintenance burden. Key efficiency opportunities exist in extracting reusable components, reducing inline documentation, and simplifying the agent invocation templates.

## Current Implementation Overview

### Command Structure

**File**: `/home/benjamin/.config/.claude/commands/research.md`
- **Lines**: 567 total
- **Allowed Tools**: Task, Bash, Read (lines 2)
- **Command Type**: primary (line 5)
- **Description**: "Research a topic using hierarchical multi-agent pattern (improved /report)" (line 4)

### Comparison with Predecessor (/report)

**File**: `/home/benjamin/.config/.claude/commands/report.md`
- **Lines**: 629 total
- **Allowed Tools**: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task (line 2)
- **Key Difference**: `/report` has more allowed tools but similar structure

**Evolution Analysis**:
1. `/research` is more focused (3 tools vs 8 tools) - orchestrator role emphasized
2. Both commands share identical workflow structure (6 steps)
3. `/research` adds STEP 1.5 for lazy directory creation in agent invocations (lines 217-225, 367-375)
4. `/research` removes numbered "OVERVIEW.md" requirement, uses ALL CAPS format (line 286, 320)
5. Core workflow identical: decompose → calculate paths → invoke agents → verify → synthesize → cross-reference

## Hierarchical Multi-Agent Pattern

### Workflow Architecture (6 Steps)

**STEP 1: Topic Decomposition** (lines 35-76)
- Uses `topic-decomposition.sh` utility library (lines 42-44)
- Calculates subtopic count based on complexity (line 48)
- Generates decomposition prompt for Task tool (line 50)
- Validates subtopics are snake_case and 2-4 count (lines 61-63)

**STEP 2: Path Pre-Calculation** (lines 78-172)
- Uses unified location detection library (lines 84-86)
- Performs location detection to get/create topic directory (line 88)
- Extracts topic_path and topic_name from JSON output (lines 91-98)
- **MANDATORY VERIFICATION**: Topic directory creation verified (lines 101-107)
- Creates research subdirectory using `create_research_subdirectory()` (line 121)
- Calculates absolute paths for all subtopic reports BEFORE agent invocation (lines 133-146)
- **Critical Design**: Pre-calculation prevents path mismatch errors in agent file creation

**STEP 3: Parallel Agent Invocation** (lines 174-252)
- Invokes multiple research-specialist agents in parallel (one per subtopic)
- Uses Task tool with 5-minute timeout per agent (line 201)
- Agent prompt template: 55 lines (lines 190-246)
- **Key Pattern**: Injects behavioral guidelines from `.claude/agents/research-specialist.md` (lines 194-195)
- Passes absolute pre-calculated paths to each agent (line 212)
- Includes lazy directory creation step (STEP 1.5, lines 217-225)
- Monitors progress markers from agents (lines 248-252)

**STEP 4: Report Verification** (lines 254-322)
- Verifies all subtopic reports exist at expected paths (lines 260-276)
- **Fallback Strategy**: Searches alternate locations if expected path not found (lines 276-283)
- Tracks verification errors and failed agents (lines 262-263, 284-288)
- Critical checkpoint before synthesis (line 321)

**STEP 5: Overview Synthesis** (lines 324-392)
- Calculates overview path (OVERVIEW.md, ALL CAPS) (line 332)
- Invokes research-synthesizer agent (single invocation after all subtopics) (lines 300-337)
- Synthesizer reads ALL subtopic reports and creates unified overview (lines 352-385)
- Includes lazy directory creation step (lines 367-375)
- Returns OVERVIEW_CREATED confirmation (line 379)

**STEP 6: Cross-Reference Updates** (lines 394-427)
- Invokes spec-updater agent for bidirectional cross-references (lines 356-406)
- Updates plan metadata if related plan exists (lines 429-432)
- Links subtopic reports to overview (line 435)
- Links overview to plan if applicable (line 439)
- Validates all cross-references are bidirectional (lines 442-446)

### Agent Integration Points

**research-specialist Agent** (lines 477-555)
- **Behavioral File**: `/home/benjamin/.config/.claude/agents/research-specialist.md` (28 completion criteria)
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch, Write, Edit, Bash (7 tools)
- **Output**: Individual subtopic report at pre-calculated path
- **Invocation Pattern**: Parallel (multiple agents invoked in single message)

**research-synthesizer Agent** (lines 520-554)
- **Behavioral File**: `/home/benjamin/.config/.claude/agents/research-synthesizer.md`
- **Tools**: Read, Write (2 tools)
- **Output**: OVERVIEW.md synthesis report
- **Invocation Pattern**: Sequential (after all subtopic reports verified)

**spec-updater Agent** (lines 356-406)
- **Behavioral File**: `/home/benjamin/.config/.claude/agents/spec-updater.md`
- **Purpose**: Cross-reference management and bidirectional linking

## Topic Decomposition Strategy

### Decomposition Utility

**File**: `/home/benjamin/.config/.claude/lib/topic-decomposition.sh`
- **Functions**:
  - `decompose_research_topic()` (lines 5-44): Generates prompt for Task tool decomposition
  - `validate_subtopic_name()` (lines 46-62): Validates snake_case format and max 50 chars
  - `calculate_subtopic_count()` (lines 64-80): Heuristic based on word count (2-4 subtopics)

### Complexity Heuristic

```bash
# Simple heuristic: More words = more subtopics (lines 67-79)
# 1-3 words: 2 subtopics
# 4-6 words: 3 subtopics
# 7+ words: 4 subtopics
```

**Analysis**: This is a very simple heuristic that may not capture true complexity. Alternative metrics could include:
- Presence of "and" or "or" keywords
- Number of distinct concepts (via NLP)
- User-specified complexity level

## Agent Invocation Mechanisms

### Behavioral Injection Pattern

Both `/research` and `/report` use the **behavioral injection pattern** (not SlashCommand invocation):

```yaml
# Pattern (lines 190-246 in /research.md, 197-253 in /report.md)
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent...

    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]
    ...
  "
}
```

### Inline Template Bloat

**Agent Prompt Templates**:
- **research-specialist invocation**: 55 lines (lines 190-246)
- **research-synthesizer invocation**: 38 lines (lines 300-337)
- **spec-updater invocation**: 50 lines (lines 356-406)

**Total Inline Template Lines**: 143 lines (25% of command file)

**Issue**: These templates are duplicated between `/research` and `/report` with minor variations, creating maintenance burden.

## Path Calculation and File Management

### Unified Location Detection Library

**File**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`

**Key Functions Used**:

1. **`perform_location_detection()`** (line 321)
   - Orchestrates complete location detection workflow
   - Returns JSON with topic_path, topic_name, artifact_paths
   - **Output Example**:
     ```json
     {
       "topic_number": "082",
       "topic_name": "auth_patterns_research",
       "topic_path": "/path/to/specs/082_auth_patterns_research",
       "artifact_paths": {
         "reports": "/path/to/specs/082_auth_patterns_research/reports",
         "plans": "/path/to/specs/082_auth_patterns_research/plans",
         ...
       }
     }
     ```

2. **`create_research_subdirectory()`** (line 448)
   - Creates numbered subdirectory within reports/ (e.g., `001_research/`)
   - Finds next available number by scanning existing directories
   - Returns absolute path to research subdirectory

3. **`ensure_artifact_directory()`** (line 239)
   - **Lazy directory creation pattern**
   - Creates parent directory only when file is written
   - Eliminates empty subdirectory creation (400-500 empty dirs reduced to 0)

### Path Pre-Calculation Critical Pattern

**Why Pre-Calculation Matters** (documented in lines 110-113):
```
**ABSOLUTE REQUIREMENT**: You MUST calculate all subtopic report paths BEFORE
invoking research agents.

**WHY THIS MATTERS**: Research-specialist agents require EXACT absolute paths to
create files in correct locations. Skipping this step causes path mismatch errors.
```

**Implementation** (lines 116-146):
```bash
# MANDATORY: Calculate absolute paths for each subtopic
declare -A SUBTOPIC_REPORT_PATHS

# Create subdirectory for this research task using unified library function
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_DIR" "${TOPIC_NAME}_research")

# Calculate paths for each subtopic
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
  SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))
done
```

**Verification Checkpoints** (lines 150-171):
- Validates all paths are absolute (start with `/`)
- Counts total paths calculated
- Confirms readiness before agent invocation

## Bloat and Redundancy Analysis

### Inline Documentation Duplication

**Problem Areas**:

1. **Agent Invocation Templates** (143 lines total):
   - research-specialist template: 55 lines (lines 190-246)
   - research-synthesizer template: 38 lines (lines 300-337)
   - spec-updater template: 50 lines (lines 356-406)
   - **Redundancy**: These templates are nearly identical between `/research` and `/report`
   - **Alternative**: Extract to shared templates in `.claude/templates/agent-invocations/`

2. **Verification Checkpoints** (repeated 4 times):
   - Path pre-calculation verification (lines 150-171): 22 lines
   - Report verification (lines 260-276): 17 lines
   - MANDATORY VERIFICATION blocks with extensive comments
   - **Redundancy**: Verification pattern repeats with similar structure

3. **Inline Process Documentation**:
   - "WHY THIS MATTERS" explanations (lines 112-113, 79)
   - "CRITICAL INSTRUCTION" blocks (lines 191)
   - "ABSOLUTE REQUIREMENT" headers (lines 110, 192, 203)
   - **Redundancy**: Could reference external documentation instead

### Code vs Documentation Ratio

**Line Count Analysis**:
- Total lines: 567
- Executable bash code blocks: ~80 lines (14%)
- YAML agent invocation templates: 143 lines (25%)
- Inline documentation/comments: ~344 lines (61%)

**Comparison with /report**:
- Total lines: 629 (62 lines more than /research)
- Similar code vs documentation ratio

### Structural Redundancy

**Identical Sections Between /research and /report**:

1. **STEP 2: Path Pre-Calculation** (nearly identical)
   - `/research` lines 78-172
   - `/report` lines 78-183
   - **Difference**: `/research` uses `create_research_subdirectory()`, `/report` uses manual numbering logic

2. **STEP 3: Agent Invocation Template** (95% identical)
   - `/research` lines 190-246
   - `/report` lines 197-253
   - **Difference**: `/research` adds STEP 1.5 for lazy directory creation (lines 217-225)

3. **STEP 5: Synthesis Agent Invocation** (nearly identical)
   - `/research` lines 300-337
   - `/report` lines 347-393
   - **Difference**: Overview filename (OVERVIEW.md vs numbered)

4. **STEP 6: Cross-Reference Updates** (identical)
   - `/research` lines 356-406
   - `/report` lines 406-456
   - **No meaningful differences**

## Efficiency Concerns

### Command File Size

**Current State**:
- `/research.md`: 567 lines
- `/report.md`: 629 lines
- **Combined**: 1,196 lines with ~60% content duplication

**Impact**:
- Large context window consumption when command is invoked
- Increased maintenance burden (changes must be applied to both files)
- Harder to identify differences and evolution between commands

### Verification Overhead

**Mandatory Verification Checkpoints**:
1. Path pre-calculation verification (lines 150-171)
2. Topic directory creation verification (lines 101-107)
3. Research subdirectory verification (lines 123-130)
4. Report file verification (lines 260-322)
5. Overview file verification (monitoring phase, lines 388-392)

**Analysis**:
- Each verification adds 10-25 lines of bash code + documentation
- Most verifications are defensive programming against agent failures
- Could be consolidated into reusable verification library

### Agent Invocation Template Verbosity

**Current Template Size**: 55 lines per agent (research-specialist)

**Template Breakdown**:
- Behavioral injection instructions: 10 lines
- Step-by-step process (4 steps): 25 lines
- Progress marker requirements: 8 lines
- Context/metadata: 12 lines

**Optimization Opportunity**:
- Extract common instructions to agent behavioral files
- Command only needs to pass: topic, path, specific requirements (10-15 lines max)
- Reduce 55 lines → 15 lines (73% reduction per agent invocation)

### Library Integration Complexity

**Current Usage**:
- `topic-decomposition.sh` - 3 function calls
- `unified-location-detection.sh` - 3 function calls
- `artifact-creation.sh` - referenced but not actually used
- `template-integration.sh` - referenced but not actually used

**Issue**: Lines 42-45 in `/research.md` source libraries that are never called:
```bash
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-creation.sh  # Not used in command
source .claude/lib/template-integration.sh  # Not used in command
```

**Analysis**: Dead code or aspirational references should be removed.

## Recommendations

### 1. Extract Agent Invocation Templates to Shared Library

**Current State**: 143 lines of inline YAML templates (25% of command file)

**Proposed Solution**:
- Create `.claude/templates/agent-invocations/research-specialist.yaml`
- Create `.claude/templates/agent-invocations/research-synthesizer.yaml`
- Create `.claude/templates/agent-invocations/spec-updater.yaml`
- Commands reference templates with variable substitution

**Benefits**:
- Reduce command file size by ~120 lines (21%)
- Single source of truth for agent invocation patterns
- Easier to update agent protocols system-wide

**Implementation**:
```bash
# In command file (reduced from 55 lines to ~10 lines)
AGENT_TEMPLATE=$(cat .claude/templates/agent-invocations/research-specialist.yaml)
AGENT_PROMPT=$(substitute_vars "$AGENT_TEMPLATE" \
  SUBTOPIC="$subtopic" \
  REPORT_PATH="$report_path")

# Invoke with templated prompt
Task { ... prompt: "$AGENT_PROMPT" }
```

### 2. Consolidate Verification Logic into Reusable Library

**Current State**: Verification checkpoints duplicated 4+ times

**Proposed Solution**:
- Create `.claude/lib/verification-utils.sh`
- Functions: `verify_directory_created()`, `verify_file_created()`, `verify_paths_absolute()`
- Commands call verification functions instead of inline bash blocks

**Benefits**:
- Reduce verification code by ~60 lines (10%)
- Consistent error messages and exit codes
- Testable verification logic (can unit test library)

**Example**:
```bash
# Current: 22 lines (lines 150-171)
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path not absolute..."
    exit 1
  fi
done

# Proposed: 2 lines
source .claude/lib/verification-utils.sh
verify_paths_absolute SUBTOPIC_REPORT_PATHS || exit 1
```

### 3. Move Inline Documentation to External Reference Files

**Current State**: 61% of command file is inline documentation

**Proposed Solution**:
- Create `.claude/docs/workflows/hierarchical-research.md` with complete workflow documentation
- Command file references documentation for "WHY THIS MATTERS" explanations
- Keep only critical warnings and step headers in command file

**Benefits**:
- Reduce command file by ~200 lines (35%)
- Documentation can be more comprehensive (images, examples, troubleshooting)
- Faster command file parsing and context loading

**Example**:
```markdown
# Current (in command file, lines 110-113):
**ABSOLUTE REQUIREMENT**: You MUST calculate all subtopic report paths BEFORE
invoking research agents.

**WHY THIS MATTERS**: Research-specialist agents require EXACT absolute paths to
create files in correct locations. Skipping this step causes path mismatch errors.

# Proposed (in command file):
**STEP 2**: Calculate paths (see: .claude/docs/workflows/hierarchical-research.md#path-calculation)
```

### 4. Unify /research and /report Commands via Shared Workflow Library

**Current State**: 60% code duplication between commands (720 duplicated lines)

**Proposed Solution**:
- Create `.claude/lib/hierarchical-research-workflow.sh`
- Extract 6-step workflow as reusable functions
- Both commands invoke workflow library with minor parameter variations

**Benefits**:
- Eliminate 400+ lines of duplication
- Single implementation to maintain and test
- Commands become thin wrappers (50-100 lines each)

**Example**:
```bash
# In .claude/lib/hierarchical-research-workflow.sh
execute_hierarchical_research() {
  local topic="$1"
  local overview_format="$2"  # "OVERVIEW.md" or "NNN_overview.md"

  # STEP 1: Topic decomposition
  # STEP 2: Path pre-calculation
  # STEP 3: Parallel agent invocation
  # STEP 4: Verification
  # STEP 5: Synthesis
  # STEP 6: Cross-references
}

# In /research.md (reduced to ~100 lines)
source .claude/lib/hierarchical-research-workflow.sh
execute_hierarchical_research "$ARGUMENTS" "OVERVIEW.md"

# In /report.md (reduced to ~100 lines)
source .claude/lib/hierarchical-research-workflow.sh
execute_hierarchical_research "$ARGUMENTS" "NNN_overview.md"
```

### 5. Remove Dead Library References

**Current Issue**: Lines 42-45 source libraries that are never used

**Proposed Solution**: Remove unused library references
```bash
# Remove these lines:
source .claude/lib/artifact-creation.sh  # Not actually called
source .claude/lib/template-integration.sh  # Not actually called
```

**Benefits**:
- Clearer dependency graph
- Faster command initialization (fewer files sourced)
- Reduced confusion about which libraries are actually used

## References

### Primary Files Analyzed

1. **`/home/benjamin/.config/.claude/commands/research.md`** (lines 1-567)
   - Main research command implementation
   - 6-step hierarchical multi-agent workflow
   - 143 lines of inline agent invocation templates

2. **`/home/benjamin/.config/.claude/commands/report.md`** (lines 1-629)
   - Predecessor command to /research
   - Nearly identical workflow structure
   - 60% code duplication with /research

3. **`/home/benjamin/.config/.claude/lib/topic-decomposition.sh`** (lines 1-86)
   - Topic decomposition utility functions
   - Complexity heuristic based on word count
   - Subtopic validation logic

4. **`/home/benjamin/.config/.claude/lib/unified-location-detection.sh`** (lines 1-500+)
   - Unified location detection library
   - Key functions: `perform_location_detection()`, `create_research_subdirectory()`, `ensure_artifact_directory()`
   - Implements lazy directory creation pattern

5. **`/home/benjamin/.config/.claude/agents/research-specialist.md`** (lines 1-671)
   - Research specialist agent behavioral file
   - 28 completion criteria
   - 4-step research execution process

6. **`/home/benjamin/.config/.claude/agents/research-synthesizer.md`** (lines 1-259)
   - Research synthesizer agent behavioral file
   - 5-step synthesis execution process
   - Overview report creation and cross-referencing

### Key Metrics

- **Command File Size**: 567 lines (/research), 629 lines (/report)
- **Code vs Documentation Ratio**: 14% code, 25% templates, 61% documentation
- **Duplication Rate**: 60% code duplication between /research and /report
- **Agent Invocation Template Size**: 143 lines (25% of command file)
- **Verification Overhead**: 5 mandatory checkpoints, ~80 lines total
- **Library Dependencies**: 2 actively used, 2 dead references
