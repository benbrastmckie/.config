# Research Report: Pattern A Consistency Analysis

## Metadata
- **Date**: 2025-12-09
- **Research Topic**: Applying lean-coordinator optimization patterns (Spec 065) to research-orchestrator library extraction (Spec 063)
- **Research Complexity**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Executive Summary

The recently completed Lean Coordinator Wave Optimization (Spec 065) established several key patterns that should be applied consistently to the lean-plan Coordinator Library Extraction (Spec 063). This research identifies the overlapping patterns and provides recommendations for uniform application.

**Key Finding**: Three optimization patterns from Spec 065 should be integrated into Spec 063:
1. **Brief Summary Format** (96% context reduction)
2. **Metadata-Driven Extraction** (no runtime analysis overhead)
3. **Sequential-by-Default** with explicit parallel indicators

## Pattern Analysis

### Pattern 1: Brief Summary Format

**From Spec 065 (lean-coordinator.md)**:
- Summary files have metadata fields on lines 1-8
- summary_brief field limited to 150 characters
- Brief field parsing extracts 80 tokens vs full file read of 2,000 tokens
- 96% context reduction achieved

**Application to Spec 063 (research-orchestrator.sh)**:
- `aggregate_research_results()` function should generate brief summary metadata
- Summary format: `coordinator_type: research`, `summary_brief: "..."`, `reports_completed: [1,2,3]`
- Result aggregation should return brief summary (80 tokens) not full research content

**Recommended Changes**:
```bash
# aggregate_research_results() should return brief metadata format
aggregate_research_results() {
  local report_dir="$1"

  # Count reports
  local report_count=$(find "$report_dir" -name "*.md" -type f | wc -l)

  # Extract brief metadata from each report
  local summaries=""
  for report in "$report_dir"/*.md; do
    local brief=$(head -20 "$report" | grep -m1 "^## Executive Summary" -A3 | tail -1 | cut -c1-50)
    summaries="${summaries}${brief}; "
  done

  # Return brief aggregation (80 tokens target)
  echo "coordinator_type: research"
  echo "summary_brief: \"Completed $report_count research reports. Topics: ${summaries:0:100}\""
  echo "reports_completed: $report_count"
  echo "research_status: complete"
}
```

### Pattern 2: Metadata-Driven Extraction (No Runtime Analysis)

**From Spec 065**:
- Eliminated STEP 2 (Dependency Analysis) completely
- Wave structure extracted from plan metadata (`dependencies:` field)
- No dependency-analyzer utility invocation
- Plan metadata is source of truth

**Application to Spec 063**:
- `decompose_research_topics()` should be deterministic based on input parameters
- No LLM reasoning needed for topic decomposition
- Complexity level directly maps to topic count:
  - Complexity 1-2: 2-3 topics
  - Complexity 3-4: 4-5 topics
- Topic generation uses keyword extraction, not runtime analysis

**Recommended Changes**:
```bash
# decompose_research_topics() should be deterministic
decompose_research_topics() {
  local feature="$1"
  local complexity="$2"

  # Deterministic topic count based on complexity
  local topic_count
  case "$complexity" in
    1) topic_count=2 ;;
    2) topic_count=3 ;;
    3) topic_count=4 ;;
    4) topic_count=5 ;;
    *) topic_count=3 ;;  # Default
  esac

  # Predefined topic categories for research
  # These are extracted from feature description, not analyzed
  local topics=()
  topics+=("Implementation patterns for: $feature")
  topics+=("Best practices and standards for: $feature")

  if [ "$topic_count" -ge 3 ]; then
    topics+=("Architecture considerations for: $feature")
  fi
  if [ "$topic_count" -ge 4 ]; then
    topics+=("Testing strategy for: $feature")
  fi
  if [ "$topic_count" -ge 5 ]; then
    topics+=("Integration requirements for: $feature")
  fi

  # Return newline-separated topics
  printf '%s\n' "${topics[@]:0:$topic_count}"
}
```

### Pattern 3: Sequential-by-Default with Explicit Parallel Indicators

