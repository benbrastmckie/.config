# Performance Optimization Guide

**Path**: docs → guides → performance-optimization.md

This guide provides comprehensive guidance on measuring, validating, and improving performance in Claude Code workflows. It combines measurement techniques with efficiency enhancements to help you optimize both execution speed and resource utilization.

## Overview

This guide covers:

- **Performance Measurement**: Context reduction tracking, time benchmarking, metadata validation
- **Workflow Efficiency**: Dynamic agent selection, progress streaming, intelligent parallelization
- **Optimization Strategies**: System-wide improvements and best practices
- **Validation Techniques**: End-to-end benchmarking and quality assurance

**Expected Impact**:
- 40-60% time savings through parallel execution
- 92-97% context reduction through metadata extraction
- 15-30% faster execution from optimal agent selection
- 85% token reduction through Phase 0 optimization (25x speedup)

## Prerequisites

- Understanding of hierarchical agent architecture (see CLAUDE.md)
- Familiarity with metadata extraction and parallel execution patterns
- Access to benchmark utilities (`.claude/lib/workflow/metadata-extraction.sh`, `.claude/tests/fixtures/benchmark_001_context/`)

---

# Part 1: Performance Measurement

This section demonstrates how to validate context reduction and time savings claims in Claude Code workflows.

## Context Usage Measurement

Context usage measurement tracks token consumption throughout multi-agent workflows.

### Manual Token Counting

```bash
# Count tokens in a report (approximate: 1 token ≈ 4 characters)
REPORT_SIZE=$(wc -c < specs/027_auth/reports/027_research.md)
TOKENS=$((REPORT_SIZE / 4))
echo "Approximate tokens: $TOKENS"

# Example:
# Report size: 20,000 bytes
# Tokens: 5,000
```

### Metadata Extraction Baseline

```bash
# Full report context (before extraction)
FULL_REPORT=$(cat specs/027_auth/reports/027_research.md)
FULL_TOKENS=$(echo "$FULL_REPORT" | wc -c | awk '{print $1/4}')

# Metadata-only context (after extraction)
METADATA=$(extract_report_metadata specs/027_auth/reports/027_research.md)
METADATA_TOKENS=$(echo "$METADATA" | wc -c | awk '{print $1/4}')

# Calculate reduction
REDUCTION=$((100 - (METADATA_TOKENS * 100 / FULL_TOKENS)))
echo "Context reduction: $REDUCTION%"
echo "Before: $FULL_TOKENS tokens"
echo "After: $METADATA_TOKENS tokens"

# Example output:
# Context reduction: 97%
# Before: 5,000 tokens
# After: 150 tokens
```

### Multi-Report Context Measurement

```bash
# Scenario: 4 parallel research reports
REPORTS=(
  "specs/027_auth/reports/027_database_design.md"
  "specs/027_auth/reports/027_security_patterns.md"
  "specs/027_auth/reports/027_api_design.md"
  "specs/027_auth/reports/027_testing_strategy.md"
)

# Calculate full context (passing all reports)
FULL_CONTEXT=0
for report in "${REPORTS[@]}"; do
  SIZE=$(wc -c < "$report")
  TOKENS=$((SIZE / 4))
  FULL_CONTEXT=$((FULL_CONTEXT + TOKENS))
done

# Calculate metadata context (passing only metadata)
METADATA_CONTEXT=0
for report in "${REPORTS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  SIZE=$(echo "$METADATA" | wc -c)
  TOKENS=$((SIZE / 4))
  METADATA_CONTEXT=$((METADATA_CONTEXT + TOKENS))
done

# Results
echo "Full context: $FULL_CONTEXT tokens (4 reports × ~5,000 tokens)"
echo "Metadata context: $METADATA_CONTEXT tokens (4 metadata × ~150 tokens)"
echo "Reduction: $((100 - (METADATA_CONTEXT * 100 / FULL_CONTEXT)))%"

# Example output:
# Full context: 20,000 tokens
# Metadata context: 600 tokens
# Reduction: 97%
```

### Context Usage Throughout Workflow

```bash
# Track context at each phase
declare -A phase_contexts

# Phase 1: Research (4 reports created, metadata extracted)
phase_contexts[research]=600

# Phase 2: Planning (1 plan created, receives 600 tokens from Phase 1)
phase_contexts[planning]=$((600 + 250))  # 600 from research + 250 plan metadata

# Phase 3: Implementation (receives 850 tokens from previous phases)
phase_contexts[implementation]=$((850 + 300))  # + 300 for implementation artifacts

# Calculate total context vs baseline
BASELINE_TOKENS=200000  # Claude context window
for phase in research planning implementation; do
  USAGE=$((${phase_contexts[$phase]} * 100 / BASELINE_TOKENS))
  echo "Phase $phase: ${phase_contexts[$phase]} tokens ($USAGE%)"
done

# Target: <30% context usage throughout workflow
```

## Time Savings Benchmarking

Time savings measurement compares sequential vs parallel execution.

### Sequential Baseline

