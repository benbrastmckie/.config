# Planning Subagent Architecture Analysis

## Executive Summary

Analysis of planning subagent architecture (plan-architect, lean-plan-architect) reveals that these agents do NOT have Task tool access and are designed to operate as terminal executors rather than coordinators. Unlike research coordinators, planning agents perform direct work (plan creation) using Read/Write/Edit tools. However, lean-plan-output.md shows the primary agent bypassed lean-plan-architect entirely and created the plan directly, indicating a different delegation failure mode than the research coordination issue.

## Findings

### Finding 1: Planning Agents Are NOT Coordinators

**Evidence from agent tool declarations**:

**lean-plan-architect.md** (line 2):
```yaml
allowed-tools: Read, Write, Edit, Grep, Glob, WebSearch, Bash
```

**plan-architect.md** (expected similar pattern based on architecture):
```yaml
allowed-tools: Read, Write, Edit, Grep, Glob, WebSearch, Bash
```

**Critical Observation**: Planning agents do NOT have Task tool access.

**Architectural Role**:
- **Coordinators**: Decompose tasks → delegate via Task → validate artifacts → return metadata
- **Planning Agents**: Read research → analyze requirements → write plan file directly → return completion signal

**Implication**: Planning agents are TERMINAL EXECUTORS, not coordinators. They should be invoked via Task but should NOT invoke further subagents.

### Finding 2: lean-plan Command Expects lean-plan-architect Invocation

**Evidence from `/home/benjamin/.config/.claude/commands/lean-plan.md`**:

**Grep search** for "lean-plan-architect" found (line 1874+):
```
**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-architect agent.
```

**Expected Delegation Flow**:
1. lean-plan command (primary agent) completes research phase
2. lean-plan invokes lean-plan-architect via Task
3. lean-plan-architect reads research reports
4. lean-plan-architect creates implementation plan file
5. lean-plan-architect returns: `PLAN_CREATED: /path/to/plan.md`
6. lean-plan validates plan file exists and completes workflow

**Actual Behavior** (from lean-plan-output.md):
- No "lean-plan-architect" string found in output
- No Task invocation block for planning phase
- Lines 162-185: Primary agent Write plan file directly

**Delegation Failure**: lean-plan skipped lean-plan-architect invocation and created plan itself.

### Finding 3: Planning Agent Design Differs from Coordinator Pattern

**From `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` lines 15-100**:

**Execution Process**:
- STEP 1: Analyze Formalization Requirements (Read research reports, standards)
- STEP 2: Create Plan Structure (Generate phases, estimate complexity)
- STEP 3: Write Plan File (Use Write tool at provided absolute path)
- STEP 4: Verify Plan File Exists (Validate artifact created)
- STEP 5: Return Completion Signal (`PLAN_CREATED: /path`)

**Key Characteristics**:
- No Task invocations in agent logic
- Direct file I/O operations (Read research, Write plan)
- Single-file output artifact (plan.md)
- Simpler validation (file exists check)

**Contrast with Coordinator Pattern**:
- Coordinators generate MULTIPLE artifacts via specialist delegation
- Coordinators validate MULTIPLE report files (hard barrier)
- Coordinators aggregate metadata from multiple sources
- Planning agents generate ONE artifact directly

### Finding 4: Planning Agent Input Contract Requirements

**From lean-plan-architect.md lines 70-78**:

**Inputs Planning Agent MUST Receive**:
- User formalization description (theorem proving goal)
- **Lean research report paths** (from research phase)
- CLAUDE.md standards file path
- Lean project path and structure
- Lean style guide content (if provided)

**Critical Dependency**: Planning agent assumes research reports ALREADY EXIST.

**Hard Barrier Pattern** (for commands invoking planning agents):
1. Command completes research phase FIRST
2. Command validates research reports exist
3. Command invokes planning agent with report paths
4. Planning agent reads reports (expects files to exist)

**Implication**: Planning agent delegation CANNOT occur if research phase was skipped or failed.

### Finding 5: lean-plan Output Shows Integrated Research-and-Plan

**From lean-plan-output.md**:

**Lines 11-138**: Research phase
- Primary agent reads existing files
- Primary agent performs WebSearch (10+ queries)
- Primary agent fetches external resources
- **Lines 139-146**: Primary agent Write research report (001-alternative-proof-strategies.md)

**Lines 162-185**: Planning phase
- **No Task invocation**
- Primary agent Write implementation plan directly (001-modal-theorems-alternative-proofs-plan.md)
- Plan metadata includes research report reference (lines 183-184)

