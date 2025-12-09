# Orchestrator-Coordinator-Specialist Pattern Architecture

## Executive Summary

The orchestrator-coordinator-specialist pattern is a three-tier hierarchical agent architecture that provides parallel orchestration, context efficiency (95%+ reduction), and clear separation of concerns. This pattern extends the two-tier model by introducing a middle coordination layer that manages parallel specialist invocations and performs metadata aggregation, preventing context explosion while enabling 40-60% time savings through parallel execution.

The pattern consists of:
1. **Orchestrator Layer** (slash commands): User-facing workflow state management
2. **Coordinator Layer** (supervisor agents): Parallel specialist orchestration with metadata aggregation
3. **Specialist Layer** (domain experts): Deep expertise with comprehensive artifact generation

Successfully implemented in `/lean-plan` (research-coordinator) and `/lean-implement` (implementer-coordinator) with validated 95-96% context reduction and 100% test pass rate (48 tests).

## Analysis

### Three-Tier Architecture Design

The pattern introduces three distinct layers with specific responsibilities:

**Orchestrator Layer** (Slash Commands):
- User-facing entry points (e.g., `/lean-plan`, `/create-plan`, `/debug`)
- Argument parsing and validation
- Workflow state machine management (via state-persistence.sh)
- Hard barrier enforcement via path pre-calculation
- Console output and progress reporting
- Receives metadata summaries (110 tokens) instead of full content (2,500 tokens)

**Coordinator Layer** (Supervisor Agents):
- Parallel specialist invocation via Task tool
- Dependency analysis and wave-based orchestration
- Artifact validation using hard barrier pattern (fail-fast on missing outputs)
- Metadata extraction from specialist artifacts (95% reduction)
- Progress monitoring and failure isolation
- Error return protocol using structured signals

**Specialist Layer** (Domain Experts):
- Deep domain expertise (research, implementation, testing, debugging)
- Comprehensive artifact generation (reports, code, test results)
- Structured error return protocol
- Focus on single, well-defined tasks
- No coordination responsibilities

### Context Efficiency Mechanism

The pattern achieves dramatic context reduction through metadata-only passing between layers:

**Without Coordinator (2-tier)**:
- 4 specialist reports × 2,500 tokens each = 10,000 tokens to orchestrator
- Context pollution from full content
- Limited iteration capacity (3-4 iterations before context exhaustion)

**With Coordinator (3-tier)**:
- 4 specialist reports × 2,500 tokens → coordinator
- Coordinator extracts 110 tokens per report = 440 tokens to orchestrator
- **Context Reduction**: 95.6%
- Increased iteration capacity (10+ iterations possible)

**Metadata Format**:
```json
{
  "path": "/absolute/path/to/artifact.md",
  "title": "Artifact Title",
  "key_counts": {
    "findings": 12,
    "recommendations": 5,
    "errors": 0
  },
  "status": "[COMPLETE]",
  "brief_summary": "One-line summary (max 100 chars)"
}
```

### Parallelization Benefits

Wave-based parallel execution provides 40-60% time savings:

**Sequential Execution (2-tier)**:
- Phase 1 (3 hrs) → Phase 2 (3 hrs) → Phase 3 (3 hrs) = 9 hours total

**Parallel Execution (3-tier)**:
- Wave 1: Phase 1 (3 hrs)
- Wave 2: Phase 2 + Phase 3 in parallel (3 hrs)
- Total: 6 hours
- **Time Savings**: 33% (single wave), 40-60% (multi-wave)

The coordinator analyzes phase dependencies to determine parallel execution groups:
```yaml
phases:
  - name: "Research Authentication"
    dependencies: []
  - name: "Research Logging"
    dependencies: []
  - name: "Create Plan"
    dependencies: ["Research Authentication", "Research Logging"]
```

### Hard Barrier Pattern Integration

The three-tier pattern enforces mandatory subagent delegation through hard barriers:

**Pattern Components**:
1. **Path Pre-Calculation**: Orchestrator calculates artifact paths BEFORE invoking coordinator
2. **Contract-Based Invocation**: Coordinator receives paths as literal values in prompt
3. **Coordinator Path Calculation**: Coordinator pre-calculates specialist paths BEFORE invocation
4. **Artifact Validation**: Coordinator validates files exist at paths AFTER specialists return
5. **Fail-Fast**: Coordinator exits with structured error if validation fails
6. **Orchestrator Verification**: Orchestrator validates coordinator artifacts exist

**Three-Block Structure**:
```
Block Na: Setup
├── State transition (fail-fast)
├── Variable persistence
└── Checkpoint reporting

Block Nb: Execute [CRITICAL BARRIER]
└── Task invocation (MANDATORY)

Block Nc: Verify
├── Artifact existence check
├── Fail-fast on missing outputs
└── Error logging with recovery hints
```

