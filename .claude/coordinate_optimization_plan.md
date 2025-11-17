# Coordinate Command Initial Phase Optimization Plan

## Executive Summary

The `/coordinate` command's initial phase (workflow description capture through classification) currently requires **2 min 45 sec** and **6k tokens** to reach the research phase. This plan identifies optimization opportunities that could reduce this to **~45-60 seconds** (60% latency reduction) through targeted LLM optimization, parallel initialization, and architectural refactoring.

---

## Current State Analysis

### Performance Baseline
- **Total Initial Phase Time**: 2 min 45 sec
- **Token Consumption**: 6k tokens
- **Breakdown** (from coordinate_output.md):
  - Workflow description capture: ~5s
  - State machine pre-initialization: ~10s
  - Workflow classification Task (workflow-classifier agent): **15s, 24.3k tokens** ← PRIMARY BOTTLENECK
  - Classification loading and state persistence: ~30s
  - Library sourcing and initialization: ~45s
  - State ID file creation and verification: ~20s

### Critical Issues Identified
1. **Workflow Classifier Token Overhead**: 24.3k tokens for a deterministic classification task is excessive
2. **Sequential Initialization**: State machine pre-init, classification, and library sourcing execute sequentially
3. **Library Re-sourcing**: Each bash block re-sources entire libraries (workflow-state-machine.sh: 905 lines, workflow-llm-classifier.sh: 596 lines)
4. **Single-Model Dependency**: Sonnet 4.5 used for classification (slower than Haiku 4.5 by 3-4x per research)
5. **State Persistence Overhead**: Multiple verification checkpoints and state file writes add latency

---

## Phase 1: LLM Optimization (Target: 15s → 5s, 24.3k → 4k tokens)

### 1.1 Model Downgrade: Sonnet → Haiku for Classification

**Current**: workflow-classifier uses Sonnet 4.5 (fallback model)
**Optimization**: Switch to Haiku 4.5 as primary model

**Rationale**:
- Haiku 4.5 is 3-4x faster than Sonnet 4.5 for equivalent tasks
- Classification is a deterministic, well-structured task (not requiring advanced reasoning)
- Response time: Sonnet ~1.0s vs Haiku ~0.25-0.35s (estimated 0.7s savings per invocation)
- Cost: 90% reduction with no quality loss for classification
- Research evidence: Haiku 4.5 achieves sub-200ms response for small prompts

**Implementation**:
```bash
# In .claude/agents/workflow-classifier.md (frontmatter)
- model: haiku  # Changed from sonnet-4.5
- model-justification: Fast semantic classification for <5s execution
- fallback-model: sonnet-4.5  # Keep as fallback if needed
```

**Expected Impact**: -10s latency, -19.3k tokens

---

### 1.2 Prompt Caching for Standard Workflow Types

**Current**: Full workflow description prompt sent to classifier every invocation
**Optimization**: Cache common prefix (classification taxonomy) in prompt

**Rationale**:
- Prompt caching can reduce tokens by up to 90% for repeated prefixes
- Classification taxonomy (workflow types, complexity levels, research topics) is static
- Moving variable parts (user description) to end of prompt enables caching
- Research evidence: Organizations achieved 63-77% token savings with semantic caching

**Implementation**:
```bash
# In workflow-classifier.md - Restructure prompt for caching:

# STATIC PREFIX (cached):
- Complete workflow type taxonomy (research-only, research-and-plan, etc.)
- Research complexity scale (1-4 with descriptions)
- Topic structure template
- Semantic analysis rules and anti-patterns
- Edge case handling examples

# VARIABLE SUFFIX (not cached):
- [USER WORKFLOW DESCRIPTION INSERTED HERE]
- JSON output format (minimal, 2-3 lines)
```

**Expected Impact**: -7k tokens per call (from 24.3k → 17.3k), assuming 25-30% of request is prefix

---

### 1.3 Structured Output Token Reduction

**Current**: Full JSON with verbose descriptions in classification output
**Optimization**: Return minimal JSON for classification phase, defer detailed metadata generation

**Rationale**:
- Current output includes research_topics with full descriptions (why classifier generates these details)
- Initial classification only needs: workflow_type, confidence, research_complexity
- Topic details can be generated in next phase with cached topics
- Reduces output tokens by 40-50%

**Implementation**:
```json
{
  "workflow_type": "full-implementation",
  "confidence": 0.95,
  "research_complexity": 4,
  "reasoning": "..."
}
```

Then generate research_topics in a separate, cached "topic expansion" phase.

