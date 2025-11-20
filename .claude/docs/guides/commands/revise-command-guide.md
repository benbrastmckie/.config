# /revise Command - Complete Guide

**Executable**: `.claude/commands/revise.md`

**Quick Start**: Run `/revise "revise plan at /path/to/plan.md based on NEW_INSIGHTS"` - creates research and revises existing plan.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/revise` command provides a research-and-revise workflow that creates research reports based on new insights and then revises an existing implementation plan. It's designed for adaptive planning when new information emerges or requirements change.

### When to Use

- **Plan updates with new insights**: When research reveals information requiring plan changes
- **Requirement changes**: Adapting plans to changed specifications or constraints
- **Post-review adjustments**: Updating plans after code review feedback
- **Iterative refinement**: Improving plans based on implementation learnings

### When NOT to Use

- **Creating new plans**: Use `/plan` or `/plan` for initial plan creation
- **Research-only tasks**: Use `/research` if you don't need plan revision
- **Simple plan edits**: Use `/revise` for direct plan revision without research
- **Debugging**: Use `/debug` for debug-focused workflows

---

## Architecture

### Design Principles

1. **Two-Phase Workflow**: Research → Revision (no implementation)
2. **Backup Safety**: Automatic backup creation before revision
3. **Change Detection**: Fails if plan unmodified (prevents no-op revisions)
4. **Research-Informed Revision**: Revision based on new research findings
5. **Complexity-Aware**: Default complexity 2 (lower than new plan creation)

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Two-state workflow
- **Behavioral Injection**: (behavioral-injection.md) Agent behavior separated from orchestration
- **Fail-Fast Verification**: (Standard 0) Change detection ensures revision occurred
- **Backup Strategy**: (Standard 16) Automatic backups before modification

### Workflow States

```
┌──────────────┐
│   RESEARCH   │ ← New insights investigation
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     PLAN     │ ← Plan revision (terminal state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   COMPLETE   │
└──────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Research**: research-specialist agent for new insights investigation
- **Revision**: plan-architect agent for plan modification (Edit tool)
- **Backup**: Automatic timestamped backups in plans/backups/
- **Output**: Modified plan + backup + new research reports

### Data Flow

1. **Input**: Revision description with embedded plan path + optional complexity (default: 2)
2. **Plan Path Extraction**: Extracts /path/to/plan.md from description
3. **State Initialization**: sm_init() with workflow_type="research-and-revise"
4. **Research Phase**: research-specialist investigates new insights
5. **Backup Creation**: Original plan backed up to plans/backups/
6. **Revision Phase**: plan-architect modifies existing plan using Edit tool
7. **Change Verification**: Ensures plan actually changed (fails if identical to backup)
8. **Output**: Revised plan + backup + research reports

---

## Usage Examples

### Example 1: Basic Plan Revision

```bash
/revise"revise plan at .claude/specs/752_auth/plans/001_plan.md based on new security requirements"
```

**Expected Output**:
```
=== Research-and-Revise Workflow ===
Existing Plan: .claude/specs/752_auth/plans/001_plan.md
Revision Details: based on new security requirements
Research Complexity: 2

✓ State machine initialized

=== Phase 1: Research ===

EXECUTE NOW: USE the Task tool to invoke research-specialist agent

Workflow-Specific Context:
- Research Complexity: 2
- Revision Details: based on new security requirements
- Output Directory: .claude/specs/752_auth/reports
- Workflow Type: research-and-revise
- Existing Plan: .claude/specs/752_auth/plans/001_plan.md

✓ Research phase complete (total reports: 8, new: 2)

=== Phase 2: Plan Revision ===

✓ Backup created: .claude/specs/752_auth/plans/backups/001_plan_20251117_143022.md

EXECUTE NOW: USE the Task tool to invoke plan-architect agent

Workflow-Specific Context:
- Existing Plan Path: .claude/specs/752_auth/plans/001_plan.md
- Backup Path: .claude/specs/752_auth/plans/backups/001_plan_20251117_143022.md
- Revision Details: based on new security requirements
- Research Reports: [...]
- Workflow Type: research-and-revise
- Operation Mode: plan revision

✓ Plan revision complete: .claude/specs/752_auth/plans/001_plan.md

=== Research-and-Revise Complete ===

Workflow Type: research-and-revise
Specs Directory: .claude/specs/752_auth
Research Reports: 8 total (2 new)
Revised Plan: .claude/specs/752_auth/plans/001_plan.md
Plan Backup: .claude/specs/752_auth/plans/backups/001_plan_20251117_143022.md

Next Steps:
- Review revised plan: cat .claude/specs/752_auth/plans/001_plan.md
- Compare with backup: diff .claude/specs/752_auth/plans/backups/001_plan_20251117_143022.md .claude/specs/752_auth/plans/001_plan.md
- Implement revised plan: /implement .claude/specs/752_auth/plans/001_plan.md
```

**Explanation**:
Researches new security requirements, backs up original plan, revises plan based on research findings. Change verification ensures plan was actually modified.

### Example 2: Higher Complexity Revision

```bash
/revise"revise plan at ./plans/001_api.md based on performance testing results showing N+1 query issues --complexity 3"
```

**Expected Output**:
```
=== Research-and-Revise Workflow ===
Existing Plan: ./plans/001_api.md
Revision Details: based on performance testing results showing N+1 query issues
Research Complexity: 3

✓ State machine initialized

=== Phase 1: Research ===
✓ Research phase complete (total reports: 12, new: 5)

=== Phase 2: Plan Revision ===
✓ Backup created: ./plans/backups/001_api_20251117_143500.md
✓ Plan revision complete

=== Research-and-Revise Complete ===
```

**Explanation**:
Higher complexity (3) for deeper investigation of performance issues. Creates more comprehensive research reports about N+1 query patterns and solutions.

### Example 3: Post-Implementation Revision

```bash
/revise"revise plan at .claude/specs/753_caching/plans/001_plan.md based on implementation learnings about Redis memory limits"
```

**Expected Output**:
```
=== Research-and-Revise Workflow ===
Existing Plan: .claude/specs/753_caching/plans/001_plan.md
Revision Details: based on implementation learnings about Redis memory limits
Research Complexity: 2

✓ State machine initialized

=== Phase 1: Research ===
✓ Research phase complete (total reports: 6, new: 2)

=== Phase 2: Plan Revision ===
✓ Backup created: .claude/specs/753_caching/plans/backups/001_plan_20251117_144000.md
✓ Plan revision complete

=== Research-and-Revise Complete ===
```

**Explanation**:
Updates plan based on real implementation experience. Research investigates Redis memory management, revision adjusts plan to address constraints discovered during implementation.

### Example 4: No Changes Needed (Error Case)

```bash
/revise"revise plan at ./plans/001_plan.md based on minor style feedback"
```

**Expected Output**:
```
=== Research-and-Revise Workflow ===
...
=== Phase 2: Plan Revision ===

✓ Backup created: ./plans/backups/001_plan_20251117_144500.md

EXECUTE NOW: USE the Task tool to invoke plan-architect agent
...

ERROR: Plan file not modified (identical to backup)
DIAGNOSTIC: Plan revision must make changes based on research insights
SOLUTION: Review research reports and ensure agent applies revisions
```

**Explanation**:
Fail-fast verification detects when plan wasn't actually modified. Prevents no-op revisions and ensures meaningful changes occur.

---

## Advanced Topics

### Performance Considerations

**Default Complexity**:
- Research-and-revise defaults to complexity 2 (lower than new plan creation)
- Rationale: Revisions typically need focused investigation, not comprehensive research

**Complexity Selection**:
- **Complexity 1**: Minor updates, quick research
- **Complexity 2** (default): Standard revisions with moderate investigation
- **Complexity 3**: Significant changes requiring deeper research
- **Complexity 4**: Major overhauls needing exhaustive investigation

**Backup Strategy**:
- Automatic timestamped backups (YYYYMMDD_HHMMSS format)
- Stored in plans/backups/ subdirectory
- Manual restoration: `cp plans/backups/BACKUP.md plans/PLAN.md`

### Customization

**Complexity Override**:
```bash
# Higher complexity for major revisions
/revise"revise plan at ./plans/001.md based on architecture change --complexity 4"

# Lower complexity for minor updates
/revise"revise plan at ./plans/001.md based on typo fixes --complexity 1"
```

**Revision Description Best Practices**:
- **Always include plan path**: Must contain `/path/to/plan.md` or `./relative/path.md`
- **Specify revision reason**: "based on security audit findings" vs generic "update plan"
- **Provide context**: "performance testing shows 5s latency" vs "slow"

**Plan Path Formats**:
```bash
# Absolute path
/revise"revise plan at /home/user/.claude/specs/752/plans/001.md based on changes"

# Relative path
/revise"revise plan at .claude/specs/752/plans/001.md based on changes"
/revise"revise plan at ./plans/001.md based on changes"

# Parent directory path
/revise"revise plan at ../other-project/plans/001.md based on changes"
```

### Integration with Other Workflows

**Implementation → Revise Chain**:
```bash
/build plans/001.md              # Start implementation
# Discover issues during implementation
/revise"revise plan at plans/001.md based on discovered API limitations"
/build plans/001.md              # Continue with revised plan
```

**Review → Revise Chain**:
```bash
# After code review
/revise"revise plan at plans/001.md based on security review findings"
/build plans/001.md              # Implement security improvements
```

**Iterative Revision**:
```bash
/plan "implement caching"
# Initial implementation attempt
/revise"revise plan at plans/001.md based on memory constraints"
# Second implementation attempt
/revise"revise plan at plans/001.md based on performance testing"
# Final implementation
```

---

## Troubleshooting

### Common Issues

#### Issue 1: No Plan Path Found in Description

**Symptoms**:
- Error: "No plan path found in revision description"
- Command exits immediately

**Cause**:
Revision description doesn't contain valid plan path pattern.

**Solution**:
```bash
# Include plan path in description
/revise"revise plan at /path/to/plan.md based on changes"

# Path formats that work:
# - /absolute/path/plan.md
# - ./relative/path/plan.md
# - ../parent/path/plan.md
# - .claude/specs/NNN/plans/plan.md

# These DON'T work:
# - "revise my plan based on changes" (no path)
# - "update plan.md" (ambiguous, no directory context)
```

#### Issue 2: Plan File Not Found

**Symptoms**:
- Error: "Existing plan not found: /path/to/plan.md"
- Diagnostic suggests ensuring file exists

**Cause**:
Plan path in description doesn't point to existing file.

**Solution**:
```bash
# Verify plan exists
ls /path/to/plan.md

# Use correct path (check spelling, directory)
find .claude/specs -name "*.md" -path "*/plans/*"

# Ensure path is absolute or relative from current directory
pwd  # Check current directory
```

#### Issue 3: Plan Not Modified (Identical to Backup)

**Symptoms**:
- Error: "Plan file not modified (identical to backup)"
- Diagnostic says revision must make changes

**Cause**:
Plan-architect didn't actually modify the plan, or modifications were trivial.

**Solution**:
```bash
# Ensure revision details are meaningful
# Bad: "update plan"
# Good: "revise plan to use JWT instead of session cookies based on security audit"

# Check if research provided sufficient context
cat .claude/specs/*/reports/*.md

# Manually compare backup and current plan
diff plans/backups/BACKUP.md plans/PLAN.md
```

#### Issue 4: Backup Creation Failed

**Symptoms**:
- Error: "Backup creation failed at /path/to/backup"
- Backup verification shows file too small

**Cause**:
Write permissions issue or disk space problem.

**Solution**:
```bash
# Check backup directory exists and is writable
ls -ld plans/backups/
mkdir -p plans/backups/

# Verify disk space
df -h

# Check file permissions
ls -l plans/

# Manually create backup if needed
cp plans/001.md plans/backups/001_manual_backup.md
```

#### Issue 5: Research Creates No New Reports

**Symptoms**:
- Warning: "No new research reports created"
- Note: "Proceeding with plan revision using existing reports"

**Cause**:
Research topic too narrow or existing reports already cover the area.

**Solution**:
This is often normal behavior. The command will proceed using existing reports.

```bash
# If you need new research, increase complexity
/revise"revise plan at plans/001.md based on details --complexity 3"

# Or provide more specific revision details
/revise"revise plan at plans/001.md based on newly discovered WebSocket security vulnerability CVE-2025-1234"
```

### Debug Mode

Enable verbose output:

```bash
# Bash debugging
set -x
/revise"revise plan at path/to/plan.md based on changes"
set +x
```

**Path Extraction Debugging**:
```bash
# Test path extraction pattern
REVISION_DESC="revise plan at ./plans/001.md based on changes"
echo "$REVISION_DESC" | grep -oE '[./][^ ]+\.md' | head -1
# Should output: ./plans/001.md
```

**Backup Verification**:
```bash
# List all backups
ls -lh plans/backups/

# Compare backup with current plan
diff plans/backups/BACKUP.md plans/PLAN.md

# Check backup file size
ls -lh plans/backups/BACKUP.md
# Should be >100 bytes
```

**Change Detection**:
```bash
# Manually check if files differ
cmp -s plans/backups/BACKUP.md plans/PLAN.md
echo $?  # 0 = identical (would fail), 1 = different (would pass)
```

### Getting Help

- Check [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [Plan-Architect Agent](../../agents/plan-architect.md) for revision patterns
- See related commands: `/plan`, `/revise`, `/plan`
- Review [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md) for plan structure

---

## See Also

- [Research-Specialist Agent](../../agents/research-specialist.md)
- [Plan-Architect Agent](../../agents/plan-architect.md)
- [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md)
- [Directory Protocols](../concepts/directory-protocols.md)
- [Command Reference](../reference/standards/command-reference.md)
- Related Commands: `/plan`, `/revise`, `/build`, `/implement`