This structure makes delegation bypass impossible because:
- Bash verification blocks sit between Task invocations
- Claude cannot skip bash blocks
- Fail-fast errors prevent progression without artifacts
- State transitions act as gates preventing phase skipping

### Decision Matrix for Pattern Selection

**When to Use Each Pattern**:

| Scenario | Complexity | Parallel Benefit | Pattern | Example |
|----------|-----------|------------------|---------|---------|
| Simple, single task | 1 | None | 1-tier (direct) | Single test file execution |
| Sequential multi-step | 2 | None | 2-tier (orchestrator → specialist) | Linear debug investigation |
| Parallel independent tasks | 3 | 40-60% time savings | 3-tier (orchestrator → coordinator → specialist) | Multi-module testing |
| Complex multi-domain | 4 | 50-70% time savings | 3-tier with sub-supervisors | Full system validation |

**Use Three-Tier When**:
- Workflow has 4+ parallel agents
- Context reduction is critical (specialists produce >1,000 tokens each)
- Parallel execution provides tangible time benefits
- Need clear responsibility boundaries
- Workflow has distinct phases (research → plan → implement)

**Don't Use Three-Tier When**:
- Single agent workflow
- Simple sequential operations (no parallelization benefit)
- Minimal context management needs
- Two-tier pattern sufficient

### Coordinator Responsibilities

Coordinators occupy the middle tier with specific responsibilities:

**Input Contract Parsing**:
- Receive topics, paths, and context from orchestrator
- Verify all inputs present and valid
- Determine operating mode (automated vs pre-decomposed)

**Parallel Specialist Invocation**:
- Invoke specialists in single response via multiple Task calls
- Pass pre-calculated paths to each specialist (hard barrier pattern)
- Provide topic-specific context to each specialist

**Artifact Validation (Hard Barrier)**:
- Verify all specialist artifacts exist at pre-calculated paths
- Check artifact quality (minimum size, required sections)
- Fail-fast if any artifacts missing (mandatory delegation enforcement)

**Metadata Extraction**:
- Extract title, key counts, status from each artifact
- Avoid loading full content into context
- Use grep/awk for targeted extraction (110 tokens per artifact)

**Aggregated Metadata Return**:
- Combine metadata into structured JSON format
- Return to orchestrator with completion signal
- Include summary counts (total findings, recommendations, errors)

**Error Handling**:
- Partial success mode (≥50% threshold)
- Structured error return protocol
- Recovery hints for debugging

### Error Return Protocol

All agents use structured error signals for consistent error handling:

**Error Signal Format**:
```
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Human-readable description",
  "details": {"key": "value"}
}

TASK_ERROR: error_type - Brief message
```

**Standardized Error Types**:
- `state_error`: Workflow state persistence issues
- `validation_error`: Input validation failures
- `agent_error`: Subagent execution failures
- `parse_error`: Output parsing failures
- `file_error`: File system operation failures
- `timeout_error`: Operation timeout errors
- `execution_error`: General execution failures
- `dependency_error`: Missing or invalid dependencies

**Error Handling Flow**:
1. Specialist encounters error → Returns TASK_ERROR signal
2. Coordinator parses error using `parse_subagent_error()`
3. Coordinator decides: partial success or full failure
4. Coordinator logs error and returns TASK_ERROR to orchestrator
5. Orchestrator logs to errors.jsonl via `log_command_error()`
6. User queries errors via `/errors` command
7. User creates fix plan via `/repair` command

### Implemented Examples

**Research-Coordinator Pattern** (implemented in `/lean-plan`, `/create-plan`):

```
/lean-plan Command
    │
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Mathlib Theorems)
            +-- research-specialist 2 (Proof Strategies)
            +-- research-specialist 3 (Project Structure)
```

**Results**:
- Context reduction: 7,500 tokens → 330 tokens (95.6%)
- Parallel execution: 3 topics simultaneously
- Iteration capacity: 10+ iterations (vs 3-4 before)
- Partial success mode: ≥50% threshold (continues if 2/3 succeed)

**Implementer-Coordinator Pattern** (implemented in `/lean-implement`):

```
/lean-implement Command
    │
    +-- implementer-coordinator (Supervisor)
            +-- Wave-based phase execution
            +-- Brief summary parsing (80 tokens vs 2,000 full file)
```

**Results**:
- Context reduction: 2,000 tokens → 80 tokens (96%)
- Wave-based orchestration: 40-60% time savings
- Hard barrier enforcement: 100% delegation success
- Validation: 48 integration tests, 100% pass rate

### Migration Path from Two-Tier to Three-Tier