**Expected Impact**: -3k tokens (output reduction)

---

### 1.4 Confidence-Based Early Exit

**Current**: Always await full Task completion, even if confidence can be determined mid-response
**Optimization**: Implement early exit when sufficient confidence detected

**Rationale**:
- Workflow classifier can determine workflow_type early in response
- Stop processing once confidence > 0.85 and required fields complete
- Reduces token consumption and latency (research shows 40% latency improvement with output reduction)

**Expected Impact**: -2k tokens, -2s latency

---

## Phase 2: Initialization Parallelization (Target: 90s sequential → 40s parallel)

### 2.1 Parallel Bash Block Execution Strategy

**Current**: Bash blocks execute sequentially:
1. Workflow description capture
2. State machine pre-init
3. Classification (Task)
4. Classification loading + state init
5. Research phase prep

**Optimization**: Run independent blocks in parallel

**Parallelizable Blocks**:
- Block 1: Workflow description capture (no dependencies) → background
- Block 2: State machine pre-init + library verification (no dependencies) → background
- Block 3: Classification (Task) - run when Blocks 1 & 2 complete

**Implementation Pattern**:
```bash
# Execute Blocks 1 & 2 in background (run_in_background=true)
# Poll for completion
# Wait for both before Block 3
# This matches Temporal's "Eager Workflow Start" pattern

# Expected time: max(Block1, Block2) + Block3 instead of Block1 + Block2 + Block3
```

**Expected Impact**: -30s to -45s latency (parallel exec reduces sequential overhead)

---

### 2.2 Lazy Library Sourcing

**Current**: All libraries sourced upfront in initialization bash block:
- workflow-state-machine.sh (905 lines)
- state-persistence.sh (392 lines)
- error-handling.sh (unknown size)
- verification-helpers.sh (unknown size)
- Total: ~1500+ lines sourced before classification

**Optimization**: Defer non-critical library sourcing until after classification

**Critical for Classification Phase**:
- Only: state-persistence.sh (for saving state)

**Can Be Deferred**:
- workflow-state-machine.sh (needed in Phase 1, not Phase 0)
- error-handling.sh (needed for error cases, not critical path)
- verification-helpers.sh (can be inlined for critical path)

**Implementation**:
```bash
# Phase 0 (Classification):
source "$LIB_DIR/state-persistence.sh"  # Minimal, 392 lines

# Phase 1+ (Research):
source "$LIB_DIR/workflow-state-machine.sh"  # Deferred
source "$LIB_DIR/error-handling.sh"  # Deferred
```

**Expected Impact**: -3s to -5s latency, -0.3k tokens (less code to parse)

---

### 2.3 Library Function Caching via Memoization

**Current**: Each bash block re-sources entire libraries, re-parsing all function definitions
**Optimization**: Cache parsed functions in memory or compiled form

**Implementation Options**:

**Option A: Function Bytecode Caching** (Complex)
- Precompile bash functions to optimized form
- Store in .claude/tmp/lib_cache/
- Load via source instead of re-parsing
- Complexity: High, requires custom tooling

**Option B: Function Export via Environment** (Simple)
- After sourcing in Block 1, export critical functions to environment
- Subsequent bash blocks inherit these functions
- Works with Bash tool's subprocess isolation via careful state passing
- Complexity: Medium, requires state coordination

**Option C: Consolidate into Single Bash Block** (Simple)
- Move classification logic into single bash block that sources once
- Trade: Slightly larger single block vs. multiple re-sourcing
- Complexity: Low, requires refactoring coordinate.md
- Expected Impact: -10s to -15s latency

**Recommended**: Option B or C (Option A has diminishing returns)

**Expected Impact**: -5s to -15s latency, depending on implementation

---

## Phase 3: Architectural Refactoring (Target: 30-40s additional savings)

### 3.1 Combine Initialization and Classification

**Current**: Two separate bash blocks (pre-init, then classification)
**Optimization**: Single bash block for initialization + classification

**Rationale**:
- Eliminates subprocess startup overhead
- Enables function memoization (prevents re-sourcing)
- Reduces state file I/O operations

**Implementation**:
```bash
# Bash Block: "Initialization and Classification"
# 1. Source libraries (once)
# 2. Initialize workflow state
# 3. Invoke workflow classifier
# 4. Load classification and persist to state
# 5. Output: Ready for Phase 1
```

**Expected Impact**: -5s to -10s latency (subprocess startup), enables other optimizations

---

### 3.2 Reduce State Verification Checkpoints