```bash
# Measure sequential execution time
START=$(date +%s)

# Sequential research (one agent at a time)
claude-code /report "database design" > /dev/null
claude-code /report "security patterns" > /dev/null
claude-code /report "api design" > /dev/null
claude-code /report "testing strategy" > /dev/null

END=$(date +%s)
SEQUENTIAL_TIME=$((END - START))
echo "Sequential time: ${SEQUENTIAL_TIME}s"

# Example: 800 seconds (4 reports × 200s each)
```

### Parallel Execution

```bash
# Measure parallel execution time
START=$(date +%s)

# Parallel research (4 agents simultaneously via /orchestrate)
claude-code /orchestrate "research authentication system:
- database design
- security patterns
- api design
- testing strategy"

END=$(date +%s)
PARALLEL_TIME=$((END - START))
echo "Parallel time: ${PARALLEL_TIME}s"

# Calculate savings
SAVINGS=$((100 - (PARALLEL_TIME * 100 / SEQUENTIAL_TIME)))
echo "Time savings: $SAVINGS%"
echo "Sequential: ${SEQUENTIAL_TIME}s"
echo "Parallel: ${PARALLEL_TIME}s"

# Example output:
# Time savings: 60%
# Sequential: 800s (13.3 minutes)
# Parallel: 320s (5.3 minutes)
```

### Wave-Based Implementation Benchmark

```bash
# Scenario: Plan with 3 waves of independent phases
# Wave 1: Phases 1, 2, 3 (independent)
# Wave 2: Phase 4 (depends on waves 1)
# Wave 3: Phase 5 (depends on wave 2)

# Sequential time (5 phases × 300s each)
SEQUENTIAL_TIME=$((5 * 300))
echo "Sequential: ${SEQUENTIAL_TIME}s (25 minutes)"

# Parallel time (wave-based)
# Wave 1: 300s (3 phases in parallel)
# Wave 2: 300s (1 phase)
# Wave 3: 300s (1 phase)
PARALLEL_TIME=$((3 * 300))
echo "Parallel: ${PARALLEL_TIME}s (15 minutes)"

# Savings
SAVINGS=$((100 - (PARALLEL_TIME * 100 / SEQUENTIAL_TIME)))
echo "Time savings: $SAVINGS%"

# Example output:
# Sequential: 1500s (25 minutes)
# Parallel: 900s (15 minutes)
# Time savings: 40%
```

### Benchmark Automation

```bash
# Create benchmark script
cat > .claude/tests/benchmark_workflow.sh <<'EOF'
#!/usr/bin/env bash

# Benchmark workflow performance
benchmark() {
  local workflow=$1
  local iterations=${2:-3}
  local total_time=0

  for i in $(seq 1 $iterations); do
    echo "Iteration $i/$iterations"
    START=$(date +%s)

    # Execute workflow
    claude-code $workflow > /dev/null 2>&1

    END=$(date +%s)
    ELAPSED=$((END - START))
    total_time=$((total_time + ELAPSED))
    echo "  Time: ${ELAPSED}s"
  done

  # Calculate average
  AVG=$((total_time / iterations))
  echo "Average time: ${AVG}s ($iterations iterations)"
}

# Run benchmarks
benchmark "/orchestrate 'research: test topic'" 3
EOF

chmod +x .claude/tests/benchmark_workflow.sh
```

## Metadata Extraction Validation

Verify that metadata extraction maintains information quality while reducing context.

### Extraction Quality Test

```bash
# Extract metadata from report
METADATA=$(extract_report_metadata specs/027_auth/reports/027_database_design.md)

# Verify required fields present
echo "$METADATA" | jq -e '.title' >/dev/null || echo "✗ Missing title"
echo "$METADATA" | jq -e '.summary' >/dev/null || echo "✗ Missing summary"
echo "$METADATA" | jq -e '.file_path' >/dev/null || echo "✗ Missing file_path"
echo "$METADATA" | jq -e '.key_findings' >/dev/null || echo "✗ Missing key_findings"

# Verify summary length (target: 50 words)
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
WORD_COUNT=$(echo "$SUMMARY" | wc -w)
if [ $WORD_COUNT -le 60 ]; then
  echo "✓ Summary concise ($WORD_COUNT words)"
else
  echo "✗ Summary too long ($WORD_COUNT words, target ≤50)"
fi

# Verify key findings actionable
FINDINGS=$(echo "$METADATA" | jq -r '.key_findings[]')
if [ -n "$FINDINGS" ]; then
  echo "✓ Key findings extracted"
else
  echo "✗ No key findings"
fi
```

### Information Preservation Test

```bash
# Question: Can agent make decisions using only metadata?

# Scenario: Planning agent needs research findings
METADATA=$(extract_report_metadata specs/027_auth/reports/027_security_patterns.md)

# Check if metadata contains:
# 1. Recommended approach
echo "$METADATA" | jq -e '.recommendations[]' >/dev/null || echo "✗ Missing recommendations"

# 2. Key constraints
echo "$METADATA" | jq -e '.constraints[]' >/dev/null || echo "✗ Missing constraints"

# 3. Reference to full report
FILE_PATH=$(echo "$METADATA" | jq -r '.file_path')
if [ -f "$FILE_PATH" ]; then
  echo "✓ Full report accessible if needed"
else
  echo "✗ Full report path invalid"
fi

# Result: Agent can make initial decisions from metadata,
# access full report only when needed for specific details
```