**Step 1: Identify Parallelization Opportunities**
- Analyze current workflow for independent tasks
- Assess specialist output sizes (>1,000 tokens?)
- Evaluate time savings potential (40-60% worth complexity?)

**Step 2: Create Coordinator Agent**
- Use coordinator template (.claude/agents/templates/coordinator-template.md)
- Define input contract (paths, topics, context)
- Implement parallel Task invocation pattern
- Add artifact validation (hard barrier)
- Implement metadata extraction functions
- Define return signal format

**Step 3: Update Orchestrator Command**
- Replace direct specialist invocations with coordinator invocation
- Add path pre-calculation (hard barrier pattern)
- Update verification to check coordinator artifacts
- Modify downstream consumers to receive metadata instead of full content

**Step 4: Add Hard Barrier Validation**
- Add verification block after coordinator returns
- Check coordinator created required artifacts
- Fail-fast if validation fails
- Log errors with recovery hints

**Step 5: Update Metadata Passing**
- Change downstream consumers to receive metadata
- Update consumers to use Read tool for full artifacts (delegated reads)
- Verify context reduction achieved

**Step 6: Test Both Paths**
- Verify parallel execution (standard path)
- Test fallback to sequential (if parallel fails)
- Validate partial success mode (≥50% threshold)

### Anti-Patterns to Avoid

**Context Explosion**:
```yaml
# WRONG: Passing full content
"Here are the complete research reports:
[2,500 tokens from worker 1]
[2,500 tokens from worker 2]"

# CORRECT: Passing metadata only
"Research completed:
- auth_report.md: 15 patterns found
- logging_report.md: 8 patterns found"
```

**Behavioral Duplication**:
```yaml
# WRONG: Inline behavior
Task {
  prompt: |
    You are a research specialist.
    [180 lines of behavioral instructions]
    Topic: ${topic}
}

# CORRECT: Reference + context
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${topic}
}
```

**Missing Verification**:
```bash
# WRONG: Trust agent output
RESULT=$(invoke_agent)
use_result "$RESULT"

# CORRECT: Verify before using
RESULT=$(invoke_agent)
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  exit 1
fi
use_result "$RESULT"
```

**Serial Invocation of Parallel Tasks**:
```markdown
# WRONG: Sequential invocation
**EXECUTE**: Task 1
[wait]
**EXECUTE**: Task 2

# CORRECT: Parallel invocation
**EXECUTE NOW**: All tasks in single message

Task { ... topic 1 ... }
Task { ... topic 2 ... }
Task { ... topic 3 ... }
```

## Findings

### Architecture Findings

1. **Three-tier hierarchy provides clear separation of concerns**: Orchestrators manage workflow state, coordinators manage parallel execution, specialists provide domain expertise

2. **Metadata-only passing achieves 95%+ context reduction**: By extracting only essential information (110 tokens) instead of full artifacts (2,500 tokens), the pattern dramatically reduces context consumption

3. **Hard barrier pattern enforces mandatory delegation**: Path pre-calculation + artifact validation prevents orchestrators from bypassing coordinators and performing work directly

4. **Wave-based parallel execution provides 40-60% time savings**: By analyzing phase dependencies and executing independent phases in parallel, total workflow time is reduced significantly

5. **Partial success mode (≥50% threshold) provides graceful degradation**: Coordinators can proceed with partial results if majority of specialists succeed, improving workflow resilience

6. **Structured error return protocol enables queryable error tracking**: Standardized error types and ERROR_CONTEXT format allow errors to be logged centrally and queried via `/errors` command

7. **Three-block structure (Setup → Execute → Verify) prevents delegation bypass**: Bash verification blocks between Task invocations make it impossible for orchestrators to skip coordinator delegation

8. **Coordinator reusability across commands reduces duplication**: Same research-coordinator used by `/lean-plan`, `/create-plan`, `/research` commands; same pattern applicable to testing, debug, repair domains

### Implementation Findings

9. **Research-coordinator successfully integrated into planning commands**: Validated in `/lean-plan` and `/create-plan` with 95.6% context reduction and parallel multi-topic research

10. **Implementer-coordinator successfully integrated into `/lean-implement`**: Achieved 96% context reduction via brief summary parsing (80 tokens vs 2,000 full file)

11. **Integration tests demonstrate pattern reliability**: 48 tests across lean-plan and lean-implement coordinators with 100% pass rate

12. **Iteration capacity increased 3x**: From 3-4 iterations before context exhaustion to 10+ iterations after coordinator integration

13. **Two operating modes support flexible invocation**: Automated decomposition (coordinator decomposes topics) and manual pre-decomposition (orchestrator provides pre-calculated topics/paths)