**Observation**: Primary agent performed BOTH research AND planning without delegation to either research-coordinator or lean-plan-architect.

**Consequence**: All specialized logic in lean-plan-architect.md was bypassed:
- Theorem dependency analysis (lines 95-100)
- Wave structure generation (lines 84-85)
- Lean-specific phase metadata (lines 27-61)
- Phase routing summary table (lines 48-59)

### Finding 6: Potential Quality Issues from Bypassing Planning Agent

**lean-plan-architect.md Critical Features** (lines 27-61):

**Phase Metadata Requirements**:
```markdown
### Phase N: Phase Name [NOT STARTED]
implementer: lean                    # REQUIRED: "lean" or "software"
lean_file: /absolute/path/file.lean  # REQUIRED for lean phases
dependencies: []                      # REQUIRED: array of prerequisite phase numbers
```

**Parser Enforcement**: "/lean-implement will FAIL if fields are out of order"

**Field Order**:
1. `implementer:` - First field after heading
2. `lean_file:` - Second field (only for lean phases)
3. `dependencies:` - Third field (always required)

**Phase Routing Summary Table** (lines 48-59): Required immediately after "## Implementation Phases"

**Risk**: If primary agent created plan without following lean-plan-architect specifications:
- Phase metadata may be missing or incorrectly formatted
- /lean-implement may fail when parsing plan
- Dependency analysis may be incomplete
- Wave-based parallelization may not work

**Validation Needed**: Check if lean-plan-output.md plan (001-modal-theorems-alternative-proofs-plan.md) contains required metadata.

### Finding 7: Delegation Skip Pattern Consistent Across Agents

**Pattern Observed**:
- lean-plan expected to invoke research-coordinator → SKIPPED
- lean-plan expected to invoke lean-plan-architect → SKIPPED
- Primary agent performed all work directly

**Common Factor**: Both delegations use Task tool invocation blocks in command file.

**Hypothesis**: The directive "**EXECUTE NOW**: USE the Task tool..." is not triggering Task invocations.

**Possible Causes**:
1. **Interpretation Issue**: Agent interprets Task blocks as documentation/examples
2. **Tool Availability**: Task tool not available during command execution
3. **Optimization Decision**: Agent chooses direct execution over delegation
4. **Directive Format**: Task blocks require different formatting to trigger

### Finding 8: No Self-Validation in lean-plan Command

**Evidence**: Searching lean-plan.md for validation checkpoints after delegation blocks.

**Block 1e-validate** (lines 1047-1179): Validates research-coordinator OUTPUT
- Checks if reports exist
- Counts expected vs actual reports
- Logs errors if coordinator failed

**Missing Validation**: No check BEFORE validation block confirming Task invocation occurred.

**Gap**: Command assumes Task invocation happened but has no checkpoint verifying:
```bash
# MISSING CHECKPOINT (should appear after Block 1e-exec)
if [ ! -f "$REPORT_DIR/.invocation-trace.log" ]; then
  echo "ERROR: research-coordinator Task did not execute"
  echo "Trace file missing - delegation was skipped"
  exit 1
fi
```

**Consequence**: If Task invocation silently fails, command proceeds to validation, finds no reports, and returns generic error without identifying root cause (delegation skip).

## Recommendations

### 1. Validate lean-plan-Output Plan Quality

**Priority**: HIGH

**Action**: Read the plan file created in lean-plan-output.md and verify:
- Phase metadata fields present and correctly ordered
- Phase routing summary table present
- Dependency arrays use correct format
- Lean file paths are absolute

**File**: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/060_modal_theorems_alternative_proofs/plans/001-modal-theorems-alternative-proofs-plan.md`

**Validation Script**:
```bash
# Check for required phase metadata
grep -E "^implementer:" plan.md
grep -E "^lean_file:" plan.md
grep -E "^dependencies:" plan.md

# Check for phase routing table
grep -A 5 "Phase Routing Summary" plan.md
```

### 2. Add Planning Agent Invocation Checkpoint

**Action**: Enhance lean-plan.md with explicit validation after planning Task block.

**Pattern** (insert after Block 2a-exec):
```bash
# Checkpoint: Verify lean-plan-architect invocation
PLAN_FILE="${PLAN_DIR}/001-${TOPIC_SLUG}-plan.md"
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: lean-plan-architect Task invocation did not execute"
  echo "Plan file missing: $PLAN_FILE"
  echo "Root cause: Task tool invocation was skipped or failed"
  exit 1
fi

