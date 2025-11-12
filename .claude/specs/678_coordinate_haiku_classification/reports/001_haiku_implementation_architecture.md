# Haiku Classification Implementation Architecture Report

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Haiku classification implementation in plan 678
- **Report Type**: codebase analysis
- **Complexity Level**: 4
- **Source Plan**: /home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md

## Executive Summary

Plan 678 implements a comprehensive Haiku-based classification system that replaces all pattern matching with a single LLM call returning workflow type, research complexity (1-4), and descriptive subtopic names. The architecture follows a clean three-layer design: (1) LLM classifier library providing JSON-based communication with Haiku 4.5, (2) hybrid classification layer combining LLM-first with regex fallback, and (3) state machine integration that exports classification results for dynamic path allocation. The implementation achieves zero pattern matching for workflow classification while maintaining 100% reliability through automatic fallback and preserving Phase 0 optimization (85% token reduction).

## Findings

### 1. Core Architecture - Three-Layer Design

The implementation follows a clean separation of concerns across three architectural layers:

#### Layer 1: LLM Classifier Library (workflow-llm-classifier.sh)

**Purpose**: Low-level interface to Claude Haiku 4.5 model

**Key Functions**:
- `classify_workflow_llm_comprehensive()` (lines 99-146): Entry point for comprehensive classification
- `build_llm_classifier_input()` (lines 155-208): Constructs JSON payload with classification instructions
- `invoke_llm_classifier()` (lines 216-265): File-based signaling to AI assistant with timeout
- `parse_llm_classifier_response()` (lines 274-379): Validates JSON response structure

**JSON Schema**:
```json
// Request (lines 169-182)
{
  "task": "classify_workflow_comprehensive",
  "description": "<workflow description>",
  "valid_scopes": ["research-only", "research-and-plan", ...],
  "instructions": "Return: workflow_type, research_complexity (1-4), subtopics array"
}

// Response (parsed lines 292-331)
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": ["Auth patterns in codebase", "Security best practices"],
  "reasoning": "..."
}
```

**Validation Logic** (lines 319-331):
- Research complexity must be 1-4 integer
- Subtopics array count must match complexity
- Confidence must be 0.0-1.0 float
- Workflow type must be one of valid scopes

**Performance**: File-based signaling with 10-second timeout (line 236), 0.5s polling interval (line 257)

#### Layer 2: Hybrid Classification (workflow-scope-detection.sh)

**Purpose**: Orchestrates LLM-first with automatic regex fallback

**Key Functions**:
- `classify_workflow_comprehensive()` (lines 50-106): Main entry point, routes based on mode
- `fallback_comprehensive_classification()` (lines 114-141): Combines regex scope + heuristic complexity
- `infer_complexity_from_keywords()` (lines 149-188): Heuristic calculation matching coordinate.md patterns
- `generate_generic_topics()` (lines 195-205): Fallback topic name generation
- `classify_workflow_regex()` (lines 212-268): Traditional regex patterns (unchanged from Spec 670)

**Classification Modes** (lines 61-105):
- **hybrid** (default): LLM first, fallback on error/timeout/low-confidence (lines 63-77)
- **llm-only**: Fail-fast on LLM errors (lines 80-90)
- **regex-only**: Skip LLM entirely (lines 93-97)

**Complexity Heuristics** (lines 154-185):
Maps keyword indicators to 1-4 scale:
- 0 indicators → complexity 1 (simple)
- 1 indicator → complexity 2 (moderate)
- 2 indicators → complexity 3 (complex)
- 3+ indicators → complexity 4 (highly complex)

Indicators checked: multiple subtopics (and/,/;), complex actions (analyze/research), implementation scope (implement/build), planning/design keywords.

**Fallback Confidence**: 0.6 hardcoded for regex+heuristic classification (line 136)

#### Layer 3: State Machine Integration (workflow-state-machine.sh)

**Purpose**: Calls classification and exports results to workflow state

**Key Integration** (lines 225-301):
- Calls `classify_workflow_comprehensive()` at initialization (line 232)
- Parses JSON response to extract three dimensions (lines 234-238)
- Exports `WORKFLOW_SCOPE`, `RESEARCH_COMPLEXITY`, `RESEARCH_TOPICS_JSON` (lines 241-243)
- **CRITICAL**: Returns `RESEARCH_COMPLEXITY` value for path allocation (line 300)
- Fallback: regex-only + defaults on comprehensive failure (lines 248-256)