14. **Lean command coordinator optimization demonstrates dual coordinator benefits**: Research-coordinator for planning phase + implementer-coordinator for execution phase = compound context reduction

### Pattern Selection Findings

15. **Complexity-based decision matrix guides pattern selection**: Clear criteria for when to use 1-tier (direct), 2-tier (orchestrator → specialist), or 3-tier (orchestrator → coordinator → specialist)

16. **Parallelization benefit is key decision factor**: If tasks are sequential with no parallel opportunities, 2-tier pattern is sufficient; coordinator overhead not justified

17. **Context reduction justifies pattern for high-volume outputs**: When specialists produce >1,000 tokens each, coordinator metadata aggregation provides significant value

18. **Hard barrier enforcement critical for context discipline**: Without barriers, orchestrators tend to bypass delegation and perform work directly, defeating context reduction benefits

## Recommendations

### Immediate Recommendations

1. **Apply three-tier pattern to testing domain**: Create testing-coordinator agent for parallel test-specialist invocation across test modules/suites (40-50% time savings expected)

2. **Apply three-tier pattern to debug domain**: Create debug-coordinator agent for parallel investigation vectors (50-60% time savings, comprehensive hypothesis coverage)

3. **Apply three-tier pattern to repair domain**: Create repair-coordinator agent for parallel error dimension analysis (40-50% time savings, holistic repair recommendations)

4. **Document coordinator template with copy-paste examples**: Provide reusable coordinator template in `.claude/agents/templates/coordinator-template.md` for easy pattern adoption

5. **Create migration checklist for two-tier to three-tier conversion**: Step-by-step guide for identifying parallelization opportunities, creating coordinators, updating orchestrators, and validating results

### Architectural Recommendations

6. **Standardize metadata format across all coordinators**: Use consistent JSON schema for metadata (path, title, key_counts, status, brief_summary) to enable uniform parsing

7. **Implement sub-coordinator pattern for complex domains**: For complexity 4 workflows, introduce sub-coordinators (e.g., research-coordinator invokes domain-specific coordinators)

8. **Enforce hard barrier pattern via pre-commit hooks**: Add validation that orchestrator blocks follow Setup → Execute → Verify structure with mandatory verification

9. **Extend partial success mode to all coordinators**: Use ≥50% threshold as standard for all coordinator implementations (fail if <50%, warn if 50-99%, succeed if 100%)

10. **Create coordinator-specific error types**: Add `coordinator_error` type for coordinator-level failures (e.g., metadata extraction failure across all specialists)

### Integration Recommendations

11. **Integrate research-coordinator into `/repair` command**: Use for parallel error pattern research (type, command, severity dimensions)

12. **Integrate research-coordinator into `/debug` command**: Use for parallel investigation vector research (symptoms, root causes, dependencies)

13. **Integrate research-coordinator into `/revise` command**: Use for parallel context research before plan revision (impact, dependencies, implementation approaches)

14. **Create implementer-coordinator variants for domain-specific workflows**: Lean-implementer-coordinator (theorem proving), software-implementer-coordinator (code implementation), test-implementer-coordinator (test suite execution)

15. **Document coordinator invocation decision tree**: Create flowchart showing when to use research-coordinator vs research-specialist directly (complexity-based thresholds)

### Quality Assurance Recommendations

16. **Add coordinator integration tests to validation suite**: Create test templates for coordinator validation (parallel execution, metadata extraction, hard barrier enforcement)

17. **Monitor context usage metrics in coordinator executions**: Track actual context reduction percentages to validate 95%+ claims and identify optimization opportunities

18. **Create coordinator performance benchmarks**: Measure time savings from parallel execution and iteration capacity improvements for each coordinator implementation

19. **Validate error return protocol coverage**: Ensure all error types covered by coordinator error handling and properly logged to errors.jsonl

20. **Test partial success mode edge cases**: Validate behavior at exactly 50% threshold, with 0% success (all failures), and with 100% success (all completions)

### Documentation Recommendations

21. **Create command-specific coordinator integration guides**: Document how each command (`/lean-plan`, `/create-plan`, `/test`, `/debug`, `/repair`) uses coordinators

22. **Provide coordinator debugging guide**: Common issues (delegation bypass, metadata extraction failures, hard barrier failures) with troubleshooting steps

23. **Document coordinator-to-coordinator communication patterns**: For sub-coordinator architectures, define how coordinators communicate with each other

24. **Create coordinator performance comparison matrix**: Show before/after metrics for each coordinator integration (context reduction %, time savings %, iteration capacity increase)

25. **Maintain coordinator implementation examples**: Keep hierarchical-agents-examples.md updated with real-world coordinator implementations as they're added to the system
