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

**IMPORTANT**: Do NOT use generic templates. Instead:

1. **Read and understand** the phase objective and tasks
2. **Analyze** what the phase is actually trying to accomplish
3. **Research** the codebase context (read relevant files if needed)
4. **Write** a detailed, specific implementation plan

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
