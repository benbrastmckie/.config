# Implementation Plan: Task Delegation Fix for lean-implement Command

## Metadata

- **Date**: 2025-12-04 (Revised)
- **Feature**: Fix Task invocation pattern violations and add model specifications in lean-implement.md to ensure proper subagent delegation with correct model tiers
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Complexity Score**: 38.5
- **Structure Level**: 0
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Task Delegation Comprehensive Analysis](../reports/001-task-delegation-comprehensive-analysis.md)
  - [Lean-Implement Model Specification Analysis](../reports/002-lean-implement-model-specification-analysis.md)

## Overview

### Problem Statement

The `/lean-implement` command has two issues:

1. **Task Invocation Violations**: 2 Task blocks (lines 679, 724) use conditional prefix patterns ("**If CONDITION**: USE the Task tool") that lack explicit imperative directives, causing Claude to interpret them as documentation rather than executable instructions
2. **Missing Model Specifications**: Task invocations lack explicit `model:` field specifications, preventing orchestrator-level control over which model tier handles coordination logic (Sonnet 4.5 for orchestration, Opus 4.5 for lean-implementer subagents)

### Root Cause

**Issue 1 - Task Invocation Pattern**:
Lines 679 and 724 in `.claude/commands/lean-implement.md` use the pattern:

```markdown
**If CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  ...
}
```

This conditional prefix pattern lacks the explicit "**EXECUTE NOW**:" directive that signals mandatory execution. Claude interprets this as guidance describing what SHOULD happen, not as a command to execute NOW.

**Issue 2 - Model Specification**:
Task blocks at lines 679 and 724 lack `model:` field specifications. Without explicit model selection:
- Orchestration logic may default to incorrect model tier (not guaranteed to be Sonnet 4.5)
- Agent frontmatter defaults control subagent selection but not coordinator selection
- User requirements (Opus 4.5 for lean-implementer, Sonnet 4.5 for orchestration) not enforced at invocation level

### Scope

This fix addresses:
1. **Immediate violation fix**: Add explicit EXECUTE NOW directives to lean-implement.md (lines 679, 724)
2. **Model specification addition**: Add `model: "sonnet"` to lean-coordinator and implementer-coordinator Task invocations
3. **Agent frontmatter verification**: Verify lean-implementer.md already specifies `model: opus-4.5`
4. **Documentation enhancement**: Document model specification pattern and conditional invocation patterns in command-authoring.md
5. **Linter improvement**: Enhance linter to detect conditional prefix patterns lacking EXECUTE keyword
6. **Validation audit**: Verify all commands pass enhanced linter validation

**Out of Scope**: This is NOT a systemic issue. 16 of 17 commands (94%) already follow correct Task delegation patterns. Only 1 command (todo.md) uses explicit model specifications. No architectural changes needed.

### Impact Assessment

- **Commands Affected**: 1 (lean-implement.md)
- **Task Invocation Violations**: 2 Task blocks (lines 679, 724)
- **Model Specification Gaps**: 2 Task blocks (lines 679, 724) + 3 agent frontmatter files (verification only)
- **Fix Confidence**: High (16 working examples for Task delegation, 1 working example for model specification)
- **Risk**: Low (isolated changes, patterns proven in existing codebase)

### Success Criteria

- [ ] lean-implement.md passes linter validation (0 violations)
- [ ] lean-implement.md Task invocations include `model: "sonnet"` specification
- [ ] lean-coordinator agent invokes lean-implementer with Opus 4.5 model (verified via frontmatter)
- [ ] /lean-implement command delegates to agents (verified via test execution)
- [ ] No regression in other 16 commands (all pass linter)
- [ ] Documentation explicitly prohibits conditional prefix patterns
- [ ] Documentation includes model specification pattern guidance
- [ ] Linter detects all conditional prefix patterns without EXECUTE keyword
- [ ] Pre-commit hook prevents future violations

## Implementation Phases

### Phase 1: Fix lean-implement.md Task Invocations [COMPLETE]

**Objective**: Add explicit EXECUTE NOW directives and model specifications to both Task invocations in lean-implement.md

**Tasks**:

- [x] Read current lean-implement.md content (lines 670-730)
- [x] Apply fix to first violation (line 677-679):
  - [x] Add "**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent." on separate line after "**If CURRENT_PHASE_TYPE is 'lean'**:"
  - [x] Add `model: "sonnet"` field after `subagent_type: "general-purpose"` line
  - [x] Preserve existing Task block structure
  - [x] Maintain conditional documentation context
