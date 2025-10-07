---
allowed-tools: Read, Write, Edit, Bash, Glob
argument-hint: <plan-path> <phase-num>
description: Expand a phase into a detailed implementation plan with concrete specifications
command-type: workflow
---

# Expand Phase to Detailed Implementation Plan

I'll expand a phase from a Level 0 plan into a comprehensive, detailed Level 1 implementation plan with specific implementation specifications (target: 300-500+ lines).

## Arguments

- `$1` (required): Path to plan file or directory (e.g., `specs/plans/025_feature.md`)
- `$2` (required): Phase number to expand (e.g., `3`)

## Objective

Transform a brief 30-50 line phase outline into a detailed 300-500+ line implementation specification with:
- **Concrete implementation details**, not generic guidance
- **Specific code examples and patterns** for the actual tasks
- **Detailed testing specifications** with actual test cases
- **Architecture and design decisions** specific to this phase
- **Error handling patterns** for the specific scenarios
- **Performance considerations** relevant to the work

## Process

### 1. Analyze Current Structure

First, determine the plan's current structure level:

```bash
# Check if plan is a file or directory
if [[ -d "$plan_path" ]]; then
  # Level 1 - already expanded
  plan_file="$plan_path/$(basename "$plan_path").md"
  structure_level=1
elif [[ -f "$plan_path" ]]; then
  # Level 0 - single file
  plan_file="$plan_path"
  structure_level=0
fi
```

### 2. Extract Phase Content

Read the specified phase from the main plan:

```bash
# Use parse-adaptive-plan.sh utilities
source utils/parse-adaptive-plan.sh
phase_content=$(extract_phase_content "$plan_file" "$phase_num")
```

Extract all components:
- Phase heading and title
- Objective
- Complexity
- Scope
- Expected Impact
- All task checkboxes
- Any existing implementation notes

### 3. Complexity Detection and Agent Selection

**Objective**: Determine whether the phase requires agent-assisted research or can be expanded directly.

#### Complexity Analysis

Analyze the phase content to determine complexity level:

```bash
# Count tasks
task_count=$(echo "$phase_content" | grep -c "^- \[ \]")

# Extract file references (*.md, *.sh, *.lua, etc.)
file_refs=$(echo "$phase_content" | grep -oE "[a-zA-Z0-9_/.-]+\.(md|sh|lua|js|py|ts)" | sort -u)
file_count=$(echo "$file_refs" | wc -l)

# Count unique directories
unique_dirs=$(echo "$file_refs" | xargs dirname | sort -u | wc -l)

# Check for complexity keywords
has_consolidate=$(echo "$phase_content" | grep -ic "consolidate")
has_refactor=$(echo "$phase_content" | grep -ic "refactor")
has_migrate=$(echo "$phase_content" | grep -ic "migrate")
```

#### Complexity Thresholds

A phase is considered **complex** if any of these conditions are met:

| Indicator | Simple Phase | Complex Phase |
|-----------|--------------|---------------|
| Task count | ≤5 tasks | >5 tasks |
| File references | <10 files | ≥10 files |
| Directories | 1-2 dirs | >2 dirs |
| Keywords | None | "consolidate", "refactor", "migrate" |

**Decision Logic**:
```bash
is_complex=false

if [[ $task_count -gt 5 ]] || \
   [[ $file_count -ge 10 ]] || \
   [[ $unique_dirs -gt 2 ]] || \
   [[ $has_consolidate -gt 0 ]] || \
   [[ $has_refactor -gt 0 ]] || \
   [[ $has_migrate -gt 0 ]]; then
  is_complex=true
fi
```

#### Agent Selection

When complexity is detected, select appropriate agent behavior based on phase type:

```
┌──────────────────────────────────────────────────────────┐
│              Complexity Detection Flow                    │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
    ┌─────────┐
    │ Analyze │ Count tasks, files, dirs, keywords
    │  Phase  │
    └────┬────┘
         │
         ▼
    ┌─────────────┐
    │  Complexity │
    │   Check     │
    └─┬─────────┬─┘
      │         │
Simple│         │Complex
      │         │
      ▼         ▼
  ┌───────┐  ┌──────────────────────────────┐
  │Direct │  │  Select Agent Behavior       │
  │Expand │  │                              │
  └───────┘  │  ┌────────────────────────┐  │
             │  │ Codebase Analysis?     │  │
             │  │ → research-specialist  │  │
             │  └────────────────────────┘  │
             │  ┌────────────────────────┐  │
             │  │ Refactor/Consolidate?  │  │
             │  │ → code-reviewer        │  │
             │  └────────────────────────┘  │
             │  ┌────────────────────────┐  │
             │  │ Phase breakdown needed?│  │
             │  │ → plan-architect       │  │
             │  └────────────────────────┘  │
             └──────────────────────────────┘
```

**Agent Behavior Selection**:

1. **research-specialist** (Default for complex phases)
   - Use when: Phase involves many files or directories
   - Purpose: Analyze current codebase state, find patterns
   - Tools: Read, Glob, Grep (read-only)
   - Output: 200-250 word research summary

2. **code-reviewer** (For refactoring phases)
   - Use when: Phase contains "refactor", "consolidate", "cleanup"
   - Purpose: Analyze code quality, find improvement opportunities
   - Tools: Read, Grep (read-only)
   - Output: Standards compliance analysis

3. **plan-architect** (For very complex phases)
   - Use when: Phase might need sub-phase breakdown
   - Purpose: Suggest optimal phase structure
   - Tools: Read (read-only)
   - Output: Structural recommendations

**Default Selection Logic**:
```bash
if [[ $has_refactor -gt 0 ]] || [[ $has_consolidate -gt 0 ]]; then
  agent_behavior="code-reviewer"
elif [[ $task_count -gt 10 ]] && [[ $unique_dirs -gt 3 ]]; then
  agent_behavior="plan-architect"
else
  agent_behavior="research-specialist"  # Default
fi
```

### 4. Create Detailed Implementation Specification

**Path Selection**: Based on complexity analysis from step 3:

- **Simple phases** → Direct to specification writing (this step)
- **Complex phases** → Agent-assisted research (step 4a), then specification writing (step 4b)

#### 4a. Agent-Assisted Research (Complex Phases Only)

When complexity detected (`is_complex=true`), invoke agent for codebase research.

**Skip to step 4b if simple phase.**

**Agent Invocation Pattern**:

Use the Task tool with `general-purpose` agent type + behavioral injection:

```markdown
Task tool invocation:
  subagent_type: general-purpose
  description: "Research phase context using [agent-behavior] protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-behavior].md

    You are acting as a [Agent Role] with these constraints:
    - Read-only operations (tools: Read, Glob, Grep only)
    - Concise summaries (200-250 words max)
    - Specific file references with line numbers
    - Evidence-based findings only

    Research Task: [Phase Objective]

    Phase Tasks:
    [List all tasks from phase]

    Requirements:
    1. Search codebase for files mentioned in tasks
    2. Identify existing patterns and implementations
    3. Find dependencies and integration points
    4. Assess current state vs target state
    5. Note any potential conflicts or challenges

    Output Format:
    ## Current State
    - [What exists now with file:line references]

    ## Patterns Found
    - [Relevant patterns with concrete examples]

    ## Recommendations
    - [Specific approach based on findings]

    ## Challenges
    - [Potential issues or constraints]

    Word limit: 250 words maximum
```

**Example 1: research-specialist Behavior**

For general codebase analysis (default for complex phases):

