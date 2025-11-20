# /expand Command - Complete Guide

**Executable**: `.claude/commands/expand.md`

**Quick Start**: Run `/expand <plan-path>` for auto-analysis or `/expand phase <plan-path> <number>` for explicit expansion.

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

The `/expand` command transforms brief phase outlines (30-50 lines) into detailed implementation specifications (300-500+ lines). It supports the progressive plan organization from Level 0 (inline) to Level 1 (phase files) to Level 2 (stage files).

### When to Use

- Phase complexity score exceeds threshold (8+)
- Phase has more than 10 tasks
- Implementation requires detailed specifications
- Need to break down complex phases for parallel work
- Team needs more granular task tracking

### When NOT to Use

- Simple phases that don't need expansion
- Phases already at maximum detail level
- When you want to keep the plan compact
- After implementation has started (use `/collapse` to consolidate completed work)

---

## Architecture

### Design Principles

- **Delegation Pattern**: Orchestrator delegates to specialized agents (complexity-estimator, plan-structure-manager)
- **Progressive Organization**: Level 0 (inline) to Level 1 (phase files) to Level 2 (stage files)
- **Fallback Mechanisms**: 100% expansion success through multiple fallback strategies

### Patterns Used

- Complexity-based agent delegation
- Plan structure manager pattern
- Verification checkpoint pattern

### Integration Points

- **complexity-estimator agent**: Analyzes phases for complexity score
- **plan-structure-manager agent**: Performs the actual expansion
- **Collapse command**: Reverse operation to consolidate completed phases

### Data Flow

```
User Request → Mode Detection → Complexity Analysis → Agent Delegation
                                                              ↓
Plan File ← Metadata Update ← Verification ← Expanded Phase File
```

---

## Usage Examples

### Example 1: Auto-Analysis Mode

```bash
/expand /home/user/.claude/specs/027_auth/plans/027_auth_plan.md
```

**Expected Output**:
```
PROGRESS: Analyzing plan for expansion candidates...
PROGRESS: Found 3 phases with complexity >= 8
PROGRESS: Expanding Phase 2: Backend Implementation
PROGRESS: Expanding Phase 3: Frontend Integration
PROGRESS: Expanding Phase 5: Testing Suite
EXPANSION_COMPLETE: 3 phases expanded
```

**Explanation**:
Auto-analysis mode scans all phases, calculates complexity scores, and expands those meeting the threshold. This is the recommended mode for initial plan expansion.

### Example 2: Explicit Phase Expansion

```bash
/expand phase /home/user/.claude/specs/027_auth/plans/027_auth_plan.md 3
```

**Expected Output**:
```
PROGRESS: Extracting Phase 3 content...
PROGRESS: Creating phase file: 027_auth_plan/phase_3_frontend.md
PROGRESS: Updating parent plan metadata...
EXPANSION_COMPLETE: Phase 3 expanded successfully
```

**Explanation**:
Explicitly expands Phase 3 regardless of complexity score. Useful when you know a phase needs detailed specification.

### Example 3: Stage Expansion (Level 2)

```bash
/expand stage /home/user/.claude/specs/027_auth/plans/027_auth_plan/phase_3_frontend.md 2
```

**Expected Output**:
```
PROGRESS: Extracting Stage 2 from phase file...
PROGRESS: Creating stage file: phase_3_frontend/stage_2_components.md
PROGRESS: Updating phase file metadata...
EXPANSION_COMPLETE: Stage 2 expanded successfully
```

**Explanation**:
Expands a stage within an already-expanded phase file to Level 2 organization. Use for very complex phases requiring granular breakdown.

---

## Advanced Topics

### Performance Considerations

- Auto-analysis adds ~2-3s overhead for complexity calculation
- Large plans (10+ phases) may take longer for full analysis
- Consider explicit expansion for targeted optimization

### Customization

- Complexity threshold configurable via `.claude/docs/reference/standards/adaptive-planning.md`
- Default threshold: 8 for expansion
- Adjust based on project needs (higher = fewer expansions)

### Integration with Other Workflows

- **Plan command**: Creates plans that may need expansion
- **Implement command**: Executes expanded phases
- **Collapse command**: Consolidates completed expansions
- **Revise command**: Updates expanded phase content

### Content Quality

Expanded phases include:
- Concrete implementation details (not generic guidance)
- Specific code examples and patterns
- Detailed testing specifications
- Architecture and design decisions
- Error handling patterns
- Performance considerations

---

## Troubleshooting

### Common Issues

#### Issue 1: Phase Not Expanding

**Symptoms**:
- Command completes but phase stays inline
- "No phases found meeting threshold" message

**Cause**:
Phase complexity score is below threshold (default: 8)

**Solution**:
```bash
# Force expansion with explicit mode
/expand phase <plan-path> <phase-number>
```

#### Issue 2: Expansion Agent Timeout

**Symptoms**:
- Command hangs during agent invocation
- Timeout error after 2+ minutes

**Cause**:
Complex phase content causing agent processing delay

**Solution**:
```bash
# Check agent status
ls -la .claude/tmp/

# Retry with simpler scope
/expand phase <plan-path> <phase-number>
```

#### Issue 3: Metadata Not Updated

**Symptoms**:
- Phase file created but parent plan unchanged
- Structure Level still shows "0"

**Cause**:
Metadata update step failed or was skipped

**Solution**:
```bash
# Verify plan structure
grep "Structure Level" <plan-path>

# Manually update if needed
# Change "Structure Level: 0" to "Structure Level: 1"
```

### Debug Mode

Enable verbose output by checking the plan-structure-manager agent logs:
```bash
# Check recent agent activity
grep "expansion" .claude/data/logs/*.log | tail -20
```

### Getting Help

- Check [Command Reference](.claude/docs/reference/standards/command-reference.md) for quick syntax
- Review [Directory Protocols](.claude/docs/concepts/directory-protocols.md) for plan levels
- See related commands: `/collapse`, `/plan`, `/implement`

---

## See Also

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Adaptive Planning Configuration](.claude/docs/reference/standards/adaptive-planning.md)
- [Command Reference](.claude/docs/reference/standards/command-reference.md)
