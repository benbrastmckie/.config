---
description: Research a task and create reports
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash(git:*), TodoWrite, mcp__lean-lsp__lean_leansearch, mcp__lean-lsp__lean_loogle, mcp__lean-lsp__lean_leanfinder, mcp__lean-lsp__lean_local_search
argument-hint: TASK_NUMBER [FOCUS]
model: claude-opus-4-5-20251101
---

# /research Command

Conduct research for a task and create a research report.

## Arguments

- `$1` - Task number (required)
- Remaining args - Optional focus/prompt for research direction

## Execution

### 1. Parse and Validate

```
task_number = first token from $ARGUMENTS
focus_prompt = remaining tokens (optional)
```

Read .claude/specs/state.json:
- Find task by project_number
- Extract: language, status, project_name, description
- If not found: Error "Task {N} not found"

### 2. Validate Status

Allowed statuses: not_started, planned, partial, blocked
- If completed/abandoned: Error with recommendation
- If researching: Warn about stale status
- If already researched: Note existing report, offer --force

### 3. Update Status to RESEARCHING

Update both files atomically:
1. state.json: status = "researching"
2. TODO.md: Status: [RESEARCHING]

### 4. Route by Language

**If language == "lean":**
Use Lean-specific search tools:
- `lean_leansearch` - Natural language queries about Mathlib
- `lean_loogle` - Type signature pattern matching
- `lean_leanfinder` - Semantic concept search
- `lean_local_search` - Check local declarations

Search strategy:
1. Search for relevant theorems/lemmas
2. Find similar proofs in Mathlib
3. Identify required imports
4. Note proof patterns and tactics

**If language == "general" or other:**
Use web and codebase search:
- `WebSearch` - External documentation/tutorials
- `WebFetch` - Retrieve specific pages
- `Read`, `Grep`, `Glob` - Codebase exploration

Search strategy:
1. Search for relevant documentation
2. Find similar implementations
3. Identify patterns and best practices
4. Note dependencies and considerations

### 5. Create Research Report

Create directory if needed:
```
mkdir -p .claude/specs/{N}_{SLUG}/reports/
```

Find next report number (research-001.md, research-002.md, etc.)

Write report to `.claude/specs/{N}_{SLUG}/reports/research-{NNN}.md`:

```markdown
# Research Report: Task #{N}

**Task**: {title}
**Date**: {ISO_DATE}
**Focus**: {focus_prompt or "General research"}

## Summary

{2-3 sentence overview of findings}

## Findings

### {Topic 1}

{Detailed findings}

### {Topic 2}

{Detailed findings}

## Recommendations

1. {Approach recommendation}
2. {Key considerations}
3. {Potential challenges}

## References

- {Source 1}
- {Source 2}

## Next Steps

{Suggested next actions for planning/implementation}
```

### 6. Update Status to RESEARCHED

Update both files atomically:
1. state.json:
   - status = "researched"
   - artifacts = [{path, type: "research"}]
2. TODO.md:
   - Status: [RESEARCHED]
   - Add Research link

### 7. Git Commit

```bash
git add .claude/specs/
git commit -m "task {N}: complete research"
```

### 8. Output

```
Research completed for Task #{N}

Report: .claude/specs/{N}_{SLUG}/reports/research-{NNN}.md

Key findings:
- {finding 1}
- {finding 2}

Status: [RESEARCHED]
Next: /plan {N}
```