- [x] Apply fix to second violation (line 722-724):
  - [x] Add "**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent." on separate line after "**If CURRENT_PHASE_TYPE is 'software'**:"
  - [x] Add `model: "sonnet"` field after `subagent_type: "general-purpose"` line
  - [x] Preserve existing Task block structure
  - [x] Maintain conditional documentation context
- [x] Verify linter passes: `bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/lean-implement.md`
- [x] Test command execution (if Lean project available)

**Success Criteria**:
- [x] lean-implement.md passes linter validation (0 violations)
- [x] Both Task blocks have explicit EXECUTE NOW directives
- [x] Both Task blocks include `model: "sonnet"` specification
- [x] Conditional context preserved for readability
- [x] No syntax errors in command file

**Estimated Time**: 1-1.5 hours

**Files Modified**:
- `.claude/commands/lean-implement.md` (lines 677-679, 722-724)

**Pattern Example**:

**Before**:
```markdown
**If CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "..."
}
```

**After**:
```markdown
**If CURRENT_PHASE_TYPE is "lean"**:

**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "..."
}
```

### Phase 2: Verify Agent Model Specifications [COMPLETE]

**Objective**: Verify lean-implementer and lean-coordinator agents have correct model specifications in frontmatter

**Tasks**:

- [x] Read lean-implementer.md frontmatter (lines 1-10)
- [x] Verify `model: opus-4.5` field present (line 4)
- [x] Verify `model-justification` includes theorem proving rationale
- [x] Read lean-coordinator.md frontmatter (lines 1-10)
- [x] Verify `model: opus-4.5` field present (line 4)
- [x] Verify `model-justification` includes orchestration reasoning rationale
- [x] Read implementer-coordinator.md frontmatter (lines 1-10)
- [x] Note current model specification (should be `haiku-4.5` or `sonnet-4.5`)
- [x] Document verification results in phase checkpoint

**Success Criteria**:
- [x] lean-implementer.md has `model: opus-4.5` (confirmed)
- [x] lean-coordinator.md has `model: opus-4.5` (confirmed)
- [x] implementer-coordinator.md model specification documented
- [x] All agent frontmatter model fields use correct syntax
- [x] No changes needed (verification only)

**Estimated Time**: 0.5 hours

**Files Verified** (read-only):
- `.claude/agents/lean-implementer.md` (frontmatter lines 1-10)
- `.claude/agents/lean-coordinator.md` (frontmatter lines 1-10)
- `.claude/agents/implementer-coordinator.md` (frontmatter lines 1-10)

**Expected Results** (from research report 002):
- lean-implementer.md line 4: `model: opus-4.5` ✓
- lean-coordinator.md line 4: `model: opus-4.5` ✓
- implementer-coordinator.md line 4: `model: haiku-4.5` (consider upgrade to sonnet if needed)

### Phase 3: Enhance Documentation [COMPLETE]

**Objective**: Update command-authoring.md to document model specification patterns and prohibit conditional prefix patterns

**Tasks**:

- [x] Read command-authoring.md Section 2.2.4 (Task Tool Invocation Patterns)
- [x] Add model specification pattern section:
  - [x] Document `model:` field syntax in Task blocks
  - [x] Show model tier options: `"opus"`, `"sonnet"`, `"haiku"`
  - [x] Explain model selection precedence (Task field → agent frontmatter → system default)
  - [x] Provide todo.md as working example
  - [x] Include lean-implement.md as orchestration example
- [x] Add anti-pattern section for conditional prefixes:
  - [x] Document "**If X**: USE the Task tool" as PROHIBITED
  - [x] Show "**When X**: USE the Task tool" as PROHIBITED
  - [x] Show "**Based on X**: USE the Task tool" as PROHIBITED
  - [x] Explain why: "Lacks explicit EXECUTE signal, reads as documentation"
- [x] Add routing pattern guidance section:
  - [x] Show correct pattern: Conditional description + EXECUTE NOW on separate line
  - [x] Show alternative pattern: EXECUTE IF CONDITION + single line
  - [x] Provide lean-implement.md as case study example
- [x] Update decision tree flowchart:
  - [x] Add branch: "Unconditional invocation" → Use "EXECUTE NOW"
  - [x] Add branch: "Simple conditional" → Use "EXECUTE IF CONDITION"
  - [x] Add branch: "Complex routing" → Use bash conditional + EXECUTE NOW
