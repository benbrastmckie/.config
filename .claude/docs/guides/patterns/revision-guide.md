# Revision Guide

This guide covers plan revision workflows, revision types, and auto-mode operation.

## Contents

- [Revise Auto-Mode](#revise-auto-mode)
- [Revision Types](#revision-types)

---

# Automated Mode Specification

This document provides comprehensive documentation for the automated revision mode (`--auto-mode`) in the /revise command, designed for programmatic integration with /implement.

**Referenced by**: [revise.md](../../commands/revise.md)

**Contents**:
- Context JSON Structure
- Revision Types (expand_phase, add_phase, split_phase, update_tasks, collapse_phase)
- Decision Logic and Safety Mechanisms
- Integration with /implement
- Testing Auto-Mode

---

## Automated Mode Specification

### Context JSON Structure

When invoked with `--auto-mode`, the command expects a `--context` parameter with JSON in this format:

```json
{
  "revision_type": "<type>",
  "current_phase": <number>,
  "reason": "<explanation>",
  "suggested_action": "<action description>",
  "<additional_context>": <context-specific data>
}
```

### Revision Types

#### 1. `expand_phase` - Expand Complex Phase

**Trigger**: Phase complexity score exceeds threshold (score > 8 or tasks > 10)

**Context Fields**:
```json
{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score exceeds threshold (9.2 > 8)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {
    "tasks": 12,
    "score": 9.2,
    "estimated_duration": "4-5 sessions"
  }
}
```

**Automated Actions**:
1. Invoke `/expand phase <plan> <phase-number>`
2. Update plan structure level metadata (0 → 1)
3. Add revision history entry
4. Return updated plan path

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "expanded_phase",
  "phase_expanded": 3,
  "new_structure_level": 1,
  "updated_files": [
    "specs/plans/025_plan/025_plan.md",
    "specs/plans/025_plan/phase_3_implementation.md"
  ]
}
```

#### 2. `add_phase` - Insert Missing Phase

**Trigger**: Multiple test failures indicate missing prerequisites or scope drift

**Context Fields**:
```json
{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "test_failure_log": "Error: Module not found: crypto-utils\nError: Database not initialized",
  "insert_position": "before",
  "new_phase_name": "Setup Dependencies"
}
```

**Automated Actions**:
1. Insert new phase at specified position (before/after current phase)
2. Renumber subsequent phases
3. Populate new phase with basic structure:
   - Objective (derived from reason)
   - Tasks (derived from failure analysis)
   - Dependencies
4. Update phase count in metadata
5. Add revision history entry

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "added_phase",
  "new_phase_number": 2,
  "new_phase_name": "Setup Dependencies",
  "phases_renumbered": true,
  "total_phases": 6
}
```

#### 3. `split_phase` - Split Overly Broad Phase

**Trigger**: Phase proves to cover multiple distinct concerns during implementation

**Context Fields**:
```json
{
  "revision_type": "split_phase",
  "current_phase": 4,
  "reason": "Phase 4 combines frontend and backend work - too broad",
  "suggested_action": "Split into frontend (Phase 4) and backend (Phase 5)",
  "split_criteria": {
    "part1_name": "Frontend Implementation",
    "part1_tasks": [1, 2, 3, 4],
    "part2_name": "Backend Implementation",
    "part2_tasks": [5, 6, 7, 8, 9]
  }
}
```

**Automated Actions**:
1. Create new phase after current phase
2. Move specified tasks to new phase
3. Update both phases' objectives
4. Renumber subsequent phases
5. Update dependencies
6. Add revision history

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "split_phase",
  "original_phase": 4,
  "new_phases": [4, 5],
  "phases_renumbered": true,
  "total_phases": 7
}
```

#### 4. `update_tasks` - Modify Phase Tasks

**Trigger**: Implementation reveals tasks need adjustment (add, remove, reorder)

**Context Fields**:
```json
{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Migration script required before data model changes",
  "suggested_action": "Add migration task before schema changes",
  "task_operations": [
    {"action": "insert", "position": 2, "task": "Create database migration script"},
    {"action": "remove", "position": 5},
    {"action": "update", "position": 3, "task": "Update schema with foreign keys"}
  ]
}
```

**Automated Actions**:
1. Apply task operations in order
2. Preserve completion markers for existing tasks
3. Update acceptance criteria if needed
4. Add revision history

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "updated_tasks",
  "phase": 3,
  "tasks_added": 1,
  "tasks_removed": 1,
  "tasks_updated": 1
}
```

#### 5. `collapse_phase` - Collapse Simple Expanded Phase

**Trigger**: Phase completed and now simple (tasks ≤ 5, complexity < 6.0)

**Context Fields**:
```json
{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {
    "tasks": 4,
    "complexity_score": 3.5,
    "completion": true
  }
}
```