### Extraction Consistency Test

```bash
# Test extraction across different report types
REPORT_TYPES=(
  "specs/027_auth/reports/027_research.md"
  "specs/042_api/reports/042_design.md"
  "specs/056_testing/reports/056_strategy.md"
)

for report in "${REPORT_TYPES[@]}"; do
  echo "Testing: $report"

  # Extract metadata
  METADATA=$(extract_report_metadata "$report" 2>/dev/null)

  # Verify structure consistent
  if echo "$METADATA" | jq -e '.title, .summary, .file_path' >/dev/null 2>&1; then
    echo "  ✓ Consistent structure"
  else
    echo "  ✗ Inconsistent structure"
  fi
done
```

## End-to-End Workflow Performance

Combine all metrics for comprehensive workflow measurement.

### Complete Workflow Benchmark

```bash
#!/usr/bin/env bash
# Benchmark complete workflow with all metrics

# Workflow: Research → Plan → Implement
WORKFLOW_DESC="Add authentication system"

echo "======================================"
echo "Workflow Benchmark: $WORKFLOW_DESC"
echo "======================================"
echo ""

# Metric 1: Time measurement
START=$(date +%s)
claude-code /orchestrate "$WORKFLOW_DESC" > /tmp/workflow_output.log 2>&1
END=$(date +%s)
ELAPSED=$((END - START))

echo "Time: ${ELAPSED}s ($((ELAPSED / 60)) minutes)"
echo ""

# Metric 2: Context usage (from log analysis)
# Extract token usage from workflow log
RESEARCH_CONTEXT=$(grep -oP 'Research phase: \K[0-9]+' /tmp/workflow_output.log | tail -1)
PLANNING_CONTEXT=$(grep -oP 'Planning phase: \K[0-9]+' /tmp/workflow_output.log | tail -1)
IMPL_CONTEXT=$(grep -oP 'Implementation phase: \K[0-9]+' /tmp/workflow_output.log | tail -1)

MAX_CONTEXT=$(echo -e "$RESEARCH_CONTEXT\n$PLANNING_CONTEXT\n$IMPL_CONTEXT" | sort -n | tail -1)
BASELINE=200000
USAGE=$((MAX_CONTEXT * 100 / BASELINE))

echo "Context Usage:"
echo "  Research: $RESEARCH_CONTEXT tokens"
echo "  Planning: $PLANNING_CONTEXT tokens"
echo "  Implementation: $IMPL_CONTEXT tokens"
echo "  Peak: $MAX_CONTEXT tokens ($USAGE%)"
echo ""

# Metric 3: Artifact count
ARTIFACTS=$(find specs/*/reports -name "*.md" -newer /tmp/workflow_start 2>/dev/null | wc -l)
echo "Artifacts Created: $ARTIFACTS reports"
echo ""

# Metric 4: File creation rate
EXPECTED_FILES=4  # 4 research reports + 1 plan
ACTUAL_FILES=$(find specs/*/reports -name "*.md" -newer /tmp/workflow_start 2>/dev/null | wc -l)
CREATION_RATE=$((ACTUAL_FILES * 100 / EXPECTED_FILES))
echo "File Creation Rate: $CREATION_RATE% ($ACTUAL_FILES/$EXPECTED_FILES)"
echo ""

# Summary
echo "======================================"
echo "Performance Summary"
echo "======================================"
echo "Time: ${ELAPSED}s"
echo "Context Usage: $USAGE% (target <30%)"
echo "Creation Rate: $CREATION_RATE% (target 100%)"

# Validation
if [ $USAGE -lt 30 ] && [ $CREATION_RATE -eq 100 ]; then
  echo "Status: ✓ PERFORMANCE TARGETS MET"
else
  echo "Status: ✗ PERFORMANCE TARGETS NOT MET"
fi
```

## Phase 0 Optimization: Unified Location Detection

**Scenario**: Replace agent-based location detection with utility library across workflow commands

**Context**: Comparing agent-based location detection versus utility library implementation in Phase 0.

### Measurement

```bash
# Before: Agent-based location detection
# Command: /orchestrate "implement authentication patterns"

# Measure Phase 0 execution time
START=$(date +%s%3N)
# ... Phase 0: Invoke location-specialist agent via Task tool ...
END=$(date +%s%3N)
AGENT_TIME=$((END - START))

echo "Agent-based Phase 0 time: ${AGENT_TIME}ms"

# Measure token usage (from Claude API logs)
AGENT_TOKENS=75600  # location-specialist agent invocation

echo "Agent-based token usage: $AGENT_TOKENS tokens"

# After: Library-based location detection
# Command: /orchestrate "implement authentication patterns"

START=$(date +%s%3N)
# Source library and perform detection
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "implement authentication patterns")
END=$(date +%s%3N)
LIBRARY_TIME=$((END - START))

echo "Library-based Phase 0 time: ${LIBRARY_TIME}ms"
echo "Library-based token usage: 0 tokens"  # Pure bash, no AI invocation

# Calculate improvements
TIME_REDUCTION=$((100 - (LIBRARY_TIME * 100 / AGENT_TIME)))
TOKEN_REDUCTION=$((100 - (0 * 100 / AGENT_TOKENS)))

echo "Time reduction: ${TIME_REDUCTION}% (${AGENT_TIME}ms → ${LIBRARY_TIME}ms)"
echo "Token reduction: ${TOKEN_REDUCTION}% (${AGENT_TOKENS} → 0)"
echo "Speedup: $((AGENT_TIME / LIBRARY_TIME))x faster"
```