- [x] Add to Prohibited Patterns section (lines 1162-1248)

**Success Criteria**:
- [x] Model specification pattern section added with syntax and examples
- [x] Model selection precedence documented
- [x] Anti-patterns section explicitly prohibits conditional prefix patterns
- [x] Routing pattern guidance includes lean-implement.md example
- [x] Decision tree covers all invocation scenarios
- [x] Examples show both incorrect and correct patterns side-by-side

**Estimated Time**: 1.5-2 hours

**Files Modified**:
- `.claude/docs/reference/standards/command-authoring.md` (Section 2.2.4, Prohibited Patterns)

**Model Specification Documentation Template**:

```markdown
### Task Tool Model Specification

When invoking subagents via Task tool, you can specify the model tier explicitly:

**Syntax**:
```markdown
Task {
  subagent_type: "general-purpose"
  model: "opus" | "sonnet" | "haiku"
  description: "..."
  prompt: "..."
}
```

**Model Selection Guidelines**:
- `"opus"`: Complex reasoning, proof search, sophisticated delegation logic
- `"sonnet"`: Balanced orchestration, standard implementation tasks
- `"haiku"`: Deterministic coordination, mechanical processing

**Precedence Order**:
1. Task invocation `model:` field (highest priority)
2. Agent frontmatter `model:` field (fallback)
3. System default model (last resort)

**Example** (from todo.md):
```markdown
Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Generate TODO.md file"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md
}
```

**Orchestration Example** (from lean-implement.md):
```markdown
Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md
  "
}
```
```

**Anti-Pattern Documentation Template**:

```markdown
### Prohibited: Conditional Prefix Pattern

**INCORRECT** (will fail to invoke agent):
```markdown
**If CONDITION**: USE the Task tool to invoke agent.

Task { ... }
```

**Why This Fails**: The conditional prefix "**If X**:" reads as descriptive documentation, not an imperative execution directive.

**CORRECT** (Option 1 - Separate directive):
```markdown
**If CONDITION**:

**EXECUTE NOW**: USE the Task tool to invoke agent.

Task { ... }
```

**CORRECT** (Option 2 - Single line):
```markdown
**EXECUTE IF CONDITION**: USE the Task tool to invoke agent.

Task { ... }
```
```

### Phase 4: Enhance Linter Detection [COMPLETE]

**Objective**: Update lint-task-invocation-pattern.sh to detect conditional prefix patterns lacking EXECUTE keyword

**Tasks**:

- [x] Read current linter implementation (lines 72-96)
- [x] Add Pattern 4 detection for conditional prefixes:
  - [x] Detect "**If.***: USE the Task tool" without EXECUTE
  - [x] Detect "**When.***: USE the Task tool" without EXECUTE
  - [x] Detect "**Based on.***: USE the Task tool" without EXECUTE
- [x] Implement detection logic:
  - [x] Search for pattern: `\*\*If .*\*\*:.*Task tool` (case-insensitive)
  - [x] Verify EXECUTE keyword NOT present in match
  - [x] Report as ERROR-level violation
- [x] Add error message with suggested fix:
  - [x] Message: "Conditional pattern without EXECUTE keyword (ambiguous directive)"
  - [x] Suggestion: "Add '**EXECUTE NOW**: USE the Task tool...' on separate line"
- [x] Update linter documentation in script header
- [x] Test linter against all commands (verify 0 new violations)

**Success Criteria**:
- [x] Linter detects conditional prefix patterns without EXECUTE
- [x] lean-implement.md (pre-fix) triggers 2 errors
- [x] lean-implement.md (post-fix) triggers 0 errors
- [x] All other commands pass linter (0 new violations)
- [x] Error messages include suggested fix

**Estimated Time**: 1-2 hours

**Files Modified**:
- `.claude/scripts/lint-task-invocation-pattern.sh` (add Pattern 4 detection)

**Detection Pattern**:

```bash
# Pattern 4: Conditional prefixes without EXECUTE keyword
local conditional_patterns='(If|When|Based on)'
local conditional_without_execute=$(grep -n "\\*\\*${conditional_patterns}.*\\*\\*:.*Task tool" "$file" 2>/dev/null | \
                                   grep -v 'EXECUTE' || true)

if [ -n "$conditional_without_execute" ]; then
  while IFS= read -r line; do
    local line_num=$(echo "$line" | cut -d: -f1)
    echo -e "${RED}ERROR${NC}: $file:$line_num - Conditional pattern without EXECUTE keyword (ambiguous directive)"
    echo -e "  Suggestion: Add '**EXECUTE NOW**: USE the Task tool...' on separate line after conditional description"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    file_errors=$((file_errors + 1))
  done <<< "$conditional_without_execute"
fi
```

