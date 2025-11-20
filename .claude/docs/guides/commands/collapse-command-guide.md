# /collapse Command - Complete Guide

**Executable**: `.claude/commands/collapse.md`

**Quick Start**: Run `/collapse <plan-path>` for auto-analysis or `/collapse phase <plan-path> <number>` to collapse a specific phase.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/collapse` command reverses phase expansion by merging expanded phase content back into the main plan. It consolidates completed work, maintains task completion status, and cleans up directory structure.

### When to Use

- After completing all tasks in an expanded phase
- To consolidate simple phases (complexity <= 5)
- When preparing for final documentation
- To reduce plan complexity for review
- Before archiving completed features

### When NOT to Use

- Phase still has incomplete tasks
- Phase is actively being worked on by team members
- When you need detailed task tracking during implementation
- If the phase content needs to remain accessible separately

---

## Architecture

### Design Principles

- **Content Preservation**: 100% content preservation through verification
- **Safe Operations**: Files deleted only after content verified in parent
- **Delegation Pattern**: Uses complexity-estimator and plan-structure-manager agents

### Patterns Used

- Complexity-based agent delegation
- Content preservation verification
- Plan structure manager pattern (operation=collapse)

### Integration Points

- **complexity-estimator agent**: Identifies phases with low complexity
- **plan-structure-manager agent**: Performs the actual collapse
- **Expand command**: Reverse operation to expand phases

### Data Flow

```
User Request → Mode Detection → Complexity Analysis → Agent Delegation
                                                              ↓
Plan File (Updated) ← Cleanup ← Verification ← Content Merge
```

---

## Usage Examples

### Example 1: Auto-Analysis Mode

```bash
/collapse /home/user/.claude/specs/027_auth/plans/027_auth_plan/
```

**Expected Output**:
```
PROGRESS: Analyzing expanded phases for collapse candidates...
PROGRESS: Found 2 phases with complexity <= 5
PROGRESS: Collapsing Phase 1: Project Setup
PROGRESS: Collapsing Phase 4: Documentation
COLLAPSE_COMPLETE: 2 phases collapsed
```

**Explanation**:
Auto-analysis mode scans all expanded phases, calculates complexity scores, and collapses those meeting the threshold (complexity <= 5).

### Example 2: Explicit Phase Collapse

```bash
/collapse phase /home/user/.claude/specs/027_auth/plans/027_auth_plan/ 2
```

**Expected Output**:
```
PROGRESS: Reading expanded Phase 2 content...
PROGRESS: Merging content into parent plan...
PROGRESS: Verifying content preservation...
PROGRESS: Deleting phase file...
PROGRESS: Updating metadata...
COLLAPSE_COMPLETE: Phase 2 collapsed successfully
```

**Explanation**:
Explicitly collapses Phase 2 regardless of complexity score. Useful when you know a phase should be consolidated.

### Example 3: Stage Collapse (Level 2 to Level 1)

```bash
/collapse stage /home/user/.claude/specs/027_auth/plans/027_auth_plan/phase_3_frontend/ 2
```

**Expected Output**:
```
PROGRESS: Reading expanded Stage 2 content...
PROGRESS: Merging into phase file...
PROGRESS: Verifying content...
PROGRESS: Deleting stage file...
COLLAPSE_COMPLETE: Stage 2 collapsed successfully
```

**Explanation**:
Collapses a stage within an expanded phase file back to Level 1 organization.

---

## Advanced Topics

### Performance Considerations

- Content verification adds overhead but ensures safety
- Large phases (500+ lines) take longer to merge
- Auto-analysis efficient for bulk consolidation

### Customization

- Collapse complexity threshold configurable (default: 5)
- Adjust threshold based on team preferences
- Higher threshold = more phases collapse automatically

### Integration with Other Workflows

- **Expand command**: Reverse operation to expand phases
- **Implement command**: Complete phases before collapsing
- **Plan command**: Creates plans that may be collapsed later
- **Document command**: Often run after collapsing completed features

### Content Preservation

The collapse process:
1. Reads all content from expanded file
2. Merges into parent plan at correct location
3. Verifies byte-for-byte content match
4. Only then deletes the expanded file
5. Updates metadata (Structure Level, Expanded Phases list)

### Directory Cleanup

When the last expanded phase is collapsed:
- Plan returns to Level 0 (inline)
- Plan directory is deleted
- Single plan file remains

---

## Troubleshooting

### Common Issues

#### Issue 1: Content Verification Failed

**Symptoms**:
- "Content verification failed" error
- Phase file not deleted
- Parent plan partially updated

**Cause**:
Content mismatch during merge (usually whitespace or encoding)

**Solution**:
```bash
# Check both files
diff <plan-dir>/phase_N.md <(grep -A 1000 "### Phase N" <plan-path>)

# Manual fix if needed, then retry
/collapse phase <plan-path> <phase-number>
```

#### Issue 2: Phase File Not Found

**Symptoms**:
- "Phase file not found" error
- Phase number valid but file missing

**Cause**:
Phase was already collapsed or never expanded

**Solution**:
```bash
# Verify plan structure
ls -la <plan-dir>/

# Check metadata
grep "Expanded Phases" <plan-path>
```

#### Issue 3: Incomplete Tasks Warning

**Symptoms**:
- Warning about incomplete tasks
- Collapse proceeds but with caution

**Cause**:
Phase has unchecked task markers `[ ]`

**Solution**:
```bash
# Review incomplete tasks
grep -n "\[ \]" <plan-dir>/phase_N.md

# Complete tasks or mark as N/A before collapsing
```

### Debug Mode

Enable verbose output by checking the plan-structure-manager agent logs:
```bash
# Check collapse operations
grep "collapse" .claude/data/logs/*.log | tail -20
```

### Getting Help

- Check [Command Reference](.claude/docs/reference/standards/command-reference.md) for quick syntax
- Review [Directory Protocols](.claude/docs/concepts/directory-protocols.md) for plan levels
- See related commands: `/expand`, `/plan`, `/implement`

---

## See Also

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Adaptive Planning Configuration](.claude/docs/reference/standards/adaptive-planning.md)
- [Command Reference](.claude/docs/reference/standards/command-reference.md)