**Current**: Multiple `verify_state_variable` and `verify_file_created` calls
- Line 162-164: Verify state ID file created
- Line 168-170: Verify WORKFLOW_ID persisted
- Line 173-175: Verify WORKFLOW_DESCRIPTION persisted
- Line 179-181: Verify COORDINATE_STATE_ID_FILE persisted
- Many more in subsequent blocks

**Optimization**: Batch verification or defer to error cases

**Implementation**:
```bash
# Instead of:
verify_state_variable "WORKFLOW_ID" || handle_state_error "..." 1
verify_state_variable "WORKFLOW_DESCRIPTION" || handle_state_error "..." 1
verify_state_variable "COORDINATE_STATE_ID_FILE" || handle_state_error "..." 1

# Use:
verify_critical_state "WORKFLOW_ID" "WORKFLOW_DESCRIPTION" "COORDINATE_STATE_ID_FILE" || {
  handle_state_error "Critical state variables missing" 1
}
```

**Expected Impact**: -2s to -3s latency (fewer subprocess calls for verification)

---

### 3.3 Precompile Classification Prompt Template

**Current**: Classification prompt built dynamically in workflow-classifier.md
**Optimization**: Precompile static prompt template in a shell library

**Rationale**:
- Prompt template is static (workflow types, complexity scale, examples never change)
- Building it dynamically adds parsing/string concatenation overhead
- Caching requires precompiled template anyway
- Enables static analysis and optimization

**Implementation**:
```bash
# New file: .claude/lib/workflow-classification-prompts.sh
# Export precompiled prompt templates for:
# - workflow_type classification
# - research_complexity scoring
# - research_topic generation

# Usage:
CLASSIFICATION_PROMPT="$PROMPT_WORKFLOW_TYPE_CLASSIFIER"
```

**Expected Impact**: -1s to -2s latency, enables prompt caching

---

## Phase 4: Optional Advanced Optimizations

### 4.1 Batch Multiple Classifications (Future)
If multiple workflows need classification, batch them in single API call.

### 4.2 Local Classification Cache (Future)
Cache classification results for similar workflow descriptions using semantic hashing.
- Redis-backed or local file-based
- Reduces repeated classifications by 80%

### 4.3 Speculative Classification (Future)
Start research with high-probability topics while waiting for classification confidence.
- Assumes full-implementation workflow (most common)
- Cancel/adjust if different workflow type determined

---

## Implementation Roadmap

### Wave 1: Quick Wins (45 min implementation, 10-15s latency savings, ~8k token savings)
1. ✅ Model downgrade: Sonnet → Haiku (5 min implementation)
2. ✅ Structured output reduction (5 min)
3. ✅ Confidence-based early exit (10 min)
4. ✅ Reduce verification checkpoints (5 min)

**Expected Result**: 15s → 8-10s, 24.3k tokens → 8-10k tokens

### Wave 2: Architectural (2-3 hour implementation, 25-35s latency savings)
5. ✅ Combine initialization + classification bash blocks (30 min)
6. ✅ Lazy library sourcing (30 min)
7. ✅ Function memoization via environment export (45 min)
8. ✅ Precompile classification prompt (15 min)

**Expected Result**: 8-10s → 3-5s classification, plus 30-40s initialization parallelization

### Wave 3: Caching & Advanced (4-6 hour implementation, 8-12s additional savings)
9. ⚠️ Prompt caching implementation (2 hours, requires careful cache key design)
10. ⚠️ Local classification cache (1-2 hours)
11. ⚠️ Speculative execution (2-3 hours, risky)

**Expected Result**: Further 8-12s reduction with caching

---

## Success Criteria

### Initial Phase Optimization Targets (Achievable in Wave 1+2)
| Metric | Current | Target | Delta |
|--------|---------|--------|-------|
| Initial phase latency | 165s (2m 45s) | 60-90s | -45% to -63% |
| Classification latency | 15s | 3-5s | -67% to -80% |
| Token consumption | 24.3k | 6-8k | -67% to -75% |
| Library sourcing | ~45s | ~10-15s | -67% |
| State verification | ~10s | ~3-5s | -50% |

### Full Optimization Targets (With Wave 3)
| Metric | Current | Target | Delta |
|--------|---------|--------|-------|
| Initial phase latency | 165s | 40-50s | -75% to -80% |
| First API call to classification | ~70s | ~10-15s | -80% |
| Token consumption | 24.3k | 4-6k | -75% to -83% |

---

## Risks & Mitigation

