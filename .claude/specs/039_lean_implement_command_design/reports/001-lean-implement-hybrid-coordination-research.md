# Lean-Implement Hybrid Coordination Research Report

## Executive Summary

This report analyzes the existing /lean-build and /implement commands to design a unified /lean-implement command that intelligently routes phases to appropriate coordinators (lean-coordinator or implementer-coordinator) based on task type. The design leverages existing architectural patterns while introducing phase-type detection and hybrid orchestration capabilities.

## Research Findings

### 1. /lean-build Command Analysis

**File**: `/home/benjamin/.config/.claude/commands/lean-build.md`

#### Architecture Overview

The /lean-build command follows a **4-block orchestration pattern**:

1. **Block 1a**: Setup & State Initialization
   - Captures arguments via temp file pattern
   - Detects project directory (git-based or .claude/ marker)
   - Sources three-tier library pattern (error-handling, state-persistence, workflow-state-machine)
   - Validates Lean project (lakefile.toml/lakefile.lean detection)
   - Initializes workflow state and error logging
   - Parses modes: `--prove-all` (default), `--verify`, `--max-attempts`, `--max-iterations`

2. **Block 1b**: Invoke Lean Coordinator [HARD BARRIER]
   - **Delegation Pattern**: Task tool invocation with structured input contract
   - **Input Contract**:
     - `lean_file_path`: Absolute path to Lean source file
     - `topic_path`: Topic directory for artifacts
     - `artifact_paths`: Pre-calculated paths (summaries, outputs, checkpoints)
     - `max_attempts`: Maximum proof attempts per theorem
     - `plan_path`: Optional plan file path (empty for file-based mode)
     - `execution_mode`: "file-based" or "plan-based"
     - `continuation_context`: Path to previous iteration summary (for multi-iteration)
     - `max_iterations`: Maximum iterations allowed (default: 5)
   - **Coordinator Responsibilities**:
     - Invoke dependency-analyzer for wave structure
     - Execute theorems wave-by-wave with parallel lean-implementers
     - Manage MCP rate limits (3 requests/30s shared budget)
     - Update plan file progress markers in real-time
     - Create proof summaries in summaries/ directory

3. **Block 1c**: Verification & Iteration Decision
   - **Hard Barrier Validation**: Ensures summary file exists (≥100 bytes)
   - **Iteration Management**:
     - Parses `work_remaining`, `context_exhausted`, `requires_continuation`
     - Detects stuck state (work_remaining unchanged for 2 iterations)
     - Checks max_iterations threshold
     - Creates continuation context for next iteration
   - **Decision Logic**:
     - If `requires_continuation: true` AND `iteration < max_iterations`: Loop to Block 1b
     - Otherwise: Proceed to Block 1d

4. **Block 1d**: Phase Marker Validation and Recovery
   - Validates [COMPLETE] markers added by lean-implementer
   - Recovers missing markers for phases with all tasks complete
   - Updates plan metadata status to COMPLETE if all phases done
   - Skipped for file-based mode

5. **Block 2**: Completion & Summary
   - Displays console summary with proof metrics
   - Emits PROOF_COMPLETE signal with summary path
   - Cleanup: Removes temp files, preserves state for /test

#### Key Coordination Patterns

**Lean-Specific Features**:
- **2-Tier Lean File Discovery**:
  - Tier 1 (preferred): `lean_file: /path` in phase metadata
  - Tier 2 (fallback): `- **Lean File**: /path` in global metadata
- **Multi-File Support**: Comma-separated lean files per phase
- **MCP Rate Limit Coordination**: Budget allocation across parallel implementers
- **Wave-Based Parallelization**: Dependency-aware theorem batching
- **Context Exhaustion Handling**: Iteration-based continuation with checkpoints

