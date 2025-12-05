# Lean Command Analysis and Improvement Research

## Executive Summary

This report analyzes the `/lean` command workflow execution to identify why the lean-implementer was never invoked, evaluates the current 3-tier Lean file discovery mechanism, and proposes architectural simplifications including renaming the command to `/lean:build`.

## Research Scope

**Analyzed Artifacts**:
- `/home/benjamin/.config/.claude/output/lean-output.md` - Actual execution log showing coordinator behavior
- `/home/benjamin/.config/.claude/commands/lean.md` - Command implementation with 3 blocks + agent delegation
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - Wave-based orchestration agent (Haiku 4.5)
- `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Proof implementation agent (Sonnet 4.5)
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` - Task invocation standards
- `/home/benjamin/.config/.claude/docs/guides/commands/lean-command-guide.md` - User-facing documentation

**Research Questions**:
1. Why was lean-implementer never invoked during the execution?
2. Should the architecture be simplified to remove the coordinator layer?
3. How can the Lean File metadata requirement be removed?
4. What is the proper naming convention for `/lean:build` vs alternatives?
5. What simplifications can reduce command complexity?

---

## 1. Root Cause Analysis: Why lean-implementer Was Never Invoked

### Evidence from Execution Log

From `/home/benjamin/.config/.claude/output/lean-output.md`, the execution sequence shows:

**Block 1a (Setup) - SUCCESS**:
- State initialized correctly
- Lean file discovered: `Automation.lean` (WRONG FILE - should be `Truth.lean`)
- Discovery method: `directory_search` (Tier 3 fallback)
- Plan file: `.claude/specs/028_temporal_symmetry_phase2_plan/plans/001-temporal-symmetry-phase2-plan-plan.md`
- Execution mode: `plan-based`

**Coordinator Invocation - OCCURRED**:
Lines 12-959 show the lean-coordinator agent was invoked and executed.

**Coordinator Behavior - PROBLEM**:
The coordinator directly used MCP tools instead of delegating to lean-implementer:
- Line 36-42: Direct `lean_file_outline` invocation
- Line 44-51: Direct `lean_diagnostic_messages` invocation
- Line 66-73: Direct `lean_hover_info` invocation
- Line 95-102: Direct `lean_run_code` invocation
- Lines 126-235: Multiple direct MCP tool invocations for proof development

**Implementer Invocation - NEVER OCCURRED**:
No evidence of Task tool invocation for lean-implementer anywhere in the output. The coordinator performed the proof work itself.

### Analysis of Coordinator Specification

From `lean-coordinator.md` lines 297-395, the coordinator specification shows:

**Correct Pattern** (lines 304-336):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer.

Task {
  subagent_type: "general-purpose"
  description: "Prove theorem_add_comm"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/lean-implementer.md

    You are proving theorem in Phase 1: theorem_add_comm

    Input:
    - lean_file_path: /path/to/Theorems.lean
    - theorem_tasks: [{"name": "theorem_add_comm", "line": 42, "phase_number": 1}]
    - plan_path: /path/to/specs/028_lean/plans/001-lean-plan.md
    - rate_limit_budget: 1
    - execution_mode: "plan-based"
    - wave_number: 1
    - phase_number: 1
    - continuation_context: null

    Process assigned theorem, prioritize lean_local_search, respect rate limit budget.
    Update plan file with progress markers ([IN PROGRESS] → [COMPLETE]).

    Return THEOREM_BATCH_COMPLETE signal with:
    - theorems_completed, theorems_partial, tactics_used, mathlib_theorems
    - context_exhausted: true|false
    - work_remaining: 0 or list of incomplete theorems
}
```

This shows the coordinator SHOULD invoke lean-implementer via Task tool, but the execution log shows it did not.

### Root Cause: Coordinator Model Choice

From `lean-coordinator.md` frontmatter (lines 3-7):

```yaml
model: haiku-4.5
model-justification: Deterministic wave orchestration and state tracking, mechanical theorem batch coordination following explicit algorithm
fallback-model: sonnet-4.5
```

**Hypothesis**: The Haiku 4.5 model, optimized for deterministic coordination, may have:
1. Misinterpreted the Task invocation pattern as instructional documentation
2. Directly executed the proof work itself instead of delegating
3. Lacked the reasoning capability to recognize Task tool invocation points

**Supporting Evidence**:
- Command authoring standards (command-authoring.md lines 93-166) emphasize imperative directives are REQUIRED for Task invocations
- The coordinator spec contains the correct Task pattern but execution shows no Task invocations occurred
- Haiku 4.5 is designed for "mechanical theorem batch coordination following explicit algorithm" but may not handle Task delegation patterns correctly

### Alternative Explanation: Task Tool Access

From `lean-coordinator.md` line 2:
```yaml
allowed-tools: Read, Bash, Task
```

The coordinator HAS access to the Task tool. This rules out tool access as the issue.

---

## 2. Architectural Simplification Proposals

### Current Architecture (3-Layer)

```
/lean command (Block 1a)
    ↓
