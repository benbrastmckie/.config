---
description: Create new version of implementation plan
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), TodoWrite
argument-hint: TASK_NUMBER [REASON]
model: claude-opus-4-5-20251101
---

# /revise Command

Create a new version of an implementation plan, incorporating lessons learned.

## Arguments

- `$1` - Task number (required)
- Remaining args - Optional reason for revision

## Execution

### 1. Parse and Validate

```
task_number = first token from $ARGUMENTS
revision_reason = remaining tokens (optional)
```

Read .claude/specs/state.json:
- Find task by project_number
- Extract: language, status, project_name
- If not found: Error "Task {N} not found"

### 2. Validate Status

Allowed: planned, implementing, partial, blocked
- If not_started: Error "No plan to revise, use /plan first"
- If completed: Error "Task completed, no revision needed"
- If researched: Note "Consider /plan instead for initial plan"

### 3. Load Current Context

1. **Current plan** from .claude/specs/{N}_{SLUG}/plans/implementation-{LATEST}.md
   - Extract phase statuses (what's done, what's remaining)
   - Note which phases succeeded/failed

2. **Research reports** if any

3. **Implementation progress** - what was learned during partial implementation

### 4. Analyze What Changed

Compare original plan assumptions vs reality:
- What phases succeeded?
- What phases failed and why?
- What new information emerged?
- What dependencies weren't anticipated?

### 5. Create Revised Plan

Increment version: implementation-002.md, implementation-003.md, etc.

Write to `.claude/specs/{N}_{SLUG}/plans/implementation-{NEW_VERSION}.md`:

```markdown
# Implementation Plan: Task #{N}

**Task**: {title}
**Version**: {NEW_VERSION}
**Created**: {ISO_DATE}
**Revision of**: implementation-{PREV_VERSION}.md
**Reason**: {revision_reason or "Plan adjustment based on implementation feedback"}

## Revision Summary

{What changed from previous version and why}

### Previous Plan Status
- Phase 1: [COMPLETED] - {outcome}
- Phase 2: [PARTIAL] - {what happened}
- Phase 3: [NOT STARTED] - {now revised}

### Key Changes
1. {Change 1 and rationale}
2. {Change 2 and rationale}

## Overview

{Updated implementation approach}

## Phases

### Phase 1: {Name} [COMPLETED]
{Preserved from previous - already done}

### Phase 2: {Revised Name}
**Status**: [NOT STARTED]
**Estimated effort**: {revised estimate}

{Revised steps based on learnings}

### Phase 3: {New/Revised}
...

## Risks and Mitigations

{Updated based on experience}

## Success Criteria

{Potentially revised criteria}
```

### 6. Update Status

Update both files atomically:
1. state.json:
   - status = "planned" (reset for re-implementation)
   - plan_version = NEW_VERSION
   - artifacts += [{path, type: "plan"}]
2. TODO.md:
   - Status: [PLANNED]
   - Update Plan link to new version

### 7. Git Commit

```bash
git add .claude/specs/
git commit -m "task {N}: revise plan (v{NEW_VERSION})"
```

### 8. Output

```
Plan revised for Task #{N}

Previous: implementation-{PREV}.md
New: implementation-{NEW}.md

Key changes:
- {Change 1}
- {Change 2}

Preserved phases: 1
Revised phases: 2-3

Status: [PLANNED]
Next: /implement {N}
```