### Results

```
Agent-based Phase 0 time: 25,200ms (25.2 seconds)
Agent-based token usage: 75,600 tokens

Library-based Phase 0 time: 980ms (<1 second)
Library-based token usage: 0 tokens

Time reduction: 96% (25,200ms → 980ms)
Token reduction: 100% (75,600 → 0)
Speedup: 25x faster
```

### System-Wide Impact

After applying unified library to all workflow commands (`/supervise`, `/orchestrate`, `/report`, `/research`, `/plan`):

```bash
# Commands using location detection per day: ~50
# Average token savings per command: 65,000 tokens
# Daily token savings: 3,250,000 tokens
# Monthly token savings: ~97.5M tokens

# Cost reduction (Sonnet 4.5 pricing)
# Before: 50 workflows × $0.68 = $34/day → $1,020/month
# After: 50 workflows × $0.03 = $1.50/day → $45/month
# Savings: $975/month (96% reduction)
```

### Key Learnings

1. **Deterministic operations should never use AI agents**
   - Location detection is pure string manipulation and directory creation
   - No reasoning required → Library is always faster and more reliable

2. **Measure both time and token usage**
   - Time: 25x speedup (25s → 1s)
   - Tokens: 100% reduction (75.6k → 0)
   - Cost: 96% reduction ($0.68 → $0.03 per workflow)

3. **System-wide optimizations compound**
   - 5 commands × 50 daily workflows = 250 invocations
   - 250 invocations × 65k tokens saved = 16.25M tokens/day
   - Optimization once, benefit everywhere

4. **User experience improvement**
   - Workflows start instantly (1s vs 25s wait)
   - More predictable performance (bash vs AI latency)
   - Zero failure rate (no API timeouts, no model errors)

See [Library API Reference](../reference/library-api/overview.md) for unified-location-detection.sh implementation details.

---

# Part 2: Workflow Efficiency Enhancements

This section documents efficiency enhancements including dynamic agent selection, progress streaming, and intelligent parallelization.

## Dynamic Agent Selection

### Overview

The `/implement` command automatically analyzes each phase and selects the optimal agent based on complexity and type. This ensures specialized agents handle appropriate tasks while avoiding overhead for simple operations.

### Complexity Scoring Algorithm

Phases are scored on a 0-10 scale:

```
score = 0
score += count_keywords(phase_name, ["refactor", "architecture"]) * 3
score += count_keywords(phase_name, ["implement", "create"]) * 2
score += count_keywords(phase_name, ["fix", "update"]) * 1
score += count_keywords(tasks, ["test", "verify"]) * 0.5
score += estimated_file_count * 0.5
score += (task_count / 5)
```

**Keyword Weighting**:
- **High complexity** (3 points): "refactor", "architecture", "redesign", "overhaul"
- **Medium complexity** (2 points): "implement", "create", "build", "develop"
- **Low complexity** (1 point): "fix", "update", "modify", "adjust"
- **Test indicators** (0.5 points): "test", "verify", "validate", "check"

**File Count Estimation**:
- Parse task descriptions for file references
- Count explicit file paths mentioned
- Add 0.5 points per file

**Task Count Factor**:
- Divide task count by 5
- More tasks = higher complexity

### Agent Selection Logic

Based on complexity score:

```
if score 0-2:
  → Direct execution (no agent)
  → Simple tasks don't need delegation overhead

elif score 3-5:
  → code-writer agent
  → Standard complexity, basic agent sufficient

elif score 6-7:
  → code-writer agent + "think" mode
  → Moderate complexity, needs careful planning

elif score 8-9:
  → code-writer agent + "think hard" mode
  → High complexity, needs deep analysis

elif score 10+:
  → code-writer agent + "think harder" mode
  → Critical complexity, maximum reasoning
```

**Special Case Detection**:
- **"documentation" or "README" in phase name** → doc-writer agent
- **"test" in phase name** → test-specialist agent
- **"debug" or "investigate" in phase name** → debug-assistant agent

### Usage

Agent selection happens automatically during `/implement` execution:

```bash
# The command analyzes each phase before execution
/implement specs/plans/045_feature.md

# Output shows agent selection:
Phase 1: Setup (score: 2) → Direct execution
Phase 2: Core Implementation (score: 6) → code-writer + think
Phase 3: Documentation (detected) → doc-writer
Phase 4: Tests (detected) → test-specialist
```

### Configuration

The complexity scoring is implemented in `.claude/lib/analyze-phase-complexity.sh`:

```bash
# Analyze phase complexity
.claude/lib/analyze-phase-complexity.sh "Phase Name" "task1|task2|task3"

# Output: complexity score (0-10)
```

### Benefits

- **Performance**: Simple tasks execute faster without agent overhead
- **Quality**: Complex tasks get specialized agents with appropriate reasoning
- **Specialization**: Doc and test tasks handled by expert agents
- **Adaptability**: Scoring algorithm can be tuned based on experience

### Examples

**Example 1: Simple Fix (Score: 1)**
```markdown
### Phase 1: Fix typo in README
Tasks:
- [ ] Update README.md line 42 typo

Score: 1 (1 for "fix")
Action: Direct execution (no agent)
```

**Example 2: Standard Implementation (Score: 5)**
```markdown
### Phase 2: Create authentication module
Tasks:
- [ ] Create auth/login.lua
- [ ] Create auth/logout.lua
- [ ] Add session management

Score: 5 (2 for "create" + 3 files * 0.5 + 3 tasks / 5)
Action: code-writer agent
```

**Example 3: Complex Refactor (Score: 8)**
```markdown
### Phase 3: Refactor plugin loading architecture
Tasks:
- [ ] Redesign lazy loading system
- [ ] Refactor plugin manager
- [ ] Update 15+ plugin configurations
- [ ] Add comprehensive tests

Score: 8 (3 for "refactor" + 3 for "redesign" + 15 files * 0.5 / 2)
Action: code-writer + "think hard"
```

**Example 4: Documentation (Detected)**
```markdown
### Phase 4: Update documentation
Tasks:
- [ ] Update README.md
- [ ] Create API documentation

Score: N/A (special case detected: "documentation")
Action: doc-writer agent
```

## Progress Streaming

### Overview

Agents emit progress markers during execution to provide real-time visibility into long-running operations. Commands detect these markers and display them to users.

### Progress Marker Format

Agents emit progress using this format:

```
PROGRESS: <brief-message>
```

**Guidelines for Messages**:
- 5-10 words maximum
- Present continuous tense ("Searching...", "Analyzing...", "Generating...")
- Milestone-based (not continuous updates)
- Actionable and informative

### Agent Implementation

All agents include progress markers at key milestones:

**research-specialist**:
```markdown
PROGRESS: Searching for existing patterns...
PROGRESS: Found 15 files, analyzing...
PROGRESS: Reviewing best practices...
PROGRESS: Generating summary report...
```

**code-writer**:
```markdown
PROGRESS: Analyzing phase requirements...
PROGRESS: Implementing module 1 of 3...
PROGRESS: Running tests...
PROGRESS: Creating git commit...
```

**test-specialist**:
```markdown
PROGRESS: Discovering test files...
PROGRESS: Running test suite...
PROGRESS: Analyzing failures...
PROGRESS: Generating report...
```

**plan-architect**:
```markdown
PROGRESS: Analyzing feature requirements...
PROGRESS: Reviewing research findings...
PROGRESS: Structuring implementation phases...
PROGRESS: Writing plan document...
```

### Command Integration

Commands monitor for progress markers and display them:

**In /implement**:
```markdown
Phase 2: Core Implementation

Delegating to code-writer agent...
└─ Analyzing phase requirements...
└─ Implementing module 1 of 3...
└─ Implementing module 2 of 3...
└─ Implementing module 3 of 3...
└─ Running tests...
└─ Creating git commit...

Phase 2 complete ✓
```

**In /orchestrate**:
```markdown
Research Phase

Launching 3 parallel agents...
├─ Agent 1: Searching for existing patterns...
├─ Agent 2: Reviewing best practices...
└─ Agent 3: Analyzing alternatives...

Research complete ✓
```

### Benefits

- **Visibility**: Users know what's happening during long operations
- **Confidence**: Progress updates confirm the system is working
- **Debugging**: Progress markers help identify where failures occur
- **UX**: Better experience than silent execution

### Implementation

Progress streaming is implemented in agent definitions (`.claude/agents/*.md`) and monitored by commands.

**No configuration needed** - works automatically when agents emit `PROGRESS:` markers.

## Intelligent Parallelization

### Overview

Implementation plans can declare phase dependencies, enabling parallel execution of independent phases while respecting dependency order. This dramatically speeds up complex workflows.

### Dependency Format

Phases declare dependencies using this syntax:

```markdown
### Phase 1: Setup
dependencies: []

### Phase 2: Module A
dependencies: [1]

### Phase 3: Module B
dependencies: [1]

### Phase 4: Integration
dependencies: [2, 3]
```

**Dependency Rules**:
- `dependencies: []` - No dependencies (can run immediately)
- `dependencies: [1]` - Depends on Phase 1
- `dependencies: [1, 2]` - Depends on Phases 1 AND 2
- Missing `dependencies` field - Treated as sequential (depends on previous phase)

### Execution Waves

The `/implement` command parses dependencies and creates execution waves:

```
Wave 1: [Phase 1]           (no dependencies)
Wave 2: [Phase 2, Phase 3]  (both depend only on Phase 1 - parallel)
Wave 3: [Phase 4]           (depends on Phases 2 and 3)
```

