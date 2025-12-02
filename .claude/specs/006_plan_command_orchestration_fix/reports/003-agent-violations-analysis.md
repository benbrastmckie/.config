# Agent Task Invocation Violations - Analysis Report

## Metadata
- **Date**: 2025-12-02
- **Research Topic**: Task invocation pattern violations in agent files
- **Analysis Scope**: 33 violations across 12 agent/template/prompt files
- **Related Plan**: /home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md
- **Linter**: lint-task-invocation-pattern.sh

## Executive Summary

The existing plan successfully fixed all 16+ Task invocation violations in workflow commands (Phases 2-3), but missed **33 additional violations** in agent files, templates, and prompts. These violations follow the same pattern: naked `Task {` blocks in example/documentation sections that lack the imperative "**EXECUTE NOW**: USE the Task tool" directive.

**Key Finding**: Unlike commands (which actively invoke agents), agent files contain **instructional examples** showing other agents how to delegate. However, the linter correctly flags these as violations because:

1. **Template Propagation Risk**: Agents copy these examples when delegating, potentially creating naked Task blocks in live workflows
2. **Pattern Consistency**: All Task blocks should model correct invocation syntax, even in documentation
3. **Training Value**: Agents learn delegation patterns from these examples

**Recommended Action**: Add a new Phase 6 to the existing plan to fix all 33 agent violations using the same imperative pattern applied to commands.

## Violation Breakdown

### Summary Statistics
- **Total Violations**: 33
- **Files Affected**: 14 (12 agent/template/prompt files + 2 commands with incomplete directives)
- **Violation Types**:
  - Incomplete EXECUTE NOW directives: 2 (commands)
  - Naked Task blocks in agent examples: 31 (agents/templates/prompts)

### Files by Category

#### Category 1: Commands with Incomplete Directives (2 violations)
These commands have "EXECUTE NOW" but are missing "USE the Task tool":

| File | Line | Context | Fix Required |
|------|------|---------|--------------|
| expand.md | 938 | Phase 3: Parallel Agent Invocation | Complete directive: "**EXECUTE NOW**: USE the Task tool to invoke parallel expansion agents" |
| optimize-claude.md | 200 | Block 1c: Invoke Topic Naming Agent | Complete directive: "**EXECUTE NOW**: USE the Task tool to invoke topic-naming agent" |

#### Category 2: Core Workflow Agents (11 violations)
These are primary agents invoked directly by workflow commands:

| File | Violations | Lines | Agent Type | Context |
|------|-----------|-------|------------|---------|
| plan-architect.md | 3 | 737, 782, 839 | Core | Example usage sections showing delegation patterns |
| implementer-coordinator.md | 2 | 267, 297 | Core | Parallel wave execution examples |
| research-specialist.md | 3 | 564, 605, 628 | Core | Research delegation examples |
| spec-updater.md | 5 | 418, 468, 750, 788, 824 | Core | Plan update invocation examples |
| debug-specialist.md | 4 | 386, 423, 459, 670 | Core | Debug investigation examples |
| implementation-executor.md | 1 | 344 | Core | Phase execution example |

#### Category 3: Support/Utility Agents (5 violations)
These agents support specific workflows (document conversion, research supervision):

| File | Violations | Lines | Agent Type | Context |
|------|-----------|-------|------------|---------|
| research-sub-supervisor.md | 4 | 137, 156, 175, 194 | Support | Parallel worker delegation pattern |
| conversion-coordinator.md | 2 | 85, 105 | Support | Document conversion delegation |
| doc-converter.md | 1 | 773 | Support | Conversion task example |

#### Category 4: Templates (8 violations)
Template files used to generate new agents or prompts:

| File | Violations | Lines | Template Type | Context |
|------|-----------|-------|---------------|---------|
| templates/sub-supervisor-template.md | 4 | 144, 164, 184, 204 | Agent Template | Generic parallel delegation pattern |

#### Category 5: Evaluation Prompts (2 violations)
Prompt files loaded by agents for specific evaluation tasks:

| File | Violations | Lines | Prompt Type | Context |
|------|-----------|-------|-------------|---------|
| prompts/evaluate-phase-expansion.md | 1 | 92 | Evaluation | Integration pattern example |
| prompts/evaluate-phase-collapse.md | 1 | 101 | Evaluation | Integration pattern example |

## Detailed Violation Analysis

### Pattern Analysis

All 31 naked Task blocks in agent files follow a similar structure:

**Current (Violation Pattern)**:
```markdown
## Example Usage

### From /command Command

```
Task {
  subagent_type: "general-purpose"
  description: "Perform some action"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/some-agent.md

    Execute the task...
}
```
```

**Problem**: The example shows a naked `Task {` block without the imperative directive. When agents read these examples to learn delegation patterns, they may copy this incorrect syntax.

**Required Fix**:
```markdown
## Example Usage

### From /command Command

**EXECUTE NOW**: USE the Task tool to invoke the some-agent.

```
Task {
  subagent_type: "general-purpose"
  description: "Perform some action"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/some-agent.md

    Execute the task...
}
```
```

### Special Cases

#### 1. Incomplete EXECUTE NOW Directives (2 violations)

**expand.md:938**:
```markdown
**EXECUTE NOW - Invoke Parallel Expansion Agents**
```

Should be:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke parallel expansion agents.
```

**optimize-claude.md:200**:
```markdown
**EXECUTE NOW**: Invoke topic naming agent and initialize workflow paths:
```

Should be:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke topic naming agent and initialize workflow paths.
```

#### 2. Template Files (4 violations in sub-supervisor-template.md)

Template files are particularly critical because they're used to generate new agents. Any violations in templates propagate to all derived agents.

Lines 144, 164, 184, 204 all show worker delegation patterns without imperative directives.

#### 3. Evaluation Prompts (2 violations)

Prompt files like `evaluate-phase-expansion.md` are loaded by agents at runtime. Line 92 shows an "Integration Pattern" example with a naked Task block in the YAML-style syntax.

#### 4. Parallel Delegation Patterns (10 violations)

Several agents show parallel delegation examples (research-sub-supervisor, implementer-coordinator, sub-supervisor-template). Each parallel worker example needs the imperative directive.

## Impact Assessment

### Risk Level: MEDIUM-HIGH

While these violations exist in documentation/example sections (not active code paths), they pose several risks:

1. **Template Propagation**: Agents learning from these examples may copy incorrect syntax into active workflows
2. **Pattern Inconsistency**: Mixed patterns (commands correct, agents incorrect) create confusion
3. **Linter False Positives**: Pre-commit hooks will block commits to agent files until violations are fixed
4. **Documentation Quality**: Examples should always demonstrate correct patterns

### Behavioral Impact

**Current State**: Agents with these violations can still function correctly because:
- The violations are in example/documentation sections, not active delegation code
- Commands have already been fixed and invoke agents correctly
- Agents typically delegate using patterns they see in command files

**Post-Fix State**: After fixing violations:
- All examples consistently show correct imperative pattern
- Pre-commit hooks pass for agent file modifications
- Agents learning delegation patterns see uniform syntax
- Reduced risk of incorrect pattern propagation

## Fix Strategy

### Approach: Mechanical Pattern Application

Each fix follows the same mechanical transformation:

1. **Locate naked Task block**: Find lines with `Task {` pattern
2. **Add imperative directive**: Insert `**EXECUTE NOW**: USE the Task tool to invoke [agent-name].` before the Task block
3. **Preserve context**: Maintain all surrounding documentation and examples
4. **Verify syntax**: Ensure Task block remains properly formatted

### Fix Pattern Template

```markdown
# Before:
## Example Usage
```
Task {
  subagent_type: "general-purpose"
  ...
}
```

# After:
## Example Usage

**EXECUTE NOW**: USE the Task tool to invoke [agent-name].

```
Task {
  subagent_type: "general-purpose"
  ...
}
```
```

### Effort Estimation

- **Per-file effort**: 5-15 minutes (depending on violation count)
- **Total violations**: 33
- **Estimated time**: 2-3 hours for all fixes
- **Testing time**: 1 hour (linter verification, pre-commit hook testing)
- **Total phase time**: 3-4 hours