```markdown
Task: Research utils consolidation phase

Prompt:
  Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md

  You are acting as a Research Specialist with constraints:
  - Read-only: Use Read, Glob, Grep tools only
  - Concise: 200-250 word summary
  - Specific: Include file:line references
  - Evidence-based: Only report what you find

  Research Task: Analyze utils/ directory for consolidation opportunities

  Phase Tasks:
  - Audit all util scripts in utils/ and lib/
  - Identify duplicate functionality
  - Map dependencies between utils
  - Recommend consolidation strategy
  - Create migration plan
  - Update documentation

  Requirements:
  1. List all util scripts with their purposes
  2. Find duplicated functions (same name or behavior)
  3. Map which scripts depend on which utils
  4. Identify utils that could be merged
  5. Note any breaking change risks

  Output Format:
  ## Current State
  - Found N scripts in utils/, M in lib/
  - utils/foo.sh:15 implements function X
  - lib/bar.sh:23 duplicates function X

  ## Patterns Found
  - Common pattern: error handling via error-utils.sh
  - Dependency graph: [describe]

  ## Recommendations
  - Merge utils/foo.sh and lib/bar.sh
  - Standardize on lib/ for reusable utilities

  ## Challenges
  - 12 scripts depend on utils/foo.sh
  - Breaking change requires careful migration

  Word limit: 250 words
```

**Example 2: code-reviewer Behavior**

For refactoring/consolidation phases:

```markdown
Task: Review code for refactoring opportunities

Prompt:
  Read and follow: /home/benjamin/.config/.claude/agents/code-reviewer.md

  You are acting as a Code Reviewer with constraints:
  - Read-only: Use Read, Grep tools only
  - Concise: 200-250 word analysis
  - Standards-focused: Check against CLAUDE.md
  - Specific: File:line references for issues

  Research Task: Analyze codebase section for refactoring needs

  Phase Tasks:
  - Review code quality in [directory]
  - Identify style violations
  - Find improvement opportunities
  - Check standards compliance
  - Recommend refactoring approach

  Requirements:
  1. Check indentation, line length (CLAUDE.md standards)
  2. Find code duplication or complexity
  3. Identify naming convention issues
  4. Note missing error handling
  5. Assess test coverage gaps

  Output Format:
  ## Current State
  - [Files reviewed with issue counts]
  - [Specific violations with file:line]

  ## Patterns Found
  - [Common issues or anti-patterns]

  ## Recommendations
  - [Specific refactoring steps]

  ## Challenges
  - [Risks or blockers]

  Word limit: 250 words
```

**Example 3: plan-architect Behavior**

For very complex phases needing sub-structure:

```markdown
Task: Analyze phase for potential sub-phase breakdown

Prompt:
  Read and follow: /home/benjamin/.config/.claude/agents/plan-architect.md

  You are acting as a Plan Architect with constraints:
  - Read-only: Use Read tool only
  - Concise: 200-250 word structure analysis
  - Specific: Justify recommendations with task analysis

  Research Task: Determine if phase needs sub-phase breakdown

  Phase Tasks:
  [List all tasks - if >10 tasks]

  Requirements:
  1. Analyze task dependencies
  2. Identify natural groupings
  3. Assess complexity per task group
  4. Recommend phase structure
  5. Estimate effort per group

  Output Format:
  ## Current State
  - Phase has N tasks across M areas
  - Identified K natural groupings

  ## Patterns Found
  - Task group 1: [theme] (complexity: X/10)
  - Task group 2: [theme] (complexity: Y/10)

  ## Recommendations
  - Yes/No on sub-phase breakdown
  - If Yes: Suggested structure with rationale

  ## Challenges
  - [Risks of over/under-structuring]

  Word limit: 250 words
```

**Error Handling**:

If agent invocation fails or times out:

1. **Fallback to direct expansion**: Proceed to step 4b without research
2. **Log the error**: Note in phase file that agent research was skipped
3. **Increase file reads**: Read more context files directly
4. **Notify user**: Mention research limitation in output

**Timeout Handling**:

- Set Task tool timeout: 5 minutes for research
- If exceeded: Cancel agent, use fallback
- Document in phase file: "Note: Agent research timed out, expanded with direct file reads"

**Incomplete Research**:

If agent returns <100 words or missing sections:

1. **Request clarification**: Ask agent to elaborate on specific section
2. **Supplement with direct reads**: Fill gaps by reading files directly
3. **Document limitation**: Note which aspects lack research coverage

#### 4b. Write Detailed Implementation Specification

**Context Integration**:

- **If agent research available**: Synthesize findings into specification (see "Synthesizing Agent Research" below)
- **If direct expansion**: Read relevant files and write specification

**IMPORTANT**: Do NOT use generic templates. Instead:

1. **Read and understand** the phase objective and tasks
2. **Analyze** what the phase is actually trying to accomplish
3. **Research** the codebase context (from agent or direct file reads)
4. **Synthesize** research into concrete implementation details
5. **Write** a detailed, specific implementation plan

### Synthesizing Agent Research into Specifications

When agent research is available, follow this synthesis process to transform 200-250 word findings into 300-500+ line detailed specifications.

#### Synthesis Strategy

**Input**: Agent research with 4 sections (Current State, Patterns Found, Recommendations, Challenges)

**Output**: 300-500+ line phase specification with concrete implementation details

**Process**:

1. **Extract Key Findings** (5-10 minutes)
   - List all file:line references from "Current State"
   - Note all patterns from "Patterns Found"
   - Capture all recommendations
   - Identify all challenges

2. **Map Findings to Tasks** (10-15 minutes)
   - For each task in phase, identify relevant findings
   - Link specific files/patterns to each task
   - Note which recommendations apply to which tasks
   - Flag tasks affected by challenges

3. **Generate Concrete Examples** (15-20 minutes)
   - Use patterns found as basis for code examples
   - Base examples on actual file structures discovered
   - Show before/after for refactoring tasks
   - Include specific function signatures from research

4. **Create Testing Strategy** (10-15 minutes)
   - Base test cases on current state found
   - Test transitions from current → target state
   - Cover edge cases from challenges identified
   - Use actual file paths in test specifications

5. **Write Implementation Steps** (20-30 minutes)
   - Use actual file paths from research
   - Reference specific line numbers where relevant
   - Order steps based on dependency findings
   - Address challenges with mitigation steps

#### Synthesis Example

**Input**: 250-word research on utils consolidation

```markdown
## Current State
- Found 23 scripts in utils/, 15 in lib/
- utils/error-utils.sh:25 implements log_error()
- lib/logging.sh:18 implements log_error() (duplicate)
- utils/path-utils.sh:12 implements normalize_path()
- 12 scripts depend on utils/error-utils.sh

## Patterns Found
- Common pattern: Source utils/error-utils.sh for error handling
- Dependency graph: commands → utils → lib
- Naming: Functions use snake_case, exported variables use UPPER_CASE
- Error handling: All utils use `set -e` and log_error for failures

## Recommendations
- Consolidate to lib/ for reusable utilities (accessed by utils/ and commands/)
- Merge error-utils.sh and logging.sh → lib/logging.sh
- Create lib/path-utils.sh, deprecate utils/path-utils.sh
- Update all 12 dependent scripts with new paths

## Challenges
- Breaking change: 12 scripts use old paths
- Migration requires testing all dependent scripts
- Risk: Commands might source utils/ in .bashrc or external scripts
```

**Synthesis Process**:

**Step 1: Extract Key Findings**

```
File References:
- utils/error-utils.sh:25 (log_error function)
- lib/logging.sh:18 (duplicate log_error)
- utils/path-utils.sh:12 (normalize_path)

Patterns:
- Source pattern: utils/error-utils.sh sourced 12 times
- Naming: snake_case functions, UPPER_CASE exported vars
- Error handling: set -e + log_error

Recommendations:
- Consolidate to lib/
- Merge error-utils.sh + logging.sh
- Migrate path-utils.sh

Challenges:
- 12 dependent scripts
- External sourcing risk
```

**Step 2: Map to Tasks**