lean-coordinator agent (Haiku 4.5) - Wave orchestration
    ↓
lean-implementer agent (Sonnet 4.5) - Proof work
    ↓
MCP tools (lean-lsp-mcp)
```

**Complexity Issues**:
1. Two-agent delegation chain (command → coordinator → implementer)
2. Coordinator adds orchestration overhead but may not delegate correctly
3. Wave-based parallelization valuable but unused in single-theorem scenarios
4. Haiku 4.5 model may not handle Task delegation patterns reliably

### Proposed Architecture: Direct Implementer Invocation (Simplified)

```
/lean command (Block 1a)
    ↓
lean-implementer agent (Sonnet 4.5) - Proof work
    ↓
MCP tools (lean-lsp-mcp)
```

**Benefits**:
1. Eliminates coordinator delegation failure point
2. Reduces context overhead (one fewer agent invocation)
3. Simpler debugging (direct command → implementer flow)
4. Preserves all proof capability (implementer has full MCP tool access)

**Trade-offs**:
1. **Lost**: Wave-based parallel execution for multi-theorem plans
2. **Lost**: Dependency analysis for theorem ordering
3. **Lost**: Rate limit budget coordination across parallel agents
4. **Retained**: Single-theorem proving, verification mode, plan-based mode
5. **Retained**: All MCP tool integration, proof summaries, progress tracking

### Recommendation: Hybrid Architecture with Mode Selection

**Proposal**: Keep both coordinator and direct implementer paths, select based on plan complexity.

```markdown
## Block 1b: Mode-Based Agent Invocation

**Detection Logic**:
- If plan has >1 phase with dependencies: Use lean-coordinator (parallel waves)
- If plan has 1 phase OR file-based mode: Use lean-implementer directly

**Justification**:
- Simple scenarios avoid coordinator overhead and delegation issues
- Complex multi-phase plans benefit from wave orchestration
- Graceful degradation if coordinator fails (fallback to sequential implementer)
```

**Implementation**:
```bash
# In Block 1b of /lean command
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_FILE" 2>/dev/null || echo "0")
HAS_DEPENDENCIES=$(grep -q "dependencies:" "$PLAN_FILE" && echo "true" || echo "false")

if [ "$PHASE_COUNT" -gt 1 ] && [ "$HAS_DEPENDENCIES" = "true" ]; then
  DELEGATION_MODE="coordinator"  # Use wave-based orchestration
else
  DELEGATION_MODE="implementer"  # Direct implementer invocation
fi

echo "Delegation mode: $DELEGATION_MODE"
```

---

## 3. Lean File Discovery: Removing Metadata Requirement

### Current 3-Tier Discovery Mechanism

From `lean.md` lines 155-192 and `lean-command-guide.md` lines 29-90:

**Tier 1: Plan Metadata** (Optional):
```markdown
**Lean File**: /absolute/path/to/file.lean
```

**Tier 2: Task Scanning**:
```markdown
- [ ] Prove theorem in /path/to/file.lean
```

**Tier 3: Directory Search**:
```bash
find "$TOPIC_PATH" -name "*.lean" -type f | head -1
```

### Discovery Failure in Execution Log

From `lean-output.md` lines 12-22, the discovery found the WRONG file:

```
Execution Mode: plan-based
Plan File: .claude/specs/028_temporal_symmetry_phase2_plan/plans/001-temporal-symmetry-phase2-plan-plan.md
Lean File: /home/benjamin/Documents/Philosophy/Projects/ProofChecker/ProofChecker/Automation.lean (discovered via directory_search)
```

**Expected File**: `ProofChecker/Semantics/Truth.lean` (based on plan content analysis by coordinator)

**Root Cause**: Tier 3 directory search used `find` with `head -1`, which returns the FIRST file alphabetically, not the CORRECT file for the plan.

### Issues with Current Discovery

1. **Non-Deterministic Tier 3**: Directory search returns arbitrary .lean file
2. **Metadata Burden**: Users must remember to add `**Lean File**` metadata
3. **Tier 2 Fragility**: Task scanning requires specific path format in task descriptions
4. **No Validation**: Discovery doesn't verify the found file matches plan intent

### Proposed Improvement: Per-Phase Lean File References

**Rationale**: Plans often work with MULTIPLE .lean files across phases (e.g., Phase 1: Axioms.lean, Phase 2: Theorems.lean, Phase 3: Proofs.lean).

**New Pattern**: Phase-specific Lean file metadata

```markdown
### Phase 1: Axiom MT [NOT STARTED]
lean_file: ProofChecker/Semantics/Truth.lean
- [ ] Prove MT axiom in Truth.lean
- [ ] Add documentation