**Automated Actions**:
1. Validate phase is expanded (not inline)
2. Validate phase has no expanded stages
3. Invoke `/collapse phase <plan> <phase-number>`
4. Update structure level metadata
5. Add revision history entry
6. Return updated plan path

**Response Format**:
```json
{
  "status": "success",
  "action_taken": "collapsed_phase",
  "phase_collapsed": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "new_structure_level": 1,
  "updated_file": "specs/plans/025_plan/025_plan.md"
}
```

**Error Cases**:
- Phase not expanded: Return error with `error_type: "invalid_state"`
- Phase has expanded stages: Return error with message "collapse stages first"
- Collapse operation fails: Return error with collapse command output

### Decision Logic

```
Auto-Mode Invocation
     ↓
Parse --context JSON
     ↓
Validate required fields
  ├─ Missing fields → Return error
  └─ Valid → Continue
     ↓
Switch on revision_type:
  ├─ "expand_phase" → Invoke /expand phase
  ├─ "add_phase" → Insert new phase
  ├─ "split_phase" → Split existing phase
  ├─ "update_tasks" → Modify task list
  ├─ "collapse_phase" → Invoke /collapse phase (validate first)
  └─ Unknown type → Return error
     ↓
Create backup of original plan
     ↓
Execute automated revision logic
  ├─ Success → Add revision history, return success response
  └─ Failure → Restore backup, return error response
     ↓
Return JSON response to /implement
```

### Response Format

**Success Response**:
```json
{
  "status": "success",
  "action_taken": "<revision_type>",
  "plan_file": "<updated plan path>",
  "backup_file": "<backup path>",
  "revision_summary": "<brief description>",
  "structure_recommendations": {
    "collapse_opportunities": [
      {
        "phase": 2,
        "phase_name": "Simple Phase",
        "tasks": 4,
        "complexity": 3.5,
        "command": "/collapse phase <plan-path> 2"
      }
    ],
    "expansion_opportunities": [
      {
        "phase": 5,
        "phase_name": "Complex Phase",
        "tasks": 12,
        "complexity": 9.2,
        "command": "/expand phase <plan-path> 5"
      }
    ]
  },
  "<context-specific-fields>": "<values>"
}
```

**Error Response**:
```json
{
  "status": "error",
  "error_type": "<error classification>",
  "error_message": "<detailed error>",
  "plan_file": "<original plan path>",
  "backup_restored": true/false
}
```

### Integration with /implement

**When /implement Detects Trigger**:

```
/implement Phase 3
     ↓
Execute tasks
     ↓
Detect complexity > threshold
     ↓
Build revision context JSON
     ↓
Invoke: /revise <plan> --auto-mode --context '<json>'
     ↓
Parse JSON response
  ├─ status=="success" → Continue with updated plan
  └─ status=="error" → Log error, ask user for guidance
```

**Loop Prevention**:
- Track replanning count in checkpoint
- Maximum 2 replans per phase
- After limit, escalate to user

**Checkpoint Updates**:
```json
{
  "replanning_count": 1,
  "last_replan_reason": "Phase 3 complexity exceeded threshold",
  "replan_phase_3_count": 1,
  "replan_history": [
    {
      "phase": 3,
      "type": "expand_phase",
      "timestamp": "2025-10-06T15:00:00Z",
      "reason": "Complexity threshold exceeded"
    }
  ]
}
```

### Validation and Error Handling

**Input Validation**:
- `--auto-mode` flag present
- `--context` parameter provided
- JSON is valid and parseable
- Required fields present for revision_type
- `revision_type` is recognized
- `current_phase` is valid number

**Error Cases**:

1. **Invalid JSON**: Return error, do not modify plan
2. **Unknown revision_type**: Return error with list of valid types
3. **Invalid phase number**: Return error, check plan structure
4. **Missing required fields**: Return error listing missing fields
5. **File operation failure**: Restore backup, return error
6. **Expansion command fails**: Return error with /expand phase output

### Safety Mechanisms

1. **Always Create Backup**: Before any modification
2. **Atomic Operations**: Complete revision or rollback entirely
3. **Validation Before Write**: Verify plan structure after changes
4. **Idempotency**: Same context → same result (deterministic)
5. **Audit Trail**: Every auto-mode revision logged in plan history

### Example Revision History Entry (Auto-Mode)

```markdown
## Revision History

### [2025-10-06 15:23:45] - Auto-Revision: Expand Phase 3
**Trigger**: /implement detected complexity threshold exceeded
**Type**: expand_phase
**Reason**: Phase 3 complexity score 9.2 exceeds threshold 8.0 (12 tasks)
**Action**: Expanded Phase 3 into separate file
**Files Modified**:
- Created: specs/plans/025_plan/phase_3_implementation.md
- Updated: specs/plans/025_plan/025_plan.md (structure level 0 → 1)
**Automated**: Yes (--auto-mode)
```