```
Task 1: Audit utils
→ Findings: 23 utils/ scripts, 15 lib/ scripts
→ Action: List all with purposes, check for duplicates

Task 2: Identify duplicates
→ Findings: log_error in error-utils.sh:25 and logging.sh:18
→ Action: Compare implementations, choose canonical version

Task 3: Map dependencies
→ Findings: 12 scripts depend on error-utils.sh
→ Action: Use grep to find all source statements

Task 4: Consolidation strategy
→ Recommendations: Consolidate to lib/, merge duplicates
→ Action: Design lib/ structure, migration plan

Task 5: Migration plan
→ Challenges: Breaking changes, external sourcing
→ Action: Incremental migration with deprecation warnings

Task 6: Update documentation
→ All findings: Document new lib/ structure, update READMEs
→ Action: Write migration guide for maintainers
```

**Step 3: Generate Concrete Examples**

```lua
-- From research: error-utils.sh:25 implements log_error()
-- Synthesized example showing actual function

### Before (utils/error-utils.sh:25)
```bash
log_error() {
  local msg="$1"
  echo "[ERROR] $msg" >&2
}
```

### After (lib/logging.sh - merged version)
```bash
# Merged from utils/error-utils.sh:25 and lib/logging.sh:18
log_error() {
  local msg="$1"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp ERROR] $msg" >&2
}

# Deprecated alias for backwards compatibility
error_log() {
  log_error "$@"
}
```

### Migration Example (utils/some-script.sh)
```bash
# Before
source "$(dirname "$0")/error-utils.sh"

# After
source "$(dirname "$0")/../lib/logging.sh"
```
```

**Step 4: Testing Strategy**

```markdown
### Unit Tests

Test file: `.claude/tests/test_lib_logging.sh`

**Test 1: log_error function exists**
```bash
test_log_error_exists() {
  source lib/logging.sh
  type -t log_error >/dev/null || fail "log_error not defined"
}
```

**Test 2: log_error outputs to stderr**
```bash
test_log_error_stderr() {
  source lib/logging.sh
  output=$(log_error "test" 2>&1 1>/dev/null)
  [[ "$output" == *"test"* ]] || fail "log_error didn't write to stderr"
}
```

**Test 3: Backwards compatibility alias**
```bash
test_error_log_alias() {
  source lib/logging.sh
  type -t error_log >/dev/null || fail "error_log alias missing"
}
```

### Integration Tests

**Test 4: Dependent scripts still work**
```bash
# Test each of the 12 dependent scripts identified
for script in utils/script1.sh utils/script2.sh ...; do
  bash "$script" --test || fail "$script broken after migration"
done
```

### Edge Case Tests

**Test 5: External sourcing**
```bash
# Verify utils/error-utils.sh still exists as symlink or stub
test -f utils/error-utils.sh || fail "Backwards compat broken"
```
```

**Step 5: Implementation Steps**

