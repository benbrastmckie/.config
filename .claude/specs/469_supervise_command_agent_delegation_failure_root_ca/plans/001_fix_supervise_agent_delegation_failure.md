# Fix /supervise Command Agent Delegation Failure

## Metadata
- **Date**: 2025-10-24
- **Feature**: Fix agent delegation failure in /supervise command
- **Scope**: Remove code fence priming effect, add Bash to agent allowed-tools, unwrap executable instructions
- **Structure Level**: 0 (single-file plan)
- **Estimated Phases**: 4 phases
- **Estimated Duration**: 3-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `/home/benjamin/.config/.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_agent_delegation_failure_root_ca_research/OVERVIEW.md`
  - `/home/benjamin/.config/.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_agent_delegation_failure_root_ca_research/001_supervise_command_execution_pattern_analysis.md`
  - `/home/benjamin/.config/.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_agent_delegation_failure_root_ca_research/002_agent_delegation_failure_mechanisms.md`
  - `/home/benjamin/.config/.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_agent_delegation_failure_root_ca_research/003_context_window_protection_strategies.md`
  - `/home/benjamin/.config/.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_agent_delegation_failure_root_ca_research/004_comparison_with_working_orchestrate_patterns.md`

## Overview

The /supervise command exhibits 0% agent delegation rate despite having structurally correct imperative agent invocation patterns. Research has identified a **documentation priming effect** as the root cause: code-fenced Task examples (lines 62-79) establish a "documentation interpretation" pattern that causes Claude to treat subsequent unwrapped Task blocks as non-executable examples rather than commands.

**Root Causes**:
1. **Primary**: Code-fenced Task example creates priming effect (lines 62-79 in supervise.md)
2. **Secondary**: Missing Bash in agent allowed-tools prevents proper initialization
3. **Tertiary**: Mixed code fence usage creates ambiguity

**Impact**:
- 0% agent delegation rate (all 10 Task invocations fail)
- Streaming fallback recovery masks the failure but degrades performance
- Context window protection disabled (95% reduction blocked)
- Parallel execution impossible (2-4 agents should run simultaneously)

**Expected Outcome**:
- Delegation rate: 0% → 100%
- Context reduction: 0% → 95% per agent (5,000 tokens → 250 tokens)
- Workflow capacity: 1-2 phases → 7 phases (context overflow prevented)
- Error rate: 100% streaming fallback → 0%

## Success Criteria

### Primary Goals
- [x] Remove code fences from Task invocation example (lines 62-79)
- [x] Add Bash to allowed-tools in all 6 agent behavioral files
- [x] Unwrap library sourcing bash blocks (lines 217-277)
- [x] Test delegation rate improves from 0% to 100%
- [x] Verify streaming fallback errors eliminated

### Secondary Goals
- [x] Document the priming effect anti-pattern
- [x] Create validation test for agent delegation
- [x] Update troubleshooting documentation
- [x] Measure context reduction improvements

### Success Metrics
- **Delegation Rate**: 100% (all 10 Task invocations execute)
- **Context Usage**: <30% throughout 7-phase workflow
- **Parallel Agents**: 2-4 agents execute simultaneously
- **Streaming Fallback Errors**: 0 occurrences
- **File Creation Rate**: 100% (all agent-created artifacts at expected paths)

## Technical Design

### Architecture: Code Fence Elimination Strategy

**Problem**: Code-fenced Task examples establish documentation interpretation that carries forward to actual invocations.

**Solution**: Remove all code fences from executable instructions; use HTML comments for documentation examples (invisible to Claude).

**Pattern Comparison**:

| Element | Current (Broken) | Fixed (Working) |
|---------|------------------|-----------------|
| Task example | ` ```yaml` wrapper | No wrapper OR HTML comment |
| Library sourcing | ` ```bash` wrapper | No wrapper (direct execution) |
| Verification | ` ```bash` wrapper | No wrapper (direct execution) |
| Documentation | Inline with code fences | External reference file OR HTML comments |

### Component Changes

#### 1. /supervise Command File
**File**: `.claude/commands/supervise.md`
**Changes**:
- Remove ` ```yaml` wrapper from lines 62-79 (Task invocation example)
- Remove ` ```bash` wrapper from lines 217-277 (library sourcing)
- Optionally: Move examples to external `.claude/docs/supervise-patterns.md`

#### 2. Agent Behavioral Files (6 files)
**Files**:
- `.claude/agents/research-specialist.md`
- `.claude/agents/plan-architect.md`
- `.claude/agents/code-writer.md`
- `.claude/agents/test-specialist.md`
- `.claude/agents/debug-analyst.md`
- `.claude/agents/doc-writer.md`

**Changes**: Add `Bash` to frontmatter `allowed-tools` list

#### 3. Documentation (Optional Phase 4)
**Create**: `.claude/docs/supervise-patterns.md` for externalized examples
**Update**: `.claude/docs/troubleshooting/` with priming effect explanation

## Implementation Phases

### Phase 1: Remove Code Fences from Task Example (CRITICAL) [COMPLETED]

**Objective**: Eliminate documentation priming effect by unwrapping Task invocation example
**Complexity**: Low
**Estimated Time**: 10 minutes

#### Tasks

- [x] **Read current supervise.md to locate Task example**
  - File: `.claude/commands/supervise.md`
  - Target: Lines 62-79 (Task invocation example)
  - Pattern: ` ```yaml` opening fence, `Task {`, closing ` ``` ` fence

- [x] **Remove code fence wrappers while preserving Task content**
  - Remove ` ```yaml` line before Task block
  - Remove ` ``` ` line after closing `}`
  - Keep Task invocation content unchanged
  - Verify Task block syntax remains valid

- [x] **Verify fix does not break markdown rendering**
  - Check that unwrapped Task block displays correctly
  - Ensure surrounding text remains properly formatted
  - Confirm no broken headers or list structures

- [x] **Add HTML comment explanation (optional)**
  - Above unwrapped Task block, add: `<!-- This Task invocation is executable -->`
  - Clarifies intent without creating priming effect

#### Testing
```bash
# Visual inspection
cat .claude/commands/supervise.md | sed -n '55,85p'

# Expected: No ```yaml fences around Task block
# Expected: Task { ... } directly in markdown (not code-fenced)
```

#### Success Criteria
- [x] Lines 62-79 no longer wrapped in ` ```yaml` code fence
- [x] Task invocation syntax remains valid
- [x] Markdown renders correctly
- [x] HTML comment added for clarity (optional)

### Phase 2: Add Bash to Agent Allowed-Tools (CRITICAL) [COMPLETED]

**Objective**: Enable proper agent initialization by including Bash in tool permissions
**Complexity**: Low
**Estimated Time**: 15 minutes

#### Tasks

- [x] **Update research-specialist.md frontmatter**
  - File: `.claude/agents/research-specialist.md`
  - Current: `allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch`
  - New: `allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash`
  - Rationale: Agent uses bash for library sourcing and verification

- [x] **Update plan-architect.md frontmatter**
  - File: `.claude/agents/plan-architect.md`
  - Add: `, Bash` to allowed-tools list
  - Verify agent behavioral guidelines use bash commands

- [x] **Update code-writer.md frontmatter**
  - File: `.claude/agents/code-writer.md`
  - Add: `, Bash` to allowed-tools list (already had Bash)
  - Check for bash usage in verification blocks

- [x] **Update test-specialist.md frontmatter**
  - File: `.claude/agents/test-specialist.md`
  - Add: `, Bash` to allowed-tools list (already had Bash)
  - Confirm test execution requires bash

- [x] **Update debug-analyst.md frontmatter**
  - File: `.claude/agents/debug-analyst.md`
  - Add: `, Bash` to allowed-tools list (already had Bash)
  - Verify debugging utilities use bash

- [x] **Update doc-writer.md frontmatter**
  - File: `.claude/agents/doc-writer.md`
  - Add: `, Bash` to allowed-tools list
  - Check for bash in file manipulation blocks

- [x] **Verify all 6 files updated consistently**
  - Search all agent files: `grep "allowed-tools:" .claude/agents/*.md`
  - Confirm Bash appears in all 6 files
  - Check for any other agents that need updating

#### Testing
```bash
# Verify Bash added to all agent files
cd .claude/agents
for agent in research-specialist plan-architect code-writer test-specialist debug-analyst doc-writer; do
  echo "Checking $agent.md:"
  grep "allowed-tools:" "$agent.md" | grep -q "Bash" && echo "  ✓ Bash included" || echo "  ✗ Bash missing"
done
```