# Validate plan metadata
if ! grep -q "^implementer:" "$PLAN_FILE"; then
  echo "WARNING: Plan missing required 'implementer:' metadata"
  echo "lean-plan-architect may have been bypassed"
fi
```

### 3. Test Task Tool Directive Recognition

**Priority**: CRITICAL

**Action**: Create minimal test case to isolate Task directive execution.

**Test Script** (`test-task-directive.md`):
```markdown
# Test Task Directive Recognition

**EXECUTE NOW**: USE the Task tool to invoke test specialist.

Task {
  subagent_type: "general-purpose"
  description: "Test task delegation"
  prompt: "
    Echo test message:
    This is a test Task invocation.

    Return: TASK_COMPLETE: test successful
  "
}
```

**Execution**: Run test script and verify:
- Does Task block execute?
- Is subprocess created?
- Is output captured?

**Expected Outcome**: If Task executes → directive format is correct, issue is elsewhere.
If Task skipped → directive format may need adjustment OR Task tool has constraints.

### 4. Investigate Alternative Directive Formats

**If Task directives are not executing**, test alternative formats:

**Format A: Explicit tool invocation marker**
```yaml
!!! TASK_INVOCATION !!!
Task {
  ...
}
```

**Format B: Structured frontmatter**
```yaml
---
action: invoke-task
agent: lean-plan-architect
---
```

**Format C: Imperative instruction**
```
You MUST now invoke the Task tool with the following configuration:
[Task block]
```

### 5. Consider Inline Planning Logic for Reliability

**If Task delegation remains unreliable**:

**Option**: Move critical planning logic into command file inline.

**Pattern**:
```bash
# In lean-plan.md Block 2a
# Instead of: Task { invoke lean-plan-architect }
# Use: Inline planning logic

echo "Creating implementation plan..."

# Generate plan metadata
cat > "$PLAN_FILE" <<EOF
# Lean Implementation Plan: ${FEATURE_NAME}

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Feature**: ${FEATURE_DESCRIPTION}
- **Status**: [NOT STARTED]
...

## Implementation Phases

### Phase Routing Summary
| Phase | Type | Implementer Agent |
|-------|------|-------------------|
$(generate_phase_routing_table)

EOF
```

**Tradeoff**: Less modular but more reliable if Task delegation is unstable.

### 6. Document Planning Agent Invocation Requirements

**Action**: Create invocation guide for planning agents.

**Content**:
- Input contract (required parameters)
- Output contract (completion signal format)
- Hard barrier dependencies (research reports must exist FIRST)
- Validation procedures (plan metadata verification)
- Error handling (what to do if planning fails)

**Location**: `/home/benjamin/.config/.claude/docs/guides/agents/planning-agent-invocation-guide.md`

### 7. Implement Graceful Degradation Pattern

**Action**: Add fallback logic to commands when delegation fails.

**Pattern** (in lean-plan.md after Block 2a):
```bash
# Attempt planning agent delegation
# EXECUTE NOW: USE Task tool...
Task { invoke lean-plan-architect }

# Fallback: Verify plan was created
if [ ! -f "$PLAN_FILE" ]; then
  echo "WARNING: lean-plan-architect delegation failed"
  echo "Falling back to inline plan creation"

  # Generate basic plan inline
  create_basic_plan "$PLAN_FILE" "$FEATURE_DESCRIPTION" "$RESEARCH_DIR"
fi
```

**Benefit**: Workflow completes even if delegation fails, but logs degradation.

## Conclusion

Planning subagent architecture differs from coordinator architecture:
- **Planning agents**: Terminal executors with Read/Write tools, create single artifact (plan file)
- **Coordinator agents**: Orchestrators with Task tool, delegate to multiple specialists, aggregate metadata

lean-plan-output.md shows BOTH delegation types were skipped:
1. Research phase: Should invoke research-coordinator → Skipped (primary agent researched directly)
2. Planning phase: Should invoke lean-plan-architect → Skipped (primary agent planned directly)

**Root Cause**: Common factor is Task tool invocation blocks not executing.

**Quality Risk**: Bypassing lean-plan-architect means specialized logic was skipped:
- Phase metadata formatting (required by /lean-implement parser)
- Theorem dependency analysis
- Wave structure generation
- Phase routing table

**Recommended Action**:
1. Validate quality of plan created without lean-plan-architect delegation
2. Add delegation checkpoints to detect invocation failures early
3. Test Task directive recognition in isolation
4. Document known limitations and workarounds
5. Consider inline fallback logic for critical planning features