### Testing Strategy

1. **Linter Verification**:
   ```bash
   bash .claude/scripts/lint-task-invocation-pattern.sh
   # Expected: 0 violations
   ```

2. **Pre-commit Hook**:
   ```bash
   git add .claude/agents/*.md
   git commit -m "test: verify agent files pass pre-commit"
   # Expected: No lint-task-invocation-pattern.sh errors
   ```

3. **Pattern Consistency**:
   ```bash
   # Verify all Task blocks have EXECUTE NOW within 2 lines before
   grep -r "^Task {" .claude/agents/ .claude/commands/ | while read line; do
     file=$(echo "$line" | cut -d: -f1)
     linenum=$(echo "$line" | cut -d: -f2)
     context=$(head -n $((linenum)) "$file" | tail -n 3)
     echo "$context" | grep -q "EXECUTE NOW.*Task tool" || echo "VIOLATION: $file:$linenum"
   done
   # Expected: No output
   ```

4. **Regression Testing**:
   - Run existing workflow commands (/plan, /build, /implement)
   - Verify agents still delegate correctly
   - Confirm no behavioral changes in agent operation

## Recommended Plan Extension

### New Phase 6: Fix Agent Task Invocation Violations
dependencies: [5]

**Objective**: Apply imperative Task invocation pattern to all agent files, templates, and prompts with naked Task blocks

**Complexity**: Low-Medium (mechanical fixes with some template complexity)

**Tasks**:
- [ ] Fix incomplete EXECUTE NOW directives in commands (2 violations)
  - [ ] expand.md:938 - Complete directive with "USE the Task tool"
  - [ ] optimize-claude.md:200 - Complete directive with "USE the Task tool"
- [ ] Fix core workflow agents (11 violations)
  - [ ] plan-architect.md - Add directive before 3 Task blocks (lines 737, 782, 839)
  - [ ] implementer-coordinator.md - Add directive before 2 Task blocks (lines 267, 297)
  - [ ] research-specialist.md - Add directive before 3 Task blocks (lines 564, 605, 628)
  - [ ] spec-updater.md - Add directive before 5 Task blocks (lines 418, 468, 750, 788, 824)
  - [ ] debug-specialist.md - Add directive before 4 Task blocks (lines 386, 423, 459, 670)
  - [ ] implementation-executor.md - Add directive before 1 Task block (line 344)
- [ ] Fix support/utility agents (5 violations)
  - [ ] research-sub-supervisor.md - Add directive before 4 Task blocks (lines 137, 156, 175, 194)
  - [ ] conversion-coordinator.md - Add directive before 2 Task blocks (lines 85, 105)
  - [ ] doc-converter.md - Add directive before 1 Task block (line 773)
- [ ] Fix template files (8 violations)
  - [ ] templates/sub-supervisor-template.md - Add directive before 4 Task blocks (lines 144, 164, 184, 204)
- [ ] Fix evaluation prompts (2 violations)
  - [ ] prompts/evaluate-phase-expansion.md - Add directive before 1 Task block (line 92)
  - [ ] prompts/evaluate-phase-collapse.md - Add directive before 1 Task block (line 101)
- [ ] Verify all fixes with linter
- [ ] Test pre-commit hook with modified agent files
- [ ] Run regression tests on workflow commands

**Testing**:
```bash
# Verify zero violations
bash .claude/scripts/lint-task-invocation-pattern.sh
# Expected: 0 ERROR violations

# Test pre-commit hook
git add .claude/agents/*.md .claude/commands/*.md
git commit -m "test: verify pre-commit passes"
# Expected: No errors from lint-task-invocation-pattern.sh

# Verify pattern consistency across all files
find .claude/agents .claude/commands -name "*.md" -type f | while read file; do
  if grep -q "^Task {" "$file"; then
    if ! grep -B2 "^Task {" "$file" | grep -q "EXECUTE NOW.*Task tool"; then
      echo "VIOLATION: $file"
    fi
  fi
done
# Expected: No output

# Test workflow commands still delegate correctly
/plan "test feature" --complexity 1
/implement /path/to/test/plan --dry-run
# Expected: Proper agent delegation, no behavioral regressions
```