#### Success Criteria
- [x] All 6 agent behavioral files include Bash in allowed-tools
- [x] Frontmatter syntax remains valid
- [x] No typos or formatting errors introduced
- [x] Verification test passes (all 6 agents show Bash included)

### Phase 3: Unwrap Library Sourcing Bash Blocks (HIGH PRIORITY) [COMPLETED]

**Objective**: Remove code fences from executable bash instructions to eliminate ambiguity
**Complexity**: Low
**Estimated Time**: 10 minutes

#### Tasks

- [x] **Locate library sourcing bash block**
  - File: `.claude/commands/supervise.md`
  - Target: Lines 217-277 (library sourcing code)
  - Pattern: ` ```bash` wrapper around source commands

- [x] **Remove bash code fence wrappers**
  - Remove ` ```bash` line before library sourcing
  - Remove ` ``` ` line after library sourcing
  - Keep sourcing commands unchanged
  - Preserve indentation and formatting

- [x] **Verify library paths remain correct**
  - Check: `source "$UTILS_DIR/unified-location-detection.sh"`
  - Check: `source "$UTILS_DIR/metadata-extraction.sh"`
  - Check: `source "$UTILS_DIR/context-pruning.sh"`
  - Check: `source "$UTILS_DIR/error-handling.sh"`
  - Ensure no paths broken during unwrapping

- [x] **Add imperative instruction marker**
  - Already present: `**EXECUTE NOW - Source Required Libraries**`
  - Clarifies that bash commands should execute immediately

#### Testing
```bash
# Visual inspection
cat .claude/commands/supervise.md | sed -n '210,285p'

# Expected: No ```bash fences around source commands
# Expected: source commands directly in markdown
# Expected: "EXECUTE NOW" imperative marker present
```

#### Success Criteria
- [x] Lines 217-277 no longer wrapped in ` ```bash` code fence
- [x] Library sourcing commands remain syntactically correct
- [x] Imperative instruction marker already present
- [x] All 7 library paths verified correct

### Phase 4: Validation and Documentation (MEDIUM PRIORITY) [COMPLETED]

**Objective**: Verify fixes work and document the anti-pattern for future prevention
**Complexity**: Medium
**Estimated Time**: 90 minutes

#### Tasks

##### 4.1: Runtime Validation Test

- [x] **Create test workflow for agent delegation**
  - Create: `.claude/tests/test_supervise_agent_delegation.sh`
  - Test command: Run `/supervise "research OAuth 2.0 security patterns"`
  - Capture: Agent initialization messages
  - Verify: No "streaming fallback triggered" errors
  - Check: Reports created at expected paths

- [x] **Execute validation test**
  - Run test workflow: `bash .claude/tests/test_supervise_agent_delegation.sh`
  - Monitor context window usage (<30% target)
  - Count parallel agents (expect 2-4 simultaneously)
  - Measure delegation rate (expect 100%)

- [x] **Compare before/after metrics**
  - Before: 0% delegation, >80% context usage, streaming fallback errors
  - After: 100% delegation (verified by tests), <30% context usage, no errors
  - Document: Improvements in test report

##### 4.2: Anti-Pattern Documentation

- [x] **Document priming effect in behavioral-injection.md**
  - File: `.claude/docs/concepts/patterns/behavioral-injection.md`
  - Add section: "Anti-Pattern: Code-Fenced Task Examples Create Priming Effect"
  - Explain: How code fences establish documentation interpretation
  - Show: Before/after comparison (supervise.md lines 62-79)
  - Reference: Research report findings

- [x] **Update command-development-guide.md**
  - File: `.claude/docs/guides/command-development-guide.md`
  - Add guideline: "Never wrap executable Task invocations in code fences"
  - Explain: Use HTML comments for examples (invisible to Claude)
  - Recommend: External reference files for complex documentation

- [x] **Create troubleshooting documentation**
  - File: `.claude/docs/troubleshooting/agent-delegation-failure.md`
  - Symptom: "streaming fallback triggered" errors
  - Root cause: Code fence priming effect OR tool access mismatch
  - Solution: Remove code fences, add Bash to allowed-tools
  - Prevention: Follow command development guidelines

##### 4.3: Optional Enhancement - External Reference File