```markdown
### Task 1: Audit all util scripts

**Implementation Steps**:

1. List all scripts with purposes
   ```bash
   for f in utils/*.sh lib/*.sh; do
     echo "$f: $(head -3 "$f" | grep "^#" | sed 's/^# //')"
   done > audit.txt
   ```

2. Identify duplicate functions
   ```bash
   # Find all function definitions
   grep -n "^function\|^[a-z_]*() {" utils/*.sh lib/*.sh > functions.txt

   # Check for duplicates
   awk '{print $NF}' functions.txt | sort | uniq -d > duplicates.txt
   ```

3. Verify findings match research
   - Expect: log_error in utils/error-utils.sh:25 and lib/logging.sh:18
   - Expect: normalize_path in utils/path-utils.sh:12
   - Report any additional duplicates found

**Success Criteria**:
- Complete inventory of 38 scripts (23 utils + 15 lib)
- Duplicates list matches research findings
- No unexpected duplicates discovered

---

### Task 2: Identify duplicate functionality

**Implementation Steps**:

1. Read and compare log_error implementations
   ```bash
   # utils/error-utils.sh:25
   sed -n '25,30p' utils/error-utils.sh

   # lib/logging.sh:18
   sed -n '18,23p' lib/logging.sh
   ```

2. Determine canonical version
   - Compare implementations for features
   - Choose lib/logging.sh as base (research recommendation)
   - Plan to merge best features from both

3. Document differences
   ```markdown
   **utils/error-utils.sh:25**:
   - Simple implementation
   - No timestamp
   - Used by 12 scripts

   **lib/logging.sh:18**:
   - More features (timestamps, colors)
   - Newer implementation
   - Used by 3 scripts

   **Decision**: Merge into lib/logging.sh, keep utils/error-utils.sh:25 simplicity for backwards compat
   ```

**Success Criteria**:
- Documented comparison of both implementations
- Clear decision on canonical version
- Migration plan preserves backwards compatibility
```

**Output**: 500+ line specification with:
- Concrete file paths from research
- Specific line numbers where relevant
- Code examples based on actual patterns
- Test cases covering actual state transitions
- Implementation steps using discovered structure

#### Quality Checklist for Synthesized Specs

Before completing synthesis, verify:

- [ ] All file:line references from research are incorporated
- [ ] Code examples use actual patterns found (not generic)
- [ ] File paths are specific (e.g., `lib/logging.sh:25`, not `some-file.sh`)
- [ ] Testing strategy covers current → target state transition
- [ ] Challenges from research are addressed with mitigation
- [ ] Implementation steps reference actual files discovered
- [ ] Specification length: 300-500+ lines with substance
- [ ] No generic placeholders like `[file]`, `[function]`, `[directory]`

#### Section Templates for Synthesis

Use these templates when synthesizing research:

**Task Implementation Template**:
```markdown
### Task N: [Task Name from Phase]

**Context from Research**:
- Current state: [File references from agent research]
- Relevant patterns: [Patterns that apply to this task]
- Recommendations: [Agent recommendations for this task]

**Implementation Approach**:
[Specific approach based on research findings]

**Detailed Steps**:
1. [Step using actual file from research]
   - File: `[actual file path from research]`
   - Command: `[actual command with real paths]`
   - Expected: [based on current state from research]

2. [Step addressing challenge from research]
   - Mitigation: [how to handle challenge]
   - Verification: `[actual verification command]`

**Code Example** (based on research pattern):
```[language]
[Actual code pattern found in research, adapted for this task]
```

**Testing** (based on current state):
- Test case: [Transition from current state to target]
- Expected behavior: [Based on patterns found]
- Edge case: [From challenges in research]

**Success Criteria**:
- [Measurable outcome based on research]
- [Verification using actual files]
```

**Architecture Section Template**:
```markdown
### Architecture and Design

**Current Architecture** (from research):
```
[Diagram showing structure found in research]

Files:
- [actual file 1 from research]: [purpose]
- [actual file 2 from research]: [purpose]

Dependencies (from research):
- [actual dependency 1]
- [actual dependency 2]
```

**Target Architecture**:
```
[Diagram showing target based on recommendations]

Changes:
- Move [actual file] to [new location]
- Merge [actual file 1] + [actual file 2]
- Update [N] dependents (specific count from research)
```

**Design Decisions**:
1. [Decision based on research recommendation]
   - Rationale: [From patterns or challenges in research]
   - Trade-off: [Based on findings]

2. [Decision addressing challenge]
   - Rationale: [Mitigation strategy]
   - Risk: [From challenges section]
```

**Testing Strategy Template**:
```markdown
### Comprehensive Testing Strategy

**Test Baseline** (from current state research):
- Current behavior: [Specific behavior from research]
- Affected files: [Actual count and list from research]
- Integration points: [From dependency findings]

**Unit Tests**:
1. Test [specific function from research]
   - Input: [Based on actual usage found]
   - Expected: [Based on pattern found]
   - File: `.claude/tests/test_[specific].sh`

2. Test [challenge scenario from research]
   - Edge case: [Actual challenge described]
   - Expected: [Mitigation behavior]

**Integration Tests**:
1. Test [N dependent scripts] (from research findings)
   - Scripts: [Actual list from research]
   - Verification: [Each script still works]

2. Test [pattern found in research]
   - Scenario: [Actual pattern usage]
   - Expected: [Pattern still works after changes]

**Regression Tests**:
1. Test backwards compatibility
   - Old import: `[actual old path from research]`
   - Should: [Still work via symlink/stub]

**Performance Benchmarks**:
- Baseline: [Current performance if researched]
- Target: [Expected improvement]
- Metric: [Specific measurement]
```

The expanded phase should include:

#### Section 1: Phase Overview (50-100 lines)
- Expanded objective with full context
- Detailed scope breakdown
- Success criteria (specific, measurable)
- Dependencies on previous phases
- Impact on downstream work
- Risk analysis

#### Section 2: Task-by-Task Implementation (150-250 lines)

For EACH task, provide:

**Task N: [Task Description]**

**Implementation Approach**:
- Specific files to create/modify (actual paths)
- Exact functions/commands to implement
- Data structures and interfaces
- Concrete code patterns (not generic examples)

**Detailed Steps**:
1. Step with specific action (e.g., "Create `.claude/lib/metadata-utils.sh` with function `get_plan_metadata()`")
2. Code example showing actual implementation pattern
3. Verification step with actual command

**Testing Requirements**:
- Specific test file path
- Actual test cases to write
- Expected inputs and outputs
- Edge cases specific to this functionality

**Success Criteria**:
- Measurable outcomes
- Verification commands
- Performance targets

#### Section 3: Architecture and Design (50-75 lines)
- Component structure diagram
- Data flow specific to this phase
- Integration points with existing code
- API contracts and interfaces
- Design decisions and rationale

#### Section 4: Comprehensive Testing Strategy (50-75 lines)
- Unit test specifications with actual test cases
- Integration test scenarios
- Edge case tests (specific scenarios)
- Performance/benchmark tests
- Test data requirements

#### Section 5: Error Handling (30-50 lines)
- Specific error scenarios for these tasks
- Error handling patterns with code examples
- Validation logic
- Recovery strategies

#### Section 6: Implementation Checklist (20-30 lines)
- Pre-implementation setup
- Step-by-step execution checklist
- Verification steps
- Completion criteria

### 5. Handle File Structure

**If Level 0 → Level 1 (first expansion)**:
```bash
# Create directory
plan_name=$(basename "$plan_file" .md)
plan_dir=$(dirname "$plan_file")/$plan_name
mkdir -p "$plan_dir"

# Move main plan
mv "$plan_file" "$plan_dir/$(basename "$plan_file")"
plan_file="$plan_dir/$(basename "$plan_file")"
```

**Create phase file**:
```bash
# Generate phase filename
phase_name=$(echo "$phase_title" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -d '/:*?"<>|&')
phase_file="$(dirname "$plan_file")/phase_${phase_num}_${phase_name}.md"
```

### 6. Write Enhanced Phase Content

Write the detailed implementation specification to the phase file with:

```markdown
### Phase N: [Title]

## Metadata
- **Phase Number**: N
- **Parent Plan**: [plan-name].md
- **Estimated Complexity**: [score]/10
- **Estimated Time**: [estimate]

[Original phase objective, tasks, etc.]

---

## Detailed Implementation Specification

### Overview
[Comprehensive overview with full context]

### Task Breakdown
[Detailed implementation for each task]

### Architecture and Design
[Specific design for this phase]

### Testing Strategy
[Comprehensive test specifications]

### Error Handling
[Specific error scenarios]

### Implementation Checklist
[Step-by-step checklist]

### Cross-References
- Previous Phase: Phase N-1
- Next Phase: Phase N+1
- Related Files: [specific files]

---

## Stage Expansion Recommendation

**Recommendation**: [Yes/No]
**Reason**: [Specific rationale based on complexity]
```

### 7. Update Main Plan

Replace the full phase section in main plan with summary:

```markdown
### Phase N: [Title]
**Objective**: [Brief objective]
**Status**: [PENDING]

For detailed implementation specification, see [Phase N Details](phase_N_name.md)
```

### 8. Update Metadata

In main plan metadata section:
```markdown
## Metadata
- **Structure Level**: 1
- **Expanded Phases**: [list of expanded phase numbers]
- **Stage Expansion Candidates**: [phases with recommendation: Yes]
```

## Available Agent Types and Behaviors

**IMPORTANT**: Claude Code only supports 3 agent types:

1. **general-purpose** - Multi-purpose agent for research, search, and multi-step tasks
2. **statusline-setup** - Specialized for configuring status lines
3. **output-style-setup** - Specialized for output style configuration

For `/expand-phase`, we use **general-purpose** agents with behavioral injection.

### Agent Behavior Files

Located in `.claude/agents/`, these files define specialized behaviors:

| Behavior File | Use Case | Tools | Output |
|--------------|----------|-------|--------|
| `research-specialist.md` | Codebase analysis, pattern discovery | Read, Glob, Grep | 200-250 word research summary |
| `code-reviewer.md` | Standards compliance, refactoring analysis | Read, Grep | Code quality assessment |
| `plan-architect.md` | Phase structure analysis | Read | Structure recommendations |
| `debug-specialist.md` | Issue investigation | Read, Grep | Diagnostic findings |
| `test-specialist.md` | Test strategy analysis | Read, Grep | Testing recommendations |

**Usage Pattern**:
```markdown
Task tool:
  subagent_type: general-purpose  # Only valid agent type
  prompt: |
    Read and follow: /path/to/.claude/agents/[behavior].md

    You are acting as a [Role] with [constraints]...
```

This pattern simulates specialized agents by injecting behavioral guidelines into general-purpose agents.

## Key Principles

1. **Specificity Over Generality**: Write concrete details for THIS phase, not generic templates
2. **Context-Aware**: Read relevant codebase files to understand the actual implementation context
3. **Actionable**: Every instruction should be specific enough to execute immediately
4. **Complete**: Should be 300-500+ lines with comprehensive coverage
5. **Realistic**: Base estimates and complexity on actual task analysis

## Validation

Before completing, verify:
- [ ] Phase file is 300-500+ lines (or more if warranted)
- [ ] All tasks have detailed implementation sections
- [ ] Code examples are specific to the actual work
- [ ] Test cases are concrete and actionable
- [ ] Architecture section addresses actual integration
- [ ] Main plan updated with summary
- [ ] Metadata updated correctly

## Example Output

```
Analyzing plan structure...
  Current level: 0 (single file)
  Plan: specs/plans/028_complete_system_optimization.md

Reading Phase 3: Utils Consolidation...
  Objective: Complete utils/lib architectural cleanup
  Tasks: 6
  Complexity: Medium-High

Researching codebase context...
  Reading: utils/README.md
  Reading: lib/README.md
  Analyzing: 15 util scripts

Creating detailed implementation specification...
  Writing comprehensive overview
  Detailing 6 tasks with specific steps
  Adding architecture analysis
  Specifying test requirements
  Including error handling patterns

Creating directory structure (Level 0 → 1)...
  Created: specs/plans/028_complete_system_optimization/
  Moved: 028_complete_system_optimization.md → directory

Writing phase file (540 lines)...
  File: phase_3_utils_consolidation.md

Updating main plan...
  Replaced Phase 3 with summary and link

✓ Phase 3 expanded successfully
  Main plan: specs/plans/028_complete_system_optimization/028_complete_system_optimization.md
  Phase file: specs/plans/028_complete_system_optimization/phase_3_utils_consolidation.md
  Lines: 540
```

## Process Implementation

Now I'll execute this process for the specified plan and phase.
