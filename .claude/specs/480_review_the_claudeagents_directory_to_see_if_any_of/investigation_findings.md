# Orphaned Agents Investigation Findings

## Metadata
- **Investigation Date**: 2025-10-27
- **Phase**: Phase 2 of Implementation Plan 001
- **Agents Investigated**: 5 orphaned agents with no direct command invocations

## Summary

Investigated 5 agents identified as "orphaned" (no direct command references found in initial analysis). Results show 3 agents ARE actually used, 1 is documentation, and 1 requires archival.

## Investigation Results

### 1. collapse-specialist.md

**Status**: USED (via /collapse command)

**Evidence**:
- Referenced 4 times in `/collapse.md` command:
  - Line references in auto-analysis mode
  - Line references in explicit mode
  - Invoked by complexity-estimator workflow
  - Invoked for targeted phase/stage collapses

**Command Integration**: `/collapse` command uses Task tool to invoke collapse-specialist agent

**Disposition**: **RETAIN** - Active agent used by /collapse command

**Notes**: Research report incorrectly identified as orphaned due to behavioral injection pattern (agent invoked via Task tool, not direct file reference)

---

### 2. metrics-specialist.md

**Status**: NOT USED (no command references found)

**Evidence**:
- Zero references in `/analyze.md` command
- `/analyze` command mentions "metrics" but implements analysis inline
- No agent invocation patterns found

**Search Results**:
```bash
grep -r "metrics-specialist" /home/benjamin/.config/.claude/commands/
# No results
```

**Disposition**: **ARCHIVE** - Unused agent, superseded by inline /analyze logic

**Recommendation**: Move to `.claude/archive/agents/metrics-specialist.md` in Phase 7

---

### 3. debug-specialist.md

**Status**: USED (via multiple commands)

**Evidence**:
- Referenced 19 times across 4 command files:
  - `/orchestrate.md` (9 references) - Phase 5 debugging workflow
  - `/implement.md` (5 references) - Test failure auto-invocation
  - `/debug.md` (2 references) - Debug command main agent
  - Shared files (3 references) - Workflow documentation

**Command Integration**:
- `/debug` command uses Task tool to invoke debug-specialist
- `/orchestrate` Phase 5 conditionally invokes debug-specialist for test failures
- `/implement` auto-invokes debug-specialist for test failures (Step 3.3)

**Disposition**: **RETAIN** - Heavily used agent, critical for debugging workflows

**Notes**: Research report incorrectly identified as orphaned. This is one of the most used agents in the system.

---

### 4. doc-converter-usage.md

**Status**: DOCUMENTATION FILE (not an agent)

**Evidence**:
- File content: Quick start guide for doc-converter agent
- No YAML frontmatter with allowed-tools
- No behavioral instructions for AI execution
- Contains human-readable usage examples

**File Type**: Documentation/tutorial

**Disposition**: **MOVE TO DOCS** - Should be relocated to `.claude/docs/`

**Action**: Move to `/home/benjamin/.config/.claude/docs/doc-converter-usage.md`

**Registry Impact**: Should be removed from agent-registry.json after move (it's a documentation file, not an agent)

---

### 5. git-commit-helper.md

**Status**: NOT USED (zero command references)

**Evidence**:
- Zero grep results across all command files
- Agent purpose: Generate standardized commit messages
- Implementation: Deterministic template formatting (no behavioral logic)

**Analysis**: This agent was designed for commit message generation but is not currently invoked by any command. The functionality could be better served by a utility library function.

**Disposition**: **REFACTOR TO LIBRARY** (Phase 5 of this plan)

**Planned Action**: Create `.claude/lib/git-commit-utils.sh` with `generate_commit_message()` function

---

## Summary Statistics

| Agent | Status | Disposition | Command References |
|-------|--------|-------------|-------------------|
| collapse-specialist | USED | Retain | 4 (/collapse) |
| metrics-specialist | UNUSED | Archive | 0 |
| debug-specialist | USED | Retain | 19 (multiple commands) |
| doc-converter-usage | DOCUMENTATION | Move to docs | N/A |
| git-commit-helper | UNUSED | Refactor to library | 0 |

**Agents to Retain**: 2 (collapse-specialist, debug-specialist)
**Agents to Archive**: 1 (metrics-specialist)
**Documentation to Move**: 1 (doc-converter-usage.md)
**Agents to Refactor**: 1 (git-commit-helper → library)

## Research Report Correction

The original research report (001_agent_command_reference_mapping.md) identified 5 orphaned agents based on zero direct file references. However, this investigation reveals:

1. **Behavioral Injection Pattern**: Agents invoked via Task tool (not file references) were missed
2. **Actual Orphaned Count**: 2 agents (metrics-specialist, git-commit-helper)
3. **Misclassified**: 2 agents are actively used (collapse-specialist, debug-specialist)
4. **Documentation Confusion**: 1 file is documentation, not an agent

**Lesson Learned**: Agent usage analysis must account for behavioral injection pattern (Task tool invocations) in addition to direct file references.

## Actions Taken in This Phase

1. ✓ Searched codebase for all 5 orphaned agents
2. ✓ Verified /collapse command implementation (uses collapse-specialist)
3. ✓ Verified /analyze command implementation (no metrics-specialist)
4. ✓ Compared debug-specialist usage (heavily used, 19 references)
5. ✓ Confirmed doc-converter-usage.md is documentation
6. ✓ Documented findings in this file

## Next Phase Actions

**Phase 3-4**: Consolidate expansion-specialist + collapse-specialist (collapse-specialist is retained)
**Phase 5**: Refactor git-commit-helper to utility library
**Phase 7**: Archive metrics-specialist to `.claude/archive/agents/`
**Phase 7**: Move doc-converter-usage.md to `.claude/docs/`
**Phase 7**: Update agent-registry.json to remove doc-converter-usage entry

## References

- [Agent Command Reference Mapping](../reports/001_review_the_claudeagents_directory_to_see_if_any_of_research/001_agent_command_reference_mapping.md)
- [Implementation Plan](../plans/001_agents_directory_cleanup_and_consolidation.md)
- `/collapse` command: `.claude/commands/collapse.md`
- `/debug` command: `.claude/commands/debug.md`
- `/orchestrate` command: `.claude/commands/orchestrate.md`
- `/implement` command: `.claude/commands/implement.md`