**Architectural Innovation**: sm_init() return value enables just-in-time dynamic allocation (lines 298-301). This eliminates Phase 0 pre-allocation tension by determining complexity BEFORE allocating paths.

### 2. Dynamic Path Allocation Pattern

**Implementation** (workflow-initialization.sh lines 326-352):

```bash
# Just-in-time dynamic allocation (Spec 678 enhancement)
for i in $(seq 1 "$research_complexity"); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export exactly $research_complexity paths (zero-indexed)
for i in $(seq 0 $((research_complexity - 1))); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done

export REPORT_PATHS_COUNT="$research_complexity"  # Exact count, no unused variables
```

**Architectural Improvement**:
- **Before**: Allocated 4 paths (fixed capacity), used 1-4 (dynamic usage) → mismatch
- **After**: Allocate exactly N paths where N = RESEARCH_COMPLEXITY → perfect match
- **Benefit**: Zero unused variable exports, cleaner diagnostics, eliminates user confusion

**Coordinate.md Integration** (lines 244-276):
- Receives RESEARCH_COMPLEXITY from sm_init() return value (line 164)
- Passes to initialize_workflow_paths() (line 244)
- Saves all classification results to state (lines 263-264, 267-274)
- Diagnostic message clarifies dynamic allocation (line 276)

### 3. Descriptive Subtopic Names

**State Persistence** (coordinate.md lines 503-523):
- RESEARCH_TOPICS_JSON serialized to state (line 264)
- Reconstructed as array after bash block boundary (line 505)
- Fallback to generic names if state unavailable (line 508)

**Agent Prompt Usage** (lines 515-522):
```bash
# Export descriptive names (not "Topic N")
for i in $(seq 1 4); do
  topic_index=$((i-1))
  if [ $topic_index -lt ${#RESEARCH_TOPICS[@]} ]; then
    export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$topic_index]}"
  else
    export "RESEARCH_TOPIC_${i}=Topic ${i}"  # Fallback
  fi
done
```

**Example**: Instead of "Research Topic 1", agent receives "Authentication patterns in existing codebase" - specific and actionable.

### 4. Pattern Matching Removal

**Complete Elimination** (coordinate.md lines 671-674):
```bash
# RESEARCH_COMPLEXITY loaded from workflow state (set by sm_init in Phase 0)
# Pattern matching removed in Spec 678: comprehensive haiku classification provides
# all three dimensions (workflow_type, research_complexity, subtopics) in single call.
# Zero pattern matching for any classification dimension.
```

**Verification**: Grep search confirms no pattern matching for complexity calculation in coordinate.md. The old logic at lines 402-414 (mentioned in plan) is completely removed.

**Clean Break**: No wrapper functions, no backward compatibility shims. Old `detect_workflow_scope()` function deleted entirely per plan's clean-break philosophy.

### 5. Testing Infrastructure

**Test Coverage**:
- `test_llm_classifier.sh`: 12+ unit tests for LLM classifier library (input validation, JSON handling, timeout, error cases)
- `test_scope_detection*.sh`: Multiple test suites for scope detection (4 files found)
- Comprehensive test validation per Phase 6 of plan

**Test Framework** (test_llm_classifier.sh lines 1-40):
- Pass/fail/skip tracking with colored output
- JSON validation using jq
- Special character and Unicode testing (lines 88-100)

### 6. Documentation and Standards Compliance

**LLM Classification Pattern** (llm-classification-pattern.md):
- Documents hybrid classification architecture (lines 43-56)
- Explains semantic understanding vs regex patterns (lines 21-29)
- Performance metrics: 98%+ accuracy, <2% false positive rate (line 34)
- Cost analysis: $0.03/month typical usage (line 36)

**Model Selection**: Haiku 4.5 chosen for cost efficiency (plan Technical Design section):
- Cost: $0.024/month vs Sonnet $0.090/month (3.75x cheaper)
- Quality: 95%+ accuracy for workflow type, 90%+ for complexity, 85%+ for subtopics
- Task complexity: Medium (3 classification dimensions)