**Progress Tracking**:
- **Real-Time Markers**: [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
- **Source Pattern**: `source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh`
- **Marker Updates**:
  - Before phase: `add_in_progress_marker '$PLAN_FILE' <phase_num>`
  - After completion: `mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>`
- **Graceful Degradation**: Progress tracking non-fatal if unavailable

#### Lean Coordinator Deep Dive

**File**: `/home/benjamin/.config/.claude/agents/lean-coordinator.md`

**Model**: Opus 4.5 (complex delegation, wave orchestration, sophisticated reasoning)

**Core Responsibilities**:
1. **Dependency Analysis**: Invoke dependency-analyzer to build wave structure
2. **Wave Orchestration**: Execute theorem batches wave-by-wave
3. **Rate Limit Coordination**: Allocate MCP search budget (3 requests/30s)
4. **Progress Monitoring**: Collect proof results from all implementers
5. **Failure Handling**: Mark theorems, continue independent work
6. **Result Aggregation**: Collect completion reports and metrics
7. **Context Management**: Estimate usage, create checkpoints

**Workflow Stages**:
1. **Plan Structure Detection**: Level 0 (inline) vs Level 1 (phase files) vs Level 2 (N/A for Lean)
2. **Dependency Analysis**: Invoke `dependency-analyzer.sh` → wave structure JSON
3. **Iteration Management**:
   - **Context Estimation**: Per-theorem cost model (~8000 tokens/proof)
   - **Checkpoint Saving**: v1.0 schema with iteration fields
   - **Stuck Detection**: Track work_remaining across iterations
   - **Iteration Limit**: Enforce max_iterations threshold
4. **Wave Execution Loop**:
   - **Phase Number Extraction**: From theorem metadata for progress tracking
   - **Parallel Implementer Invocation**: Multiple Task calls in single response
   - **Progress Monitoring**: Collect THEOREM_BATCH_COMPLETE signals
   - **Wave Synchronization**: Wait for ALL implementers before proceeding
5. **Result Aggregation**: Create proof summary, calculate time savings

**Output Format Requirements**:
- **work_remaining**: Space-separated string (NOT JSON array)
  - Correct: `work_remaining: Phase_4 Phase_5 Phase_6` ✓
  - WRONG: `work_remaining: [Phase 4, Phase 5, Phase 6]` ✗ (triggers state_error)
- Reason: Parent workflow uses `append_workflow_state()` which only accepts scalars

**MCP Rate Limit Strategy**:
- Budget per implementer: `TOTAL_BUDGET / wave_size`
- Wave with 1 agent: 3 requests
- Wave with 2 agents: 1 request each
- Wave with 3+ agents: 0-1 requests (rely on lean_local_search)
- Implementers prioritize lean_local_search (no rate limit)

### 2. /implement Command Analysis

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

#### Architecture Overview

The /implement command follows a **4-block orchestration pattern** (similar to /lean-build):

1. **Block 1a**: Implementation Phase Setup
   - Captures arguments via temp file pattern
   - Detects project directory
   - Sources three-tier library pattern
   - Validates plan file existence
   - Initializes workflow state machine (STATE_IMPLEMENT)
   - Parses modes: plan file, starting phase, `--dry-run`, `--max-iterations`, `--resume`
   - Marks starting phase [IN PROGRESS]

2. **Block 1b**: Implementer-Coordinator Invocation [CRITICAL BARRIER]
   - **Delegation Pattern**: Task tool invocation with structured input contract
   - **Input Contract**:
     - `plan_path`: Absolute path to plan file
     - `topic_path`: Topic directory
     - `summaries_dir`: Summaries directory path
     - `artifact_paths`: Pre-calculated paths
     - `continuation_context`: Path to previous iteration summary
     - `iteration`: Current iteration number
     - `max_iterations`, `context_threshold`: Iteration limits
   - **Coordinator Responsibilities**:
     - Invoke dependency-analyzer for wave structure
     - Execute phases wave-by-wave with parallel implementation-executors
     - Update plan file progress markers
     - Create implementation summaries

3. **Block 1c**: Implementation Phase Verification (Hard Barrier)
   - **Hard Barrier Validation**: Ensures summary file exists (≥100 bytes)
   - **Iteration Management**:
     - Parses `work_remaining`, `context_exhausted`, `requires_continuation`
     - Detects stuck state
     - Checks max_iterations threshold
     - Updates IMPLEMENTATION_STATUS (continuing|complete|stuck|max_iterations)
   - **Iteration Decision**:
     - If `IMPLEMENTATION_STATUS=continuing`: Loop to Block 1b
     - Otherwise: Proceed to Block 1d

4. **Block 1d**: Phase Marker Validation and Recovery
   - Validates [COMPLETE] markers added by executors
   - Recovers missing markers for phases with all tasks complete
   - Updates plan metadata status to COMPLETE if all phases done

5. **Block 2**: Completion
   - State transition to STATE_COMPLETE
   - Console summary with 4-section format
   - Emits IMPLEMENTATION_COMPLETE signal
   - Preserves state for /test

#### Key Coordination Patterns

**Software Implementation Features**:
- **Auto-Resume Logic**: Finds incomplete plans via checkpoint or most recent plan
- **Dry-Run Mode**: Preview execution without changes
- **Wave-Based Parallelization**: Dependency-aware phase batching
- **Context Exhaustion Handling**: Iteration-based continuation
- **Testing Strategy**: Summaries include test files, execution requirements, coverage targets

**Progress Tracking** (identical pattern to /lean-build):
- Source checkbox-utils.sh
- Before phase: `add_in_progress_marker`
- After completion: `mark_phase_complete` + `add_complete_marker`
- Graceful degradation if unavailable

#### Implementer Coordinator Deep Dive

**File**: `/home/benjamin/.config/.claude/agents/implementer-coordinator.md`

**Model**: Haiku 4.5 (deterministic orchestration, mechanical coordination)

**Core Responsibilities**:
1. **Dependency Analysis**: Invoke dependency-analyzer to build execution structure
2. **Wave Orchestration**: Execute phases wave-by-wave with parallel executors
3. **Progress Monitoring**: Collect updates from all executors
4. **State Management**: Maintain implementation state across waves
5. **Failure Handling**: Mark phases, continue independent work
6. **Result Aggregation**: Collect completion reports and metrics

**Workflow Stages**:
1. **Plan Structure Detection**: Level 0 (inline) vs Level 1 (phase files) vs Level 2 (stage files)
2. **Dependency Analysis**: Invoke `dependency-analyzer.sh` → wave structure JSON
3. **Iteration Management**:
   - **Context Estimation**: Per-phase cost model (~15k tokens/phase)
   - **Checkpoint Saving**: v2.1 schema with iteration fields
   - **Stuck Detection**: Track work_remaining across iterations
4. **Wave Execution Loop**:
   - **Parallel Executor Invocation**: Multiple Task calls in single response
   - **Progress Monitoring**: Collect PHASE_COMPLETE signals
   - **Wave Synchronization**: Wait for ALL executors before proceeding
5. **Result Aggregation**: Create implementation report, calculate time savings

**Output Format Requirements** (identical to lean-coordinator):
- **work_remaining**: Space-separated string (NOT JSON array)
- Reason: Parent workflow uses `append_workflow_state()` which only accepts scalars

### 3. Coordinator Comparison Matrix

| Aspect | Lean Coordinator | Implementer Coordinator |
|--------|-----------------|-------------------------|
| **Model** | Opus 4.5 | Haiku 4.5 |
| **Justification** | Complex proof search, tactic generation, Mathlib discovery | Deterministic orchestration, mechanical coordination |
| **Task Type** | Theorem proving (Lean 4 proofs) | Software implementation (code, tests, docs) |
| **Subagent** | lean-implementer (Opus 4.5) | implementation-executor (Sonnet 4.5) |
| **Input** | lean_file_path, theorem_tasks, rate_limit_budget | plan_path (phase structure) |
| **Wave Unit** | Theorems (atomic proof tasks) | Phases (multi-task units) |
| **Rate Limits** | MCP search tools (3 req/30s) | None |
| **Context Model** | ~8000 tokens/proof | ~15000 tokens/phase |
| **Progress Tracking** | Phase markers (plan-based) | Phase markers (always) |
| **Output Signal** | PROOF_COMPLETE | IMPLEMENTATION_COMPLETE |
| **Artifacts** | Proof summaries, Lean source edits | Implementation summaries, code files, git commits |

### 4. Phase Type Detection Patterns

#### Lean-Specific Indicators

**Strong Indicators** (match any = Lean phase):
- Filename patterns: `*.lean` in phase description
- Keywords: "theorem", "lemma", "proof", "sorry", "tactic", "Mathlib"
- Tool references: "lean_goal", "lean_build", "lean_leansearch"
- File extensions: Phase tasks reference `.lean` files
- Imports: References to Mathlib, Lean 4 standard library

**Example Lean Phase**:
```markdown
### Phase 1: Prove Modal Axioms [NOT STARTED]
lean_file: /path/to/Modal.lean

**Tasks**:
- [ ] Prove theorem_K: ⊢ □(P → Q) → (□P → □Q)
- [ ] Prove theorem_T: ⊢ □P → P
- [ ] Verify compilation via lean_build
```

#### Software Implementation Indicators

**Strong Indicators** (match any = software phase):
- Languages: TypeScript, JavaScript, Python, Bash, etc.
- File extensions: `.ts`, `.js`, `.py`, `.sh`, `.md`, etc.
- Actions: "implement", "write tests", "create API", "setup database"
- Tools: npm, git, pytest, jest, etc.
- Artifacts: "create file", "modify function", "add endpoint"

**Example Software Phase**:
```markdown
### Phase 2: Implement Authentication API [NOT STARTED]

**Tasks**:
- [ ] Create auth.ts with JWT token generation
- [ ] Write unit tests in auth.test.ts
- [ ] Add authentication middleware
- [ ] Update API documentation
```

#### Detection Algorithm

```python
def detect_phase_type(phase_content: str) -> str:
    """Detect if phase is Lean or software implementation."""

    # Extract phase heading and tasks
    heading = extract_heading(phase_content)
    tasks = extract_tasks(phase_content)

    # Check for lean_file metadata (strongest signal)
    if "lean_file:" in phase_content:
        return "lean"

    # Check filename patterns
    if re.search(r'\.lean\b', phase_content):
        return "lean"

    # Check Lean keywords (case-insensitive)
    lean_keywords = ["theorem", "lemma", "proof", "sorry", "tactic", "mathlib",
                     "lean_goal", "lean_build", "lean_leansearch"]
    if any(keyword.lower() in phase_content.lower() for keyword in lean_keywords):
        return "lean"

    # Check software file extensions
    software_extensions = [".ts", ".js", ".py", ".sh", ".md", ".json", ".yaml", ".toml"]
    if any(ext in phase_content for ext in software_extensions):
        return "software"

    # Check software action verbs
    software_verbs = ["implement", "create", "write tests", "setup", "configure",
                      "deploy", "build", "compile", "install"]
    if any(verb.lower() in phase_content.lower() for verb in software_verbs):
        return "software"

    # Default: software (conservative choice)
    return "software"
```

### 5. Hybrid Coordination Design

#### Architecture Overview

The /lean-implement command acts as a **router-orchestrator** that:
1. Analyzes plan structure to classify phases (Lean vs software)
2. Routes phases to appropriate coordinators
3. Manages cross-coordinator state (shared workflow_id, topic_path)
4. Aggregates results from both coordinator types
5. Handles iteration management across mixed plans

#### Block Structure (5 blocks)

**Block 1a**: Setup & Phase Classification
- Initialize workflow state
- Parse plan file
- Classify each phase as "lean" or "software"
- Build routing map: `{phase_number: coordinator_type}`
- Detect execution mode (all-lean, all-software, mixed)

**Block 1b**: Route to Coordinator (HARD BARRIER)
- Determine current phase type from routing map
- Invoke appropriate coordinator via Task tool:
  - If lean: Invoke lean-coordinator with lean-specific inputs
  - If software: Invoke implementer-coordinator with software-specific inputs
- Pass shared context: topic_path, continuation_context, iteration

**Block 1c**: Verification & Continuation
- Validate summary creation (hard barrier)
- Parse coordinator output
- Update phase routing map with completion status
- Determine if more work remains (check next phases in routing map)
- Decide: continue to next phase OR next iteration OR complete

**Block 1d**: Phase Marker Recovery
- Validate [COMPLETE] markers for all coordinators
- Recover missing markers

**Block 2**: Completion & Summary
- Aggregate metrics from all coordinators
- Display unified console summary
- Emit IMPLEMENTATION_COMPLETE signal

#### Routing Map Data Structure

```json
{
  "routing_map": {
    "1": {
      "phase_type": "software",
      "coordinator": "implementer-coordinator",
      "status": "complete",
      "summary_path": "/path/to/summaries/phase_1_summary.md"
    },
    "2": {
      "phase_type": "lean",
      "coordinator": "lean-coordinator",
      "lean_file": "/path/to/file.lean",
      "status": "complete",
      "summary_path": "/path/to/summaries/phase_2_summary.md"
    },
    "3": {
      "phase_type": "software",
      "coordinator": "implementer-coordinator",
      "status": "in_progress"
    }
  },
  "current_phase": 3,
  "total_phases": 5,
  "lean_phases": [2, 4],
  "software_phases": [1, 3, 5]
}
```

#### Coordinator Invocation Patterns

**Lean Coordinator Invocation**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for Phase ${PHASE_NUM}"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md

    **Input Contract**:
    - lean_file_path: ${LEAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - artifact_paths:
      - summaries: ${SUMMARIES_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}
    - max_attempts: ${MAX_ATTEMPTS}
    - plan_path: ${PLAN_FILE}
    - execution_mode: plan-based
    - starting_phase: ${PHASE_NUM}
    - continuation_context: ${CONTINUATION_CONTEXT}
    - max_iterations: ${MAX_ITERATIONS}

    Execute wave-based proof orchestration for Phase ${PHASE_NUM}.

    Return: ORCHESTRATION_COMPLETE
    summary_path: /path/to/summary
    phases_completed: [...]
    work_remaining: Phase_X Phase_Y
    context_exhausted: true|false
    requires_continuation: true|false
}
```

**Implementer Coordinator Invocation**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Wave-based implementation for Phase ${PHASE_NUM}"
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Input Contract**:
    - plan_path: ${PLAN_FILE}
    - topic_path: ${TOPIC_PATH}
    - summaries_dir: ${SUMMARIES_DIR}
    - artifact_paths:
      - reports: ${REPORTS_DIR}
      - plans: ${PLANS_DIR}
      - summaries: ${SUMMARIES_DIR}
      - debug: ${DEBUG_DIR}
      - outputs: ${OUTPUTS_DIR}
      - checkpoints: ${CHECKPOINTS_DIR}
    - continuation_context: ${CONTINUATION_CONTEXT}
    - iteration: ${ITERATION}
    - max_iterations: ${MAX_ITERATIONS}
    - context_threshold: ${CONTEXT_THRESHOLD}

    Execute wave-based implementation for Phase ${PHASE_NUM}.

    Return: IMPLEMENTATION_COMPLETE
    summary_path: /path/to/summary
    work_remaining: Phase_X Phase_Y
    context_exhausted: true|false
    requires_continuation: true|false
}
```

#### Model Selection Strategy

**Command Level** (lean-implement.md):
- Model: Sonnet 4.5 (default for command orchestration)
- Justification: Routing logic, phase classification, state management

**Coordinator Level**:
- Lean tasks → Opus 4.5 (lean-coordinator model field)
  - Justification: Complex proof search, tactic generation (AIME 2025: 93-100%)
- Software tasks → Haiku 4.5 (implementer-coordinator model field)
  - Justification: Deterministic orchestration, mechanical coordination

**Dynamic Routing**:
- No need for dynamic model selection
- Coordinators declare their own models via frontmatter
- Command simply routes to appropriate coordinator agent

#### Iteration Management

**Cross-Coordinator Continuity**:
- Shared workflow_id across all coordinators
- Continuation context passed between coordinators
- Routing map persisted in workflow state
- Each coordinator manages its own iteration checkpoints

**Example: 3-Phase Mixed Plan**:
```
Phase 1 (software) → implementer-coordinator
  Iteration 1: Completes, returns work_remaining: ""

Phase 2 (lean) → lean-coordinator
  Iteration 1: Proves 3/6 theorems, returns work_remaining: Phase_2
  Iteration 2: Proves remaining 3 theorems, returns work_remaining: ""

Phase 3 (software) → implementer-coordinator
  Iteration 1: Completes, returns work_remaining: ""
```

**State Persistence Pattern**:
```bash
# Shared state variables (cross-coordinator)
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "PLAN_FILE" "$PLAN_FILE"
append_workflow_state "ROUTING_MAP" "$ROUTING_MAP_JSON"
append_workflow_state "CURRENT_PHASE" "$CURRENT_PHASE"

# Coordinator-specific state
append_workflow_state "LEAN_ITERATION" "$LEAN_ITERATION"
append_workflow_state "SOFTWARE_ITERATION" "$SOFTWARE_ITERATION"
```

### 6. Edge Cases & Error Handling

#### Ambiguous Phase Type

**Strategy**: Default to software implementation (conservative choice)
- Lean phases have strong signals (lean_file, .lean extensions)
- Ambiguous phases likely software-related
- Log classification decision for user review

**Example**:
```markdown
### Phase 4: Integration Testing [NOT STARTED]
**Tasks**:
- [ ] Test Lean proof integration with application
- [ ] Verify proof certificates load correctly
```
**Classification**: Software (testing focus, no lean_file metadata)

#### Mixed Lean/Software Tasks in Single Phase

**Strategy**: Split phase into sub-phases during classification
- Detect mixed tasks during phase analysis
- Create virtual sub-phases in routing map
- Route each sub-phase to appropriate coordinator

**Example**:
```markdown
### Phase 5: Proof Verification & UI Integration [NOT STARTED]
**Tasks**:
- [ ] Prove verification_correctness theorem (Lean)
- [ ] Implement proof checker UI (TypeScript)
```

**Split into**:
- Phase 5a (lean): Prove verification_correctness
- Phase 5b (software): Implement proof checker UI

#### Coordinator Failure

**Strategy**: Isolate failure, continue independent work
- If lean-coordinator fails: Mark lean phases blocked, continue software phases
- If implementer-coordinator fails: Mark software phases blocked, continue lean phases
- Aggregate partial results in final summary

#### Plan Structure Mismatch

**Strategy**: Validate plan compatibility before routing
- Both coordinators require Level 0 or Level 1 structure
- Level 2 (stage expansion) only for software phases
- Error if lean phase requires Level 2 structure

### 7. Implementation Roadmap

#### Phase 1: Command Scaffolding
- Create /lean-implement command file
- Implement argument parsing (plan_file, --mode, --max-iterations)
- Setup state initialization with routing map

#### Phase 2: Phase Classification
- Implement phase type detection algorithm
- Build routing map data structure
- Persist routing map in workflow state

#### Phase 3: Coordinator Routing
- Implement lean-coordinator invocation logic
- Implement implementer-coordinator invocation logic
- Add routing decision logic (if/else based on phase type)

#### Phase 4: Iteration Management
- Implement cross-coordinator continuation context
- Add iteration loop for each coordinator type
- Handle context exhaustion and checkpoints

#### Phase 5: Verification & Recovery
- Implement hard barrier validation (summary existence)
- Add phase marker recovery for both coordinator types
- Aggregate results from multiple coordinators

#### Phase 6: Console Summary & Completion
- Design unified console summary format
- Aggregate metrics (lean: theorems proven, software: phases completed)
- Emit IMPLEMENTATION_COMPLETE signal

#### Phase 7: Testing & Documentation
- Create test plans with mixed lean/software plans
- Document usage examples
- Add troubleshooting guide

## Design Recommendations

### 1. Naming Convention

**Command Name**: `/lean-implement`
- Clear indication of Lean focus
- Distinguishes from pure /implement command
- Suggests hybrid implementation capability

**Alternative Names Considered**:
- `/hybrid-implement` - Less clear about Lean focus
- `/implement-all` - Unclear scope
- `/unified-implement` - Generic, not descriptive

### 2. Model Selection

**Command Level**: Sonnet 4.5
- Routing logic and state management are deterministic
- No complex reasoning required at command level
- Cost optimization (75% cheaper than Opus 4.5)

**Coordinator Level**: Preserve existing model selections
- lean-coordinator: Opus 4.5 (proof search complexity)
- implementer-coordinator: Haiku 4.5 (mechanical orchestration)

### 3. Input Contract

```yaml
plan_path: /path/to/plan.md
starting_phase: 1
mode: auto  # Options: auto, lean-only, software-only
max_iterations: 5
context_threshold: 85
dry_run: false
```

**Mode Options**:
- `auto`: Detect phase types and route automatically (default)
- `lean-only`: Skip software phases, execute only lean phases
- `software-only`: Skip lean phases, execute only software phases

### 4. Output Signal Format

```yaml
IMPLEMENTATION_COMPLETE:
  total_phases: 5
  lean_phases_completed: 2
  software_phases_completed: 3
  theorems_proven: 12
  files_created: 8
  git_commits: 3
  plan_file: /path/to/plan.md
  topic_path: /path/to/topic
  summary_paths:
    - lean: /path/to/lean_summary.md
    - software: /path/to/software_summary.md
  work_remaining: ""
  context_exhausted: false
  requires_continuation: false
```

### 5. Error Logging Integration

Both coordinators already support structured error signals:
- Use `parse_subagent_error()` to extract error context
- Log coordinator failures to errors.jsonl with full workflow context
- Enable `/errors --command /lean-implement` queries
- Support `/repair` workflow for implementation failures

### 6. Backward Compatibility

**Preserve Existing Commands**:
- `/lean-build`: Keep for pure Lean workflows (no plan file required)
- `/implement`: Keep for pure software workflows
- `/lean-implement`: New hybrid command for mixed plans

**Migration Path**:
- Users can gradually adopt /lean-implement for mixed plans
- No breaking changes to existing workflows
- Documentation should clarify when to use each command

## Conclusion

The /lean-implement command design leverages existing architectural patterns from /lean-build and /implement while introducing intelligent phase-type detection and hybrid orchestration. The key innovation is the **routing map** data structure that tracks phase types and coordinator assignments, enabling seamless coordination between lean-coordinator (theorem proving) and implementer-coordinator (software implementation) agents.

### Key Design Principles

1. **Separation of Concerns**: Command handles routing, coordinators handle execution
2. **Intelligent Routing**: Automatic phase classification with manual override
3. **State Continuity**: Shared workflow_id and continuation context across coordinators
4. **Iteration Management**: Per-coordinator iteration loops with unified continuation
5. **Model Efficiency**: Preserve coordinator-level model selections (Opus for Lean, Haiku for software)
6. **Backward Compatibility**: No breaking changes to existing commands

### Success Criteria

- ✅ Supports mixed Lean/software implementation plans
- ✅ Intelligent phase-type detection (>95% accuracy)
- ✅ Seamless coordinator routing with shared state
- ✅ Multi-iteration support with cross-coordinator continuity
- ✅ Unified console summary aggregating both coordinator types
- ✅ Preserves all existing /lean-build and /implement features
- ✅ No breaking changes to existing workflows

## Appendices

### Appendix A: Phase Classification Test Cases

| Phase Content | Expected Classification | Reasoning |
|--------------|------------------------|-----------|
| `lean_file: Modal.lean` | Lean | Strong signal: lean_file metadata |
| `Prove theorem_K in Modal.lean` | Lean | Lean keyword + .lean extension |
| `Implement auth.ts API` | Software | .ts extension + implement verb |
| `Write tests for proof checker` | Software | Testing focus, no .lean files |
| `Deploy to production` | Software | Deployment verb |
| `Setup Lean project with lakefile` | Software | Setup/configuration focus |

### Appendix B: Coordinator Input Contract Comparison

| Field | Lean Coordinator | Implementer Coordinator | Shared? |
|-------|------------------|------------------------|---------|
| lean_file_path | ✅ | ❌ | ❌ |
| plan_path | ✅ | ✅ | ✅ |
| topic_path | ✅ | ✅ | ✅ |
| artifact_paths | ✅ | ✅ | ✅ |
| continuation_context | ✅ | ✅ | ✅ |
| iteration | ✅ | ✅ | ✅ |
| max_iterations | ✅ | ✅ | ✅ |
| max_attempts | ✅ | ❌ | ❌ |
| rate_limit_budget | ✅ | ❌ | ❌ |
| context_threshold | ✅ | ✅ | ✅ |

### Appendix C: Existing Dependency-Analyzer Integration

Both coordinators use the same dependency-analyzer utility:
- **Path**: `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh`
- **Input**: Plan file path
- **Output**: JSON with wave structure, dependency graph, parallelization metrics
- **Usage**: `bash dependency-analyzer.sh "$plan_path" > analysis.json`

The /lean-implement command does NOT need to modify dependency-analyzer; it works transparently with both coordinator types.

### Appendix D: References

- `/home/benjamin/.config/.claude/commands/lean-build.md` - Lean theorem proving command
- `/home/benjamin/.config/.claude/commands/implement.md` - Software implementation command
- `/home/benjamin/.config/.claude/agents/lean-coordinator.md` - Wave-based proof orchestration agent
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Wave-based implementation orchestration agent
- `/home/benjamin/.config/.claude/agents/lean-implementer.md` - Lean 4 theorem proving agent
- `/home/benjamin/.config/.claude/lib/util/dependency-analyzer.sh` - Dependency analysis utility

---

**Report Created**: 2025-12-04
**Research Complexity**: 3
**Report Type**: Hybrid Coordination Design
**Next Steps**: Create implementation plan based on this research
