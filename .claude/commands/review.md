---
description: Review code and create analysis reports
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), TodoWrite, mcp__lean-lsp__*
argument-hint: [SCOPE] [--create-tasks]
model: claude-opus-4-5-20251101
---

# /review Command

Analyze codebase, identify issues, and optionally create tasks for fixes.

## Arguments

- `$1` - Optional scope: file path, directory, or "all"
- `--create-tasks` - Create tasks for identified issues

## Execution

### 1. Parse Arguments

```
scope = $1 or "all"
create_tasks = "--create-tasks" in $ARGUMENTS
```

Determine review scope:
- If file path: Review that file
- If directory: Review all files in directory
- If "all": Review entire codebase

### 2. Gather Context

**For Lean files (.lean):**
- Run `lean_diagnostic_messages` for each file
- Check for `sorry`, axioms, admitted proofs
- Identify incomplete theorems
- Check import organization

**For general code:**
- Check for TODO/FIXME comments
- Identify code smells
- Check for security issues
- Review error handling

**For documentation:**
- Check for outdated information
- Identify missing documentation
- Verify links work

### 3. Analyze Findings

Categorize issues:
- **Critical**: Broken functionality, security vulnerabilities
- **High**: Missing features, significant bugs
- **Medium**: Code quality issues, incomplete implementations
- **Low**: Style issues, minor improvements

### 4. Create Review Report

Write to `.claude/specs/reviews/review-{DATE}.md`:

```markdown
# Code Review Report

**Date**: {ISO_DATE}
**Scope**: {scope}
**Reviewed by**: Claude

## Summary

- Total files reviewed: {N}
- Critical issues: {N}
- High priority issues: {N}
- Medium priority issues: {N}
- Low priority issues: {N}

## Critical Issues

### {Issue Title}
**File**: `path/to/file:line`
**Description**: {what's wrong}
**Impact**: {why it matters}
**Recommended fix**: {how to fix}

## High Priority Issues

{Same format}

## Medium Priority Issues

{Same format}

## Low Priority Issues

{Same format}

## Code Quality Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Sorry count | {N} | {OK/Warning/Critical} |
| Axiom count | {N} | {OK/Warning} |
| TODO count | {N} | {Info} |
| Build status | {Pass/Fail} | {Status} |

## Recommendations

1. {Priority recommendation}
2. {Secondary recommendation}
```

### 5. Create Tasks (if --create-tasks)

For each High/Critical issue, create a task:

```
/task "Fix: {issue title}"
```

Link tasks to review report.

### 6. Update Registries (if applicable)

If reviewing specific domains, update relevant registries:
- `.claude/docs/registries/lean-files.md`
- `.claude/docs/registries/documentation.md`

### 7. Git Commit

```bash
git add .claude/specs/reviews/
git commit -m "review: {scope} code review"
```

### 8. Output

```
Review complete for: {scope}

Report: .claude/specs/reviews/review-{DATE}.md

Summary:
- Critical: {N} issues
- High: {N} issues
- Medium: {N} issues
- Low: {N} issues

{If --create-tasks}
Created {N} tasks for critical/high issues:
- Task #{N1}: {title}
- Task #{N2}: {title}

Top recommendations:
1. {recommendation}
2. {recommendation}
```
