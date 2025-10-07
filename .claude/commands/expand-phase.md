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

See "Agent Invocation Infrastructure" section below for detailed agent usage.

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