**Expected Duration**: 3-4 hours

## File-by-File Fix Checklist

### Commands (2 files, 2 violations)
- [ ] .claude/commands/expand.md:938
- [ ] .claude/commands/optimize-claude.md:200

### Core Agents (6 files, 18 violations)
- [ ] .claude/agents/plan-architect.md (3 violations: lines 737, 782, 839)
- [ ] .claude/agents/implementer-coordinator.md (2 violations: lines 267, 297)
- [ ] .claude/agents/research-specialist.md (3 violations: lines 564, 605, 628)
- [ ] .claude/agents/spec-updater.md (5 violations: lines 418, 468, 750, 788, 824)
- [ ] .claude/agents/debug-specialist.md (4 violations: lines 386, 423, 459, 670)
- [ ] .claude/agents/implementation-executor.md (1 violation: line 344)

### Support Agents (3 files, 7 violations)
- [ ] .claude/agents/research-sub-supervisor.md (4 violations: lines 137, 156, 175, 194)
- [ ] .claude/agents/conversion-coordinator.md (2 violations: lines 85, 105)
- [ ] .claude/agents/doc-converter.md (1 violation: line 773)

### Templates (1 file, 4 violations)
- [ ] .claude/agents/templates/sub-supervisor-template.md (4 violations: lines 144, 164, 184, 204)

### Prompts (2 files, 2 violations)
- [ ] .claude/agents/prompts/evaluate-phase-expansion.md (1 violation: line 92)
- [ ] .claude/agents/prompts/evaluate-phase-collapse.md (1 violation: line 101)

## Success Criteria

- [ ] All 33 violations resolved (linter reports 0 errors)
- [ ] Pre-commit hook passes for all agent/command files
- [ ] Pattern consistency: All Task blocks have imperative directives
- [ ] No behavioral regressions in workflow commands
- [ ] Template files fixed (prevent propagation to new agents)
- [ ] Documentation sections consistently show correct patterns

## Next Steps

1. **Plan Revision**: Add Phase 6 to existing plan (001-plan-command-orchestration-fix-plan.md)
2. **Implementation**: Execute Phase 6 fixes using /implement or /build
3. **Validation**: Run full linter suite and regression tests
4. **Commit**: Create git commit with all agent fixes
5. **Close**: Mark plan as complete with all 6 phases finished

## Appendix: Linter Output

```
ERROR: /home/benjamin/.config/.claude/scripts/../commands/expand.md:938 - Incomplete EXECUTE NOW (missing 'USE the Task tool')
ERROR: /home/benjamin/.config/.claude/scripts/../commands/optimize-claude.md:200 - Incomplete EXECUTE NOW (missing 'USE the Task tool')
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-sub-supervisor.md:137 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-sub-supervisor.md:156 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-sub-supervisor.md:175 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-sub-supervisor.md:194 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/templates/sub-supervisor-template.md:144 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/templates/sub-supervisor-template.md:164 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/templates/sub-supervisor-template.md:184 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/templates/sub-supervisor-template.md:204 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-specialist.md:564 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-specialist.md:605 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/research-specialist.md:628 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/prompts/evaluate-phase-expansion.md:92 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/prompts/evaluate-phase-collapse.md:101 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/spec-updater.md:418 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/spec-updater.md:468 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/spec-updater.md:750 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/spec-updater.md:788 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/spec-updater.md:824 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/conversion-coordinator.md:85 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/conversion-coordinator.md:105 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/implementer-coordinator.md:267 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/implementer-coordinator.md:297 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/plan-architect.md:737 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/plan-architect.md:782 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/plan-architect.md:839 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/doc-converter.md:773 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/implementation-executor.md:344 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/debug-specialist.md:386 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/debug-specialist.md:423 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/debug-specialist.md:459 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: /home/benjamin/.config/.claude/scripts/../agents/debug-specialist.md:670 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task Invocation Pattern Linter Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files checked: 50
Files with errors: 14

ERROR violations: 33
WARN violations: 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