### 7. Error Handling and Fallback Strategy

**Multi-Level Fallback** (workflow-scope-detection.sh lines 63-77):
1. Try LLM comprehensive classification
2. If fails or low confidence → regex scope + heuristic complexity
3. If regex fails → defaults (full-implementation, complexity 2, generic topics)

**Defensive State Loading** (workflow-state-machine.sh lines 247-256):
```bash
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
  # Parse and export results
else
  # Fallback to regex-only + defaults
  WORKFLOW_SCOPE=$(classify_workflow_regex "$workflow_desc" 2>/dev/null || echo "full-implementation")
  RESEARCH_COMPLEXITY=2
  RESEARCH_TOPICS_JSON='["Topic 1", "Topic 2"]'
fi
```

**Zero-Risk Design**: Every classification path has a fallback. System never fails due to LLM unavailability.

### 8. Performance Characteristics

**Haiku Classification Latency**:
- Target: ≤500ms (per plan)
- Timeout: 10 seconds with 0.5s polling (workflow-llm-classifier.sh line 236)
- File-based signaling overhead: Minimal (write/read temp files)

**Phase 0 Optimization Preserved**:
- 85% token reduction maintained (paths pre-calculated, not agent-discovered)
- 25x speedup vs agent-based detection (per CLAUDE.md)
- Enhancement: Dynamic allocation eliminates unused variable exports

**Initialization Overhead**:
- Library loading tracked (coordinate.md lines 233-234)
- Path initialization tracked (lines 250-251)
- Total: ~600ms target including comprehensive classification

### 9. Key Data Structures

**State Variables Exported**:
- `WORKFLOW_SCOPE`: String (research-only, research-and-plan, etc.)
- `RESEARCH_COMPLEXITY`: Integer 1-4
- `RESEARCH_TOPICS_JSON`: JSON array string (for bash subprocess persistence)
- `REPORT_PATHS_COUNT`: Integer matching RESEARCH_COMPLEXITY
- `REPORT_PATH_0` through `REPORT_PATH_N-1`: Individual path variables

**Array Reconstruction Pattern** (coordinate.md line 505):
```bash
mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]' 2>/dev/null || true)
```