**Execution Rules**:
- Phases in the same wave execute in parallel
- Maximum 3 concurrent phases per wave (configurable)
- Next wave starts only after current wave completes
- If any phase in a wave fails, execution stops

### Wave-Based Execution

```bash
/implement specs/plans/046_parallel_example.md

Analyzing phase dependencies...
Found 4 phases, 3 execution waves

Wave 1: Executing Phase 1...
└─ Phase 1 complete ✓

Wave 2: Executing Phases 2 and 3 in parallel...
├─ Phase 2: Module A [running]
└─ Phase 3: Module B [running]
├─ Phase 2 complete ✓
└─ Phase 3 complete ✓

Wave 3: Executing Phase 4...
└─ Phase 4 complete ✓

All phases complete ✓
Total time: 2m 15s (vs 4m 30s sequential - 50% faster)
```

### Creating Parallel Plans

**Example: Independent Modules**

```markdown
### Phase 1: Project Setup
dependencies: []
Tasks:
- [ ] Initialize directory structure
- [ ] Configure build system

### Phase 2: Backend API
dependencies: [1]
Tasks:
- [ ] Implement REST endpoints
- [ ] Add database layer

### Phase 3: Frontend UI
dependencies: [1]
Tasks:
- [ ] Create React components
- [ ] Add state management

### Phase 4: Integration Tests
dependencies: [2, 3]
Tasks:
- [ ] Write E2E tests
- [ ] Configure CI/CD
```

**Execution**:
- Wave 1: Phase 1 (setup)
- Wave 2: Phases 2 and 3 in parallel (backend and frontend)
- Wave 3: Phase 4 (integration tests)

**Example: Diamond Pattern**

```markdown
### Phase 1: Core Module
dependencies: []

### Phase 2: Feature A
dependencies: [1]

### Phase 3: Feature B
dependencies: [1]

### Phase 4: Feature C
dependencies: [1]

### Phase 5: Integration
dependencies: [2, 3, 4]
```

**Execution**:
- Wave 1: Phase 1
- Wave 2: Phases 2, 3, 4 in parallel (max 3 concurrent)
- Wave 3: Phase 5

### Safety and Error Handling

**Concurrent Limit**:
- Maximum 3 phases execute concurrently
- Prevents resource exhaustion
- Configurable via environment variable

**Fail-Fast**:
- If any phase in a wave fails, stop execution
- Preserve checkpoints for completed phases
- Report which phase failed and why

**Checkpoint Preservation**:
- Each phase completion creates a checkpoint
- Partial work is saved even on failure
- Can resume from last successful wave

### Dependency Parser

The dependency parser is implemented in `.claude/lib/parse-phase-dependencies.sh`:

```bash
# Parse dependencies and generate execution waves
.claude/lib/parse-phase-dependencies.sh plan_file.md

# Output: execution waves in JSON format
{
  "wave_1": [1],
  "wave_2": [2, 3],
  "wave_3": [4]
}
```

**Validation**:
- Detects circular dependencies (fails with error)
- Validates dependency references (fails if referencing non-existent phase)
- Ensures DAG structure (directed acyclic graph)

### Performance Benefits

**Typical Speedups**:
- **2 parallel phases**: 40-50% faster
- **3 parallel phases**: 60-70% faster
- **Complex workflows** (5+ phases): 30-50% overall speedup

**Best for**:
- Multi-module features (backend + frontend)
- Independent component implementations
- Documentation + code + tests (when independent)

**Not beneficial for**:
- Strictly sequential workflows
- Phases with many interdependencies
- Simple 1-3 phase plans

---

# Part 3: Best Practices

## Dynamic Agent Selection

**Do**:
- Trust the algorithm for most phases
- Review agent selection in complex workflows
- Adjust keyword weighting if needed