## Testing Auto-Mode

```bash
# Test expand_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "expand_phase",
  "current_phase": 2,
  "reason": "Phase complexity: 11 tasks, score 9.5",
  "suggested_action": "Expand phase 2",
  "complexity_metrics": {"tasks": 11, "score": 9.5}
}'

# Expected: Phase 2 expanded, structure level updated

# Test add_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "add_phase",
  "current_phase": 1,
  "reason": "Missing database setup phase",
  "suggested_action": "Add phase before Phase 2",
  "insert_position": "after",
  "new_phase_name": "Database Setup"
}'

# Expected: New phase inserted after Phase 1, phases renumbered

# Test collapse_phase trigger
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "collapse_phase",
  "current_phase": 3,
  "reason": "Phase 3 completed and now simple (4 tasks, complexity 3.5)",
  "suggested_action": "Collapse Phase 3 back into main plan",
  "simplicity_metrics": {"tasks": 4, "complexity_score": 3.5, "completion": true}
}'

# Expected: Phase 3 collapsed, structure level updated

# Test error handling
/revise specs/plans/test_plan.md --auto-mode --context '{
  "revision_type": "unknown_type"
}'

# Expected: Error response with valid types listed
```

---

# Revision Types and Operation Modes

This document describes the different operation modes and revision types supported by the /revise command.

**Referenced by**: [revise.md](../../commands/revise.md)

**Contents**:
- Interactive Mode vs Auto-Mode
- Mode Comparison
- When to Use Each Mode

---

## Operation Modes

### Interactive Mode (Default)

**Purpose**: User-driven plan revisions with full context and explanation

**Behavior**:
- User provides natural language revision description
- Command infers which plan to revise from conversation context
- Presents changes and asks for confirmation
- Creates detailed revision history with rationale
- Suitable for major strategic changes

**Use When**:
- Changing project scope or requirements
- Incorporating new research findings
- Restructuring phases based on lessons learned
- User wants visibility and control over changes

### Automated Mode (`--auto-mode`)

**Purpose**: Programmatic plan revision triggered by `/implement` during execution

**Behavior**:
- Accepts structured JSON context with specific revision parameters
- Executes deterministic revision logic based on `revision_type`
- Returns machine-readable success/failure status
- Creates concise revision history for audit trail
- Designed for /implement integration (no user interaction)

**Use When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Scope drift detected (missing phases discovered)
- Automated expansion of phases is needed

**Not Suitable For**:
- Strategic plan changes requiring human judgment
- Incorporating new requirements from stakeholders
- Major scope changes or pivots

## Important Notes

### What This Command Does
- **Modifies plans or reports** with your requested changes
- **Preserves completion status** of already-executed phases (plans only)
- **Adds revision history** to track changes
- **Creates a backup** of the original artifact
- **Updates phase details** (plans) or findings/recommendations (reports)
- **Evaluates structure optimization** opportunities after revision (plans only)
- **Displays recommendations** for collapsing simple phases or expanding complex phases (plans only)
- **Section targeting** for reports (focuses on specific sections when requested)
- **Auto-mode**: Returns structured success/failure response for /implement (plans only)

### What This Command Does NOT Do
- **Does NOT execute any code changes**
- **Does NOT run tests**
- **Does NOT create commits**
- **Does NOT implement the plan**
- **Auto-mode does NOT ask for user confirmation** (deterministic logic only)

To implement the revised plan after revision, use `/implement [plan-file]`

## Mode Comparison

| Aspect | Interactive Mode | Auto-Mode |
|--------|------------------|-----------|
| **Trigger** | User explicitly calls `/revise` | `/implement` detects trigger condition |
| **Input** | Natural language description | Structured JSON context |
| **Confirmation** | Presents changes, asks confirmation (optional) | No confirmation, deterministic execution |
| **Use Case** | User-driven plan/report changes | Automated plan adjustments during implementation |
| **Revision Types** | Any content change | Specific types: expand_phase, add_phase, split_phase, update_tasks, collapse_phase |
| **History Format** | Detailed rationale and context | Concise audit trail with trigger info |
| **Artifact Support** | Plans and reports | Plans only |
| **Context** | Research reports (optional) | JSON context with metrics |

### When to Use Each Mode

**Use Interactive Mode When**:
- Incorporating new requirements from stakeholders
- Revising based on research findings
- Making strategic plan changes
- Updating reports with new findings
- You want visibility and control over changes

**Use Auto-Mode When**:
- `/implement` detects complexity threshold exceeded
- Multiple test failures indicate missing prerequisites
- Automated structure optimization needed
- You're building automated workflows

**Auto-Mode is NOT Suitable For**:
- Strategic plan changes requiring human judgment
- Major scope changes or pivots
- Report modifications
- Initial plan creation
