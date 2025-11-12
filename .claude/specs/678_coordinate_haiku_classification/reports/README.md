# Spec 678: Coordinate Haiku Classification Research Reports

## Overview

This directory contains research reports analyzing opportunities to integrate haiku-based complexity classification into the `/coordinate` command initialization sequence.

## Reports

### 001_architecture_context.md (if exists)
Context about current state-based orchestration architecture.

### 002_phase0_and_capture_improvements.md (PRIMARY)
**792 lines of comprehensive analysis**

Complete analysis of three interconnected issues in `/coordinate`:

1. **Phase 0 Pre-Allocation Analysis** (Section 1)
   - Current architecture pre-allocates 4 report paths before complexity is determined
   - Trade-off: 85% token savings vs 3 unused variable exports per 2-topic workflow
   - Design rationale from phase-0-optimization.md

2. **Workflow Capture Performance Analysis** (Section 2)
   - Part 1 takes 45+ seconds (should be instant)
   - 2.5k token overhead suggests Claude Code invokes Haiku backend
   - Root cause: Using Bash tool (not native shell) for simple echo/mkdir operations

3. **Concurrent Execution Vulnerability** (Section 3)
   - Fixed filename `coordinate_workflow_desc.txt` can be overwritten
   - Multiple concurrent `/coordinate` commands interfere with each other
   - Reference to bash-block-execution-model.md Pattern 1 (Fixed Semantic Filenames)

4. **Proposed Haiku-First Architecture** (Section 4)
   - Move RESEARCH_COMPLEXITY determination INTO sm_init()
   - Enable dynamic path allocation (allocate 1-4 paths, not fixed 4)
   - Eliminate architectural tension between capacity and actual usage

5. **Concurrent Execution Fix** (Section 5)
   - Recommendation: Use auto-increment filenames with WORKFLOW_ID
   - Change: `coordinate_workflow_desc.txt` → `coordinate_workflow_desc_${WORKFLOW_ID}.txt`
   - Lowest-risk, immediate impact solution

6. **Implementation Roadmap** (Sections 7-8)
   - Effort assessment for each component
   - Backward compatibility strategy
   - Testing strategy
   - Phased implementation plan
   - Code samples for all changes

## Key Findings

### Finding 1: Pre-Allocation Tension
```
Current: Allocate 4 paths (Phase 0) → Use 1-4 paths (Phase 3)
Proposed: Allocate N paths (Phase 0) where N=RESEARCH_COMPLEXITY
Impact: Exact capacity/usage match, no wasted exports
```

### Finding 2: Initialization Latency
```
Current Part 1: 45+ seconds (Cloud backend invocation)
Current Part 2: 5-10 seconds (Library sourcing)
Proposed: Parallel classification in Part 1b (no latency increase)
```

### Finding 3: Concurrency Risk
```
Current: /coordinate A and /coordinate B overwrite same file
Proposed: Use WORKFLOW_ID in filenames (auto-increment pattern)
Impact: Safe concurrent execution
```

### Finding 4: Architecture Inversion
```
Before: initialize_workflow_paths() → sm_init() → determine_complexity()
After:  sm_init() → determine_complexity() → initialize_workflow_paths()
Benefit: Just-in-time classification, dynamic allocation
```

## Implementation Priority

1. **Quick Win** (2-3 lines): Fix concurrent execution vulnerability
2. **Medium** (50 lines): Enhance sm_init for complexity classification
3. **Medium** (30 lines): Update path allocation to be dynamic
4. **Optional** (parallel architecture): Extract Haiku classification to Part 1b

## Evidence Sources

- `.claude/lib/workflow-initialization.sh:318-344` - Path pre-allocation
- `.claude/commands/coordinate.md:18-40` - Workflow capture
- `.claude/commands/coordinate.md:401-414` - Current complexity determination
- `.claude/lib/workflow-state-machine.sh:214-270` - sm_init function
- `.claude/docs/concepts/bash-block-execution-model.md:163-191` - Pattern 1 reference
- `.claude/docs/guides/phase-0-optimization.md` - Phase 0 rationale
- `.claude/docs/guides/coordinate-command-guide.md` - Architecture documentation

## Related Specs

- **Spec 676**: Coordinate research agent mismatch (hierarchical supervision)
- **Spec 677**: Research-specialist agent architecture
- **Spec 602**: State-based orchestration architecture
- **Spec 644**: Current command implementation analysis

## Next Steps

1. Review report for accuracy
2. Validate code samples against actual implementation
3. Prioritize: Concurrent fix vs full haiku-first architecture
4. Create implementation plan based on priority decision
5. Execute implementation with test coverage