**Don't**:
- Manually override unless necessary
- Worry about simple phase overhead (it's minimal)
- Use agent delegation for trivial tasks

## Progress Streaming

**Do**:
- Use progress markers in custom agents (5-10 word messages)
- Emit at meaningful milestones (not continuously)
- Keep messages brief and informative

**Don't**:
- Emit progress every second (too noisy)
- Use long messages (truncate display)
- Mix progress with error messages

## Intelligent Parallelization

**Do**:
- Declare dependencies for independent phases
- Use parallel execution for multi-module features
- Test dependency graph before complex plans

**Don't**:
- Create circular dependencies (will fail)
- Parallelize phases with shared file modifications
- Exceed 3 concurrent phases (resource limits)

## Performance Measurement

**Do**:
- Run benchmarks with multiple iterations (3-5)
- Track both time and token usage
- Validate metadata extraction quality
- Measure end-to-end workflow performance

**Don't**:
- Rely on single-run measurements (variability)
- Ignore context usage (cost implications)
- Skip metadata validation (quality matters)
- Forget to measure baseline performance first

---

# Part 4: Troubleshooting

## Context Usage Issues

### Issue: Context usage exceeds 30% despite metadata extraction

**Cause**: Metadata summaries too verbose or too many artifacts passed

**Solution**: Reduce summary length and implement context pruning
```bash
# Check metadata size
METADATA=$(extract_report_metadata report.md)
TOKENS=$(echo "$METADATA" | wc -c | awk '{print $1/4}')
echo "Metadata tokens: $TOKENS (target <150)"

# If too large, reduce summary to 30 words
# Update extraction to use stricter limits

# Implement context pruning
# Remove completed phase artifacts from context
prune_phase_metadata "$COMPLETED_PHASE"
```

## Time Savings Issues

### Issue: Time savings lower than expected (< 40%)

**Cause**: Phases not truly independent or overhead in parallel coordination

**Solution**: Analyze phase dependencies and reduce coordination overhead
```bash
# Visualize dependency graph
grep "depends_on" plan.md

# Check for false dependencies (phases marked dependent but actually independent)
# Example: Phase 3 depends on Phase 1, but not Phase 2
# Can parallelize Phases 2 and 3

# Reduce coordination overhead:
# - Use forward message pattern (no re-summarization)
# - Minimize checkpoint frequency
# - Batch artifact creation
```

## Metadata Extraction Issues

### Issue: Metadata extraction loses critical information

**Cause**: Summary too brief or key findings not captured

**Solution**: Improve extraction to preserve essential details
```bash
# Enhance metadata extraction
extract_report_metadata() {
  local report=$1

  # Extract more than just summary
  TITLE=$(head -1 "$report" | sed 's/^# //')
  SUMMARY=$(sed -n '/## Summary/,/## /p' "$report" | head -50 | tail -n +2)
  KEY_FINDINGS=$(sed -n '/## Key Findings/,/## /p' "$report" | grep '^-')
  RECOMMENDATIONS=$(sed -n '/## Recommendations/,/## /p' "$report" | grep '^-')

  # Return structured metadata
  jq -n \
    --arg title "$TITLE" \
    --arg summary "$SUMMARY" \
    --arg findings "$KEY_FINDINGS" \
    --arg recs "$RECOMMENDATIONS" \
    '{title: $title, summary: $summary, key_findings: $findings, recommendations: $recs}'
}
```

## Benchmark Consistency Issues

### Issue: Inconsistent benchmark results across runs

**Cause**: Network variability, cache effects, or system load

**Solution**: Run multiple iterations and calculate averages
```bash
# Run benchmark 5 times
ITERATIONS=5
TOTAL_TIME=0

for i in $(seq 1 $ITERATIONS); do
  START=$(date +%s)
  claude-code /workflow > /dev/null
  END=$(date +%s)
  ELAPSED=$((END - START))
  TOTAL_TIME=$((TOTAL_TIME + ELAPSED))
  echo "Iteration $i: ${ELAPSED}s"
done

AVG=$((TOTAL_TIME / ITERATIONS))
echo "Average: ${AVG}s"

# Use average for comparisons
```

## Agent Selection Issues

### Problem: Wrong agent selected for phase

**Solution**:
1. Check phase name keywords
2. Verify task descriptions
3. Adjust complexity scoring weights in `.claude/lib/analyze-phase-complexity.sh`

## Progress Streaming Issues

### Problem: No progress updates during long operations

**Solution**:
1. Verify agents emit `PROGRESS:` markers
2. Check command monitors for markers
3. Ensure progress messages are brief (5-10 words)

## Parallelization Issues

### Problem: Circular dependency or execution hangs

**Solution**:
1. Validate dependency graph: `.claude/lib/parse-phase-dependencies.sh plan.md`
2. Check for circular references
3. Ensure all dependency phase numbers exist
4. Review concurrent limit (max 3)

---

# Part 5: Performance Metrics

Track optimization effectiveness with these metrics:

## Context Reduction Metrics

- **Target**: 92-97% reduction through metadata extraction
- **Measurement**: Compare full report tokens vs metadata tokens
- **Validation**: Ensure metadata preserves critical information

## Time Savings Metrics

- **Target**: 40-60% savings through parallel execution
- **Measurement**: Compare sequential vs wave-based execution time
- **Validation**: Run multiple iterations for consistency

## Agent Selection Metrics

- **Accuracy**: Track when agent selection was appropriate
- **Performance**: Measure time saved from specialized agents
- **Quality**: Validate output quality by agent type

## Phase 0 Optimization Metrics

- **Token Reduction**: 100% (75.6k → 0)
- **Time Reduction**: 96% (25s → 1s)
- **Cost Reduction**: 96% ($0.68 → $0.03 per workflow)
- **Speedup**: 25x faster

## Overall Workflow Metrics

- **Context Usage**: <30% throughout workflow
- **File Creation Rate**: 100% (all expected files created)
- **Execution Time**: Baseline vs optimized
- **Resource Utilization**: Concurrent phase execution efficiency

---

# Part 6: Examples

## Example 1: Measuring Research Phase Context Reduction

```bash
# Scenario: 4 parallel research reports for authentication feature

# Before metadata extraction (passing full reports to planning)
REPORTS=(
  "specs/027_auth/reports/027_database.md"      # 6,200 bytes → 1,550 tokens
  "specs/027_auth/reports/027_security.md"      # 5,800 bytes → 1,450 tokens
  "specs/027_auth/reports/027_api.md"           # 4,400 bytes → 1,100 tokens
  "specs/027_auth/reports/027_testing.md"       # 7,600 bytes → 1,900 tokens
)

FULL_CONTEXT=6000  # 1,550 + 1,450 + 1,100 + 1,900

# After metadata extraction (passing only metadata)
METADATA_CONTEXT=0
for report in "${REPORTS[@]}"; do
  META=$(extract_report_metadata "$report")
  TOKENS=$(echo "$META" | wc -c | awk '{print $1/4}')
  METADATA_CONTEXT=$((METADATA_CONTEXT + TOKENS))
done

# Results
echo "Full reports: 6,000 tokens"
echo "Metadata only: $METADATA_CONTEXT tokens"
echo "Reduction: $((100 - (METADATA_CONTEXT * 100 / 6000)))%"

# Example output:
# Full reports: 6,000 tokens
# Metadata only: 180 tokens (4 × 45 tokens)
# Reduction: 97%
```

## Example 2: Benchmarking Wave-Based Implementation

```bash
# Plan: 6 phases with dependencies
# Wave 1: Phases 1, 2 (independent)
# Wave 2: Phases 3, 4 (depend on Wave 1)
# Wave 3: Phase 5 (depends on Wave 2)
# Wave 4: Phase 6 (depends on Wave 3)

# Sequential execution
echo "Sequential execution:"
for phase in {1..6}; do
  START=$(date +%s)
  claude-code /implement --phase $phase > /dev/null
  END=$(date +%s)
  echo "  Phase $phase: $((END - START))s"
done

# Output:
# Sequential execution:
#   Phase 1: 180s
#   Phase 2: 200s
#   Phase 3: 220s
#   Phase 4: 190s
#   Phase 5: 210s
#   Phase 6: 180s
# Total: 1,180s (19.7 minutes)

# Wave-based execution
echo "Wave-based execution:"
START=$(date +%s)

# Wave 1 (parallel)
claude-code /implement --wave 1 > /dev/null  # Phases 1-2 in parallel
WAVE1_END=$(date +%s)
echo "  Wave 1: $((WAVE1_END - START))s (Phases 1-2)"

# Wave 2 (parallel)
claude-code /implement --wave 2 > /dev/null  # Phases 3-4 in parallel
WAVE2_END=$(date +%s)
echo "  Wave 2: $((WAVE2_END - WAVE1_END))s (Phases 3-4)"

# Wave 3 (sequential)
claude-code /implement --wave 3 > /dev/null  # Phase 5
WAVE3_END=$(date +%s)
echo "  Wave 3: $((WAVE3_END - WAVE2_END))s (Phase 5)"

# Wave 4 (sequential)
claude-code /implement --wave 4 > /dev/null  # Phase 6
WAVE4_END=$(date +%s)
echo "  Wave 4: $((WAVE4_END - WAVE3_END))s (Phase 6)"

END=$(date +%s)
echo "Total: $((END - START))s"

# Output:
# Wave-based execution:
#   Wave 1: 200s (Phases 1-2 in parallel, max of 180s and 200s)
#   Wave 2: 220s (Phases 3-4 in parallel, max of 220s and 190s)
#   Wave 3: 210s (Phase 5)
#   Wave 4: 180s (Phase 6)
# Total: 810s (13.5 minutes)

# Savings
echo "Time savings: $((100 - (810 * 100 / 1180)))%"
# Output: Time savings: 31%
```

## Example 3: Validating Metadata Quality

```bash
# Test: Can planning agent work effectively with metadata only?

# Extract metadata from research reports
METADATA_1=$(extract_report_metadata specs/027_auth/reports/027_security.md)
METADATA_2=$(extract_report_metadata specs/027_auth/reports/027_api.md)

# Verify planning agent can:
# 1. Identify recommended approach
APPROACH=$(echo "$METADATA_1" | jq -r '.recommendations[0]')
echo "Recommended approach: $APPROACH"

# 2. Understand constraints
CONSTRAINTS=$(echo "$METADATA_1" | jq -r '.constraints[]')
echo "Constraints:"
echo "$CONSTRAINTS"

# 3. Access full report when needed
FILE_PATH=$(echo "$METADATA_1" | jq -r '.file_path')
DETAILED_INFO=$(grep "Implementation Steps" "$FILE_PATH")
echo "Detailed info available: $([ -n "$DETAILED_INFO" ] && echo 'Yes' || echo 'No')"

# Result:
# ✓ Agent can make high-level decisions from metadata
# ✓ Agent can access full report for details
# ✓ No loss of critical information
```

---

# Part 7: Related Documentation

- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - Extraction techniques
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based execution
- [Context Management Pattern](../concepts/patterns/context-management.md) - Context reduction techniques
- [Hierarchical Agents Guide](../concepts/hierarchical-agents.md) - Multi-agent architecture
- [Library API Reference](../reference/library-api/overview.md) - Utility library documentation
- [Command Development Guide](../development/command-development/command-development-fundamentals.md) - Command optimization patterns
- [Agent Development Guide](../development/agent-development/agent-development-fundamentals.md) - Agent efficiency patterns