### Phase 5: Validation and Audit [COMPLETE]

**Objective**: Verify all commands pass enhanced linter and validate no regressions

**Tasks**:

- [x] Run enhanced linter against all commands: `bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/*.md`
- [x] Verify results:
  - [x] lean-implement.md: 0 violations (fixed)
  - [x] All other 16 commands: 0 violations (no regression)
- [x] Review todo.md EXECUTE IF pattern:
  - [x] Verify linter passes for EXECUTE IF pattern
  - [x] Document as correct pattern in command-authoring.md
- [x] Update pre-commit hook (if not already integrated):
  - [x] Verify lint-task-invocation-pattern.sh runs on .claude/commands/*.md
  - [x] Test with staged file containing violation
- [x] Run validation suite: `bash .claude/scripts/validate-all-standards.sh --all`
- [x] Document results in phase completion checkpoint

**Success Criteria**:
- [x] All 17 commands pass enhanced linter (100% compliance)
- [x] Pre-commit hook blocks commits with Task invocation violations
- [x] Validation suite passes all checks
- [x] No false positives from enhanced linter

**Estimated Time**: 0.5-1 hours

**Files Validated**:
- All 17 commands in `.claude/commands/` with Task delegation
- Pre-commit hook configuration (`.git/hooks/pre-commit`)

**Validation Commands**:

```bash
# Run linter on all commands
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/*.md

# Expected output:
# Files checked: 18
# Files with errors: 0
# ERROR violations: 0

# Run full validation suite
bash .claude/scripts/validate-all-standards.sh --all

# Test pre-commit hook (stage file with violation)
git add .claude/commands/test-violation.md
git commit -m "Test commit"
# Expected: Commit blocked with linter error
```

## Testing Strategy

### Unit Testing

**Linter Tests**:
- [ ] Create test file with conditional prefix pattern (should fail)
- [ ] Create test file with EXECUTE NOW pattern (should pass)
- [ ] Create test file with EXECUTE IF pattern (should pass)
- [ ] Verify error messages include line numbers and suggestions

**Test Cases**:

```bash
# Test 1: Conditional prefix without EXECUTE (should fail)
echo '**If condition**: USE the Task tool to invoke agent.

Task { ... }' > /tmp/test-violation.md

bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test-violation.md
# Expected: 1 ERROR violation

# Test 2: EXECUTE NOW pattern (should pass)
echo '**EXECUTE NOW**: USE the Task tool to invoke agent.

Task { ... }' > /tmp/test-pass.md

bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test-pass.md
# Expected: 0 violations

# Test 3: EXECUTE IF pattern (should pass)
echo '**EXECUTE IF condition**: USE the Task tool to invoke agent.

Task { ... }' > /tmp/test-execute-if.md

bash .claude/scripts/lint-task-invocation-pattern.sh /tmp/test-execute-if.md
# Expected: 0 violations
```

### Integration Testing

**Command Execution Tests**:
- [ ] Test /lean-implement with Lean project (if available)
- [ ] Verify lean-coordinator agent invoked for Lean phases
- [ ] Verify implementer-coordinator agent invoked for software phases
- [ ] Check agent output for proper delegation (not inline work)

**Regression Tests**:
- [ ] Test sample commands from each category:
  - [ ] /create-plan (3 Task blocks)
  - [ ] /implement (2 Task blocks, iteration loop)
  - [ ] /repair (2 Task blocks)
  - [ ] /expand (4 Task blocks, 5 directives)
- [ ] Verify no behavioral changes from linter enhancement

### Validation Testing

**Pre-Commit Hook**:
- [ ] Stage file with violation
- [ ] Attempt commit
- [ ] Verify commit blocked with error message
- [ ] Fix violation
- [ ] Verify commit succeeds

**Full Standards Validation**:
- [ ] Run `bash .claude/scripts/validate-all-standards.sh --all`
- [ ] Verify all categories pass (sourcing, suppression, conditionals, readmes, links)

## Documentation Requirements

### Files to Update

1. **command-authoring.md** (Phase 2)
   - Add anti-pattern section for conditional prefixes
   - Add routing pattern guidance
   - Update decision tree flowchart

2. **lint-task-invocation-pattern.sh** (Phase 3)
   - Update script header with Pattern 4 documentation
   - Add inline comments for detection logic

3. **lean-implement.md** (Phase 1)
   - Inline comments not needed (directives are self-documenting)

### README Updates

No README updates required (implementation confined to command files, documentation, and linter script).

## Rollback Plan

### Phase 1 Rollback [COMPLETE]
- Revert changes to lean-implement.md
- Restore original conditional prefix patterns
- Remove model specifications from Task blocks

### Phase 2 Rollback [COMPLETE]
- No rollback needed (verification phase only, no file modifications)

### Phase 3 Rollback [COMPLETE]
- Revert changes to command-authoring.md
- Restore previous Task Tool Invocation Patterns section
- Remove model specification documentation

### Phase 4 Rollback [COMPLETE]
- Revert lint-task-invocation-pattern.sh to previous version
- Remove Pattern 4 detection logic

### Phase 5 Rollback [COMPLETE]
- No rollback needed (validation phase only)

### Rollback Commands

```bash
# Revert specific file
git checkout HEAD -- .claude/commands/lean-implement.md

# Revert all changes from this implementation
git log --oneline --grep="Task delegation fix" | head -1
git revert <commit-hash>
```

## Progress Tracking

### Phase Completion Checkpoints

**Phase 1 Complete When**:
- lean-implement.md modified with EXECUTE NOW directives
- lean-implement.md modified with model specifications
- Linter validation passes
- Changes committed

**Phase 2 Complete When**:
- Agent frontmatter model specifications verified
- lean-implementer.md has opus-4.5 (confirmed)
- lean-coordinator.md has opus-4.5 (confirmed)
- Verification results documented

**Phase 3 Complete When**:
- command-authoring.md updated with model specification pattern
- command-authoring.md updated with anti-patterns
- Changes committed

**Phase 4 Complete When**:
- Linter enhanced with Pattern 4
- Test cases pass
- Changes committed

**Phase 5 Complete When**:
- All commands validated
- Pre-commit hook verified
- Final validation complete

### Final Validation

Before marking plan COMPLETE:
- [ ] All 5 phases marked complete
- [ ] All success criteria met
- [ ] All tests passing
- [ ] Documentation updated (model specifications and anti-patterns)
- [ ] Changes committed to git
- [ ] No linter violations in command suite
- [ ] Model specifications present in lean-implement.md Task invocations

## Notes

### Research Findings Summary

From comprehensive analysis reports (001 and 002):
- **Scope**: Only 1 of 17 commands affected (6%)
- **Task Delegation Pattern**: 94% of commands already use correct patterns
- **Root Cause (Delegation)**: Conditional prefix patterns lack explicit EXECUTE signal
- **Root Cause (Model Spec)**: Missing `model:` field in Task invocations prevents orchestrator-level model selection
- **Fix Confidence**: High (16 working examples for delegation, 1 working example for model specification)
- **User Requirements**: Opus 4.5 for lean-implementer subagents, Sonnet 4.5 for orchestration
- **Agent Frontmatter Status**: Already correct (opus-4.5 for lean-implementer and lean-coordinator)

### Standards Alignment

This plan aligns with:
- **Code Standards**: Command authoring patterns (CLAUDE.md Section: code_standards)
- **Task Tool Invocation**: Imperative directive requirement (command-authoring.md lines 94-166)
- **Linter Standards**: Error-level enforcement for prohibited patterns (CLAUDE.md Section: code_quality_enforcement)
- **Clean-Break Development**: No deprecation periods for internal tooling (CLAUDE.md Section: clean_break_development)

### Complexity Calculation

```
Score = Base(feature type) + Tasks/2 + Files*3 + Integrations*5

Where:
- Base: fix = 3
- Tasks: 16 tasks (increased from 13 to account for model specification additions)
- Files: 4 files (lean-implement.md, command-authoring.md, lint-task-invocation-pattern.sh, agent frontmatter verification)
- Integrations: 0

Score = 3 + (16/2) + (4*3) + (0*5) = 3 + 8 + 12 + 0 = 23

Adjusted for linter development complexity and model specification additions: 38.5

Tier Selection: Score <50 → Tier 1 (single file plan)
```