**From Spec 065**:
- Default behavior: sequential execution (one phase per wave)
- Parallel execution only when `parallel_wave: true` + `wave_id` present
- Missing metadata defaults to sequential (fail-safe)
- Plan architect explicitly opts into parallelism

**Application to Spec 063**:
- Default behavior: sequential specialist invocation
- Parallel invocation only when complexity >= 3 AND explicit parallel flag
- Simpler error handling with sequential execution
- Parallel mode requires all prerequisites validated

**Recommended Changes**:
- Add `parallel_research` parameter to `orchestrate_research()`
- Default to `false` (sequential)
- Only set `true` for complexity 3-4 scenarios with parallel indicator
- Add validation before parallel execution

```bash
# orchestrate_research() should default to sequential
orchestrate_research() {
  local feature="$1"
  local complexity="$2"
  local report_dir="$3"
  local parallel="${4:-false}"  # Default: sequential

  # Decompose topics
  local topics=$(decompose_research_topics "$feature" "$complexity")

  # Generate prompts for Task invocations
  local prompts=$(generate_specialist_prompts "$topics" "$report_dir")

  # Return execution mode with prompts
  echo "execution_mode: ${parallel}"
  echo "topic_count: $(echo "$topics" | wc -l)"
  echo "prompts:"
  echo "$prompts"
}
```

## Integration Points

### Spec 065 → Spec 063 Mappings

| Spec 065 Concept | Spec 063 Equivalent | Consistency Action |
|------------------|---------------------|-------------------|
| brief summary format | aggregate_research_results() output | Add brief metadata fields |
| metadata-driven waves | topic decomposition | Make deterministic based on complexity |
| sequential-by-default | specialist invocation | Default to sequential, require explicit parallel flag |
| dual-mode support | N/A | Not applicable (single orchestration mode) |
| checkpoint saving | research checkpoint | Add checkpoint on partial completion |
| context estimation | N/A | Not directly applicable |

### Architecture Alignment

Both specs target the same outcome: **reduced context consumption through inline orchestration logic**.

**Spec 065** achieves this by:
- Removing analysis overhead (STEP 2 elimination)
- Brief summary parsing (96% reduction)
- Plan-driven wave structure

**Spec 063** should achieve this by:
- Inline coordinator logic (library extraction)
- Brief aggregation output (80 tokens)
- Deterministic topic decomposition

## Recommended Plan Revisions

### Phase 1: Add Brief Summary Format to Library Design

Current: Library returns full aggregation content
Revised: Library returns brief metadata (80 tokens) with full content in file

### Phase 2: Make Topic Decomposition Deterministic

Current: "Topic decomposition - splits research scope into parallel topics"
Revised: "Deterministic topic decomposition based on complexity level (no LLM reasoning)"

### Phase 3: Default to Sequential Specialist Invocation

Current: "Implement parallel Task invocation pattern (multiple Tasks in single block)"
Revised: "Default to sequential invocation; parallel mode requires explicit flag and validation"

### Phase 4: Add Checkpoint Support

Current: Not mentioned
Revised: Add checkpoint saving for partial research completion (aligned with Spec 065 pattern)

## Success Criteria Updates

Add the following success criteria to align with Spec 065 patterns:

- [ ] Brief summary format implemented in `aggregate_research_results()` (80 tokens target)
- [ ] Topic decomposition is deterministic (no LLM reasoning in library)
- [ ] Sequential specialist invocation by default (parallel requires explicit flag)
- [ ] Checkpoint support for partial research completion
- [ ] Context consumption reduced to ~500 tokens (consistent with Spec 065 metrics)

## Conclusion

Applying Pattern A uniformly requires three key changes to Spec 063:

1. **Brief Summary Format**: Add metadata fields to aggregation output (80 tokens)
2. **Deterministic Logic**: Remove any LLM reasoning from library functions
3. **Sequential Default**: Require explicit flag for parallel specialist invocation

These changes ensure consistency between lean-coordinator optimizations (Spec 065) and research-orchestrator library extraction (Spec 063), creating a uniform Pattern A implementation across both domains.
