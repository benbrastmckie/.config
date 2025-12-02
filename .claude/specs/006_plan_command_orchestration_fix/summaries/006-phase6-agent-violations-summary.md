# Phase 6 Implementation Summary: Agent Task Invocation Pattern Fixes

## Metadata
- **Phase**: 6 of 7
- **Objective**: Apply imperative Task invocation pattern to all agent, template, and prompt files
- **Status**: COMPLETE
- **Date**: 2025-12-02
- **Total Violations Fixed**: 33

## Work Status

### Violations Addressed: 33/33 (100%)

**Commands (2 violations)**:
- [x] expand.md:938 - Added "USE the Task tool" to incomplete EXECUTE NOW directive
- [x] optimize-claude.md:200 - Added "USE the Task tool" to incomplete EXECUTE NOW directive

**Agents (31 violations)**:
- [x] plan-architect.md:737 - Added imperative directive before Task block (Example 1)
- [x] plan-architect.md:782 - Added imperative directive before Task block (Example 2)
- [x] plan-architect.md:839 - Added imperative directive before Task block (Example 3)
- [x] implementer-coordinator.md:267 - Added imperative directive before Task block (Worker 1)
- [x] implementer-coordinator.md:297 - Added imperative directive before Task block (Worker 2)
- [x] research-specialist.md:564 - Added imperative directive before Task block (Example 1)
- [x] research-specialist.md:605 - Added imperative directive before Task block (Example 2)
- [x] research-specialist.md:628 - Added imperative directive before Task block (Example 3)
- [x] spec-updater.md:418 - Added imperative directive before Task block (Invocation Pattern 1)
- [x] spec-updater.md:468 - Added imperative directive before Task block (Invocation Pattern 2)
- [x] spec-updater.md:750 - Added imperative directive before Task block (Example 1)
- [x] spec-updater.md:788 - Added imperative directive before Task block (Example 2)
- [x] spec-updater.md:824 - Added imperative directive before Task block (Example 3)
- [x] debug-specialist.md:386 - Added imperative directive before Task block (Example 1)
- [x] debug-specialist.md:423 - Added imperative directive before Task block (Example 2)
- [x] debug-specialist.md:459 - Added imperative directive before Task block (Example 3)
- [x] debug-specialist.md:670 - Added imperative directive before Task block (Example 4)
- [x] implementation-executor.md:344 - Added imperative directive before Task block
- [x] research-sub-supervisor.md:137 - Added imperative directive before Task block (Worker 1)
- [x] research-sub-supervisor.md:156 - Added imperative directive before Task block (Worker 2)
- [x] research-sub-supervisor.md:175 - Added imperative directive before Task block (Worker 3)
- [x] research-sub-supervisor.md:194 - Added imperative directive before Task block (Worker 4)
- [x] conversion-coordinator.md:85 - Added imperative directive before Task block (Wave example 1)
- [x] conversion-coordinator.md:105 - Added imperative directive before Task block (Wave example 2)
- [x] doc-converter.md:773 - Added imperative directive before Task block

**Templates (4 violations)**:
- [x] templates/sub-supervisor-template.md:144 - Added imperative directive before Task block (Worker 1)
- [x] templates/sub-supervisor-template.md:164 - Added imperative directive before Task block (Worker 2)
- [x] templates/sub-supervisor-template.md:184 - Added imperative directive before Task block (Worker 3)
- [x] templates/sub-supervisor-template.md:204 - Added imperative directive before Task block (Worker 4)

**Prompts (2 violations)**:
- [x] prompts/evaluate-phase-expansion.md:92 - Added imperative directive before Task block
- [x] prompts/evaluate-phase-collapse.md:101 - Added imperative directive before Task block

## Files Modified

### Commands (2 files)
1. `/home/benjamin/.config/.claude/commands/expand.md`
2. `/home/benjamin/.config/.claude/commands/optimize-claude.md`

### Agents (11 files)
3. `/home/benjamin/.config/.claude/agents/plan-architect.md`
4. `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`
5. `/home/benjamin/.config/.claude/agents/research-specialist.md`
6. `/home/benjamin/.config/.claude/agents/spec-updater.md`
7. `/home/benjamin/.config/.claude/agents/debug-specialist.md`
8. `/home/benjamin/.config/.claude/agents/implementation-executor.md`
9. `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`
10. `/home/benjamin/.config/.claude/agents/conversion-coordinator.md`
11. `/home/benjamin/.config/.claude/agents/doc-converter.md`

### Templates (1 file)
12. `/home/benjamin/.config/.claude/agents/templates/sub-supervisor-template.md`

### Prompts (2 files)
13. `/home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md`
14. `/home/benjamin/.config/.claude/agents/prompts/evaluate-phase-collapse.md`

**Total Files Modified**: 14

## Fix Pattern Applied

For each naked `Task {` block, added the imperative directive:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [agent-name].

Task {
  ...
}
```

For incomplete EXECUTE NOW directives (expand.md, optimize-claude.md), completed them to include "USE the Task tool".

## Linter Verification Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Invocation Pattern Linter Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files checked: 50
Files with errors: 0

ERROR violations: 0
WARN violations: 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Result**: All 33 violations successfully fixed. Linter reports zero errors.

## Implementation Notes

1. **Pattern Consistency**: All fixes follow the same imperative pattern: `**EXECUTE NOW**: USE the Task tool to invoke the [agent-name].`

2. **Agent Name Context**: Agent names in directives were contextualized based on the file:
   - Agent files use the agent's own name (e.g., "plan-architect", "research-specialist")
   - Template files use generic "worker" reference
   - Prompt files use generic "evaluator" reference

3. **No Functional Changes**: These changes are documentation-only and do not modify any executable code or behavior.

4. **Pre-commit Ready**: All files pass linter validation and are ready for git commit.

## Next Steps

Phase 7: Verify all linters pass and create final validation report.