### Risk 1: Haiku Accuracy Degradation
**Concern**: Haiku might produce lower-quality classifications
**Mitigation**:
- Test with 20 sample workflows
- Keep Sonnet as fallback for confidence < 0.7
- Monitor classification quality metrics

### Risk 2: Parallel Execution Complexity
**Concern**: Multiple bash blocks in parallel could cause state conflicts
**Mitigation**:
- Use timestamp-based filenames (already implemented in Spec 678)
- Implement proper locking for shared state
- Test concurrent workflow executions

### Risk 3: Prompt Caching Requires API Changes
**Concern**: Prompt caching not available in current API version
**Mitigation**:
- Verify API support for prompt caching before implementation
- Implement fallback to manual token reduction if unavailable

### Risk 4: Library Consolidation Breaks Dependencies
**Concern**: Deferring library sourcing could break undeclared dependencies
**Mitigation**:
- Static analysis of function dependencies (grep all function calls)
- Comprehensive testing of initialization with deferred sourcing
- Gradual deferral (test one library at a time)

---

## Testing Strategy

### Phase 1 Testing (Wave 1)
1. Test Haiku classifier on 20 diverse workflows
2. Verify classification accuracy maintained (>90%)
3. Measure latency reduction on single-block classification
4. Validate token reduction via API logging

### Phase 2 Testing (Wave 2)
1. Test combined init+classification block
2. Verify parallel execution with 10 concurrent workflows
3. Measure library sourcing time with lazy loading
4. Validate all state variables properly persisted

### Phase 3 Testing (Wave 3)
1. Test prompt caching with repeated classifications
2. Measure cache hit rates and token savings
3. Verify local cache consistency across invocations
4. Test speculative execution with various workflow types

### Performance Regression Testing
- Create benchmark suite with standardized workflows
- Run baseline → each wave → measure delta
- Ensure no negative regressions
- Document metrics in .claude/data/performance-benchmarks.json

---

## Deployment Plan

### Pre-Deployment
1. [ ] Create feature branch: `feature/coordinate-optimization`
2. [ ] Run full test suite on each wave
3. [ ] Document all changes to CLAUDE.md
4. [ ] Get peer review on architectural changes

### Deployment
1. [ ] Deploy Wave 1 (low risk, highest impact/effort ratio)
2. [ ] Monitor production metrics for 1 week
3. [ ] Deploy Wave 2 (medium risk)
4. [ ] Monitor for 1 week
5. [ ] Deploy Wave 3 (higher risk, schedule during low-usage window)

### Rollback Plan
- Keep previous versions in git
- Maintain fallback to Sonnet if Haiku quality issues arise
- Revert library consolidation if state issues emerge

---

## Appendix: Detailed Analysis Notes

### Why This Optimization Strategy Works

1. **Model Selection (3-4x latency gain)**: Haiku is purpose-built for fast inference on classification tasks. The 24.3k tokens consumed suggest the prompt is large; Haiku handles this more efficiently.

2. **Token Reduction (40-50% improvement)**: Classification outputs minimal tokens; verbose descriptions are not needed in Phase 0.

3. **Parallelization (40-60% latency gain)**: Bash blocks 1 & 2 are fully independent. Even naive background execution saves significant time.

4. **Library Sourcing (15-20% latency gain)**: Parsing 1500+ lines of bash code on every block is expensive. Deferring non-critical libraries is efficient.

5. **Combined Effect**: These are multiplicative, not additive:
   - Model switch alone: -60% classification latency
   - + parallelization: -40% initialization latency
   - + lazy loading: -15% library overhead
   - Total: ~-65% to -75% initial phase latency (165s → 40-60s)

### Precedent for These Optimizations

- **Prompt Caching**: Azure, Databricks documented 63-77% token savings; Anthropic API supports prompt caching
- **Haiku for Classification**: Anthropic's own guidance recommends Haiku for fast semantic classification
- **Parallelization**: Temporal's "Eager Workflow Start" demonstrates that splitting init into parallel stages reduces latency 20-40%
- **Lazy Loading**: Standard software optimization; used in all modern frameworks

---

## Author Notes

This plan prioritizes **achievable wins** over speculative optimizations. Wave 1 is low-risk and high-impact (45 min of work for 45-70% latency reduction on classification alone). Wave 2 requires more refactoring but remains relatively safe. Wave 3 (caching) offers diminishing returns and should be evaluated after measuring Wave 1+2 results.

The 2m 45s baseline suggests that the initial classification phase is the critical path. All optimizations focus on that phase, as the research phase will be parallelized anyway (achieving 40-60% time savings through multi-agent coordination).