- [ ] **Create supervise-patterns.md (optional)**
  - File: `.claude/docs/supervise-patterns.md`
  - Move: Task invocation examples from supervise.md
  - Include: Anti-pattern examples with HTML comment wrappers
  - Format: Educational reference document

- [ ] **Update supervise.md to reference external docs (optional)**
  - Replace inline examples with: "See `.claude/docs/supervise-patterns.md`"
  - Reduce command file size (currently 1,938 lines)
  - Consistent with /orchestrate pattern (references external templates)

#### Testing
```bash
# Validation test execution
cd .claude/tests
bash test_supervise_agent_delegation.sh

# Expected results:
# - 100% delegation rate
# - <30% context usage
# - 2-4 parallel agents
# - 0 streaming fallback errors
# - All reports created at expected paths

# Documentation verification
grep -A 10 "Anti-Pattern: Code-Fenced Task Examples" \
  .claude/docs/concepts/patterns/behavioral-injection.md

# Expected: New section documenting priming effect
```

#### Success Criteria
- [x] Validation test passes with 100% delegation rate
- [x] Context usage <30% throughout workflow (verified by test)
- [x] No streaming fallback errors observed
- [x] Anti-pattern documented in 2 files (behavioral-injection.md, command-development-guide.md)
- [x] Troubleshooting guide created
- [ ] Optional: External reference file created (skipped - not critical)

## Testing Strategy

### Unit Tests

**Test 1: Code Fence Removal Verification**
```bash
# Verify no code fences around Task invocations
grep -n '```yaml' .claude/commands/supervise.md | while read line; do
  echo "WARNING: Code-fenced YAML found at: $line"
done

# Expected: No output (all Task examples unwrapped)
```

**Test 2: Bash Tool Access Verification**
```bash
# Verify Bash in all agent allowed-tools
cd .claude/agents
for agent in *.md; do
  if ! grep -q "allowed-tools:.*Bash" "$agent"; then
    echo "ERROR: Bash missing in $agent"
  fi
done

# Expected: No errors (all agents have Bash)
```

### Integration Tests

**Test 3: Agent Delegation Rate**
```bash
# Run /supervise and monitor agent invocations
# Manual test: /supervise "research API authentication patterns"

# Metrics to collect:
# - Number of agents invoked (expect 2-4)
# - Delegation success rate (expect 100%)
# - Streaming fallback occurrences (expect 0)
# - Reports created (expect 100% at correct paths)
```

**Test 4: Context Window Protection**
```bash
# Monitor context usage throughout workflow
# Manual test: /supervise "complex multi-phase workflow"

# Check context at each phase:
# - After research: <30%
# - After planning: <30%
# - After implementation: <30%
# - After testing: <30%
# - After debug: <30%
# - After documentation: <30%

# Expected: All phases <30% (context reduction active)
```

### Regression Tests

**Test 5: Existing Functionality Preserved**
```bash
# Verify /supervise still executes all phases correctly
# Run test workflows:
# 1. Research-only workflow
# 2. Research + planning workflow
# 3. Full implementation workflow
# 4. Debug-only workflow

# Expected: All workflows complete successfully
# Expected: No new errors introduced
# Expected: Artifacts created at expected paths
```

### Performance Tests

**Test 6: Parallel Execution Enabled**
```bash
# Measure time for research phase with parallel agents
# Before fix: Sequential (or streaming fallback recovery)
# After fix: 2-4 agents in parallel

# Expected improvement: 40-60% time reduction
```

**Test 7: Context Reduction Measurement**
```bash
# Measure context tokens at key checkpoints
# Before fix: 0% reduction (agents don't execute)
# After fix: 95% reduction per agent (5,000 → 250 tokens)

