# Phase 4: Command Documentation Extraction - Implementation Specification

## Overview

This phase refactors 20+ command files in `.claude/commands/` to extract common documentation patterns to the shared file `.claude/docs/command-patterns.md` (now 1,041 lines). The goal is to reduce total command LOC from 13,020 to ~6,200 (53% reduction) while maintaining clarity and improving maintainability.

**Status**: Foundation Complete (10%), Refactoring In Progress
**Last Updated**: 2025-10-10

**Links**:
- **[Main Plan](NEW_claude_system_optimization.md#phase-4-command-documentation-extraction-high-complexity)** - Phase 4 section with progress summary
- **[Implementation Roadmap](phase_4_roadmap.md)** - 55.5-hour breakdown into 18 sessions with validation checkpoints

**Current State:**
- Total command files: 13,020 lines
- command-patterns.md: 1,041 lines (was 690, +351 new patterns added)
- Backups: `.claude/commands/backups/phase4_20251010/`
- Test suite: `.claude/tests/test_command_references.sh` ✅
- Priority commands:
  - orchestrate.md: 2,092 lines (target ~1,700)
  - setup.md: ~2,200 lines (target ~1,890)
  - implement.md: ~1,650 lines (target ~1,050)

**Target State:**
- Total command files: ~6,200 lines (53% reduction)
- Priority commands optimized with pattern references
- All commands use consistent reference format
- Zero information loss

**Completed Foundation Tasks** (5.5 hours):
1. ✅ Task 1: Added Logger Init, PR Creation, Parallel Safety patterns
2. ✅ Task 2: Backed up all 20 command files
3. ✅ Task 3: Created validation test suite

**Remaining**: Tasks 4-18 (50 hours of refactoring work) - See [Roadmap](phase_4_roadmap.md) for detailed breakdown

## Research Analysis

### Pattern Categories from command-patterns.md

The shared patterns file contains 7 main categories:

1. **Agent Invocation Patterns** (lines 21-108)
   - Single agent with behavioral injection
   - Parallel agent invocation
   - Sequential agent chain
   - Template structure for agent prompts

2. **Checkpoint Management Patterns** (lines 110-180)
   - Save checkpoint after phase
   - Resume from checkpoint
   - Checkpoint cleanup
   - Checkpoint data structure

3. **Error Recovery Patterns** (lines 182-278)
   - Automatic retry with backoff
   - Error classification and routing
   - User escalation format
   - 3-retry sequence standard

4. **Artifact Referencing Patterns** (lines 280-375)
   - Artifact storage and registry
   - Artifact reference list format
   - Bidirectional cross-references
   - Context reduction strategy

5. **Testing Integration Patterns** (lines 377-469)
   - Test discovery from CLAUDE.md
   - Phase-by-phase testing
   - Test failure handling
   - Debugging loop workflow

6. **Progress Streaming Patterns** (lines 471-549)
   - Progress marker detection
   - TodoWrite integration
   - Phase completion messages
   - Real-time visibility

7. **Standards Discovery Patterns** (lines 551-651)
   - Upward CLAUDE.md search
   - Standards section extraction
   - Standards application during code generation
   - Fallback behavior

### Command Structure Analysis

#### orchestrate.md (2,092 lines)

**Sections with extraction potential:**

1. **Lines 22-24**: Shared utilities integration
   - **Extractable**: Yes, pattern in command-patterns.md
   - **Target**: Remove, reference checkpoint management patterns
   - **Savings**: ~15 lines

2. **Lines 95-108**: Research Phase → Parallel Agent Invocation
   - **Extractable**: Yes, exact match in command-patterns.md (lines 70-94)
   - **Target**: Replace with reference link
   - **Savings**: ~80 lines

3. **Lines 148-226**: Research Agent Prompt Template
   - **Extractable**: Partial, core template in patterns
   - **Keep inline**: Orchestrate-specific context injection
   - **Target**: Reduce to orchestrate-specific parts + reference
   - **Savings**: ~40 lines

4. **Lines 246-274**: Artifact Storage and Registry
   - **Extractable**: Yes, matches patterns lines 285-304
   - **Target**: Replace with reference, keep orchestrate-specific registry handling
   - **Savings**: ~20 lines

5. **Lines 275-289**: Save Research Checkpoint
   - **Extractable**: Yes, matches checkpoint patterns
   - **Target**: Replace with reference + orchestrate-specific data
   - **Savings**: ~10 lines

6. **Lines 471-497**: Planning Agent Monitoring
   - **Extractable**: Yes, progress streaming pattern
   - **Target**: Reference progress marker detection pattern
   - **Savings**: ~15 lines

7. **Lines 676-748**: Implementation Error Handling
   - **Extractable**: Yes, error recovery patterns
   - **Target**: Reference error recovery + keep implementation-specific
   - **Savings**: ~35 lines

8. **Lines 809-1175**: Debugging Loop (Conditional)
   - **Extractable**: Partial, test failure handling pattern exists
   - **Target**: Reference test failure pattern + debugging workflow
   - **Savings**: ~100 lines (largest opportunity)

9. **Lines 1272-1312**: Bidirectional Cross-References
   - **Extractable**: Yes, exact match in artifact patterns (lines 351-375)
   - **Target**: Replace with reference
   - **Savings**: ~40 lines

10. **Lines 1782-1810**: Error Recovery Mechanism
    - **Extractable**: Yes, references error patterns
    - **Target**: Consolidate with reference to error recovery patterns
    - **Savings**: ~25 lines

**Total Extractable from orchestrate.md: ~380 lines**
**Target: 2,092 - 380 = 1,712 lines (slightly above target, acceptable)**

#### setup.md (~2,200 lines)

**Sections with extraction potential:**

1. **Lines 13-19**: Shared Utilities Integration
   - **Extractable**: Yes, error handling patterns
   - **Target**: Reference error recovery patterns
   - **Savings**: ~10 lines

2. **Standards for Commands section**: Not extractable (setup-specific schema)

3. **Process sections (371-500)**: Mostly setup-specific, minimal extraction

4. **Extraction Preferences (535-723)**: Setup-specific configuration, keep inline

5. **Cleanup Mode Workflow (724-791)**: Setup-specific, keep inline

6. **Bloat Detection Algorithm (792-939)**: Setup-specific heuristics, keep inline

7. **Standards Analysis Workflow (1077-1876)**: Core setup functionality, keep inline

**Total Extractable from setup.md: ~10 lines**
**Note: Setup.md has minimal extraction potential - its content is highly command-specific**
**Alternative approach: Optimize internal structure, reduce repetition**

#### implement.md (~1,650 lines)

**Sections with extraction potential:**

1. **Lines 32-38**: Shared Utilities Integration
   - **Extractable**: Yes, checkpoint/complexity/logging patterns
   - **Target**: Reference checkpoint management + complexity patterns
   - **Savings**: ~10 lines

2. **Lines 147-175**: Logger Initialization
   - **Extractable**: Yes, could be a shared "Logger Setup Pattern"
   - **Target**: Extract to patterns as new section, reference here
   - **Savings**: ~20 lines

3. **Lines 243-276**: Dependency Analysis → Parallel Execution
   - **Extractable**: Partial, relates to parallel agent pattern
   - **Target**: Reference parallel execution safety from patterns
   - **Savings**: ~15 lines

4. **Lines 367-411**: Agent Monitoring with Progress Streaming
   - **Extractable**: Yes, exact match with progress streaming patterns
   - **Target**: Replace with reference to progress marker detection
   - **Savings**: ~30 lines

5. **Lines 594-651**: Enhanced Error Analysis
   - **Extractable**: Yes, relates to error classification pattern
   - **Target**: Reference error classification + keep implement-specific
   - **Savings**: ~35 lines

6. **Lines 1197-1231**: Error Handling and Rollback
   - **Extractable**: Yes, error recovery patterns
   - **Target**: Reference error recovery patterns
   - **Savings**: ~20 lines

7. **Lines 1282-1350**: Summary Generation → Cross-References
   - **Extractable**: Yes, matches artifact bidirectional patterns
   - **Target**: Reference artifact cross-reference patterns
   - **Savings**: ~40 lines

8. **Lines 1353-1447**: Create Pull Request (Optional)
   - **Extractable**: Potential new pattern "PR Creation Pattern"
   - **Target**: Extract to patterns, reference from implement + orchestrate
   - **Savings**: ~60 lines (implement) + 70 lines (orchestrate) = 130 total

9. **Lines 1560-1645**: Checkpoint Detection and Resume
   - **Extractable**: Yes, matches checkpoint resume pattern
   - **Target**: Reference checkpoint management patterns
   - **Savings**: ~50 lines

**Total Extractable from implement.md: ~270 lines**
**Target: 1,650 - 270 = 1,380 lines (exceeds target, good)**

### New Patterns to Add to command-patterns.md

Based on analysis, add these new patterns:

1. **Logger Initialization Pattern** (~30 lines)
   - Standard way to source adaptive planning logger
   - No-op fallbacks when logger unavailable
   - Log directory creation with permissions

2. **PR Creation Pattern** (~90 lines)
   - GitHub CLI prerequisite checks
   - Agent invocation template for github-specialist
   - PR URL capture and summary updates
   - Graceful degradation on failure
   - Manual command examples

3. **Parallel Execution Safety Pattern** (~40 lines)
   - Max parallelism limits
   - Fail-fast wave execution
   - Checkpoint preservation
   - Result aggregation

Total new patterns: ~160 lines → command-patterns.md grows to ~850 lines

## Pattern Extraction Strategy

### Mapping: Pattern Categories to Command Sections

| Pattern Category | orchestrate.md | setup.md | implement.md | Other Commands |
|-----------------|---------------|----------|--------------|----------------|
| Agent Invocation | Lines 95-108, 148-226 | - | Lines 367-411 | revise.md, plan.md |
| Checkpoint Mgmt | Lines 275-289 | - | Lines 1560-1645 | All workflow commands |
| Error Recovery | Lines 676-748, 1782-1810 | Lines 13-19 | Lines 594-651, 1197-1231 | All commands |
| Artifact Refs | Lines 246-274, 1272-1312 | - | Lines 1282-1350 | orchestrate, document |
| Testing Integration | Lines 809-1175 (partial) | - | - | test.md, test-all.md |
| Progress Streaming | Lines 471-497 | - | Lines 367-411 | orchestrate, implement |
| Standards Discovery | - | Lines 554-632 (partial) | Lines 65-140 (partial) | All commands |

### Reference Link Format

Use this consistent markdown syntax:

```markdown
For detailed [concept], see [Pattern Name](../docs/command-patterns.md#pattern-name).

**Command-specific behavior:**
- [Specific detail 1]
- [Specific detail 2]
```

**Examples:**

**Before (orchestrate.md, lines 95-108):**
```markdown
### Step 2: Launch Parallel Research Agents

For each identified research topic, I'll create a focused research task and invoke agents in parallel.

**Key Principle**: Each agent receives ONLY its specific focus. NO orchestration routing logic in prompts.

**How to invoke parallel agents**:
- Send single message with multiple Task tool calls
- Each Task block gets independent context
- No cross-referencing between agents
- Agents run concurrently, not sequentially

**Example from /orchestrate**:
[80 lines of detailed example and explanation]
```

**After (orchestrate.md):**
```markdown
### Step 2: Launch Parallel Research Agents

For parallel agent invocation patterns, see [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation).

**Orchestrate-specific invocation:**
- Launch 2-4 research agents simultaneously (single message, multiple Task blocks)
- Each agent receives ONLY its specific research focus
- NO orchestration routing logic in prompts
- Complete task description with success criteria per agent
```

**Savings: 70+ lines**

---

**Before (implement.md, lines 1560-1645):**
```markdown
### Checkpoint Detection and Resume

Before starting implementation, I'll check for existing checkpoints that might indicate an interrupted implementation.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent implement checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

[85 lines of detailed checkpoint handling, prompts, and restoration logic]
```

**After (implement.md):**
```markdown
### Checkpoint Detection and Resume

For checkpoint detection and resumption, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).

**Implement-specific checkpoint:**
- Command: `implement`
- Project name: Extracted from plan filename
- State includes: plan_path, current_phase, completed_phases, tests_passing
- Resume from: First incomplete phase
```

**Savings: 75+ lines**

### Mixed Inline/Reference Content Pattern

When a section has both generic patterns and command-specific details:

**Structure:**
1. **Brief summary** (1-2 sentences)
2. **Pattern reference link** with anchor
3. **Command-specific section** with unique details

**Example (from orchestrate.md debugging loop):**

```markdown
### Debugging Loop (Conditional - Only if Tests Fail)

This phase engages when implementation reports test failures. For error recovery patterns, see [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) and [Test Failure Handling](../docs/command-patterns.md#pattern-test-failure-handling).

**Orchestrate-specific debugging workflow:**
- Maximum 3 debugging iterations before escalation
- Uses debug-specialist agent for investigation
- Uses code-writer agent for fix application
- Tracks attempts in checkpoint for resume capability
- Updates error_history in workflow state

**Iteration tracking:**
[orchestrate-specific iteration tracking details - 20 lines]
```

## Per-Command Refactoring Plan

### Priority 1: orchestrate.md (2,092 lines → ~1,500 lines)

**Phase 1: Agent Invocation Sections**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Parallel Research Agents | 95-108 | Replace with reference + orchestrate-specific | Agent Invocation Patterns | 80 lines |
| Research Agent Prompt Template | 148-226 | Reduce to template + reference | Single Agent Pattern | 40 lines |
| Planning Agent Invocation | 471-497 | Reference + orchestrate context | Single Agent Pattern | 15 lines |

**Phase 2: Artifact and Checkpoint Sections**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Artifact Storage and Registry | 246-274 | Reference + registry specifics | Artifact Storage Pattern | 20 lines |
| Save Research Checkpoint | 275-289 | Reference + checkpoint data | Checkpoint Management | 10 lines |
| Bidirectional Cross-References | 1272-1312 | Replace with reference | Artifact Referencing | 40 lines |

**Phase 3: Error Recovery and Debugging**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Implementation Error Handling | 676-748 | Reference + implement-specific | Error Recovery Patterns | 35 lines |
| Debugging Loop | 809-1175 | Reference test failure + debug workflow | Test Failure Handling | 100 lines |
| Error Recovery Mechanism | 1782-1810 | Consolidate with reference | Error Recovery Patterns | 25 lines |

**Phase 4: Progress and Monitoring**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Progress Streaming | 471-497 (overlap) | Reference pattern | Progress Marker Detection | Included in Phase 1 |

**Total Orchestrate Reduction: ~365 lines**
**Result: 2,092 - 365 = 1,727 lines (close to target)**

**Validation Criteria:**
- [ ] All agent invocations reference patterns correctly
- [ ] Orchestrate-specific context preserved
- [ ] Error recovery workflow intact
- [ ] Checkpoint data structure documented
- [ ] No broken references

---

### Priority 2: setup.md (~2,200 lines → ~1,400 lines)

**Note:** Setup.md has minimal pattern extraction potential. Alternative: Internal optimization.

**Phase 1: Remove Redundant Documentation**

| Section | Lines | Action | Savings |
|---------|-------|--------|---------|
| Duplicate flag explanations | 109-310 | Consolidate examples, reduce verbosity | 100 lines |
| Repetitive mode descriptions | Various | Merge overlapping content | 50 lines |
| Verbose error examples | 209-310 | Keep 2-3 examples, remove redundant | 60 lines |

**Phase 2: Extract Shared Utilities Reference**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Shared Utilities Integration | 13-19 | Reference error patterns | Error Recovery Patterns | 10 lines |

**Phase 3: Simplify Workflow Diagrams**

| Section | Lines | Action | Savings |
|---------|-------|--------|---------|
| Cleanup Workflow | 756-791 | Reduce ASCII diagram verbosity | 20 lines |
| Analysis Workflow | 1290-1314 | Consolidate with execution plan | 15 lines |

**Phase 4: Consolidate Preference Sections**

| Section | Lines | Action | Savings |
|---------|-------|--------|---------|
| Threshold Settings | 540-577 | Remove examples, keep reference table | 25 lines |
| Directory Structure Prefs | 578-621 | Reduce to concise list | 30 lines |
| Link Style Preferences | 622-667 | Simplify, remove redundant examples | 30 lines |

**Phase 5: Reduce Example Verbosity**

| Section | Lines | Action | Savings |
|---------|-------|--------|---------|
| Usage Examples 1-6 | 1943-2087 | Keep 3 core examples, remove 3 redundant | 100 lines |
| Interactive prompts | Various | Reduce ASCII box verbosity | 40 lines |

**Total Setup Reduction: ~480 lines**
**Result: 2,200 - 480 = 1,720 lines (above target, but setup is dense)**

**Alternative Target: 1,700 lines (acceptable given setup's unique content)**

**Validation Criteria:**
- [ ] All modes (standard, cleanup, analyze, apply-report) documented
- [ ] Flag combinations clear
- [ ] Workflow diagrams intelligible
- [ ] Examples cover all major use cases
- [ ] Error messages actionable

---

### Priority 3: implement.md (~1,650 lines → ~1,000 lines)

**Phase 1: Shared Utilities and Logging**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Shared Utilities Integration | 32-38 | Reference checkpoint/complexity patterns | Checkpoint Management | 10 lines |
| Logger Initialization | 147-175 | Extract to new pattern, reference | NEW: Logger Init Pattern | 20 lines |

**Phase 2: Agent and Progress Patterns**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Dependency Analysis | 243-276 | Reference parallel execution | NEW: Parallel Safety Pattern | 15 lines |
| Agent Monitoring + Progress | 367-411 | Replace with progress pattern reference | Progress Streaming | 30 lines |

**Phase 3: Error Handling**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Enhanced Error Analysis | 594-651 | Reference error classification | Error Recovery Patterns | 35 lines |
| Error Handling and Rollback | 1197-1231 | Reference error recovery | Error Recovery Patterns | 20 lines |

**Phase 4: Summary and Cross-References**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Summary Generation | 1282-1350 | Reference artifact cross-refs | Artifact Referencing | 40 lines |
| Create Pull Request | 1353-1447 | Extract to new pattern, reference | NEW: PR Creation Pattern | 60 lines |

**Phase 5: Checkpoint Management**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Checkpoint Detection/Resume | 1560-1645 | Replace with checkpoint pattern ref | Checkpoint Management | 50 lines |

**Phase 6: Standards Discovery (Redundant with CLAUDE.md)**

| Section | Lines | Action | Reference | Savings |
|---------|-------|--------|-----------|---------|
| Standards Discovery and Application | 65-140 | Reduce to brief summary + CLAUDE.md ref | Standards Discovery | 50 lines |

**Total Implement Reduction: ~330 lines**
**Result: 1,650 - 330 = 1,320 lines (above target of 1,000)**

**Additional Optimization Needed: ~320 lines**

**Phase 7: Aggressive Internal Consolidation**

| Section | Lines | Action | Savings |
|---------|-------|--------|---------|
| Adaptive Planning Detection | 654-847 | Reduce verbose trigger explanations | 80 lines |
| Progressive Plan Support | 184-241 | Consolidate level detection examples | 30 lines |
| Phase Execution Protocol | 290-578 | Remove redundant step explanations | 100 lines |
| Auto-Resume Feature | 58-64 | Merge with Finding Implementation Plan | 10 lines |
| Integration with Other Commands | 1481-1527 | Reduce to concise table | 30 lines |
| Resuming Implementation | 1189-1196 | Merge with Checkpoint section | 10 lines |

**Additional Consolidation: ~260 lines**
**Revised Result: 1,650 - 590 = 1,060 lines (close to target)**

**Validation Criteria:**
- [ ] All adaptive planning triggers documented
- [ ] Checkpoint resume workflow clear
- [ ] Error handling preserves partial work
- [ ] Summary generation creates bidirectional links
- [ ] PR creation optional and graceful

---

### Secondary Commands (10-15 commands, ~8,000 lines total)

**Batch processing approach:**

For commands like `plan.md`, `test.md`, `debug.md`, `document.md`, `revise.md`, etc.:

1. **Scan for pattern matches**: Use grep to find sections matching known patterns
2. **Apply reference template**: Replace with standard reference format
3. **Preserve command-specific**: Keep unique logic inline
4. **Validate**: Ensure command still functional

**Expected savings per command: 50-100 lines average**
**Total secondary reduction: ~800 lines**
**Target: 8,000 - 800 = 7,200 lines**

## Implementation Approach

### Order of Refactoring

**Week 1: Preparation**
1. Add new patterns to command-patterns.md (Logger Init, PR Creation, Parallel Safety)
2. Create validation test suite for command parsing
3. Backup all command files

**Week 2: Priority Commands**
1. orchestrate.md (most complex, set the example)
2. implement.md (second most complex)
3. setup.md (unique structure, different approach)

**Week 3: Secondary Commands**
1. Batch process 5-7 commands (plan, test, debug, document, revise)
2. Batch process remaining commands

**Week 4: Validation and Testing**
1. Test all commands with actual workflows
2. Verify all references resolve
3. Measure LOC reduction
4. Document lessons learned

### Incremental Validation Strategy

**After Each Command Refactored:**

1. **Syntax Validation**
   ```bash
   # Check markdown validity
   mdl .claude/commands/[command].md

   # Verify all reference links resolve
   grep -o '\](../docs/command-patterns.md#[^)]*' [command].md | \
     while read link; do
       anchor=$(echo "$link" | sed 's/.*#//')
       grep -q "^## $anchor\|^### $anchor" ../docs/command-patterns.md || echo "Broken: $anchor"
     done
   ```

2. **Semantic Validation**
   ```bash
   # Test command can still be invoked
   /[command] --help

   # Run command with test data (if applicable)
   /[command] [test-args]
   ```

3. **Documentation Validation**
   - Read refactored command end-to-end
   - Verify no information loss
   - Check command-specific details preserved
   - Ensure references provide sufficient context

4. **Checkpoint**: Create git commit after each command validated

### Testing Checkpoints

**Orchestrate Validation:**
```bash
# Test orchestrate with simple workflow
/orchestrate "Create hello world script"

# Verify:
- Agent invocation works
- Checkpoint saves/resumes
- Error recovery functional
- Progress streaming visible
```

**Implement Validation:**
```bash
# Test implement with small plan
/implement specs/plans/test_plan.md

# Verify:
- Standards discovery works
- Testing integration functional
- Checkpoint resume works
- Summary generation includes cross-refs
```

**Setup Validation:**
```bash
# Test all setup modes
/setup --analyze
/setup --cleanup --dry-run
/setup --validate

# Verify:
- Mode detection works
- Standards analysis runs
- Cleanup identifies candidates
```

### Rollback Procedures

**Per-Command Rollback:**
```bash
# If command refactor fails validation
git checkout HEAD -- .claude/commands/[command].md

# Restore from backup
cp .claude/commands/[command].md.backup .claude/commands/[command].md
```

**Full Phase Rollback:**
```bash
# If entire phase needs rollback
git reset --hard [commit-before-phase-4]

# Restore all backups
for file in .claude/commands/*.md.backup; do
  cp "$file" "${file%.backup}"
done
```

**Safety Protocol:**
- Never delete backups until phase complete
- Test each command individually before proceeding
- Keep git history clean with meaningful commits
- Document rollback reasons for future reference

## Reference Link Patterns

### Standard Reference Template

```markdown
## [Section Name]

For [concept description], see [Pattern Name](../docs/command-patterns.md#pattern-name).

**[Command]-specific [aspect]:**
- [Specific detail 1]
- [Specific detail 2]
- [Specific detail 3]

[Optional: Brief example showing command-specific usage]
```

### Reference Variations

**Variation 1: Single Pattern Reference**
```markdown
For checkpoint management, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns).
```

**Variation 2: Multiple Pattern Reference**
```markdown
For error handling, see [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns) and [Test Failure Handling](../docs/command-patterns.md#pattern-test-failure-handling).
```

**Variation 3: Reference + Brief Summary**
```markdown
For parallel agent invocation patterns, see [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation).

Key principle: Each agent receives ONLY its specific focus. NO orchestration routing logic in prompts.
```

**Variation 4: Reference + Command-Specific Extension**
```markdown
For artifact storage, see [Artifact Storage and Registry](../docs/command-patterns.md#pattern-artifact-storage-and-registry).

**Orchestrate-specific artifact handling:**
- Generate artifact path: `specs/artifacts/{project_name}/{artifact_name}.md`
- Register in artifact_registry with descriptive ID
- Return references (not full content) to minimize context
```

### Before/After Examples

**Example 1: Checkpoint Pattern (from implement.md)**

**Before (85 lines):**
```markdown
### Checkpoint Detection and Resume

Before starting implementation, I'll check for existing checkpoints that might indicate an interrupted implementation.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent implement checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists for this plan, I'll present interactive options:

```
Found existing checkpoint for implementation
Plan: [plan_path]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Last test status: [tests_passing]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart from beginning
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

### Step 3: Resume Implementation State (if user chooses resume)

If user selects resume:
1. Load plan_path from checkpoint
2. Restore current_phase, completed_phases
3. Skip to next incomplete phase
4. Continue implementation from that point

[... 50 more lines of detailed checkpoint handling ...]
```

**After (15 lines):**
```markdown
### Checkpoint Detection and Resume

For checkpoint detection and resumption workflows, see [Checkpoint Management Patterns](../docs/command-patterns.md#checkpoint-management-patterns) and [Resume from Checkpoint](../docs/command-patterns.md#pattern-resume-from-checkpoint).

**Implement-specific checkpoint:**
- **Command**: `implement`
- **Project name**: Extracted from plan filename
- **State includes**: plan_path, current_phase, completed_phases, tests_passing
- **Resume from**: First incomplete phase
- **Cleanup**: Delete checkpoint on success, archive on failure
```

**Savings: 70 lines**

---

**Example 2: Error Recovery (from orchestrate.md)**

**Before (72 lines):**
```markdown
### Error Recovery Mechanism

Commands should implement graceful error handling with automatic retry and user escalation.

### Automatic Recovery Strategies

**Error Types**:
1. **Timeout Errors**: Agent execution exceeds time limits
2. **Tool Access Errors**: Permission or availability issues
3. **Validation Failures**: Output doesn't meet criteria
4. **Test Failures**: Code tests fail (handled by Debugging Loop)
5. **Integration Errors**: Command invocation failures
6. **Context Overflow**: Orchestrator context approaches limits

**Standard retry sequence** (max 3 attempts):
1. **First retry**: Same operation with extended timeout
2. **Second retry**: Modified approach (simpler requirements)
3. **Third retry**: Alternative method or tool
4. **Escalation**: Report to user with context

[... 40 more lines of retry logic and escalation format ...]
```

**After (18 lines):**
```markdown
### Error Recovery Mechanism

For error classification and recovery strategies, see [Error Recovery Patterns](../docs/command-patterns.md#error-recovery-patterns).

**Orchestrate-specific error handling:**
- **Context Overflow**: Compress context, summarize aggressively, reduce workflow scope
- **Checkpoint-based recovery**: Rollback to last successful phase
- **Error history tracking**: Learn from failures to improve future workflows
- **Agent failures**: Retry with adjusted agent parameters or different agent type

**Escalation triggers:**
- Max retries exceeded (3 attempts)
- Critical failures (data loss, security issues)
- Debugging loop limit reached (3 iterations)
```

**Savings: 54 lines**

---

**Example 3: Progress Streaming (from implement.md)**

**Before (44 lines):**
```markdown
### Agent Monitoring with Progress Streaming

After delegating to an agent, monitor progress and process results:

**Progress Monitoring**: Agents emit `PROGRESS: <message>` markers during execution
- Example: `PROGRESS: Implementing login function in auth.lua...`
- Display progress markers to user as they arrive (if tool supports streaming)
- Progress provides real-time visibility into long-running operations

**Result Processing**:
- Verify all tasks were completed
- Note any test failures or issues
- Use agent's output for subsequent testing and commit steps

**Progress Handling**:
- Filter PROGRESS: lines from agent output
- Display them separately or inline with status indicators
- Do not include progress markers in final output summary

**Example Progress Flow**:
```
PROGRESS: Reading phase tasks...
PROGRESS: Implementing auth.login() function...
PROGRESS: Adding error handling with pcall...
PROGRESS: Running test suite...
PROGRESS: All tests passed, finalizing...
```

[... more examples and edge cases ...]
```

**After (12 lines):**
```markdown
### Agent Monitoring with Progress Streaming

For progress marker detection and display, see [Progress Streaming Patterns](../docs/command-patterns.md#pattern-progress-marker-detection).

**Implement-specific progress:**
- Monitor phase implementation progress during agent execution
- Track test execution progress (test discovery, execution, results)
- Display checkpoint save progress
- Filter progress markers from final commit messages
```

**Savings: 32 lines**

## Detailed Task Breakdown

### Task 1: Add New Patterns to command-patterns.md (2 hours)

**Objective:** Extend command-patterns.md with 3 new pattern sections

**Files to Modify:**
- `/home/benjamin/.config/.claude/docs/command-patterns.md`

**Actions:**
1. Add "Logger Initialization Pattern" section (~30 lines)
   - Standard logger sourcing template
   - No-op fallbacks
   - Log directory creation with permissions
   - Example from implement.md lines 147-175

2. Add "PR Creation Pattern" section (~90 lines)
   - GitHub CLI prerequisite checks
   - Agent invocation template for github-specialist
   - PR URL capture and summary updates
   - Graceful degradation examples
   - Manual command fallbacks
   - Source: orchestrate.md lines 1583-1677, implement.md lines 1353-1447

3. Add "Parallel Execution Safety Pattern" section (~40 lines)
   - Max parallelism limits (3 concurrent phases)
   - Fail-fast wave execution
   - Checkpoint preservation after waves
   - Result aggregation from parallel agents
   - Source: implement.md lines 243-276

**Validation:**
```bash
# Check pattern structure
grep "^## " command-patterns.md | wc -l  # Should increase by 3
grep "^### Pattern:" command-patterns.md | wc -l  # Should increase by 3

# Validate markdown
mdl command-patterns.md

# Check line count
wc -l command-patterns.md  # Should be ~850 lines (690 + 160)
```

**Success Criteria:**
- [ ] Three new pattern sections added
- [ ] Each pattern has clear example code
- [ ] Table of Contents updated with new patterns
- [ ] Markdown syntax valid
- [ ] No broken internal links

---

### Task 2: Backup All Command Files (30 minutes)

**Objective:** Create safety backups before refactoring

**Files:**
- All `.claude/commands/*.md` files

**Actions:**
```bash
# Create backup directory
mkdir -p .claude/commands/backups/phase4_$(date +%Y%m%d)

# Copy all command files
cp .claude/commands/*.md .claude/commands/backups/phase4_$(date +%Y%m%d)/

# Verify backup
ls -lh .claude/commands/backups/phase4_$(date +%Y%m%d)/ | wc -l
```

**Validation:**
- [ ] Backup directory created with timestamp
- [ ] All command files backed up (20+ files)
- [ ] File sizes match originals
- [ ] Backup directory read-only (chmod 444)

---

### Task 3: Create Validation Test Suite (3 hours)

**Objective:** Build automated tests to validate refactored commands

**Files to Create:**
- `.claude/tests/test_command_references.sh`
- `.claude/tests/fixtures/test_commands/`

**Actions:**

1. **Create reference validation test:**
```bash
#!/usr/bin/env bash
# test_command_references.sh

test_reference_links_resolve() {
  local command_file="$1"
  local broken_refs=0

  # Extract all pattern references
  grep -o '\](../docs/command-patterns.md#[^)]*' "$command_file" | \
    sed 's/.*#//' | \
    while read anchor; do
      # Check if anchor exists in command-patterns.md
      if ! grep -q "^## $anchor\|^### Pattern:.*$anchor" ../docs/command-patterns.md; then
        echo "Broken reference in $command_file: #$anchor"
        broken_refs=$((broken_refs + 1))
      fi
    done

  return $broken_refs
}

test_no_information_loss() {
  local command_file="$1"
  local backup_file="$2"

  # Check that command-specific sections are preserved
  # This is a heuristic: unique terms should still appear

  local unique_terms=$(grep -i "command-specific\|orchestrate-specific\|implement-specific" "$backup_file" | \
    awk '{print $1}' | sort -u)

  for term in $unique_terms; do
    if ! grep -qi "$term" "$command_file"; then
      echo "Warning: Unique term '$term' missing from refactored $command_file"
    fi
  done
}

# Run tests
for cmd in .claude/commands/*.md; do
  backup=".claude/commands/backups/phase4_$(date +%Y%m%d)/$(basename $cmd)"
  echo "Testing $cmd..."
  test_reference_links_resolve "$cmd"
  test_no_information_loss "$cmd" "$backup"
done
```

2. **Create command execution test:**
```bash
# Test that commands can still be invoked
test_command_invocation() {
  /orchestrate --help 2>&1 | grep -q "Multi-Agent Workflow"
  /implement --help 2>&1 | grep -q "Execute Implementation Plan"
  /setup --help 2>&1 | grep -q "Setup Project Standards"
}
```

**Validation:**
- [ ] Test suite runs without errors
- [ ] All tests pass on original command files
- [ ] Tests detect broken references (verified with intentional break)
- [ ] Tests integrated into `run_all_tests.sh`

---

### Task 4: Refactor orchestrate.md - Agent Invocation Sections (4 hours)

**Objective:** Extract agent invocation patterns from orchestrate.md

**File:** `.claude/commands/orchestrate.md`

**Sections to Refactor:**

1. **Lines 95-108: Parallel Research Agents**
   - **Before**: 80 lines of detailed parallel invocation explanation
   - **After**: Reference to pattern + orchestrate-specific details (15 lines)
   - **Replacement**:
```markdown
### Step 2: Launch Parallel Research Agents

For parallel agent invocation patterns, see [Parallel Agent Invocation](../docs/command-patterns.md#pattern-parallel-agent-invocation).

**Orchestrate-specific invocation:**
- Launch 2-4 research agents simultaneously (single message, multiple Task blocks)
- Each agent receives ONLY its specific research focus
- NO orchestration routing logic in prompts
- Complete task description with success criteria per agent
```

2. **Lines 148-226: Research Agent Prompt Template**
   - **Before**: 78 lines of template structure
   - **After**: Reference to pattern + orchestrate template (38 lines)
   - **Replacement**: Keep orchestrate-specific template structure, reference single agent pattern for template format

3. **Lines 471-497: Planning Agent Monitoring**
   - **Before**: 26 lines of progress monitoring
   - **After**: Reference to pattern + orchestrate monitoring (10 lines)

**Actions:**
```bash
# Use Edit tool for each section
# Verify line count reduction
wc -l orchestrate.md  # Should be ~115 lines less

# Validate references
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md

# Test command
/orchestrate "Test simple workflow"
```

**Validation:**
- [ ] All references resolve to command-patterns.md
- [ ] Orchestrate-specific context preserved
- [ ] Command still functional (test with simple workflow)
- [ ] Line count reduced by ~115 lines
- [ ] Git commit: "refactor(orchestrate): extract agent invocation patterns"

---

### Task 5: Refactor orchestrate.md - Artifact and Checkpoint Sections (3 hours)

**Objective:** Extract artifact and checkpoint patterns

**File:** `.claude/commands/orchestrate.md`

**Sections:**

1. **Lines 246-274: Artifact Storage and Registry**
   - **Before**: 28 lines
   - **After**: Reference + orchestrate registry handling (10 lines)

2. **Lines 275-289: Save Research Checkpoint**
   - **Before**: 14 lines
   - **After**: Reference + checkpoint data structure (5 lines)

3. **Lines 1272-1312: Bidirectional Cross-References**
   - **Before**: 40 lines
   - **After**: Reference to pattern (8 lines)

**Actions:**
- Use Edit tool for each section
- Preserve orchestrate-specific artifact registry structure
- Validate with test suite

**Validation:**
- [ ] References resolve correctly
- [ ] Artifact registry logic intact
- [ ] Checkpoint data structure documented
- [ ] Line count reduced by ~70 lines
- [ ] Git commit: "refactor(orchestrate): extract artifact/checkpoint patterns"

---

### Task 6: Refactor orchestrate.md - Error Recovery and Debugging (5 hours)

**Objective:** Extract error recovery patterns (largest opportunity)

**File:** `.claude/commands/orchestrate.md`

**Sections:**

1. **Lines 676-748: Implementation Error Handling**
   - **Before**: 72 lines
   - **After**: Reference + orchestrate error types (20 lines)

2. **Lines 809-1175: Debugging Loop (Conditional)**
   - **Before**: 366 lines (LARGEST SECTION)
   - **After**: Reference to test failure pattern + orchestrate debugging workflow (100 lines)
   - **Key**: This is the biggest extraction opportunity
   - **Approach**:
     - Reference test failure handling pattern
     - Reference debugging workflow
     - Keep orchestrate-specific iteration tracking
     - Keep agent delegation logic (debug-specialist, code-writer)

3. **Lines 1782-1810: Error Recovery Mechanism**
   - **Before**: 28 lines
   - **After**: Reference + orchestrate-specific (10 lines)

**Actions:**
```bash
# This is the most complex refactor
# Use Edit tool carefully, section by section

# Validate debugging workflow still functional
# Create test case: orchestrate workflow with failing tests

# Verify iteration tracking preserved
grep -i "iteration.*3" orchestrate.md  # Should still exist
```

**Validation:**
- [ ] Debugging loop workflow intact
- [ ] 3-iteration limit documented
- [ ] Agent delegation logic preserved
- [ ] Error escalation format clear
- [ ] Line count reduced by ~180 lines (366 - 186 kept)
- [ ] Test with failing workflow
- [ ] Git commit: "refactor(orchestrate): extract error recovery patterns"

---

### Task 7: Validate orchestrate.md Refactoring (2 hours)

**Objective:** Comprehensive validation of orchestrate.md

**Actions:**

1. **Run test suite:**
```bash
bash .claude/tests/test_command_references.sh .claude/commands/orchestrate.md
```

2. **Manual validation:**
   - Read orchestrate.md end-to-end
   - Verify all workflows described
   - Check command-specific details preserved

3. **Functional testing:**
```bash
# Test simple workflow
/orchestrate "Create a hello world Python script"

# Test complex workflow (if time permits)
/orchestrate "Add user authentication with email and password"
```

4. **Measure reduction:**
```bash
# Original
wc -l .claude/commands/backups/phase4_*/orchestrate.md

# Refactored
wc -l .claude/commands/orchestrate.md

# Calculate reduction
```

**Success Criteria:**
- [ ] All references resolve
- [ ] No information loss detected
- [ ] Command executes successfully
- [ ] Line count: ~1,700 lines (target ~1,500, acceptable variance)
- [ ] Git commit: "docs(orchestrate): validate refactoring"

---

### Task 8: Refactor implement.md - Shared Utilities and Logging (2 hours)

**Objective:** Extract shared utilities and logger initialization

**File:** `.claude/commands/implement.md`

**Sections:**

1. **Lines 32-38: Shared Utilities Integration**
   - **Before**: 10 lines
   - **After**: Reference to checkpoint management (3 lines)

2. **Lines 147-175: Logger Initialization**
   - **Before**: 28 lines
   - **After**: Reference to new logger pattern (8 lines)

**Actions:**
- Extract logger initialization to pattern (already done in Task 1)
- Replace with reference + implement-specific logging details

**Validation:**
- [ ] References resolve
- [ ] Logger initialization still documented
- [ ] Line count reduced by ~27 lines
- [ ] Git commit: "refactor(implement): extract utilities/logging patterns"

---

### Task 9: Refactor implement.md - Agent, Progress, and Error Patterns (4 hours)

**Objective:** Extract agent monitoring, progress streaming, and error handling

**File:** `.claude/commands/implement.md`

**Sections:**

1. **Lines 243-276: Dependency Analysis → Parallel Execution**
   - **Before**: 33 lines
   - **After**: Reference to parallel safety pattern (12 lines)

2. **Lines 367-411: Agent Monitoring with Progress Streaming**
   - **Before**: 44 lines
   - **After**: Reference to progress pattern (12 lines)

3. **Lines 594-651: Enhanced Error Analysis**
   - **Before**: 57 lines
   - **After**: Reference to error classification (20 lines)

4. **Lines 1197-1231: Error Handling and Rollback**
   - **Before**: 34 lines
   - **After**: Reference to error recovery (12 lines)

**Actions:**
- Use Edit tool for each section
- Preserve implement-specific error handling (test failures, partial work preservation)

**Validation:**
- [ ] All references resolve
- [ ] Error analysis output format preserved
- [ ] Line count reduced by ~110 lines
- [ ] Git commit: "refactor(implement): extract agent/error patterns"

---

### Task 10: Refactor implement.md - Summary, PR, and Checkpoints (4 hours)

**Objective:** Extract summary generation, PR creation, and checkpoint patterns

**File:** `.claude/commands/implement.md`

**Sections:**

1. **Lines 1282-1350: Summary Generation → Cross-References**
   - **Before**: 68 lines
   - **After**: Reference to artifact cross-refs (20 lines)

2. **Lines 1353-1447: Create Pull Request (Optional)**
   - **Before**: 94 lines
   - **After**: Reference to PR pattern (15 lines)

3. **Lines 1560-1645: Checkpoint Detection and Resume**
   - **Before**: 85 lines
   - **After**: Reference to checkpoint management (15 lines)

**Actions:**
- Reference newly created PR pattern
- Keep implement-specific checkpoint state structure

**Validation:**
- [ ] All references resolve
- [ ] PR creation workflow preserved
- [ ] Checkpoint resume logic intact
- [ ] Line count reduced by ~197 lines
- [ ] Git commit: "refactor(implement): extract summary/PR/checkpoint patterns"

---

### Task 11: Aggressive Internal Consolidation - implement.md (4 hours)

**Objective:** Consolidate verbose sections to reach target line count

**File:** `.claude/commands/implement.md`

**Current State After Tasks 8-10:**
- Original: 1,650 lines
- After extraction: ~1,316 lines (1,650 - 334 from tasks 8-10)
- Target: 1,000 lines
- **Additional reduction needed: ~316 lines**

**Sections to Consolidate:**

1. **Lines 654-847: Adaptive Planning Detection**
   - **Current**: 193 lines with verbose trigger explanations
   - **Action**: Reduce trigger detection examples, consolidate shell script examples
   - **Target**: 100 lines
   - **Savings**: 93 lines

2. **Lines 184-241: Progressive Plan Support**
   - **Current**: 57 lines
   - **Action**: Consolidate level detection examples, reduce parser usage examples
   - **Target**: 30 lines
   - **Savings**: 27 lines

3. **Lines 290-578: Phase Execution Protocol**
   - **Current**: 288 lines with redundant step explanations
   - **Action**: Consolidate wave execution, merge redundant delegation examples
   - **Target**: 180 lines
   - **Savings**: 108 lines

4. **Lines 58-64: Auto-Resume Feature**
   - **Current**: 6 lines
   - **Action**: Merge with "Finding Implementation Plan" section
   - **Target**: 0 lines (merged)
   - **Savings**: 6 lines

5. **Lines 1481-1527: Integration with Other Commands**
   - **Current**: 46 lines
   - **Action**: Reduce to concise table format
   - **Target**: 20 lines
   - **Savings**: 26 lines

6. **Lines 1189-1196: Resuming Implementation**
   - **Current**: 7 lines
   - **Action**: Merge with Checkpoint section
   - **Target**: 0 lines (merged)
   - **Savings**: 7 lines

**Total Consolidation: ~267 lines**

**Actions:**
```bash
# Use Edit tool for each consolidation
# Focus on removing redundant examples and verbose explanations

# Verify functionality preserved
/implement --help

# Check line count
wc -l .claude/commands/implement.md  # Target: ~1,049 lines
```

**Validation:**
- [ ] All workflows still documented
- [ ] No critical information removed
- [ ] Examples still illustrative
- [ ] Line count: ~1,050 lines (within 5% of target)
- [ ] Git commit: "refactor(implement): consolidate verbose sections"

---

### Task 12: Validate implement.md Refactoring (2 hours)

**Objective:** Comprehensive validation of implement.md

**Actions:**

1. **Run test suite:**
```bash
bash .claude/tests/test_command_references.sh .claude/commands/implement.md
```

2. **Functional testing:**
```bash
# Test with simple plan
/implement specs/plans/test_simple_plan.md

# Test checkpoint resume
/implement  # Should auto-detect incomplete plan

# Test adaptive planning trigger
# (create plan with complex phase, verify detection)
```

3. **Measure reduction:**
```bash
# Calculate final reduction
original=$(wc -l < .claude/commands/backups/phase4_*/implement.md)
refactored=$(wc -l < .claude/commands/implement.md)
reduction=$((original - refactored))
percentage=$((reduction * 100 / original))

echo "Reduction: $reduction lines ($percentage%)"
# Target: ~600 lines (36% reduction)
```

**Success Criteria:**
- [ ] All references resolve
- [ ] Adaptive planning still functional
- [ ] Checkpoint resume works
- [ ] Line count: ~1,050 lines (target 1,000, within tolerance)
- [ ] Git commit: "docs(implement): validate refactoring"

---

### Task 13: Optimize setup.md - Internal Consolidation (5 hours)

**Objective:** Optimize setup.md through internal consolidation (minimal extraction)

**File:** `.claude/commands/setup.md`

**Note:** Setup.md has minimal pattern extraction potential. Focus on internal optimization.

**Consolidation Targets:**

1. **Lines 109-310: Argument Parsing and Error Handling**
   - **Current**: 201 lines with redundant flag examples
   - **Action**: Keep 2-3 key examples, consolidate error messages
   - **Target**: 120 lines
   - **Savings**: 81 lines

2. **Lines 535-723: Extraction Preferences**
   - **Current**: 188 lines with verbose threshold explanations
   - **Action**: Convert to concise tables, reduce examples
   - **Target**: 120 lines
   - **Savings**: 68 lines

3. **Lines 1943-2087: Usage Examples**
   - **Current**: 144 lines with 6 examples
   - **Action**: Keep 3 essential examples (standard, cleanup, analyze)
   - **Target**: 70 lines
   - **Savings**: 74 lines

4. **Lines 792-939: Bloat Detection Algorithm**
   - **Current**: 147 lines
   - **Action**: Reduce verbose prompt examples, consolidate threshold logic
   - **Target**: 100 lines
   - **Savings**: 47 lines

5. **Interactive Prompts (Various)**: Reduce ASCII box verbosity
   - **Current**: ~80 lines total across multiple sections
   - **Action**: Simplify box formatting, reduce whitespace
   - **Target**: 40 lines
   - **Savings**: 40 lines

**Total Setup Reduction: ~310 lines**
**Result: 2,200 - 310 = 1,890 lines**

**Note:** This exceeds initial target of 1,400 but is acceptable given setup's unique, dense content.

**Actions:**
```bash
# Use Edit tool for each consolidation
# Focus on removing redundant examples

# Validate all modes still documented
/setup --help
/setup --analyze --help
/setup --cleanup --help
```

**Validation:**
- [ ] All modes documented (standard, cleanup, analyze, validate, apply-report)
- [ ] Flag combinations clear
- [ ] Examples cover major use cases
- [ ] Line count: ~1,890 lines
- [ ] Git commit: "refactor(setup): optimize internal structure"

---

### Task 14: Validate setup.md Optimization (2 hours)

**Objective:** Validate setup.md functionality after optimization

**Actions:**

1. **Test all modes:**
```bash
/setup --analyze
/setup --cleanup --dry-run
/setup --validate
/setup --apply-report [test-report]
```

2. **Manual review:**
   - Read setup.md end-to-end
   - Verify workflow diagrams intelligible
   - Check error messages actionable

3. **Measure reduction:**
```bash
original=$(wc -l < .claude/commands/backups/phase4_*/setup.md)
refactored=$(wc -l < .claude/commands/setup.md)
reduction=$((original - refactored))
percentage=$((reduction * 100 / original))

echo "Reduction: $reduction lines ($percentage%)"
# Target: ~310 lines (14% reduction)
```

**Success Criteria:**
- [ ] All modes functional
- [ ] Standards analysis runs
- [ ] Cleanup identifies candidates
- [ ] Line count: ~1,890 lines (acceptable given dense content)
- [ ] Git commit: "docs(setup): validate optimization"

---

### Task 15: Batch Process Secondary Commands (8 hours)

**Objective:** Refactor 10-15 secondary commands using pattern references

**Commands to Refactor:**
1. plan.md
2. test.md
3. test-all.md
4. debug.md
5. document.md
6. revise.md
7. expand.md
8. collapse.md
9. list.md
10. update.md

**Batch Process Template:**

For each command:

1. **Scan for pattern matches:**
```bash
# Find sections matching known patterns
grep -n "checkpoint\|agent invocation\|error recovery" [command].md

# Find verbose sections (>50 lines)
awk '/^## /{start=NR} /^## /{if(NR-start>50) print start"-"NR, prev} {prev=$0}' [command].md
```

2. **Apply reference template:**
   - Replace matched sections with pattern references
   - Preserve command-specific details

3. **Validate:**
```bash
bash .claude/tests/test_command_references.sh .claude/commands/[command].md
/[command] --help
```

4. **Commit:**
```bash
git add .claude/commands/[command].md
git commit -m "refactor([command]): extract common patterns"
```

**Expected Savings Per Command:**
- plan.md: 80 lines (agent invocation, standards discovery)
- test.md: 60 lines (testing integration patterns)
- test-all.md: 40 lines (testing patterns)
- debug.md: 70 lines (error recovery patterns)
- document.md: 50 lines (artifact cross-references)
- revise.md: 90 lines (checkpoint management, error recovery)
- expand.md: 50 lines (progressive plan patterns)
- collapse.md: 50 lines (progressive plan patterns)
- list.md: 30 lines (artifact referencing)
- update.md: 40 lines (checkpoint management)

**Total Secondary Reduction: ~560 lines**

**Validation:**
- [ ] All references resolve
- [ ] Commands functional (test each)
- [ ] No information loss
- [ ] Git commits clean and meaningful

---

### Task 16: Final Validation and Measurement (3 hours)

**Objective:** Validate entire phase, measure final results

**Actions:**

1. **Run complete test suite:**
```bash
bash .claude/tests/run_all_tests.sh
```

2. **Validate all references resolve:**
```bash
# Test all command files
for cmd in .claude/commands/*.md; do
  echo "Validating $cmd..."
  bash .claude/tests/test_command_references.sh "$cmd"
done
```

3. **Measure final LOC reduction:**
```bash
# Total original lines
original=$(find .claude/commands/backups/phase4_* -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')

# Total refactored lines
refactored=$(find .claude/commands -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')

# Calculate reduction
reduction=$((original - refactored))
percentage=$((reduction * 100 / original))

echo "Original: $original lines"
echo "Refactored: $refactored lines"
echo "Reduction: $reduction lines ($percentage%)"
echo "Target: ~6,200 lines (53% reduction)"
```

4. **Test representative workflows:**
```bash
# Test orchestrate workflow
/orchestrate "Create a simple Python calculator"

# Test implement workflow
/implement specs/plans/test_plan.md

# Test setup workflow
/setup --analyze
```

5. **Manual review of command-patterns.md:**
   - Read entire patterns file
   - Verify new patterns integrated cleanly
   - Check table of contents updated

**Success Criteria:**
- [ ] All tests pass
- [ ] All references resolve
- [ ] LOC reduction: ~6,500 lines (close to target)
- [ ] Representative workflows functional
- [ ] command-patterns.md coherent and navigable
- [ ] Git commit: "docs(phase-4): final validation and measurement"

---

### Task 17: Document Lessons Learned (1 hour)

**Objective:** Capture insights for future optimization phases

**File to Create:**
- `.claude/NEW_claude_system_optimization/phase_4_lessons_learned.md`

**Content:**

1. **What Worked Well:**
   - Pattern extraction strategy
   - Reference link format
   - Validation testing approach
   - Incremental git commits

2. **Challenges Encountered:**
   - Commands with unique content (setup.md)
   - Balancing extraction vs. command-specific details
   - Maintaining functionality during refactoring

3. **Metrics Achieved:**
   - Original LOC: 13,020
   - Final LOC: [actual]
   - Reduction: [actual] lines ([actual]%)
   - Target: 6,200 lines (53%)

4. **Recommendations for Future Phases:**
   - Consider extracting workflow diagrams
   - Potential for shared example library
   - Opportunity for slash command auto-generation from patterns

**Validation:**
- [ ] Lessons documented
- [ ] Metrics accurate
- [ ] Recommendations actionable
- [ ] Git commit: "docs(phase-4): lessons learned"

---

### Task 18: Create Phase 4 Summary (1 hour)

**Objective:** Generate implementation summary for Phase 4

**File to Create:**
- `.claude/NEW_claude_system_optimization/summaries/phase_4_summary.md`

**Content:**

```markdown
# Phase 4 Implementation Summary: Command Documentation Extraction

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Phase**: Phase 4 of Claude System Optimization
- **Specification**: phase_4_command_documentation_extraction.md
- **Phases Completed**: 4/7

## Overview

Successfully refactored 20+ command files to extract common documentation patterns to `.claude/docs/command-patterns.md`, reducing total command LOC by [actual]% while maintaining full functionality.

## Key Changes

### Files Modified
- `.claude/docs/command-patterns.md`: Added 3 new patterns (+160 lines → ~850 total)
- `.claude/commands/orchestrate.md`: Reduced by ~[actual] lines (pattern extraction)
- `.claude/commands/implement.md`: Reduced by ~[actual] lines (pattern extraction + consolidation)
- `.claude/commands/setup.md`: Reduced by ~[actual] lines (internal optimization)
- 10+ secondary commands: Reduced by ~560 lines total

### New Patterns Added
1. Logger Initialization Pattern (~30 lines)
2. PR Creation Pattern (~90 lines)
3. Parallel Execution Safety Pattern (~40 lines)

### Files Created
- `.claude/tests/test_command_references.sh`: Validation test suite
- `.claude/NEW_claude_system_optimization/phase_4_lessons_learned.md`

## Test Results

**All tests passing:**
- [ ] Reference link resolution tests
- [ ] Command invocation tests
- [ ] Functional workflow tests (orchestrate, implement, setup)
- [ ] No information loss validation

## Metrics Achieved

| Metric | Original | Target | Actual | Status |
|--------|----------|--------|--------|--------|
| Total Command LOC | 13,020 | 6,200 | [actual] | [✓/~] |
| orchestrate.md | 2,092 | 1,500 | [actual] | [✓/~] |
| implement.md | 1,650 | 1,000 | [actual] | [✓/~] |
| setup.md | 2,200 | 1,400 | [actual] | [✓/~] |
| command-patterns.md | 690 | 850 | [actual] | ✓ |

## Lessons Learned

### Successes
- Pattern extraction strategy effective for agent invocation, checkpoints, error recovery
- Reference link format consistent and maintainable
- Incremental validation prevented regressions
- Git commit strategy enabled safe rollback

### Challenges
- setup.md had minimal extraction potential (unique content)
- Balancing brevity vs. clarity in command-specific sections
- Ensuring no information loss during extraction

### Recommendations
- Future phases: Consider extracting workflow diagrams to shared file
- Potential for shared example library across commands
- Opportunity for slash command auto-generation from patterns

## Next Phase

**Phase 5: Workflow Script Consolidation**
- Target: Consolidate `.claude/lib/` utilities
- Reduce duplication across workflow scripts
- Improve error handling consistency
```

**Validation:**
- [ ] Summary accurate
- [ ] Metrics filled in
- [ ] Links to related files work
- [ ] Git commit: "docs(phase-4): implementation summary"

---

## Risk Mitigation

### Risk 1: Broken Command Functionality

**Risk:** Refactoring breaks command execution

**Mitigation:**
- Test each command after refactoring
- Incremental git commits enable rollback
- Validation test suite detects regressions
- Backup directory preserves original files

**Recovery:**
```bash
# Rollback individual command
git checkout HEAD~1 -- .claude/commands/[command].md

# Restore from backup
cp .claude/commands/backups/phase4_*/[command].md .claude/commands/
```

### Risk 2: Information Loss

**Risk:** Critical command-specific details lost during extraction

**Mitigation:**
- Manual review of each refactored section
- "Command-specific" sections preserve unique details
- Test suite validates no missing unique terms
- Keep examples that illustrate command behavior

**Detection:**
```bash
# Compare unique terms between original and refactored
comm -23 <(grep -io '\w\+' original.md | sort -u) \
         <(grep -io '\w\+' refactored.md | sort -u) | \
  head -20  # Review missing terms
```

### Risk 3: Broken Reference Links

**Risk:** Pattern references point to non-existent sections

**Mitigation:**
- Automated reference validation tests
- Run after each command refactored
- Anchor names standardized in command-patterns.md
- Table of contents in patterns file aids navigation

**Detection:**
```bash
# Validate all references
bash .claude/tests/test_command_references.sh .claude/commands/[command].md
```

### Risk 4: Maintenance Burden

**Risk:** Patterns file becomes hard to navigate and maintain

**Mitigation:**
- Clear table of contents in command-patterns.md
- Pattern sections well-organized (7 categories)
- Each pattern has clear example code
- "When to Extract vs Inline" guidance (lines 673-686)

**Validation:**
- Pattern sections ≤100 lines each (readable)
- Table of contents up-to-date
- Cross-references within patterns file work

### Risk 5: Inconsistent Reference Format

**Risk:** Different commands use different reference styles

**Mitigation:**
- Standard reference template documented
- 4 reference variations defined
- Before/after examples provided
- Validation tests check format consistency

**Enforcement:**
```bash
# Check reference format consistency
grep -n '\](../docs/command-patterns.md#' .claude/commands/*.md | \
  awk -F: '{print $3}' | sort | uniq -c
# Should show consistent pattern usage
```

## Rollback Strategy

### Incremental Rollback (Preferred)

**Rollback Single Command:**
```bash
# Revert last commit for specific command
git log --oneline -- .claude/commands/[command].md
git checkout [commit-hash] -- .claude/commands/[command].md

# Or restore from backup
cp .claude/commands/backups/phase4_*/[command].md .claude/commands/
```

**Rollback Task:**
```bash
# Identify task completion commit
git log --oneline | grep "refactor([command]):"

# Revert to before task
git revert [commit-hash]
```

### Full Phase Rollback (Emergency)

**Complete Rollback:**
```bash
# Find phase start commit
git log --oneline | grep "docs(phase-4): start phase 4"
PHASE_START_COMMIT=[commit-hash]

# Reset to before phase
git reset --hard $PHASE_START_COMMIT

# Or restore all from backups
cp -r .claude/commands/backups/phase4_*/*.md .claude/commands/
```

**Partial Rollback:**
```bash
# Keep some refactorings, rollback others
git rebase -i [commit-before-phase-4]
# Mark unwanted commits as 'drop', keep others as 'pick'
```

### Rollback Decision Matrix

| Scenario | Rollback Type | Command |
|----------|---------------|---------|
| Single command broken | Individual file | `git checkout [hash] -- [file]` |
| Task validation failed | Revert commit | `git revert [commit]` |
| Multiple commands broken | Task group | `git reset --hard [task-start]` |
| Phase fundamentally flawed | Full phase | `git reset --hard [phase-start]` |

### Post-Rollback Actions

After any rollback:

1. **Diagnose root cause:** Why did refactoring fail?
2. **Document issue:** Add to lessons learned
3. **Adjust strategy:** Modify extraction approach if needed
4. **Re-attempt:** Try with improved approach or skip problematic section

## Success Criteria

### Overall Phase Success

- [ ] **LOC Reduction**: ≥50% reduction (target 53%)
- [ ] **Functionality**: All commands execute without errors
- [ ] **References**: 100% of references resolve correctly
- [ ] **Tests**: All validation tests pass
- [ ] **Workflows**: Representative workflows (orchestrate, implement, setup) functional

### Per-Command Success

For each refactored command:

- [ ] References resolve (validation test passes)
- [ ] Command invokes without error (`/[command] --help` works)
- [ ] Command-specific details preserved
- [ ] Functional test passes (if applicable)
- [ ] LOC reduced by target amount (within ±10%)
- [ ] Git commit created and clean

### Quality Criteria

- [ ] command-patterns.md remains navigable (table of contents, clear sections)
- [ ] No duplicate information between commands and patterns
- [ ] Reference links use consistent format
- [ ] Examples in patterns file are clear and illustrative
- [ ] Command-specific sections add value beyond patterns

### Documentation Criteria

- [ ] Lessons learned documented
- [ ] Implementation summary created
- [ ] Metrics accurate and complete
- [ ] Recommendations actionable for future phases

## Estimated Timeline

**Total Effort: ~60 hours (2 weeks at 30 hours/week)**

| Week | Tasks | Hours | Deliverables |
|------|-------|-------|--------------|
| **Week 1** | Tasks 1-7 | 30 | New patterns added, orchestrate.md refactored and validated |
| **Week 2** | Tasks 8-18 | 30 | implement.md refactored, setup.md optimized, secondary commands batch processed, phase complete |

### Daily Breakdown (Week 1)

| Day | Tasks | Hours | Focus |
|-----|-------|-------|-------|
| Mon | Tasks 1-3 | 6 | Preparation: Add patterns, backups, test suite |
| Tue | Task 4 | 4 | Refactor orchestrate.md agent sections |
| Wed | Tasks 5-6 | 8 | Refactor orchestrate.md artifacts and error recovery |
| Thu | Task 7 | 2 | Validate orchestrate.md |
| Fri | Tasks 8-9 (start) | 10 | Start implement.md refactoring |

### Daily Breakdown (Week 2)

| Day | Tasks | Hours | Focus |
|-----|-------|-------|-------|
| Mon | Tasks 9-10 | 8 | Complete implement.md refactoring |
| Tue | Tasks 11-12 | 6 | Consolidate and validate implement.md |
| Wed | Tasks 13-14 | 7 | Optimize and validate setup.md |
| Thu | Task 15 | 8 | Batch process secondary commands |
| Fri | Tasks 16-18 | 6 | Final validation, measurement, documentation |

## Conclusion

This specification provides a comprehensive, actionable plan for Phase 4: Command Documentation Extraction. The approach balances aggressive LOC reduction with maintaining clarity and functionality. The incremental, well-tested approach minimizes risk while delivering significant maintainability improvements.

**Key Takeaways:**

1. **Pattern extraction is most effective** for orchestrate.md and implement.md (multi-agent workflow commands)
2. **Internal optimization needed** for setup.md (unique, dense content)
3. **Batch processing works** for secondary commands (consistent pattern matching)
4. **Validation is critical** at every step (test suite prevents regressions)
5. **Incremental commits enable safe rollback** (granular recovery options)

**Next Steps:**

Upon completion of Phase 4, proceed to:
- **Phase 5**: Workflow Script Consolidation (`.claude/lib/` utilities)
- **Phase 6**: Test Suite Optimization
- **Phase 7**: Final Documentation and System Integration
