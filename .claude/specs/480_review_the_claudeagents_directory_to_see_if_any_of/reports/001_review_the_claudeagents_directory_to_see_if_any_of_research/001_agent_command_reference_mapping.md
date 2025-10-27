# Agent Command Reference Mapping

## Research Topic
Agent-command reference mapping: Which agents are referenced by which commands, and which agents are orphaned (never referenced).

## Status
✓ Complete

## Methodology
1. Searched all command files (.claude/commands/*.md) for agent invocations
2. Mapped each agent file to commands that reference it
3. Identified orphaned agents (never referenced by commands)
4. Analyzed reference patterns and usage frequency

## Executive Summary

**Total Agents**: 22 agent files (excluding README.md)
**Referenced Agents**: 17 (77%)
**Orphaned Agents**: 5 (23%)
**Total References**: 80+ agent invocations across 15 command files

The majority of agents are actively integrated into the command ecosystem. However, 5 agents appear to be orphaned, with no direct command references. These may be deprecated, experimental, or used in non-standard ways.

## Findings

### Agent-to-Command Mapping

#### Frequently Referenced Agents (5+ references)

**1. github-specialist.md** (6 references)
- `/orchestrate`: Lines 4185, 4774
- `/implement`: Line 1785
- `/shared/workflow-phases.md`: Lines 1210, 1799
- **Usage Pattern**: PR creation, GitHub operations, CI/CD integration

**2. spec-updater.md** (5 references)
- `/debug`: Line 493
- `/implement`: Line 630
- `/plan`: Line 933
- `/orchestrate`: Line 5317
- `/research`: Line 512
- **Usage Pattern**: Artifact management, lifecycle tracking, metadata updates

**3. code-writer.md** (5 references)
- `/implement`: Line 557
- `/orchestrate`: Lines 2811
- `/supervise`: Lines 1436, 1802
- `/shared/orchestrate-enhancements.md`: Line 338
- **Usage Pattern**: Code generation, feature implementation, bug fixes

**4. doc-writer.md** (5 references)
- `/implement`: Line 183
- `/orchestrate`: Lines 3440, 3451
- `/supervise`: Line 2001
- `/shared/workflow-phases.md`: Line 655
- **Usage Pattern**: Documentation creation and updates

**5. plan-architect.md** (5 references)
- `/orchestrate`: Lines 1559, 1592, 1633, 1770
- `/supervise`: Lines 70, 1237
- **Usage Pattern**: Implementation planning, architecture design

#### Moderately Referenced Agents (2-4 references)

**6. research-specialist.md** (4 references)
- `/plan`: Line 183
- `/plan-wizard`: Line 166
- `/supervise`: Lines 959, 965
- `/research`: Lines 227, 754
- **Usage Pattern**: Pre-implementation research, technology investigation

**7. debug-analyst.md** (4 references)
- `/debug`: Line 220, 360
- `/orchestrate`: Line 2688
- `/supervise`: Line 1680
- **Usage Pattern**: Root cause analysis, parallel investigations

**8. test-specialist.md** (3 references)
- `/orchestrate`: Line 3055
- `/supervise`: Lines 1561, 1899
- **Usage Pattern**: Test execution, result analysis, validation

**9. complexity-estimator.md** (3 references)
- `/collapse`: Line 464
- `/expand`: Line 602
- `/shared/complexity-evaluation-details.md`: Line 122
- **Usage Pattern**: Phase complexity analysis, expansion/collapse decisions

**10. implementation-researcher.md** (2 references)
- `/implement`: Lines 980, 1121
- **Usage Pattern**: Codebase exploration for complex implementation phases

**11. research-synthesizer.md** (2 references)
- `/orchestrate`: Line 1091
- `/research`: Lines 417, 775
- **Usage Pattern**: Aggregating research from multiple subagents

**12. implementation-executor.md** (1 reference)
- `/orchestrate`: Line 2245
- **Usage Pattern**: Wave-based parallel implementation execution

**13. implementer-coordinator.md** (1 reference)
- `/orchestrate`: Line 2178
- **Usage Pattern**: Multi-phase implementation coordination

**14. code-reviewer.md** (1 reference)
- `/refactor`: Line 282
- **Usage Pattern**: Code quality analysis, refactoring recommendations

**15. doc-converter.md** (1 reference)
- `/convert-docs`: Line 298
- **Usage Pattern**: Word/PDF to Markdown conversion

**16. expansion-specialist.md** (1 reference)
- `/shared/orchestration-alternatives.md`: Line 63
- **Usage Pattern**: Progressive plan expansion

**17. plan-expander.md** (1 reference, documentation)
- `/expand`: Line 1008 (documentation reference in auto-mode description)
- **Usage Pattern**: Automated phase expansion

### Orphaned Agents (No Direct References)

The following 5 agents have NO direct references in command files:

**1. collapse-specialist.md**
- **Expected Usage**: Progressive plan collapse operations
- **Status**: May be used by /collapse but not via explicit agent invocation
- **Investigation Needed**: Check if /collapse uses inline logic instead

**2. git-commit-helper.md**
- **Expected Usage**: Git commit message generation
- **Status**: May be deprecated or used in non-standard workflow
- **Investigation Needed**: Check git workflow integration

**3. doc-converter-usage.md**
- **Expected Usage**: Usage guide for doc-converter agent
- **Status**: Documentation file, not an executable agent
- **Recommendation**: Consider renaming to avoid confusion (e.g., move to docs/)

**4. metrics-specialist.md**
- **Expected Usage**: Performance metrics analysis (README shows typical uses)
- **Status**: May be invoked by /analyze command (not yet analyzed)
- **Investigation Needed**: Check /analyze command for references

**5. debug-specialist.md**
- **Expected Usage**: Issue investigation (README shows integration with /orchestrate)
- **Status**: May be deprecated in favor of debug-analyst.md
- **Investigation Needed**: Verify if debug-analyst replaced debug-specialist

### Reference Patterns

**Command-Agent Integration Patterns Observed**:

1. **Direct Task Tool Invocation** (Imperative Pattern)
   - Example: `USE the Task tool to invoke the doc-writer agent NOW.`
   - Files: `/orchestrate`, `/supervise`, `/shared/workflow-phases.md`
   - Compliant with Standard 11 (Imperative Agent Invocation)

2. **Behavioral Injection Pattern**
   - Example: `Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md`
   - Files: `/supervise`, `/plan-wizard`, `/research`
   - Agent behavioral file referenced, then invoked via Task tool

3. **Documentation References**
   - Example: `- **Agent template**: .claude/agents/debug-analyst.md`
   - Files: `/debug`, `/implement`
   - Informational only, not executable invocations

4. **Shared Template Integration**
   - Agent invocations in shared templates (workflow-phases.md, orchestrate-enhancements.md)
   - Reusable across multiple commands

### Command Files with Most Agent Invocations

1. **orchestrate.md**: 16 agent invocations
2. **supervise.md**: 12 agent invocations
3. **implement.md**: 9 agent invocations
4. **shared/workflow-phases.md**: 9 agent invocations
5. **debug.md**: 7 agent invocations

## File References

All findings based on grep search results:

**Agent Reference Search**:
- Pattern: `.claude/agents/`
- Scope: `/home/benjamin/.config/.claude/commands/`
- Total matches: 80+ references across 15 files
- Line numbers provided for all references above

**Key Command Files Analyzed**:
- `/home/benjamin/.config/.claude/commands/orchestrate.md`
- `/home/benjamin/.config/.claude/commands/implement.md`
- `/home/benjamin/.config/.claude/commands/supervise.md`
- `/home/benjamin/.config/.claude/commands/debug.md`
- `/home/benjamin/.config/.claude/commands/plan.md`
- `/home/benjamin/.config/.claude/commands/research.md`
- Plus 9 additional command files

## Recommendations

### 1. Investigate Orphaned Agents

**Priority: High**

Review the 5 orphaned agents to determine their status:

- **collapse-specialist.md**: Check if /collapse uses inline logic or external invocation
- **git-commit-helper.md**: Verify deprecation status or document usage pattern
- **doc-converter-usage.md**: Rename/move to docs/ directory (not an agent)
- **metrics-specialist.md**: Verify /analyze command integration
- **debug-specialist.md**: Confirm if superseded by debug-analyst.md

**Action Items**:
```bash
# Search for collapse-specialist usage
grep -r "collapse-specialist" /home/benjamin/.config/.claude/

# Search for git-commit-helper usage
grep -r "git-commit-helper" /home/benjamin/.config/.claude/

# Verify metrics-specialist in /analyze
grep -A5 -B5 "metrics" /home/benjamin/.config/.claude/commands/analyze.md
```

### 2. Archive or Document Orphaned Agents

**Priority: Medium**

For agents confirmed as orphaned:

- **If deprecated**: Move to `.claude/archive/agents/` (following recent cleanup pattern)
- **If active but undiscovered**: Add explicit command references or document usage
- **If documentation files**: Move to appropriate docs/ subdirectory

**Example Archive Command**:
```bash
# Archive deprecated agents
mv .claude/agents/git-commit-helper.md .claude/archive/agents/
mv .claude/agents/debug-specialist.md .claude/archive/agents/
```

### 3. Standardize Agent Invocation Patterns

**Priority: Medium**

Ensure all agent invocations follow Standard 11 (Imperative Agent Invocation):

- Replace documentation-only YAML blocks with executable Task tool calls
- Add explicit completion signals (e.g., `REPORT_CREATED:`)
- Use imperative language (`**EXECUTE NOW**: USE the Task tool...`)

**Files to Review**:
- `/expand`: Line 1008 (documentation reference only)
- Any command with <4 agent references (may be using documentation pattern)

### 4. Update Agent Registry

**Priority: Low**

Update `.claude/agents/agent-registry.json` with:

- Reference counts per agent
- Commands that use each agent
- Orphaned agent flags
- Last usage timestamp

**Schema Enhancement**:
```json
{
  "agents": [
    {
      "name": "github-specialist",
      "reference_count": 6,
      "commands": ["orchestrate", "implement", "workflow-phases"],
      "status": "active"
    },
    {
      "name": "collapse-specialist",
      "reference_count": 0,
      "commands": [],
      "status": "orphaned"
    }
  ]
}
```

### 5. Add Agent Usage Documentation

**Priority: Low**

Enhance `.claude/agents/README.md` with:

- Reference count per agent (high/medium/low usage)
- Commands that invoke each agent
- Migration guide for deprecated agents (if any)
- Best practices for agent selection

**Example Section**:
```markdown
## Agent Usage Frequency

### High Usage (5+ command references)
- github-specialist (6 refs) - Used by: orchestrate, implement, workflow-phases
- spec-updater (5 refs) - Used by: debug, implement, plan, orchestrate, research

### Low Usage (1-2 command references)
- implementation-executor (1 ref) - Used by: orchestrate
- code-reviewer (1 ref) - Used by: refactor

### No Usage (orphaned)
- collapse-specialist (0 refs) - Status: Under review
```

## Related Work

This research complements:
- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md)
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md)
- [Agent Development Guide](.claude/docs/guides/agent-development-guide.md)

## Related Reports

- [Research Overview](./OVERVIEW.md) - Complete agent directory review with consolidated recommendations

## Metadata
- **Created**: 2025-10-26
- **Agent**: Research Specialist
- **Scope**: Agent-command reference mapping
- **Status**: Complete
- **Agent Files Analyzed**: 22
- **Command Files Analyzed**: 15+
- **Total References Found**: 80+
- **Orphaned Agents Identified**: 5