This pattern handles bash subprocess isolation (arrays can't be exported) using JSON serialization as intermediate format.

### 10. Integration Points

**Commands Using This Architecture**:
- `/coordinate` (primary consumer, lines 164-276)
- `/orchestrate` (mentioned in CLAUDE.md)
- `/supervise` (mentioned in CLAUDE.md)
- Custom orchestrators (via workflow-scope-detection.sh)

**Library Dependencies**:
- `workflow-llm-classifier.sh` → `workflow-scope-detection.sh` (sourced line 29)
- `workflow-scope-detection.sh` → `workflow-state-machine.sh` (called from sm_init)
- `workflow-initialization.sh` → coordinate.md (dynamic path allocation)
- All libraries → `detect-project-dir.sh` (CLAUDE_PROJECT_DIR detection)

## Recommendations

### 1. Monitor Haiku Classification Accuracy in Production

**Action**: Implement structured logging for classification results with confidence scores, reasoning, and user corrections.

**Rationale**: Plan assumes 90%+ accuracy for complexity and 85%+ for subtopics based on Haiku capabilities. Real-world performance should be tracked to validate these assumptions. If subtopic quality drops below 85%, upgrade to Sonnet per plan's model selection guidance.

**Implementation**: Enhance `log_classification_result()` in workflow-llm-classifier.sh (lines 385-398) to integrate with unified-logger.sh (TODO comment at line 396).

### 2. Add Performance Monitoring Dashboard

**Action**: Track and visualize key metrics: LLM latency, fallback rate, complexity distribution, initialization overhead.

**Rationale**: File-based signaling introduces latency variability. Monitoring helps identify performance regressions and optimize timeout/polling intervals. Target ≤500ms for 95th percentile (plan Performance Targets section).

**Implementation**: Extend unified-logger.sh with performance metrics collection, add dashboard display to /coordinate output.

### 3. Expand Test Coverage for Edge Cases

**Action**: Add test cases for:
- Concurrent execution safety (WORKFLOW_ID-based filenames)
- State persistence across bash block boundaries
- Subtopic count mismatch handling
- Network failures during LLM invocation
- Malformed JSON responses from Haiku

**Rationale**: Current test infrastructure (test_llm_classifier.sh) covers 12+ unit tests but Phase 6 plan requires 25+ comprehensive tests including integration and edge cases. Gap analysis shows missing coverage for concurrent execution and state persistence.

**Implementation**: Create test_comprehensive_classification.sh per Phase 6 plan (line 392-409).

### 4. Document Migration Path for Other Orchestrators

**Action**: Create migration guide showing how /orchestrate and /supervise can adopt comprehensive classification.

**Rationale**: Plan mentions these commands use the architecture (CLAUDE.md state_based_orchestration section) but no migration documentation exists. Coordinate.md implementation provides proven pattern for other commands to follow.

**Implementation**: Add section to coordinate-command-guide.md or create standalone comprehensive-classification-migration-guide.md showing before/after code examples.

### 5. Consider Removing Generic Topic Fallback

**Action**: Evaluate whether "Topic 1", "Topic 2" fallback is necessary or if system should fail-fast when LLM unavailable.

**Rationale**: Current fallback generates generic names (workflow-scope-detection.sh lines 195-205) which provide zero value to research agents. Clean-break philosophy suggests failing loudly instead of degrading silently. However, this conflicts with zero-risk design goal.

**Decision Required**: User preference between (A) graceful degradation with generic topics or (B) fail-fast with explicit error when LLM classification fails. Current implementation chooses (A).

### 6. Optimize JSON Serialization for Large Workflows

**Action**: Profile RESEARCH_TOPICS_JSON serialization/deserialization overhead for workflows with complexity 4 (4 subtopics).

**Rationale**: Mapfile reconstruction (coordinate.md line 505) uses subprocess pipe which may be slow for large arrays. Negligible for 1-4 topics but pattern used elsewhere may scale poorly.

**Implementation**: Add performance benchmarks in test_state_machine.sh measuring serialization overhead for arrays of size 1, 4, 10, 100.

### 7. Validate Model Selection Decision

**Action**: Run production A/B test comparing Haiku 4.5 vs Sonnet for subtopic quality over 30-day period.

**Rationale**: Plan justifies Haiku based on cost ($0.024 vs $0.090/month) and acceptable quality (85%+ for subtopics). Real-world validation confirms whether quality threshold is met or if Sonnet upgrade needed.

**Success Criteria**: If Haiku subtopic quality ≥85% in production, decision validated. If <85%, upgrade to Sonnet per plan contingency.

### 8. Add Complexity Score Calibration

**Action**: Implement feedback loop allowing users to adjust inferred complexity after seeing research results.

**Rationale**: Heuristic complexity calculation (workflow-scope-detection.sh lines 154-185) uses simple keyword matching. User feedback can improve calibration over time or train a better heuristic model.

**Implementation**: Add post-research prompt: "Actual research needed X topics (estimated Y). Update complexity? [yes/no]". Log adjustments for future calibration.

## References

### Primary Implementation Files
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (lines 1-438) - LLM classifier library with comprehensive classification
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (lines 1-293) - Hybrid classification with fallback
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 214-302) - State machine integration
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (lines 320-369) - Dynamic path allocation
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 164-276, 503-523, 671-679) - Command integration

### Testing Infrastructure
- `/home/benjamin/.config/.claude/tests/test_llm_classifier.sh` (lines 1-100+) - LLM classifier unit tests
- `/home/benjamin/.config/.claude/tests/test_scope_detection.sh` - Scope detection tests
- `/home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh` - Workflow classification tests

### Documentation
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md` (lines 1-80) - Pattern documentation
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md` (complete file) - Implementation plan

### Related Specifications
- Spec 670: Initial LLM classification for WORKFLOW_SCOPE (mentioned in plan line 19)
- Spec 672: State persistence patterns (referenced in workflow-state-machine.sh line 177)
- Spec 676: Root cause analysis of diagnostic message confusion (plan Overview section)
- Spec 678: This implementation (all files reference via comments)