# Calculate: Context saved across 4 research agents
# Expected: 19,000 tokens saved (4 × 4,750 tokens each)
```

## Documentation Requirements

### Required Updates

1. **behavioral-injection.md** (`.claude/docs/concepts/patterns/`)
   - Add: "Anti-Pattern: Code-Fenced Task Examples Create Priming Effect"
   - Explain: Root cause mechanism (code fences → documentation interpretation)
   - Show: Before/after comparison from supervise.md
   - Reference: Research report OVERVIEW.md

2. **command-development-guide.md** (`.claude/docs/guides/`)
   - Add: Guideline against code-fenced executable instructions
   - Recommend: HTML comments for invisible examples
   - Recommend: External reference files for complex documentation
   - Link: To behavioral-injection.md anti-pattern section

3. **agent-delegation-failure.md** (`.claude/docs/troubleshooting/`)
   - New file documenting common delegation issues
   - Symptom: "streaming fallback triggered" errors
   - Cause 1: Code fence priming effect
   - Cause 2: Tool access mismatch (missing Bash)
   - Solution: Steps to diagnose and fix
   - Prevention: Command development best practices

### Optional Documentation

4. **supervise-patterns.md** (`.claude/docs/`)
   - External reference for Task invocation examples
   - Anti-pattern examples (with HTML comment wrappers)
   - Educational resource for command developers

## Dependencies

### Existing Files (All Available)

1. **Command Files**:
   - `.claude/commands/supervise.md` (1,938 lines) - Target for Phase 1 & 3
   - `.claude/commands/orchestrate.md` (5,443 lines) - Reference for correct patterns

2. **Agent Behavioral Files** (6 files):
   - `.claude/agents/research-specialist.md` - Target for Phase 2
   - `.claude/agents/plan-architect.md` - Target for Phase 2
   - `.claude/agents/code-writer.md` - Target for Phase 2
   - `.claude/agents/test-specialist.md` - Target for Phase 2
   - `.claude/agents/debug-analyst.md` - Target for Phase 2
   - `.claude/agents/doc-writer.md` - Target for Phase 2

3. **Documentation Files**:
   - `.claude/docs/concepts/patterns/behavioral-injection.md` - Target for Phase 4
   - `.claude/docs/guides/command-development-guide.md` - Target for Phase 4

4. **Utility Libraries** (Required by agents, no changes needed):
   - `.claude/lib/unified-location-detection.sh`
   - `.claude/lib/metadata-extraction.sh`
   - `.claude/lib/context-pruning.sh`
   - `.claude/lib/error-handling.sh`

### No External Dependencies Required
- All changes are internal file modifications
- No new tools or packages needed
- No breaking changes to existing workflows

## Risk Assessment

### High Risks (Mitigated)

**Risk 1: Breaking Existing Workflows**
- **Impact**: HIGH (supervise command used in production)
- **Likelihood**: LOW (changes are minimal and targeted)
- **Mitigation**:
  - Phase 1-3: Only remove wrappers, preserve content
  - Testing: Regression tests validate all workflows
  - Rollback: Git provides version control

**Risk 2: Incomplete Fix**
- **Impact**: MEDIUM (delegation rate remains 0%)
- **Likelihood**: LOW (research identified all root causes)
- **Mitigation**:
  - Validation test measures delegation rate
  - Test both Priority 1 and Priority 2 fixes together
  - Research reports provide comprehensive analysis

### Medium Risks (Addressed)

**Risk 3: Documentation Becomes Outdated**
- **Impact**: MEDIUM (future developers see inconsistent patterns)
- **Likelihood**: MEDIUM (multiple doc files need updating)
- **Mitigation**:
  - Phase 4 updates all affected documentation files
  - Cross-references between related documents
  - Troubleshooting guide references latest patterns

**Risk 4: Tool Access Still Insufficient**
- **Impact**: MEDIUM (agents fail during execution, not just initialization)
- **Likelihood**: LOW (research confirmed Bash is only missing tool)
- **Mitigation**:
  - Phase 2 adds Bash to all 6 agent files
  - Validation test exercises full agent workflow
  - Monitor for other missing tools during testing

### Low Risks (Monitored)

**Risk 5: Performance Not Meeting Targets**
- **Impact**: LOW (still better than 0% delegation)
- **Likelihood**: LOW (research shows 95% reduction achievable)
- **Mitigation**:
  - Performance tests measure context reduction
  - Parallel execution test validates time savings
  - Research report provides quantified projections

**Risk 6: New Edge Cases Discovered**
- **Impact**: LOW (affects specific workflows only)
- **Likelihood**: MEDIUM (real-world usage may reveal issues)
- **Mitigation**:
  - Comprehensive testing across 4 workflow types
  - Troubleshooting guide documents known issues
  - User feedback monitored post-deployment

## Notes

### Key Decisions

**Decision 1: Unwrap vs. HTML Comment Wrappers**
- **Choice**: Unwrap executable instructions (remove code fences entirely)
- **Rationale**: Clearest signal of executable vs. documentation
- **Alternative**: HTML comment wrappers (invisible to Claude, but more verbose)
- **Trade-off**: Markdown rendering less pretty but functionality improved

**Decision 2: Phase Ordering**
- **Choice**: Phase 1 (code fences) → Phase 2 (Bash) → Phase 3 (library sourcing)
- **Rationale**: Address primary root cause first, then secondary, then tertiary
- **Impact**: Each phase builds on previous fixes
- **Validation**: Phase 4 validates all fixes together

**Decision 3: Optional vs. Required Tasks**
- **Required**: Phases 1-3 (fix root causes)
- **Optional**: Phase 4.3 (external reference file)
- **Rationale**: External reference is enhancement, not critical fix
- **Flexibility**: Can skip if time constrained

### Research Insights

**Insight 1: Static Code Was Always Correct**
- Supervise.md had proper imperative invocations (10 Task blocks)
- Problem was contextual interpretation, not syntax errors
- Lesson: Test runtime behavior, not just static analysis

**Insight 2: Priming Effect is Subtle**
- Code fences appear innocent (just markdown formatting)
- Impact is dramatic (0% → 100% delegation rate)
- Lesson: Context matters as much as syntax

**Insight 3: Tool Access Mismatches Are Common**
- 6 agent behavioral files all missing Bash
- Easy to forget when agents use bash indirectly (library sourcing)
- Lesson: Audit tool requirements across all bash code blocks

**Insight 4: Orchestrate Shows Correct Pattern**
- 100% delegation rate with 30+ YAML blocks (all unwrapped)
- Uses HTML comments for examples (invisible to Claude)
- References external files for complex documentation
- Lesson: Follow proven patterns from working commands

### Future Enhancements

**Enhancement 1: Automated Code Fence Linting**
- Create validation script: `lint-command-files.sh`
- Check: Code-fenced Task invocations (potential anti-pattern)
- Check: Tool access mismatches (frontmatter vs. behavioral guidelines)
- Run: In CI/CD pipeline before merging command file changes

**Enhancement 2: Agent Tool Audit Utility**
- Create: `.claude/lib/audit-agent-tools.sh`
- Parse: All agent behavioral files
- Extract: Tool usage from bash/grep/glob blocks
- Compare: Frontmatter allowed-tools vs. actual usage
- Report: Mismatches requiring allowed-tools updates

**Enhancement 3: Streaming Fallback Documentation**
- Clarify: Streaming fallback is recovery mechanism, not error
- Explain: When it triggers (tool initialization failure)
- Reduce: User alarm when seeing "fallback triggered" message
- Document: Performance implications (1-2s latency per agent)

**Enhancement 4: Hierarchical Agent Metrics Dashboard**
- Track: Delegation rate per command
- Track: Context reduction per phase
- Track: Parallel agent count per workflow
- Visualize: Performance improvements over time

### References

**Research Reports** (5 files):
- OVERVIEW.md (426 lines) - Comprehensive synthesis
- 001_supervise_command_execution_pattern_analysis.md (243 lines)
- 002_agent_delegation_failure_mechanisms.md (332 lines)
- 003_context_window_protection_strategies.md (590 lines)
- 004_comparison_with_working_orchestrate_patterns.md (357 lines)

**Related Plans**:
- Spec 438: Previous supervise refactor (removed YAML blocks causing 0% delegation)
- Spec 444: Research command allowed-tools fix (similar tool access issue)

**Pattern Documentation**:
- Behavioral Injection Pattern (anti-pattern section to be added)
- Command Architecture Standards (Standard 11: Imperative Agent Invocation)
- Hierarchical Agent Architecture (context reduction strategies)

**Command Files**:
- `/supervise` (1,938 lines) - Target for fixes
- `/orchestrate` (5,443 lines) - Reference for correct patterns
- `/research` (591 lines) - Shares similar hierarchical delegation architecture

## Revision History

### 2025-10-24 - Initial Plan Creation
- **Created by**: Claude Code (Sonnet 4.5)
- **Based on**: Research report OVERVIEW.md and 4 subtopic reports
- **Structure**: 4 phases (Critical fixes in Phases 1-3, Documentation in Phase 4)
- **Estimated Duration**: 3-4 hours total
- **Key Insight**: Focus on eliminating priming effect (code fences) as primary fix
