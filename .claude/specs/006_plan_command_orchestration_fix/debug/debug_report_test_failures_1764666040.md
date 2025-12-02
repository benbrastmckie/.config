# Debug Report - Task Invocation Pattern Violations

## Summary
- **Date**: 2025-12-02
- **Issue**: 33 ERROR-level violations in Task invocation patterns
- **Files Affected**: 14 files (2 commands, 12 agents/templates)
- **Root Cause**: Original implementation focused on command files but didn't address agent files

## Violation Breakdown

### Commands with Incomplete EXECUTE NOW (2 violations)
| File | Line | Issue |
|------|------|-------|
| expand.md | 938 | Missing "USE the Task tool" |
| optimize-claude.md | 200 | Missing "USE the Task tool" |

### Agents with Naked Task Blocks (31 violations)
| File | Lines | Count |
|------|-------|-------|
| research-sub-supervisor.md | 137, 156, 175, 194 | 4 |
| templates/sub-supervisor-template.md | 144, 164, 184, 204 | 4 |
| research-specialist.md | 564, 605, 628 | 3 |
| spec-updater.md | 418, 468, 750, 788, 824 | 5 |
| debug-specialist.md | 386, 423, 459, 670 | 4 |
| plan-architect.md | 737, 782, 839 | 3 |
| implementer-coordinator.md | 267, 297 | 2 |
| conversion-coordinator.md | 85, 105 | 2 |
| implementation-executor.md | 344 | 1 |
| doc-converter.md | 773 | 1 |
| prompts/evaluate-phase-expansion.md | 92 | 1 |
| prompts/evaluate-phase-collapse.md | 101 | 1 |

## Analysis

### Why Agents Weren't Fixed
The original plan (Phase 2-3) focused on:
- 7 workflow commands (/build, /debug, /implement, /plan, /repair, /research, /revise)
- Edge case commands (/test, /errors, /expand, /collapse, /setup, /convert-docs, /optimize-claude, /todo)

However, the plan didn't include:
- Agent files that make sub-agent delegations
- Agent template files
- Prompt files used by agents

### Impact Assessment
- **Commands**: Working correctly (delegating to agents)
- **Agents**: Agents calling sub-agents bypass delegation (same issue as original commands)
- **Severity**: Medium-High (affects multi-level agent hierarchies)

## Fix Strategy

### Quick Fix (33 edits)
Add "**EXECUTE NOW**: USE the Task tool" directive before each naked Task block:

```markdown
# Before
Task {
  subagent_type: "general-purpose"
  ...
}

# After
**EXECUTE NOW**: USE the Task tool to invoke the subagent.

Task {
  subagent_type: "general-purpose"
  ...
}
```

### Files to Fix (Priority Order)
1. **Commands (2 files)**: expand.md, optimize-claude.md - Fix incomplete directives
2. **Core Agents (6 files)**: plan-architect, implementer-coordinator, research-specialist, spec-updater, debug-specialist, implementation-executor
3. **Support Agents (3 files)**: conversion-coordinator, doc-converter, research-sub-supervisor
4. **Templates (1 file)**: sub-supervisor-template.md
5. **Prompts (2 files)**: evaluate-phase-expansion.md, evaluate-phase-collapse.md

## Recommended Next Steps

1. Create revision plan to fix remaining 33 violations
2. Fix violations in priority order (commands → core agents → support → templates)
3. Re-run linter to verify all fixes
4. Update original plan with expanded scope (agents, not just commands)

## Conclusion

The core fix pattern is correct and working. The remaining violations are in agent files that were out of scope for the original plan. A follow-up implementation pass should address these files using the same pattern already validated in command files.