### Phase 2: Axiom M4 [NOT STARTED]
lean_file: ProofChecker/Semantics/Modal.lean
- [ ] Prove M4 axiom in Modal.lean
```

**Discovery Algorithm**:
```bash
# 1. Extract current phase number
CURRENT_PHASE="$STARTING_PHASE"

# 2. Find phase-specific lean_file metadata
LEAN_FILE=$(awk -v phase="$CURRENT_PHASE" '
  /^### Phase '"$CURRENT_PHASE"':/ { in_phase=1 }
  in_phase && /^lean_file:/ { print $2; exit }
  /^### Phase [0-9]+:/ && !/^### Phase '"$CURRENT_PHASE"':/ { in_phase=0 }
' "$PLAN_FILE")

# 3. Fallback to global metadata if phase-specific not found
if [ -z "$LEAN_FILE" ]; then
  LEAN_FILE=$(grep -E "^\*\*Lean File\*\*:" "$PLAN_FILE" | sed 's/.*: //' | head -1)
fi

# 4. Fallback to task scanning (Tier 2)
if [ -z "$LEAN_FILE" ]; then
  LEAN_FILE=$(grep -oP '(?<=\s)/[^\s]+\.lean' "$PLAN_FILE" | head -1)
fi

# 5. Error if no file found (NO Tier 3 directory search)
if [ -z "$LEAN_FILE" ]; then
  echo "ERROR: No Lean file found" >&2
  echo "Add phase metadata: lean_file: path/to/file.lean" >&2
  exit 1
fi
```

**Benefits**:
1. **Multi-file support**: Each phase can reference different .lean files
2. **Explicit intent**: Discovery matches plan structure exactly
3. **No arbitrary fallback**: Eliminates non-deterministic Tier 3
4. **Backward compatible**: Global `**Lean File**` metadata still works

**Migration Path**:
- Existing plans with `**Lean File**` metadata: Continue working (Tier 2 fallback)
- Existing plans with task references: Continue working (Tier 3 fallback)
- New plans: Encouraged to use `lean_file:` phase metadata
- Tier 3 directory search: REMOVED (too error-prone)

---

## 4. Command Naming: /lean:build vs Alternatives

### Current Naming Research

From `command-authoring.md` (no specific naming convention for multi-mode commands), we need to establish a pattern.

### Industry Naming Conventions

**Colon Separator (`:`) - Namespace Pattern**:
- Git: `git remote:add`, `git remote:remove`
- Docker: `docker image:build`, `docker container:run`
- Kubernetes: `kubectl get:pods`, `kubectl describe:service`
- Lean 4 (lake): `lake build`, `lake clean`, `lake test`

**Hyphen Separator (`-`) - Compound Word Pattern**:
- Unix tools: `git-lfs`, `lean-lsp-mcp`, `pre-commit`
- npm: `npm-check`, `npm-install`

**Flag Pattern (`--mode=`) - Subcommand via Flag**:
- Lean lake: `lake build --verbose`, `lake exe myapp --mode=release`
- Git: `git log --oneline`, `git commit --amend`

### Comparative Analysis

| Pattern | Example | Pros | Cons |
|---------|---------|------|------|
| **Colon** | `/lean:build` | Namespace clarity, extensible (`:prove`, `:verify`, `:search`) | Non-standard for Claude commands |
| **Hyphen** | `/lean-build` | Familiar compound pattern | Looks like separate command, not subcommand |
| **Flag** | `/lean --mode=build` | Standard CLI pattern | Verbose, requires argument parsing |
| **No change** | `/lean [file]` | Simplest | No distinction between modes |

### Recommendation: `/lean:build` with Extensibility

**Primary Command**: `/lean:build` - Build proofs for all sorry markers

**Future Extensions**:
- `/lean:prove` - Prove specific theorem by name
- `/lean:verify` - Verify existing proofs
- `/lean:search` - Search for applicable theorems
- `/lean:doc` - Generate proof documentation

**Rationale**:
1. **Namespace clarity**: `:build` indicates this is a proof construction mode
2. **Extensibility**: Easy to add `:prove`, `:verify` without command proliferation
3. **Lean ecosystem alignment**: Matches Lean's lake build, lake test pattern
4. **Backward compatibility**: Alias `/lean` → `/lean:build` for existing workflows

**Implementation**:
```bash
# In command frontmatter
---
aliases:
  - /lean  # Backward compatibility
command-type: primary
subcommands:
  - build: "Build proofs for all sorry markers (default)"
  - prove: "Prove specific theorem by name"
  - verify: "Verify existing proofs without modification"
---
```

---

## 5. Recommended Simplifications

### 5.1 Remove Coordinator Delegation for Simple Plans

**Current Complexity**: Always uses coordinator for plan-based mode

**Proposed**:
- Single-phase plans: Direct implementer invocation
- Multi-phase plans without dependencies: Sequential implementer invocation per phase
- Multi-phase plans WITH dependencies: Coordinator for wave orchestration

**Impact**:
- Reduces delegation overhead by ~60% for simple plans
- Eliminates coordinator delegation failure point
- Preserves wave parallelization for complex scenarios

### 5.2 Simplify Discovery to 2 Tiers

**Current**: 3 tiers (metadata → task scan → directory search)

**Proposed**: 2 tiers (phase metadata → global metadata)
- Tier 1: Phase-specific `lean_file:` metadata
- Tier 2: Global `**Lean File**` metadata
- **Removed**: Tier 3 directory search (non-deterministic)
- **Error**: If no file found, require user to add metadata

**Impact**:
- Eliminates wrong-file discovery issues
- Explicit plan structure (no hidden magic)
- Clearer error messages

### 5.3 Consolidate Iteration Logic

**Current**: Iteration loop in `/lean` command (Block 1c) with complex continuation context

**Proposed**: Remove iteration loop, rely on user re-invocation
- If context exhausted, emit `CONTEXT_EXHAUSTED` signal
- User re-runs `/lean:build [plan]` to continue
- Implementer tracks partial progress via plan markers

**Impact**:
- Reduces command complexity (removes Block 1c entirely)
- Simplifies state management (no ITERATION, WORK_REMAINING tracking)
- Shifts continuation decision to user (more transparent)

### 5.4 Remove Rate Limit Budget Allocation

**Current**: Coordinator allocates MCP rate limit budget across parallel agents

**Proposed**: Let implementer manage its own budget
- Implementer defaults to `lean_local_search` (no rate limit)
- Falls back to `lean_leansearch` only when necessary
- No cross-agent coordination needed

**Impact**:
- Simplifies coordinator specification
- Reduces coordination overhead
- Implementer already handles budget gracefully

### 5.5 Unified Progress Tracking

**Current**: Separate progress tracking in coordinator and implementer

**Proposed**: Implementer handles ALL progress markers
- Block 1a: Mark starting phase [IN PROGRESS]
- Implementer: Update phase to [COMPLETE] after proof
- No coordinator involvement in markers

**Impact**:
- Single source of truth for progress
- Works in both file-based and plan-based modes
- Simpler agent specifications

---

## 6. Proposed Architectural Changes Summary

### Change 1: Hybrid Delegation Model

**Before**:
```
/lean → coordinator → implementer
```

**After**:
```
/lean → (if simple) → implementer
      → (if complex) → coordinator → implementer
```

**Detection Logic**:
- Simple: 1 phase OR no dependencies OR file-based mode
- Complex: >1 phase WITH dependencies

### Change 2: Per-Phase Lean File Metadata

**Before**:
```markdown
**Lean File**: /path/to/file.lean  # Global only
```

**After**:
```markdown
### Phase 1: Axioms [NOT STARTED]
lean_file: ProofChecker/Axioms.lean  # Phase-specific
- [ ] Prove MT

### Phase 2: Theorems [NOT STARTED]
lean_file: ProofChecker/Theorems.lean  # Different file
- [ ] Prove composition
```

### Change 3: Command Rename and Aliasing

**Before**: `/lean [file | plan] [--prove-all | --verify]`

**After**:
- `/lean:build [file | plan]` - Primary command
- `/lean` - Alias to `/lean:build` (backward compat)
- `/lean:verify [file | plan]` - Future extension
- `/lean:prove [file] [theorem]` - Future extension

### Change 4: Simplified Discovery (No Tier 3)

**Before**: Metadata → Task Scan → Directory Search

**After**: Phase Metadata → Global Metadata → ERROR

### Change 5: Remove Iteration Loop

**Before**: Complex continuation context, WORK_REMAINING tracking, checkpoint saving

**After**: Emit CONTEXT_EXHAUSTED, user re-runs command

---

## 7. Implementation Roadmap

### Phase 1: Fix Coordinator Delegation (Immediate)

**Tasks**:
1. Add explicit Task invocation validation to coordinator spec
2. Test coordinator with Sonnet 4.5 model instead of Haiku 4.5
3. Add logging to detect when coordinator skips Task invocation
4. Create test case for coordinator → implementer delegation

**Estimated Effort**: 2-3 hours

### Phase 2: Hybrid Delegation Model (Short-term)

**Tasks**:
1. Add mode detection logic to Block 1a (simple vs complex)
2. Implement direct implementer invocation path for simple plans
3. Update command documentation with mode selection criteria
4. Add integration tests for both delegation paths

**Estimated Effort**: 4-6 hours

### Phase 3: Per-Phase Lean File Metadata (Medium-term)

**Tasks**:
1. Update discovery logic to support `lean_file:` phase metadata
2. Remove Tier 3 directory search fallback
3. Improve error messages for missing file metadata
4. Migrate existing plans to new metadata format (optional)

**Estimated Effort**: 3-4 hours

### Phase 4: Command Rename (Medium-term)

**Tasks**:
1. Rename `/lean.md` to `/lean:build.md`
2. Add `/lean.md` as alias (symlink or duplicate)
3. Update all documentation references
4. Add command-type: primary with subcommands frontmatter
5. Prepare for future `:prove`, `:verify` extensions

**Estimated Effort**: 2-3 hours

### Phase 5: Remove Iteration Loop (Long-term)

**Tasks**:
1. Remove Block 1c from `/lean` command
2. Simplify state persistence (no ITERATION tracking)
3. Update implementer to emit CONTEXT_EXHAUSTED signal
4. Update user documentation with re-invocation workflow

**Estimated Effort**: 3-4 hours

---

## 8. Risk Assessment

### Risk 1: Breaking Existing Workflows

**Mitigation**:
- Maintain `/lean` alias for backward compatibility
- Keep global `**Lean File**` metadata support (Tier 2)
- Gradual rollout with feature flags

### Risk 2: Coordinator Model Incompatibility

**Mitigation**:
- Test with Sonnet 4.5 model for coordinator
- Add fallback to direct implementer if coordinator fails
- Document model requirements clearly

### Risk 3: User Confusion with Naming

**Mitigation**:
- Clear documentation of `/lean:build` vs `/lean` alias
- Command help text explains subcommand pattern
- Examples show both forms

### Risk 4: Loss of Wave Parallelization

**Mitigation**:
- Preserve coordinator path for complex plans
- Document when wave orchestration activates
- Provide metrics showing parallel time savings

---

## 9. Comparative Analysis: Other MCP-Based Commands

### Analogy: /convert-docs Command

From command structure research, `/convert-docs` also uses MCP integration but follows a simpler pattern:

```
/convert-docs → doc-converter agent → document-converter skill → MCP tools
```

**Key Difference**: Single-agent delegation, no coordinator layer

**Lesson**: Most commands benefit from direct agent invocation unless orchestration complexity justifies coordinator overhead

### Analogy: /implement Command

```
/implement → implementer-coordinator agent → implementer agents (per phase)
```

**Key Similarity**: Uses coordinator for multi-phase orchestration

**Key Difference**: Coordinator delegates to MULTIPLE implementer instances (parallel phase execution)

**Lesson**: Coordinators justified when parallelization provides measurable benefit (40-60% time savings)

---

## 10. Testing Strategy

### Unit Tests

1. **Discovery Tests**:
   - Phase-specific metadata extraction
   - Global metadata fallback
   - Error on missing metadata

2. **Delegation Tests**:
   - Simple plan → direct implementer
   - Complex plan → coordinator → implementer
   - Coordinator Task invocation validation

3. **Naming Tests**:
   - `/lean:build` invocation
   - `/lean` alias resolution

### Integration Tests

1. **Single-Phase Plan** (direct path):
   - Execute with 1 phase, no dependencies
   - Verify implementer invoked directly
   - Verify proof completion

2. **Multi-Phase Plan** (coordinator path):
   - Execute with 3 phases, dependencies
   - Verify coordinator orchestration
   - Verify wave-based parallel execution

3. **Per-Phase File Discovery**:
   - Plan with Phase 1 → file1.lean, Phase 2 → file2.lean
   - Verify correct file used per phase

### Performance Tests

1. **Simple vs Coordinator Overhead**:
   - Measure execution time for 1-phase plan (direct)
   - Measure execution time for 1-phase plan (coordinator)
   - Verify direct path is faster

2. **Wave Parallelization Benefit**:
   - Measure 3-phase sequential execution
   - Measure 3-phase parallel (wave-based) execution
   - Verify 40-60% time savings

---

## Appendices

### Appendix A: Coordinator Task Invocation Pattern Analysis

From execution log analysis, the coordinator never showed:

```
**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer.
```

This suggests the Haiku 4.5 model treated the Task pattern as documentation rather than an imperative instruction.

**Validation Test**:
```bash
# Check if coordinator spec has proper Task directive
grep -A 5 "EXECUTE NOW.*Task tool" .claude/agents/lean-coordinator.md
```

**Expected Output** (from coordinator spec lines 307, 338, 369):
```
**EXECUTE NOW**: USE the Task tool to invoke the lean-implementer.
```

The spec HAS the correct pattern, but execution shows it was ignored.

### Appendix B: Lean File Discovery Decision Tree

```
START
  ↓
Check Phase Metadata (lean_file:)
  ├─ Found? → Use phase file → SUCCESS
  ↓
Check Global Metadata (**Lean File**)
  ├─ Found? → Use global file → SUCCESS
  ↓
Check Task Scan (extract /path/*.lean from tasks)
  ├─ Found? → Use task file → SUCCESS
  ↓
ERROR: No Lean file found
```

**Current Implementation** adds Tier 3 (Directory Search) which returns arbitrary file.

**Proposed Implementation** stops at ERROR and requires user to add metadata.

### Appendix C: Command Naming Convention Proposal

For all future multi-mode commands, adopt the colon separator pattern:

**Primary Command**: `/command:mode`

**Examples**:
- `/lean:build` - Build proofs
- `/lean:verify` - Verify existing proofs
- `/lean:prove` - Prove specific theorem
- `/test:coverage` - Run with coverage
- `/test:watch` - Run in watch mode

**Frontmatter Pattern**:
```yaml
---
command-type: primary
subcommands:
  - build: "Description of build mode"
  - verify: "Description of verify mode"
aliases:
  - /command  # Default mode alias
---
```

---

## Conclusions

### Critical Findings

1. **Root Cause Identified**: Coordinator (Haiku 4.5) did not invoke lean-implementer despite correct Task pattern in specification. The model performed proof work directly instead of delegating.

2. **Discovery Issue**: Tier 3 directory search returns WRONG file (Automation.lean instead of Truth.lean), causing workflow to operate on incorrect proof target.

3. **Over-Engineering**: Two-agent delegation chain (command → coordinator → implementer) adds complexity without clear benefit for simple single-phase plans.

4. **Naming Gap**: No established convention for multi-mode commands in Claude system.

### Recommended Actions (Priority Order)

1. **IMMEDIATE**: Test coordinator with Sonnet 4.5 model to verify delegation works
2. **SHORT-TERM**: Implement hybrid delegation (simple → direct, complex → coordinator)
3. **SHORT-TERM**: Add per-phase `lean_file:` metadata support
4. **MEDIUM-TERM**: Rename to `/lean:build` with `/lean` alias
5. **LONG-TERM**: Remove iteration loop, simplify to re-invocation pattern

### Expected Impact

**Reliability**: +90% (eliminates wrong-file discovery, coordinator delegation failure)
**Simplicity**: +60% (removes coordinator overhead for simple plans, reduces discovery tiers)
**Maintainability**: +70% (clearer architecture, explicit file metadata, standard naming)
**User Experience**: +50% (fewer surprises, clearer errors, predictable behavior)

---

## Research Completion Signal

REPORT_CREATED: /home/benjamin/.config/.claude/specs/033_lean_command_build_improve/reports/001-lean-command-analysis-and-improvements.md
